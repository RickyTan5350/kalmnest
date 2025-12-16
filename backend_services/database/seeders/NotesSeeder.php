<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use App\Models\Notes; 
use App\Models\File as FileModel; // Alias to avoid conflict with Facade

class NotesSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Fetch Admin ID (or fallback to first user)
        $adminId = DB::table('users')->where('email', 'admin@example.com')->value('user_id') 
                   ?? DB::table('users')->value('user_id');

        // 2. Fetch Topic IDs
        $topics = DB::table('topics')->pluck('topic_id', 'topic_name'); // ['HTML' => 'uuid', ...]

        if (!$adminId || $topics->isEmpty()) {
            $this->command->warn("Skipping Seeder: Admin or Topics not found.");
            return;
        }

        $baseSeedPath = database_path('seed_data/notes');
        $this->command->info("Scanning folder: $baseSeedPath");

        // 3. Loop through each Topic Folder
        foreach ($topics as $topicName => $topicId) {
            $topicPath = "$baseSeedPath/$topicName"; // e.g., .../notes/HTML

            if (File::exists($topicPath)) {
                $this->command->info(" -> Seeding Topic: $topicName");
                
                // Get all .md files in this topic folder
                $files = File::files($topicPath);

                foreach ($files as $file) {
                    if ($file->getExtension() === 'md') {
                        $this->seedNote($file, $topicId, $adminId, $topicPath);
                    }
                }
            }
        }
    }

    /**
     * Reads a markdown file, processes images, and saves to DB
     */
    private function seedNote($file, $topicId, $userId, $topicPath)
    {
        $filename = $file->getFilename();
        $title = pathinfo($filename, PATHINFO_FILENAME);
        $content = File::get($file->getPathname());

        $attachmentFileIds = [];

        // 4. Image Processing Logic
        // Looks for links like ![alt](pictures/image.png)
        $newContent = preg_replace_callback('/!\[(.*?)\]\((.*?)\)/', function ($matches) use ($topicPath, &$attachmentFileIds) {
            $alt = $matches[1];
            $link = $matches[2];

            // Clean the link path
            $link = str_replace('\\', '/', $link);

            // We only care about local images in the "pictures" subfolder
            if (Str::startsWith($link, 'pictures/')) {
                $imageName = basename($link);
                $sourcePath = "$topicPath/pictures/$imageName";

                if (File::exists($sourcePath)) {
                    // Upload the image to public storage
                    $storedPath = 'uploads/' . time() . '_' . $imageName;
                    Storage::disk('public')->put($storedPath, File::get($sourcePath));

                    // Create File Record for the image
                    $fileRecord = FileModel::create([
                        'file_path' => $storedPath,
                        'type' => pathinfo($imageName, PATHINFO_EXTENSION),
                    ]);
                    
                    $attachmentFileIds[] = $fileRecord->file_id;

                    // Generate new URL for the markdown
                    $newUrl = url(Storage::url($storedPath));
                    return "![$alt]($newUrl)";
                }
            }
            return $matches[0]; // Return original if not found/processed
        }, $content);

        // 5. Save the Main Note File (Markdown)
        $noteStoragePath = 'notes/' . Str::uuid() . '.md';
        Storage::disk('public')->put($noteStoragePath, $newContent);

        $mainFileRecord = FileModel::create([
            'file_path' => $noteStoragePath,
            'type' => 'md',
        ]);

        // 6. Create Note Record
        $note = Notes::create([
            'title' => $title,
            'topic_id' => $topicId,
            'file_id' => $mainFileRecord->file_id,
            'created_by' => $userId,
            'visibility' => true,
        ]);

        // 7. Attach Images to Note (Pivot Table)
        if (!empty($attachmentFileIds)) {
            $note->attachments()->attach($attachmentFileIds);
        }

        $this->command->line("    + Imported: $title");
    }
}