<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use App\Models\Notes;
use App\Models\File as FileModel;

class NotesSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 0. Clear Existing Data (Optional/Safe for re-seeding)
        // This ensures we don't have duplicates and everything is fresh
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        DB::table('note_files')->truncate(); // Pivot table
        DB::table('notes')->truncate();
        // We only truncate files that are notes (type 'md') to be safe, 
        // or just truncate all if 'files' is strictly for notes/attachments.
        // For simplicity and matching migration structure:
        DB::table('files')->truncate(); 
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');
        // 1. Get Admin ID (Query by Email)
        // We fetch the user_id for 'admin@example.com' to assign as the creator
        $adminUserId = DB::table('users')
            ->where('email', 'admin@example.com')
            ->value('user_id');

        // Fallback safety: If admin doesn't exist, default to 1
        if (!$adminUserId) {
            $this->command->warn("User 'admin@example.com' not found. Defaulting created_by to 1.");
            $adminUserId = 1;
        }

        // 2. Define Source Path (Seed Data)
        $seedPath = database_path('seed_data/notes');

        if (!File::exists($seedPath)) {
            $this->command->error("Seed path not found: $seedPath");
            return;
        }

        // 3. Define Destination Path (Public Storage)
        $storageFolder = 'notes'; 
        Storage::disk('public')->makeDirectory($storageFolder);

        // Get all Topic folders (HTML, CSS, etc.)
        $topicDirectories = File::directories($seedPath);

        foreach ($topicDirectories as $topicDir) {
            $topicName = basename($topicDir);
            $this->command->info("Processing Topic: $topicName");

            // Query or Create Topic using Eloquent to handle UUIDs automatically
            $topic = \App\Models\Topic::firstOrCreate(['topic_name' => $topicName]);
            $topicId = $topic->topic_id;

            // Scan for Markdown files in this topic
            $files = File::files($topicDir);

            foreach ($files as $file) {
                if ($file->getExtension() !== 'md') continue;

                // Pass the $adminUserId to the processing function
                $this->processNoteFile($file, $topicId, $topicName, $storageFolder, $adminUserId);
            }
        }
    }

    /**
     * Process a single Markdown file: Move images, Rewrite links, Save to DB.
     */
    private function processNoteFile($file, $topicId, $topicName, $storageFolder, $adminUserId)
    {
        $filename = $file->getFilename();
        $originalContent = File::get($file->getPathname());
        $sourceDir = $file->getPath(); 
        
        // 1. IMAGE PROCESSING LOGIC
        $processedContent = preg_replace_callback('/!\[(.*?)\]\((.*?)\)/', function ($matches) use ($sourceDir, $storageFolder, $topicName) {
            $altText = $matches[1];
            $linkPath = $matches[2];

            $linkPath = rawurldecode(trim($linkPath, '"\''));
            $linkPath = str_replace('\\', '/', $linkPath);
            $imageName = basename($linkPath);
            
            $sourceImagePath = $sourceDir . '/pictures/' . $imageName;

            if (File::exists($sourceImagePath)) {
                // Determine destination path inside 'notes/pictures'
                $destDir = $storageFolder . '/pictures';
                Storage::disk('public')->makeDirectory($destDir);
                
                // Copy the image without prefix
                Storage::disk('public')->putFileAs($destDir, new \Illuminate\Http\File($sourceImagePath), $imageName);

                // Return the relative path specifically as 'pictures/...'
                return "![$altText](pictures/$imageName)";
            } else {
                return $matches[0];
            }
        }, $originalContent);

        // 2. SAVE THE MARKDOWN FILE TO STORAGE
        $mdStorageName = Str::uuid7() . '.md';
        Storage::disk('public')->put("$storageFolder/$mdStorageName", $processedContent);

        // 3. CREATE FILE RECORD IN DB
        $fileRecord = FileModel::create([
            'file_path' => "$storageFolder/$mdStorageName",
            'type' => 'md'
        ]);

        // 4. CREATE NOTE RECORD IN DB
        $title = pathinfo($filename, PATHINFO_FILENAME);

        
        Notes::create([
            'title' => $title,
            'topic_id' => $topicId,
            'file_id' => $fileRecord->file_id,
            'visibility' => true,
            'created_by' => $adminUserId, // Uses the ID queried by email
        ]);

        $this->command->info("   -> Imported: $title (Created by User ID: $adminUserId)");
    }
}