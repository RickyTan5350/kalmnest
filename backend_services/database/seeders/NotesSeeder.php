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
        $title = pathinfo($filename, PATHINFO_FILENAME);
        
        // 1. IMAGE PROCESSING LOGIC
        $processedContent = preg_replace_callback('/!\[(.*?)\]\((.*?)\)/', function ($matches) use ($sourceDir, $storageFolder, $topicName) {
            $altText = $matches[1];
            $linkPath = $matches[2];

            $linkPath = rawurldecode(trim($linkPath, '"\''));
            $linkPath = str_replace('\\', '/', $linkPath);
            $imageName = basename($linkPath);
            
            $sourceImagePath = $sourceDir . '/pictures/' . $imageName;

            if (File::exists($sourceImagePath)) {
                $destDir = $storageFolder . '/pictures';
                Storage::disk('public')->makeDirectory($destDir);
                Storage::disk('public')->putFileAs($destDir, new \Illuminate\Http\File($sourceImagePath), $imageName);
                return "![$altText](pictures/$imageName)";
            } else {
                return $matches[0];
            }
        }, $originalContent);

        // 2. ASSET FOLDER PROCESSING (New)
        // Scan for assets targeted at this specific note
        // Expected: seed_data/notes/<Topic>/assets/<NoteTitle>/*
        $noteAssetsDir = $sourceDir . '/assets/' . $title;
        
        // Exclude specific notes from having assets created
        $excludedNotes = [
            '3.1.1 Keperluan Bahasa Penskripan Klien dalam Laman Web',
            '3.1.2 Atur Cara dan Carta Alir bagi Bahasa Penskripan Klien'
        ];

        if (!in_array($title, $excludedNotes) && File::exists($noteAssetsDir) && File::isDirectory($noteAssetsDir)) {
            $this->command->info("   -> Found assets for: $title");
            $assetFiles = File::allFiles($noteAssetsDir);
            
            $destAssetDir = "$storageFolder/assets/$title";
            Storage::disk('public')->makeDirectory($destAssetDir);

            foreach ($assetFiles as $assetFile) {
                $assetName = $assetFile->getFilename();
                $assetPath = $assetFile->getPathname();
                
                // Copy to Storage
                Storage::disk('public')->putFileAs($destAssetDir, new \Illuminate\Http\File($assetPath), $assetName);
            }
        }

        // 3. SAVE THE MARKDOWN FILE TO STORAGE
        $mdStorageName = Str::uuid7() . '.md';
        Storage::disk('public')->put("$storageFolder/$mdStorageName", $processedContent);

        // 4. CREATE DB RECORDS
        $fileRecord = FileModel::create([
            'file_path' => "$storageFolder/$mdStorageName",
            'type' => 'md'
        ]);

        Notes::create([
            'title' => $title,
            'topic_id' => $topicId,
            'file_id' => $fileRecord->file_id,
            'visibility' => true,
            'created_by' => $adminUserId,
        ]);

        $this->command->info("   -> Imported: $title");
    }
}