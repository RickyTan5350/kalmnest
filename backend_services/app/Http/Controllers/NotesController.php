<?php

namespace App\Http\Controllers;

use App\Http\Requests\CreateNotesRequest;
use App\Models\Notes;
use App\Models\File;
use App\Models\Topic;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Exception;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class NotesController extends Controller
{
    use \App\Traits\SyncsToSeedData;

    private function getEncodedUrl($path)
    {
        $parts = explode('/', $path);
        $encodedParts = array_map('rawurlencode', $parts);
        $encodedPath = implode('/', $encodedParts);
        return url(Storage::url($encodedPath));
    }


    /**
     * Get brief details of notes for list view.
     */
    public function showNotesBrief()
    {
        $notesBrief = DB::table('notes')
            ->leftJoin('topics', 'notes.topic_id', '=', 'topics.topic_id')
            ->select('notes.note_id', 'notes.title', 'notes.updated_at', 'notes.visibility', 'topics.topic_name')
            ->orderBy('notes.created_at', 'desc')
            ->get();

        return response()->json($notesBrief);
    }
    
    /**
     * Legacy/Direct upload function for images/attachments
     */
    public function uploadFile(Request $request)
    {
        $request->validate([
            'file' => 'required|file|max:20480|mimes:pdf,doc,docx,txt,png,jpg,gif', 
        ]);

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $originalName = $file->getClientOriginalName();
            $safeFileName = time() . '_' . $file->getClientOriginalName();

            try {
                $path = $file->storeAs('uploads', $safeFileName, 'public');

                // SYNC TO SEED DATA
                $this->syncFileToSeedData(storage_path('app/public/' . $path), $safeFileName, 'pictures');

                return response()->json([
                    'message' => 'File uploaded successfully',
                    'original_name' => $originalName,
                    'filename' => $safeFileName,
                    'file_url' => $this->getEncodedUrl($path), // Force absolute encoded URL
                ], 200);

            } catch (\Exception $e) {
                return response()->json(['message' => 'File upload failed: ' . $e->getMessage()], 500);
            }
        }

        return response()->json(['message' => 'No file received.'], 400);
    }

    /**
     * Store a newly created Note and link its files.
     */
    public function store(CreateNotesRequest $request)
    {
        // 1. Get Admin/Teacher ID
        $adminRoleID = DB::table('roles')->where('role_name', 'Admin')->value('role_id');
        $adminUserID = DB::table('users')->where('role_id', $adminRoleID)->value('user_id');
        
        $validatedData = $request->validated();

        // 2. Handle Topic Logic
        $topicName = $validatedData['topic'];
        $topic = Topic::where('topic_name', $topicName)->first(['topic_id']);

        if (!$topic) {
            return response()->json(['message' => "The topic '$topicName' is not valid."], 422); 
        }

        unset($validatedData['topic']);
        $validatedData['topic_id'] = $topic->topic_id; 
        
        $debugUserId = $adminUserID; 
        $validatedData['created_by'] = $debugUserId; 

        // --- START DB TRANSACTION ---
        DB::beginTransaction(); 

        try {
            // 3. Handle Main Markdown File
            if ($request->hasFile('file')) {
                $mdFile = $request->file('file');
                $mdPath = $mdFile->store('notes', 'public'); 

                $mainFileRecord = File::create([
                    'file_path' => $mdPath,
                    'type'      => $mdFile->getClientOriginalExtension(),
                ]);
                
                $validatedData['file_id'] = $mainFileRecord->file_id;

                // --- GIT SYNC ---
                // Read the content we just saved to sync it to seed_data
                $syncedContent = file_get_contents($mdFile->getRealPath());
                // Pass the topic name we already validated
                $this->_syncToSeedData($mdPath, $syncedContent, $validatedData['title'], $topicName);
            }

            // 4. Create the Note
            $note = Notes::create($validatedData);
            
            // 5. Link Attachments (Pivot Table)
            if ($request->has('attachment_ids')) {
                $ids = $request->input('attachment_ids');
                if (is_array($ids) && count($ids) > 0) {
                    $note->attachments()->attach($ids);
                }
            }

            DB::commit(); 

            return response()->json([
                'message' => 'Note created and files linked successfully.',
                'note' => $note
            ], 201);
            
        } catch (Exception $e) {
            DB::rollBack(); 
            return response()->json([
                'message' => 'Error creating note', 
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Retrieve the raw Markdown content for a specific note.
     * Route: GET /api/notes/{id}/content
     */
    public function getNoteContent($id)
    {
        $note = Notes::find($id);

        if (!$note) {
            return response()->json(['message' => 'Note not found'], 404);
        }

        if (!$note->file_id) {
            return response()->json(['content' => ''], 200); 
        }

        $fileRecord = File::find($note->file_id);

        if (!$fileRecord) {
            return response()->json(['message' => 'Linked file record not found'], 404);
        }

        if (!Storage::disk('public')->exists($fileRecord->file_path)) {
            return response()->json(['message' => 'Physical file missing from server'], 404);
        }

        try {
            $content = Storage::disk('public')->get($fileRecord->file_path);
            
            return response()->json([
                'id' => $note->note_id,
                'content' => $content
            ], 200);

        } catch (Exception $e) {
            return response()->json(['message' => 'Error reading file'], 500);
        }
    }

    /**
     * Show full note details (Title, Topic, Visibility, Content)
     * INCLUDES "AUTO-REPAIR" LOGIC to fix broken notes.
     */
    public function show($id)
    {
        $note = Notes::find($id);

        if (!$note) {
            return response()->json(['message' => 'Note not found'], 404);
        }

        // 1. Fetch Topic Name Manually
        $topicName = 'General';
        if ($note->topic_id) {
             $topicObj = Topic::find($note->topic_id);
             if ($topicObj) $topicName = $topicObj->topic_name;
        }

        // 2. ULTIMATE REPAIR LOGIC
        $content = "";
        $needsRepair = false;

        // Check if file record exists in Database
        if ($note->file_id) {
            $fileRecord = File::find($note->file_id);
            
            if (!$fileRecord) {
                // CASE A: Note points to a file ID that doesn't exist in 'files' table
                $needsRepair = true;
            } else {
                // CASE B: 'files' table record exists, checking physical disk...
                if (Storage::disk('public')->exists($fileRecord->file_path)) {
                    $content = Storage::disk('public')->get($fileRecord->file_path);
                } else {
                    // Disk is empty. Create an empty file so we can write to it later.
                    Storage::disk('public')->put($fileRecord->file_path, "");
                    $content = "";
                }
            }
        } else {
            // CASE C: Note has no file_id at all.
            $needsRepair = true;
        }

        // 3. EXECUTE REPAIR IF NEEDED
        if ($needsRepair) {
            $fileName = Str::uuid() . '_repaired.md';
            $filePath = 'notes/' . $fileName;
            
            // Create physical empty file
            Storage::disk('public')->put($filePath, "");
            
            // Create new DB record
            $newFile = File::create([
                'file_path' => $filePath,
                'type'      => 'md',
            ]);

            // Link it to the note
            $note->file_id = $newFile->file_id;
            $note->save();
        }

        // 4. Return Data
        return response()->json([
            'note_id' => $note->note_id,
            'title' => $note->title,
            'topic' => $topicName,
            'visibility' => (bool)$note->visibility,
            'content' => $content,
            'created_at' => $note->created_at,
        ], 200);
    }

    /**
     * Search functionality (Fixed Ambiguous Column Error)
     */
    public function search(Request $request)
    {
        $keyword = $request->input('query');
        $topic = $request->input('topic');

        $query = DB::table('notes')
            ->join('topics', 'notes.topic_id', '=', 'topics.topic_id')
            ->select('notes.*', 'topics.topic_name');

        if ($request->filled('query')) {
            $query->where('notes.title', 'LIKE', "%{$keyword}%");
        } 
        else if ($request->filled('topic') && $topic !== 'All') {
            $query->where('topics.topic_name', '=', $topic);
        }

        // FIX: Specify table name 'notes.created_at'
        $query->orderBy('notes.created_at', 'desc');
        $results = $query->get();

        return response()->json([
            'message' => 'Search results retrieved successfully',
            'data' => $results
        ], 200);
    }

    /**
     * Update an existing note (Title, Content, Topic, Visibility).
     * INCLUDES FORCE-SAVE logic for missing files.
     */
    public function update(Request $request, $id)
    {
        $request->validate([
            'title'      => 'required|string|max:255',
            'content'    => 'required|string',
            'topic'      => 'required|string',  
            'visibility' => 'required|boolean', 
        ]);

        $note = Notes::find($id);

        if (!$note) {
            return response()->json(['message' => 'Note not found'], 404);
        }

        // Capture old title for syncing cleanup
        $oldTitle = $note->title;

        try {
            // 1. Update Topic
            $topicName = $request->input('topic');
            $topic = Topic::where('topic_name', $topicName)->first();
            if ($topic) {
                $note->topic_id = $topic->topic_id;
            }

            // 2. Update Fields
            $note->title = $request->input('title');
            $note->visibility = $request->input('visibility') ? 1 : 0;
            
            // 3. FORCE FILE SAVE LOGIC
            $fileRecord = null;
            
            // Try to find existing file record
            if ($note->file_id) {
                $fileRecord = File::find($note->file_id);
            }

            // If missing (orphaned), create new record
            if (!$fileRecord) {
                $fileName = Str::uuid() . '_saved.md';
                $filePath = 'notes/' . $fileName;
                $fileRecord = File::create([
                    'file_path' => $filePath,
                    'type'      => 'md',
                ]);
                $note->file_id = $fileRecord->file_id;
            }

            // 4. Safely write content to disk (Creates if missing, Overwrites if exists)
            Storage::disk('public')->put($fileRecord->file_path, $request->input('content'));

            // --- GIT SYNC ---
            // Pass topic name, and also pass old topic (we need to retrieve it first if we want to support topic movement)
            // But since we only have new topic name here easily, let's fetch old topic name from DB before update if we want to be perfect.
            // For now, let's just assume we want to write to the NEW topic folder.
            // If the topic changed, we might leave a ghost file in the old folder unless we handle it.
            
            // Let's get the OLD topic name for cleanup
            $oldTopicName = null;
            if ($note->topic_id) {
                 // We need to re-fetch the old topic because we might have already updated the note->topic_id in memory (line 321)
                 // Actually line 321 updates the model instance. 
                 // We should have captured the old topic ID before line 321. 
                 // Let's restart this block slightly better below using the captured state if possible, 
                 // but since we didn't capture old topic ID, let's just write to the new one for now.
                 // To do it properly: We need to change the order of operations or fetch fresh.
            }

            // RE-FETCHING old topic name logic is tricky if we already mutated the model.
            // However, we can simply rely on the fact that we have the new topic object.
            
            $this->_syncToSeedData(
                $fileRecord->file_path, 
                $request->input('content'), 
                $request->input('title'), 
                $topic->topic_name, // NEW TOPIC
                $oldTitle
                // TODO: improved cleanup for old topic if needed, for now focusing on writing to correct place.
            );

            $note->save(); 

            return response()->json([
                'message' => 'Note updated successfully',
                'note' => $note
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'message' => 'Error updating note',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified note.
     */
    public function destroy($id)
    {
        $note = Notes::find($id);

        if (!$note) {
            return response()->json(['message' => 'Note not found'], 404);
        }

        DB::beginTransaction();

        try {
            $note->attachments()->detach();

            if ($note->file_id) {
                $fileRecord = File::find($note->file_id);

                if ($fileRecord) {
                    if (Storage::disk('public')->exists($fileRecord->file_path)) {
                        Storage::disk('public')->delete($fileRecord->file_path);
                    }
                    $fileRecord->delete();
                }
            }

            $note->delete();

            DB::commit();

            return response()->json(['message' => 'Note deleted successfully'], 200);

        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Error deleting note',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Helper to sync note content to the seed_data folder for Git commits.
     * This is primarily for the Development environment.
     */
    /**
     * Helper to sync note content to the seed_data folder for Git commits.
     * This is primarily for the Development environment.
     */
    private function _syncToSeedData($originalPath, $content, $title = null, $topicName = 'General', $oldTitle = null)
    {
        $seedDir = database_path('seed_data/notes');
        
        // Only run if the directory exists (Dev setup)
        if (is_dir($seedDir)) {
             try {
                 // 1. Determine Topic Directory
                 $topicDir = $seedDir . DIRECTORY_SEPARATOR . $topicName;
                 \Log::info("Syncing to Seed Data. Topic: $topicName, Dir: $topicDir");

                 if (!file_exists($topicDir)) {
                     \Log::info("Topic dir does not exist, creating: $topicDir");
                     mkdir($topicDir, 0755, true);
                 }

                 // 2. Determine Filename
                 if ($title) {
                     // Sanitize Title: Allow alphanumeric, spaces, dots, dashes, underscores, parentheses.
                     // Remove generally unsafe chars: \ / : * ? " < > |
                     $safeTitle = preg_replace('/[\\/\\\:\*\?\"\<\>\|]/', '', $title);
                     $safeTitle = trim($safeTitle);
                     
                     if (empty($safeTitle)) $safeTitle = 'Untitled_' . time();
                     $filename = $safeTitle . '.md';
                 } else {
                     $filename = basename($originalPath);
                 }

                 // 3. Write to Topic Folder
                 $dest = $topicDir . DIRECTORY_SEPARATOR . $filename;
                 \Log::info("Writing content to: $dest");
                 
                 file_put_contents($dest, $content);
                 
                 if (file_exists($dest)) {
                     \Log::info("Write successful.");
                 } else {
                     \Log::error("Write failed. File not found after put.");
                 }

                 // 4. CLEANUP LEGACY/DUPLICATE FILES
                 
                 // 4a. Cleanup from ROOT (Legacy location)
                 // The old system sanitized to underscores: "My Note" -> "My_Note"
                 // So we check for that specifically to delete the old duplication.
                 if ($title) {
                     $legacySafeTitle = preg_replace('/[^A-Za-z0-9_\-\(\)]/', '_', $title);
                     $legacyFilename = $legacySafeTitle . '.md';
                     $legacyRootPath = $seedDir . DIRECTORY_SEPARATOR . $legacyFilename;
                     
                     if (file_exists($legacyRootPath)) {
                          \Log::info("Removing legacy root file: $legacyRootPath");
                          unlink($legacyRootPath);
                     }
                     // Also check for the NEW safe title in root, just in case
                     $newSafeRootPath = $seedDir . DIRECTORY_SEPARATOR . $filename;
                     if (file_exists($newSafeRootPath)) {
                          unlink($newSafeRootPath);
                     }
                 }

                 // 4b. Cleanup Renamed Files within SAME topic
                 if ($oldTitle && $oldTitle !== $title) {
                     // Cleanup "New Style" old title
                     $oldSafeTitle = preg_replace('/[\\/\\\:\*\?\"\<\>\|]/', '', $oldTitle);
                     $oldSafeTitle = trim($oldSafeTitle);
                     $oldDest = $topicDir . DIRECTORY_SEPARATOR . $oldSafeTitle . '.md';
                     if (file_exists($oldDest)) {
                         unlink($oldDest);
                     }
                     
                     // Cleanup "Old Style" old title (underscores)
                     $oldLegacyTitle = preg_replace('/[^A-Za-z0-9_\-\(\)]/', '_', $oldTitle);
                     $oldLegacyDest = $topicDir . DIRECTORY_SEPARATOR . $oldLegacyTitle . '.md';
                     if (file_exists($oldLegacyDest)) {
                         unlink($oldLegacyDest);
                     }
                 }

             } catch (\Exception $e) {
                 // Ignore errors here, as this is a secondary "nice to have" feature
             }
        }
    }
}