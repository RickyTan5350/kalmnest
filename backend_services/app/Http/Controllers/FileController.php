<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Exception;
class FileController extends Controller
{
    use \App\Traits\SyncsToSeedData;

    private function getEncodedUrl($path)
    {
        // Encode path segments to ensure spaces become %20, etc.
        $parts = explode('/', $path);
        $encodedParts = array_map('rawurlencode', $parts);
        $encodedPath = implode('/', $encodedParts);
        return url(Storage::url($encodedPath));
    }

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }

    public function uploadIndependent(Request $request)
    {
        $allowedExtensions = ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg', 'webp', 'gif', 'html', 'css', 'js', 'php'];

        $request->validate([
            'file' => [
                'required',
                'file',
                'max:20480',
                function ($attribute, $value, $fail) use ($allowedExtensions) {
                    $ext = strtolower($value->getClientOriginalExtension());
                    if (!in_array($ext, $allowedExtensions)) {
                        $fail("The $attribute must be a file of type: " . implode(', ', $allowedExtensions));
                    }
                },
            ],
            'folder' => 'nullable|string|max:255',
        ]);

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $extension = $file->getClientOriginalExtension();
            $safeFileName = time() . '_' . $file->getClientOriginalName();
            
            try {
                // Determine header based on folder input, or default to 'uploads'
                $folder = $request->input('folder') ? Str::slug($request->input('folder')) : 'uploads';
                
                // If folder is provided, structure might be assets/folder
                // But to keep it simple and consistent with "upload in assets which name same with the title":
                // If the user means "public/assets", that's usually for static build assets.
                // Storage public is for user uploads. We'll put it in 'uploads/TitleSlug'.
                // Or if user specifically said "assets", maybe they want 'assets/TitleSlug'.
                // Let's use 'assets/' . $folder if folder is provided, else 'uploads'.
                
                $uploadPath = $request->input('folder') 
                    ? 'notes/assets/' . Str::slug($request->input('folder')) 
                    : 'notes/uploads';

                $path = $file->storeAs($uploadPath, $safeFileName, 'public');

                // SYNC TO SEED DATA (Use 'assets' or 'pictures' broadly)
                // If it's code/assets, maybe we want to sync to a different seed folder?
                // For now, let's keep it simple. If it's an image, 'pictures'.
                // If it's code, maybe 'code'? 
                // The current syncFileToSeedData implementation likely takes a target subfolder name.
                // Let's inspect syncFileToSeedData logic if needed, but for now passing 'assets' seems safe if folder is provided.
                $seedSubfolder = $request->input('folder') ? 'assets' : 'pictures';

                $this->syncFileToSeedData(storage_path('app/public/' . $path), $safeFileName, $seedSubfolder);

                // Create DB entry with NULL note_id initially
                $fileRecord = \App\Models\File::create([
                    'file_path' => $path,
                    'type' => $extension,
                    'note_id' => null, 
                ]);

                return response()->json([
                    'message' => 'File uploaded',
                    'file_id' => $fileRecord->file_id, 
                    'file_url' => $this->getEncodedUrl($path),
                ], 200);

            } catch (\Exception $e) {
                return response()->json(['message' => 'Upload failed: ' . $e->getMessage()], 500);
            }
        }
        return response()->json(['message' => 'No file received.'], 400);
    }

    /**
     * Handle multiple files and a markdown file upload in one request.
     * Route: POST /api/files/upload-batch
     */
    public function uploadBatch(Request $request)
    {
        $allowedExtensions = ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg', 'webp', 'html', 'css', 'js', 'php'];

        // 1. Validate the incoming request
        $request->validate([
            // 'attachments' must be an array of files
            'attachments' => 'nullable|array', 
            'attachments.*' => [
                'file',
                'max:20480',
                function ($attribute, $value, $fail) use ($allowedExtensions) {
                    $ext = strtolower($value->getClientOriginalExtension());
                    if (!in_array($ext, $allowedExtensions)) {
                        $fail("The file must be a file of type: " . implode(', ', $allowedExtensions));
                    }
                },
            ],
            
            // 'note_file' is the specific markdown file generated by Flutter
            'note_file' => 'nullable|file|max:10240|mimes:md,txt,markdown', 
        ]);

        $response = [
            'message' => 'Upload processing complete',
            'markdown_data' => null,
            'attachments_data' => [],
        ];

        try {
            // --- A. Handle the Markdown File ---
            if ($request->hasFile('note_file')) {
                $mdFile = $request->file('note_file');
                
                // Generate safe name: note_timestamp_random.md
                $mdName = 'note_' . time() . '_' . Str::random(8) . '.md';
                
                // Store in a specific 'notes' folder
                $mdPath = $mdFile->storeAs('notes', $mdName, 'public');

                // SYNC NOTE TO SEED DATA (Root notes folder)
                $this->syncFileToSeedData(storage_path('app/public/' . $mdPath), $mdName);

                $response['markdown_data'] = [
                    'original_name' => $mdFile->getClientOriginalName(),
                    'stored_name' => $mdName,
                    'file_url' => $this->getEncodedUrl($mdPath), // Force absolute encoded URL
                    'file_path' => $mdPath, // Internal path for DB saving
                ];
            }

            // --- B. Handle Multiple Attachments ---
            if ($request->hasFile('attachments')) {
                foreach ($request->file('attachments') as $file) {
                    // Generate unique name
                    $extension = $file->getClientOriginalExtension();
                    $safeFileName = time() . '_' . $file->getClientOriginalName();

                    // Store in 'notes/uploads' folder
                    $path = $file->storeAs('notes/uploads', $safeFileName, 'public');

                    // SYNC ATTACHMENT TO SEED DATA
                    $this->syncFileToSeedData(storage_path('app/public/' . $path), $safeFileName, 'pictures');

                    // Add to response array
                    $response['attachments_data'][] = [
                        'original_name' => $file->getClientOriginalName(),
                        'file_url' => $this->getEncodedUrl($path), // Force absolute encoded URL
                        'file_path' => $path,
                    ];

                    // OPTIONAL: If you use the 'File' model, save to DB here
                    /*
                    File::create([
                        'file_path' => $path,
                        'file_name' => $file->getClientOriginalName(),
                        'type' => $extension,
                    ]);
                    */
                }
            }

            return response()->json($response, 200);

        } catch (Exception $e) {
            return response()->json([
                'message' => 'Batch upload failed',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Single file upload (Keep your existing one for backward compatibility if needed)
     */
    public function upload(Request $request)
    {
        $request->validate([
            'file' => 'required|file|max:20480|mimes:pdf,doc,docx,txt,png,jpg,jpeg', 
        ]);

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $originalName = $file->getClientOriginalName();
            $safeFileName = time() . '_' . $file->getClientOriginalName();

            try {
                $path = $file->storeAs('notes/uploads', $safeFileName, 'public');

                // SYNC TO SEED DATA
                $this->syncFileToSeedData(storage_path('app/public/' . $path), $safeFileName, 'pictures');

                return response()->json([
                    'message' => 'File uploaded successfully',
                    'original_name' => $originalName,
                    'file_url' => $this->getEncodedUrl($path), // Force absolute encoded URL
                    'file_path' => $path,
                ], 200);

            } catch (Exception $e) {
                return response()->json(['message' => 'File upload failed: ' . $e->getMessage()], 500);
            }
        }

        return response()->json(['message' => 'No file received.'], 400);
    }

    /**
     * Delete a file
     */
    public function delete(Request $request)
    {
        $filePath = $request->input('file_path'); 
        
        if ($filePath && Storage::disk('public')->exists($filePath)) {
            Storage::disk('public')->delete($filePath);
            return response()->json(['message' => 'File deleted successfully'], 200);
        }
        
        return response()->json(['message' => 'File not found'], 404);
    }

    public function proxy(Request $request)
    {
        $url = $request->query('url');
        if (!$url) {
            return response()->json(['error' => 'URL required'], 400);
        }

        // Parse path from URL
        $path = parse_url($url, PHP_URL_PATH); // e.g. /storage/assets/file.png
        
        // Remove /storage/ prefix to get disk relative path
        // Note: This assumes standard Laravel storage link structure
        $relativePath = preg_replace('/^\/?storage\//', '', $path);
        $relativePath = urldecode($relativePath); // Decode spaces etc
        
        // Security check
        if (strpos($relativePath, '..') !== false) {
             return response()->json(['error' => 'Invalid path'], 400);
        }

        if (Storage::disk('public')->exists($relativePath)) {
            $fullPath = Storage::disk('public')->path($relativePath);
            return response()->file($fullPath, [
                'Access-Control-Allow-Origin' => '*',
                'Access-Control-Allow-Methods' => 'GET, OPTIONS',
                'Access-Control-Allow-Headers' => 'Content-Type, Authorization, X-Requested-With',
            ]);
        }

        return response()->json(['error' => 'File not found', 'path' => $relativePath], 404);
    }
}
