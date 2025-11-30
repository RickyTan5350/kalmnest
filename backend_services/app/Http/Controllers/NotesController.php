<?php

namespace App\Http\Controllers;

use App\Http\Requests\CreateNotesRequest;
use App\Models\Notes;
use App\Models\Topic;
use Illuminate\Http\Request;
use Illuminate\Contracts\Filesystem;
use Illuminate\Support\Facades\DB;
use Exception;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class NotesController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
    
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    public function showNotesBrief(){
        $notesBrief = DB::table('notes')
                                ->select('*')
                                ->get();

        return response()->json($notesBrief);
    }
    
    public function uploadFile(Request $request)
    {
        $request->validate([
            // 'file' is the key used in your Flutter code (request.files.add)
            'file' => 'required|file|max:20480|mimes:pdf,doc,docx,txt,png,jpg,jpeg', 
            // Max size is 20MB (20480 KB)
        ]);

        // 2. Check if the file exists in the request
        if ($request->hasFile('file')) {
            $file = $request->file('file');
            
            // Generate a unique filename to prevent overwrites
            $originalName = $file->getClientOriginalName();
            $safeFileName = (string) Str::uuid() . '_' . time() . '.' . $file->getClientOriginalExtension();

            try {
                // 3. Store the file
                // This saves the file to the 'public/uploads' directory 
                // within your storage path (storage/app/public/uploads).
                $path = $file->storeAs('uploads', $safeFileName, 'public');

                // 4. Return a successful JSON response
                return response()->json([
                    'message' => 'File uploaded successfully',
                    'original_name' => $originalName,
                    'file_url' => Storage::url($path),
                ], 200);
                

            } catch (\Exception $e) {
                // Handle storage errors
                return response()->json(['message' => 'File upload failed: ' . $e->getMessage()], 500);
            }
        }

        // Should not be reached if validation is correct
        return response()->json(['message' => 'No file received.'], 400);
    
    }
    /**
     * Store a newly created resource in storage.
     */
    public function store(CreateNotesRequest $request)
    {
        //
        $validatedData = $request->validated();

        $topicName = $validatedData['topic'];
        $topic = Topic::where('topic_name', $topicName)->first(['topic_id']);

        // Check if the topic was found (although validation should prevent it from not being found)
        if (!$topic) {
            // This is a safety net; the form request should catch this.
            return response()->json([
                'message' => "The topic '$topicName' is not valid.",
            ], 422); // 422 Unprocessable Entity
        }

    // 2. 🔄 Replace the 'topic' name with the 'topic_id'
    // Assuming your Note model expects a 'topic_id' column, 
    // we remove 'topic' and add 'topic_id'.
        unset($validatedData['topic']);
        $validatedData['topic_id'] = $topic->id;
        // 🚨 ENSURE THIS ID EXISTS AND IS AN ADMIN/TEACHER
        $debugUserId = '019a7b53-7330-7249-a4c6-1489dd90825a'; 
        
        // This line temporarily sets the creator ID for debugging.
        $validatedData['created_by'] = $debugUserId; 

         try {
            // 6. This will now run.
            $note = Notes::create($validatedData);

            // 7. Return JSON response with status 201 (Created)
            return response()->json([
                'message' => 'Note created successfully (via debug ID).',
                'note' => $note,
            ], 201);
            
        } catch (Exception $e) {
            
            // 8. Catch the specific error from your SQL trigger
            if (Str::contains($e->getMessage(), 'Note can only be created by an Admin or a Teacher')) {
                // Log this specific, expected error
                \Log::warning('NOTE_AUTH_FAILED: ' . $e->getMessage());
                return response()->json([
                    'message' => 'Access Denied: The provided user ID (debug or authenticated) is not an Admin or Teacher.',
                ], 403); // 403 Forbidden
            }

            // 9. Generic server error response
            \Log::error('NOTE_CREATE_FAILED: ' . $e->getMessage()); // Log the error!
            return response()->json([
                'message' => 'Failed to create note due to a server error.',
                'error' => $e->getMessage()
            ], 500); // 500 Internal Server Error
        }
    }
        

        
    

    /**
     * Display the specified resource.
     */
    public function show(Notes $note)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Notes $note)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Notes $note)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Notes $note)
    {
        //
    }
}
