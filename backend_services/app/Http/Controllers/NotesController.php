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
    /**
     * Get brief details of notes for list view.
     */
    public function showNotesBrief()
    {
        $notesBrief = DB::table('notes')
            ->select('*')
            ->orderBy('created_at', 'desc')
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
            $safeFileName = (string) Str::uuid() . '_' . time() . '.' . $file->getClientOriginalExtension();

            try {
                $path = $file->storeAs('uploads', $safeFileName, 'public');

                return response()->json([
                    'message' => 'File uploaded successfully',
                    'original_name' => $originalName,
                    'file_url' => Storage::url($path),
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
                $this->_syncToSeedData($mdPath, $syncedContent, $validatedData['title']);
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
            $this->_syncToSeedData($fileRecord->file_path, $request->input('content'), $request->input('title'), $oldTitle);

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
    private function _syncToSeedData($originalPath, $content, $title = null, $oldTitle = null)
    {
        $seedDir = database_path('seed_data/notes');
        
        // Only run if the directory exists (Dev setup)
        if (is_dir($seedDir)) {
             try {
                 // Determine Filename
                 if ($title) {
                     // Sanitize Title: "My Note!" -> "My_Note_"
                     $safeTitle = preg_replace('/[^A-Za-z0-9_\-\(\)]/', '_', $title);
                     // Avoid empty filename if title is all special chars
                     if (empty($safeTitle)) $safeTitle = 'Untitled_' . time();
                     $filename = $safeTitle . '.md';
                 } else {
                     $filename = basename($originalPath);
                 }

                 $dest = $seedDir . DIRECTORY_SEPARATOR . $filename;
                 file_put_contents($dest, $content);

                 // Cleanup Old File (Rename handling)
                 if ($oldTitle && $oldTitle !== $title) {
                     $safeOldTitle = preg_replace('/[^A-Za-z0-9_\-\(\)]/', '_', $oldTitle);
                     $oldDest = $seedDir . DIRECTORY_SEPARATOR . $safeOldTitle . '.md';
                     if (file_exists($oldDest)) {
                         unlink($oldDest);
                     }
                 }

             } catch (\Exception $e) {
                 // Ignore errors here, as this is a secondary "nice to have" feature
             }
        }
    }
}