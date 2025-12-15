<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use App\Models\Notes;
use App\Models\File;
use App\Models\Topic;

class ImportNotes extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'notes:import {path : The absolute path to the directory containing notes} {--user_id= : The ID of the user assigning the notes} {--topic=General : Default topic for imported notes}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Import markdown notes from a local directory, including attachments.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $path = $this->argument('path');
        $userId = $this->option('user_id');
        $topicName = $this->option('topic');

        // Validation
        if (!is_dir($path)) {
            $this->error("Directory not found: $path");
            return 1; // Failure
        }

        // Default Admin User if not provided
        if (!$userId) {
            $adminRoleID = DB::table('roles')->where('role_name', 'Admin')->value('role_id');
            $userId = DB::table('users')->where('role_id', $adminRoleID)->value('user_id');
            
            if (!$userId) {
                // Try finding ANY user if no Admin (fallback)
                $userId = DB::table('users')->value('user_id');
                if (!$userId) {
                    $this->error("No users found in database. Please create a user first.");
                    return 1; 
                }
                $this->warn("No 'Admin' user found. Falling back to first found user ID: $userId");
            }
        }
        
        // Get or Create Topic
        $topic = Topic::firstOrCreate(
            ['topic_name' => $topicName],
            ['topic_id' => Str::uuid()] // Assuming Topic has UUID primary key or handles it
        );
        // Check if Topic works with UUIDs or int. Migration 2025_11_10_061433_create_topics_table.php would confirm.
        // Usually safer to check instance.
        $topicId = $topic->topic_id;

        $this->info("Starting import from directory: $path");
        $this->info("Assigning to User ID: $userId");
        $this->info("Topic: $topicName ($topicId)");

        // Scan recursively for Markdown, Text, and HTML files
        $files = [];
        $iterator = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($path));
        
        foreach ($iterator as $file) {
            if ($file->isFile()) {
                $ext = strtolower($file->getExtension());
                if (in_array($ext, ['md', 'txt', 'html'])) {
                    $files[] = $file->getRealPath();
                }
            }
        }
        
        if (empty($files)) {
            $this->warn("No .md, .txt, or .html files found in $path or its subdirectories.");
            return 0;
        }

        $count = 0;
        foreach ($files as $filePath) {
            $this->importNote($filePath, $userId, $topicId, $path);
            $count++;
        }

        $this->info("Import completed! Processed $count notes.");
        return 0;
    }

    private function importNote($sourcePath, $userId, $topicId, $baseDir)
    {
        $filename = basename($sourcePath);
        $noteDir = dirname($sourcePath);
        $this->line("Processing: $filename (in $noteDir)");

        $content = file_get_contents($sourcePath);
        $title = pathinfo($filename, PATHINFO_FILENAME);
        
        // Array to collect attachment File IDs for pivot table
        $attachmentFileIds = [];

        // Regex to find images: ![alt](path)
        // Updated to handle filenames with parentheses like "image (1).png"
        // matches '![...](...)' where the content inside () can contain matched (...) groups
        $pattern = '/!\[(.*?)\]\(((?:[^()]|\([^()]*\))+)\)/';

        $newContent = preg_replace_callback(
            $pattern, 
            function ($matches) use ($baseDir, $noteDir, &$attachmentFileIds) {
                $altText = $matches[1];
                $link = $matches[2];
                $originalLink = $link;

                // 1. Cleaner path handling
                // Decode URL to parse spaces/special chars
                $cleanLink = urldecode($link);
                // Strip quotes if present (common in some export formats)
                $cleanLink = trim($cleanLink, '"\'');

                // 2. Determine potential local paths
                $candidates = [];
                
                // Priority 0: Is it already a valid absolute path?
                // Windows paths like "C:\..." or Unix "/"
                if (file_exists($cleanLink) && is_file($cleanLink)) {
                     $candidates[] = realpath($cleanLink);
                }

                $pathOnly = parse_url($cleanLink, PHP_URL_PATH);
                $pathOnly = $pathOnly ? ltrim($pathOnly, '/\\') : $cleanLink;
                $filename = basename($cleanLink);

                // Priority 1: Relative to the NOTE FILE itself (e.g. "3.1.1 pic/image.png")
                $candidates[] = realpath($noteDir . DIRECTORY_SEPARATOR . $cleanLink); // Try full relative path
                $candidates[] = realpath($noteDir . DIRECTORY_SEPARATOR . $pathOnly);
                $candidates[] = realpath($noteDir . DIRECTORY_SEPARATOR . $filename); // Try flat

                // Priority 2: Relative to the Base Import Dir
                $candidates[] = realpath($baseDir . DIRECTORY_SEPARATOR . $cleanLink);
                $candidates[] = realpath($baseDir . DIRECTORY_SEPARATOR . $pathOnly);
                $candidates[] = realpath($baseDir . DIRECTORY_SEPARATOR . $filename);

                // Priority 3: 'pictures' subdirectory (Relative to Note Dir and Base Dir)
                $candidates[] = realpath($noteDir . DIRECTORY_SEPARATOR . 'pictures' . DIRECTORY_SEPARATOR . $filename);
                $candidates[] = realpath($baseDir . DIRECTORY_SEPARATOR . 'pictures' . DIRECTORY_SEPARATOR . $filename);

                $foundPath = null;
                foreach ($candidates as $candidate) {
                    if ($candidate && file_exists($candidate) && is_file($candidate)) {
                        $foundPath = $candidate;
                        break;
                    }
                }

                if ($foundPath) {
                    // Import the attachment
                    $fileRecord = $this->importFile($foundPath, 'uploads');
                    
                    if ($fileRecord) {
                        $attachmentFileIds[] = $fileRecord->file_id;
                        $newUrl = Storage::url($fileRecord->file_path);
                        return "![$altText]($newUrl)";
                    }
                } else {
                    $this->warn("   Warning: Attachment not found locally: $cleanLink (Looked in $noteDir)");
                }
                
                return $matches[0]; // Return original if fail
            }, 
            $content
        );

        // 2. Save the Main Note Content File
        // We save the MODIFIED content with the new links.
        $newNoteDataName = (string) Str::uuid() . '_' . time() . '.md';
        $storagePath = 'notes/' . $newNoteDataName;
        
        Storage::disk('public')->put($storagePath, $newContent ?? "");

        $mainFileRecord = File::create([
            'file_path' => $storagePath,
            'type' => 'md'
        ]);

        // 3. Create Note Record
        try {
            $note = Notes::create([
                'title' => $title,
                'topic_id' => $topicId,
                'file_id' => $mainFileRecord->file_id,
                'created_by' => $userId,
                'visibility' => true, 
            ]);

            // 4. Attach Files (Pivot)
            // Need to verify if 'attachments' relation exists in Notes model.
            // Based on NotesController line 110: $note->attachments()->attach($ids);
            if (!empty($attachmentFileIds)) {
                $note->attachments()->attach($attachmentFileIds);
                $this->info("   - Imported and linked " . count($attachmentFileIds) . " attachments.");
            }
            
            $this->info("   - Note created: {$note->title}");

        } catch (\Exception $e) {
            $this->error("   - Error creating note record: " . $e->getMessage());
        }
    }

    private function importFile($path, $folder)
    {
        try {
            $extension = pathinfo($path, PATHINFO_EXTENSION);
            if (!$extension) $extension = 'bin';

            // Generate unique filename on server
            $newFileName = (string) Str::uuid() . '.' . $extension;
            $destinationPath = $folder . '/' . $newFileName;
            
            // Read content
            $content = file_get_contents($path);
            
            // Write to storage
            Storage::disk('public')->put($destinationPath, $content);
            
            // Create DB record
            return File::create([
                'file_path' => $destinationPath,
                'type' => $extension,
            ]);
            
        } catch (\Exception $e) {
            $this->error("   - Error importing file $path: " . $e->getMessage());
            return null;
        }
    }
}
