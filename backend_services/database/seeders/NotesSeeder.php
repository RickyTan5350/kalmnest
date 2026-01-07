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
        // 0. Clean up DB tables (Foreign Key checks disabled for safety)
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        DB::table('note_files')->truncate(); 
        DB::table('notes')->truncate();
        DB::table('files')->truncate(); 
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        // 1. Get Admin ID
        $adminUserId = DB::table('users')
            ->where('email', 'admin@example.com')
            ->value('user_id');

        if (!$adminUserId) {
            $this->command->warn("User 'admin@example.com' not found. Defaulting created_by to 1.");
            $adminUserId = 1;
        }

        // 2. Define Source Path (Targeting the PUBLIC STORAGE now)
        // We look directly at where the files are hosted.
        $storageRoot = storage_path('app/public/notes');

        if (!File::exists($storageRoot)) {
            $this->command->error("Notes storage directory not found: $storageRoot");
            return;
        }

        $this->command->info("Scanning storage directory: $storageRoot");

        // 3. Scan Topics (Subdirectories)
        $topicDirectories = File::directories($storageRoot);

        foreach ($topicDirectories as $topicDir) {
            $topicName = basename($topicDir);
            
            // Skip 'pictures' or other utility folders if they exist at root level and aren't topics
            if (in_array(strtolower($topicName), ['pictures', 'css', 'js', 'img', 'uploads', 'assets'])) {
                // Determine if this is actually a topic or just assets. 
                // Based on previous context, 'CSS' and 'JS' ARE topics. 
                // 'pictures' might be assets. 
                if ($topicName === 'pictures') continue;
            }

            $this->command->info("Processing Topic: $topicName");

            // Query or Create Topic
            $topic = \App\Models\Topic::firstOrCreate(['topic_name' => $topicName]);
            $topicId = $topic->topic_id;

            // Scan for Markdown files recursively in this topic
            // We use recursive scan to find notes even in sub-subfolders if any
            $files = File::allFiles($topicDir);

            foreach ($files as $file) {
                if ($file->getExtension() !== 'md') continue;

                $this->syncNoteFromDisk($file, $topicId, $topicName, $adminUserId);
            }
        }
    }

    /**
     * Create DB entries for an existing file on disk.
     */
    private function syncNoteFromDisk($file, $topicId, $topicName, $adminUserId)
    {
        $filename = $file->getFilename();
        
        // Calculate relative path for storage
        // storage/app/public/notes/PHP/MyNote.md -> notes/PHP/MyNote.md
        $fullPath = $file->getPathname();
        $relativePath = 'notes/' . $topicName . '/' . $file->getRelativePathname();
        
        // Normalize slashes
        $relativePath = str_replace('\\', '/', $relativePath);

        // 1. CREATE FILE RECORD IN DB
        $fileRecord = FileModel::create([
            'file_path' => $relativePath,
            'type' => 'md'
        ]);

        // 2. CREATE NOTE RECORD IN DB
        // Use filename without extension as title
        $title = pathinfo($filename, PATHINFO_FILENAME);

        Notes::create([
            'title' => $title,
            'topic_id' => $topicId,
            'file_id' => $fileRecord->file_id,
            'visibility' => true,
            'created_by' => $adminUserId,
        ]);

        $this->command->info("   -> Synced: $title");
    }
}