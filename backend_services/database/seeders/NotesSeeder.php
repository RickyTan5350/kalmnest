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
    public function run(): void
    {
        // 1. Setup: Get Admin ID and Topics
        // Adjust 'admin@example.com' to your actual admin email if needed
        $adminId = DB::table('users')->where('email', 'admin@example.com')->value('user_id') 
                   ?? DB::table('users')->value('user_id'); // Fallback to first user

        $topics = DB::table('topics')->pluck('topic_id', 'topic_name'); // e.g. ['HTML' => 'uuid', 'CSS' => 'uuid']

        if (!$adminId || $topics->isEmpty()) {
            $this->command->warn("SKIPPING: Admin user or Topics not found. Did you run 'php artisan db:seed' (main seeder) first?");
            return;
        }

        // 2. Define Source Path
        $baseSeedPath = database_path('seed_data/notes');
        $this->command->info("🚀 Starting Import from: $baseSeedPath");

        // 3. Loop through each Topic Folder (HTML, CSS, JS, PHP)
        foreach ($topics as $topicName => $topicId) {
            $topicFolderPath = "$baseSeedPath/$topicName";

            if (File::exists($topicFolderPath)) {
                $this->command->info("   📂 Scanning Topic: $topicName");
                
                // Get all .md files in this folder
                $files = File::files($topicFolderPath);

                foreach ($files as $file) {
                    if ($file->getExtension() === 'md') {
                        $this->processAndSeedNote($file, $topicId, $adminId, $topicFolderPath);
                    }
                }
            }
        }
    }

    /**
     * Reads the MD file, finds local images, uploads them, updates links, and saves to DB.
     */
    private function processAndSeedNote($file, $topicId, $userId, $currentFolder)
    {
        $filename = $file->getFilename();
        $title = pathinfo($filename, PATHINFO_FILENAME); // e.g., "3.1.1"
        $originalContent = File::get($file->getPathname());
        
        $attachmentIds = [];

        // ---------------------------------------------------------
        // MAGIC STEP: Find and Replace Images
        // Regex finds: ![Alt Text](Link)
        // ---------------------------------------------------------
        $processedContent = preg_replace_callback('/!\[(.*?)\]\((.*?)\)/', function ($matches) use ($currentFolder, &$attachmentIds) {
            $altText = $matches[1];
            $originalLink = trim($matches[2], ' "\''); // Remove quotes if user added them by mistake

            // We only care if the link points to the local "pictures" folder
            // e.g. "pictures/my-image.png"
            if (Str::startsWith($originalLink, 'pictures/')) {
                
                $imageFilename = basename($originalLink);
                // Look for the image in: .../notes/HTML/pictures/image.png
                $localImagePath = $currentFolder . '/pictures/' . $imageFilename;

                if (File::exists($localImagePath)) {
                    // 1. Generate a unique name for Storage
                    $newStorageName = 'uploads/' . time() . '_' . Str::random(5) . '_' . $imageFilename;
                    
                    // 2. Copy image from Seed folder to Public Storage
                    Storage::disk('public')->put($newStorageName, File::get($localImagePath));

                    // 3. Create a File Record in Database
                    $fileRecord = FileModel::create([
                        'file_path' => $newStorageName,
                        'type' => pathinfo($imageFilename, PATHINFO_EXTENSION),
                    ]);
                    $attachmentIds[] = $fileRecord->file_id;

                    // 4. Generate the PUBLIC URL (http://127.0.0.1:8000/storage/uploads/...)
                    // This relies on your APP_URL in .env being correct!
                    $publicUrl = url(Storage::url($newStorageName));

                    // 5. Replace the link in the Markdown
                    return "![$altText]($publicUrl)";
                } else {
                    $this->command->warn("      ⚠️  Image missing: $originalLink");
                }
            }
            
            // If it's an external link or not found, leave it alone
            return $matches[0];

        }, $originalContent);


        // ---------------------------------------------------------
        // SAVE TO DATABASE
        // ---------------------------------------------------------
        
        // 1. Save the processed Markdown file (with new links) to Storage
        $mdStoragePath = 'notes/' . Str::uuid() . '.md';
        Storage::disk('public')->put($mdStoragePath, $processedContent);

        // 2. Create File Record for the MD file itself
        $mainFileRecord = FileModel::create([
            'file_path' => $mdStoragePath,
            'type' => 'md',
        ]);

        // 3. Create the Note Record
        $note = Notes::create([
            'title' => $title,
            'topic_id' => $topicId,
            'file_id' => $mainFileRecord->file_id, // Link to the MD file
            'created_by' => $userId,
            'visibility' => true,
        ]);

        // 4. Attach the images to the note (Pivot table)
        if (!empty($attachmentIds)) {
            $note->attachments()->attach($attachmentIds);
        }

        $this->command->info("      ✅ Imported: $title (with " . count($attachmentIds) . " images)");
    }
}