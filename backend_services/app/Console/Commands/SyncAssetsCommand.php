<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

class SyncAssetsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'notes:sync-assets';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Bidirectionally sync assets between Frontend (flutter_codelab) and Backend (seed_data)';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Starting Asset Synchronization...');

        // 1. Define Paths
        // Backend Seed Data Root: backend_services/database/seed_data/notes
        $backendNotesDir = database_path('seed_data/notes');
        
        // Frontend Assets Root: configured in .env
        $frontendAssetsDir = env('FRONTEND_ASSETS_PATH');

        // Public Storage Root: storage/app/public/notes (The "Updated Directory")
        $publicNotesDir = storage_path('app/public/notes');

        if (!$frontendAssetsDir) {
            $this->error("FRONTEND_ASSETS_PATH is not set in .env file.");
            $this->line("Please add FRONTEND_ASSETS_PATH=/absolute/path/to/flutter_codelab/assets/www");
            return 1;
        }

        if (!File::exists($backendNotesDir)) {
            $this->error("Backend notes directory not found: $backendNotesDir");
            return 1;
        }

        if (!File::exists($frontendAssetsDir)) {
             $this->warn("Frontend assets directory not found: $frontendAssetsDir. Skipping frontend sync.");
        }

        $this->info("Backend Dir: $backendNotesDir");
        $this->info("Frontend Dir: $frontendAssetsDir");
        $this->info("Public Storage Dir: $publicNotesDir");

        // 2. Index Backend Notes (Title -> Topic Mapping)
        $noteToTopicMap = $this->indexBackendNotes($backendNotesDir);

        // 3. PULL: Sync Sources -> Backend (Source of Truth)
        $this->syncPublicToBackend($publicNotesDir, $backendNotesDir, $noteToTopicMap);
        
        if (File::exists($frontendAssetsDir)) {
            $this->syncFrontendToBackend($frontendAssetsDir, $backendNotesDir, $noteToTopicMap);
        }

        // 4. PUSH: Sync Backend -> Redistribution Targets
        
        // A. Sync Backend -> Public Storage (Existing)
        $this->syncBackendToPublic($backendNotesDir, $publicNotesDir);

        // B. Sync Backend -> Frontend Assets
        if (File::exists($frontendAssetsDir)) {
            $this->syncBackendToFrontend($backendNotesDir, $frontendAssetsDir);
        }

        // 5. POST-PROCESS: Run Packager
        $this->section('Post-Processing');
        $this->info('Running Note Packager to ensure relative links and UUIDs...');
        $this->call('notes:package');

        $this->info('Asset Synchronization Completed!');
    }

    private function syncPublicToBackend($publicNotesDir, $backendNotesDir, $noteToTopicMap)
    {
        $this->section('Syncing Public Storage -> Backend');

        if (!File::exists($publicNotesDir)) {
            $this->warn("Public storage directory not found: $publicNotesDir");
            return;
        }

        // 1. Sync topic folders (HTML, CSS, JS, PHP)
        $topics = File::directories($publicNotesDir);
        foreach ($topics as $topicPath) {
            $topicName = basename($topicPath);
            
            // Skip non-topic folders
            if (in_array($topicName, ['pictures', 'assets', 'uploads'])) continue;

            $this->info("Processing topic: $topicName");
            $files = File::allFiles($topicPath);
            foreach ($files as $file) {
                $relativePath = $file->getRelativePathname();
                $destPath = "$backendNotesDir/$topicName/$relativePath";
                
                $destDir = dirname($destPath);
                if (!File::exists($destDir)) {
                    File::makeDirectory($destDir, 0755, true);
                }

                $this->copyIfNewer($file->getPathname(), $destPath);
            }
        }

        // 2. Sync loose files (if they match indexed notes)
        $looseFiles = File::files($publicNotesDir);
        foreach ($looseFiles as $file) {
            if ($file->getExtension() === 'md') {
                $filename = $file->getFilenameWithoutExtension();
                $normalized = $this->normalizeTitle($filename);

                if (isset($noteToTopicMap[$normalized])) {
                    $match = $noteToTopicMap[$normalized];
                    $topic = $match['topic'];
                    $originalTitle = $match['original_title'];
                    $destPath = "$backendNotesDir/$topic/$originalTitle.md";

                    $this->copyIfNewer($file->getPathname(), $destPath);
                }
            }
        }
    }

    private function indexBackendNotes($backendNotesDir)
    {
        $map = [];
        $topics = File::directories($backendNotesDir);

        foreach ($topics as $topicPath) {
            $topicName = basename($topicPath);
            $files = File::files($topicPath);

            foreach ($files as $file) {
                if ($file->getExtension() === 'md') {
                    // Note Title is filename without extension
                    $noteTitle = $file->getFilenameWithoutExtension();
                    
                    // We map the NORMALIZED title to the original details
                    $normalized = $this->normalizeTitle($noteTitle);
                    
                    $map[$normalized] = [
                        'topic' => $topicName,
                        'original_title' => $noteTitle
                    ];
                }
            }
        }
        return $map;
    }

    private function syncFrontendToBackend($frontendAssetsDir, $backendNotesDir, $noteToTopicMap)
    {
        $this->section('Syncing Frontend -> Backend');

        // Iterate over Frontend Note Folders
        $frontendDirs = File::directories($frontendAssetsDir);

        foreach ($frontendDirs as $dir) {
            $folderName = basename($dir);
            
            // Skip "pictures" folder in root of assets/www if it exists (treated separately)
            if ($folderName === 'pictures') continue;

            // Check if this folder corresponds to a known backend note (using fuzzy matching)
            $normalizedFolder = $this->normalizeTitle($folderName);
            
            if (isset($noteToTopicMap[$normalizedFolder])) {
                $match = $noteToTopicMap[$normalizedFolder];
                $topic = $match['topic'];
                $backendNoteTitle = $match['original_title'];
                
                // We use the BACKEND note title for the target directory to maintain consistency in seed_data
                $targetDir = "$backendNotesDir/$topic/assets/$backendNoteTitle";

                // Ensure target directory exists
                if (!File::exists($targetDir)) {
                    File::makeDirectory($targetDir, 0755, true);
                    $this->line("Created backend asset dir for: $folderName");
                }

                // Copy files
                $files = File::allFiles($dir);
                foreach ($files as $file) {
                    $relativePath = $file->getRelativePathname();
                    $destPath = "$targetDir/$relativePath";
                    
                    $this->copyIfNewer($file->getPathname(), $destPath);
                }
            } else {
                $this->warn("Skipping Frontend folder '$folderName': No matching Backend note found.");
            }
        }
    }

    private function syncBackendToFrontend($backendNotesDir, $frontendAssetsDir)
    {
        $this->section('Syncing Backend -> Frontend');

        $topics = File::directories($backendNotesDir);

        foreach ($topics as $topicPath) {
            $topicName = basename($topicPath);

            // A. Sync Note-Specific Assets
            $assetsBaseDir = "$topicPath/assets";
            if (File::exists($assetsBaseDir)) {
                $noteAssetDirs = File::directories($assetsBaseDir);
                foreach ($noteAssetDirs as $noteAssetDir) {
                    $noteTitle = basename($noteAssetDir);
                    $targetDir = "$frontendAssetsDir/$noteTitle";

                    if (!File::exists($targetDir)) {
                        File::makeDirectory($targetDir, 0755, true);
                    }

                    $files = File::allFiles($noteAssetDir);
                    foreach ($files as $file) {
                        $relativePath = $file->getRelativePathname();
                        $destPath = "$targetDir/$relativePath";
                        $this->copyIfNewer($file->getPathname(), $destPath);
                    }
                }
            }

            // B. Sync Global Topic Pictures (if any)
            // Backend: seed_data/notes/<Topic>/pictures
            // Frontend: assets/www/pictures (?) OR assets/www/<LinkStructure>?
            // Based on seed data, pictures are in notes/<Topic>/pictures.
            // Based on frontend usage, we need to see where they go.
            // Usually valid markdown links are relative. 
            // If MD is in <Topic>/Note.md, listing ![]()
            // In frontend, we might just put them in a central 'pictures' folder or handle them differently.
            // For now, let's look at how frontend does it. 
            // Assumption: Frontend has a 'pictures' folder in www root? Or per note?
            // The earlier `ls` showed `assets/www` has directories for notes.
            // Let's assume we copy `pictures` to `assets/www/pictures`? Or `assets/www/<Topic>/pictures`?
            // Checking `visible_files.json` in `assets/www` showed `only3.html` at root of note folder.
            // Let's sync backend `pictures` to `assets/www/pictures/<Topic>` to avoid collisions?
            // Wait, the MD links in database are processed by `NoteSeeder` to absolute URLs.
            // But for offline / raw usage in other contexts, relative links might matter.
            // Strategy: Sync `seed_data/notes/<Topic>/pictures` -> `assets/www/pictures` (flattened or subfoldered).
            // Let's go with `assets/www/pictures` (Merge all?). Or `assets/www/<Topic>/pictures`.
            // Let's check if `assets/www/pictures` exists. `ls` output showed `assets/www` contents were directories.
            // Wait, step 12 showed backend has `notes/JS/pictures`.
            // Let's look at `assets/www` again.
            // Step 5: `assets/www` listing did NOT show `pictures` folder.
            // But Step 13 search result showed `notes\JS\pictures\BubbleSort_Avg_case.gif`.
            // Let's create `assets/www/pictures` if it doesn't exist and dump all pictures there?
            // Or maybe `assets/www/<Topic>/pictures` is safer.
            
            $backendPicDir = "$topicPath/pictures";
            if (File::exists($backendPicDir)) {
                // Target: flutter_codelab/assets/www/pictures
                // We'll create a `pictures` folder in `www`.
                $targetPicDir = "$frontendAssetsDir/pictures";
                
                if (!File::exists($targetPicDir)) {
                    File::makeDirectory($targetPicDir, 0755, true);
                }

                $pics = File::files($backendPicDir);
                foreach ($pics as $pic) {
                    $destPath = "$targetPicDir/" . $pic->getFilename();
                    $this->copyIfNewer($pic->getPathname(), $destPath);
                }
            }
        }
    }

    private function syncBackendToPublic($backendNotesDir, $publicNotesDir)
    {
        $this->section('Syncing Backend -> Public Storage');

        if (!File::exists($publicNotesDir)) {
            File::makeDirectory($publicNotesDir, 0755, true);
        }

        $files = File::allFiles($backendNotesDir);
        foreach ($files as $file) {
            $relativePath = $file->getRelativePathname();
            
            // Check if file is inside a 'pictures' folder
            // e.g., CSS/pictures/zoomin.png -> pictures/zoomin.png
            if (str_contains($relativePath, 'pictures/')) {
                $imageName = $file->getFilename();
                $destPath = "$publicNotesDir/pictures/$imageName";
            } else {
                $destPath = "$publicNotesDir/$relativePath";
            }

            // Ensure subdirectories exist
            $destDir = dirname($destPath);
            if (!File::exists($destDir)) {
                File::makeDirectory($destDir, 0755, true);
            }
            
            $this->copyIfNewer($file->getPathname(), $destPath);
        }
    }


    private function copyIfNewer($source, $dest)
    {
        if (!File::exists($dest)) {
            File::copy($source, $dest);
            $this->info("Copied new: " . basename($dest));
            return;
        }

        $srcTime = File::lastModified($source);
        $destTime = File::lastModified($dest);

        if ($srcTime > $destTime) {
            File::copy($source, $dest);
            $this->info("Updated: " . basename($dest));
        }
    }

    private function section($title)
    {
        $this->line('');
        $this->info("=== $title ===");
        $this->line('');
    }

    /**
     * Normalizes a title to allow for fuzzy matching between 
     * folder names and file names.
     */
    private function normalizeTitle($title)
    {
        // 1. Lowercase
        $title = strtolower($title);
        // 2. Replace non-alphanumeric with space
        $title = preg_replace('/[^a-z0-9]/', ' ', $title);
        // 3. Flatten extra spaces
        $title = preg_replace('/\s+/', ' ', $title);
        return trim($title);
    }
}
