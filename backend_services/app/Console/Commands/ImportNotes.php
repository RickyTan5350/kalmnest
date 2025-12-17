<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

class ImportNotes extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'notes:import';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Interactively sorts new notes into topic folders, moves images, and runs the seeder.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        // 1. Setup Paths
        // We look specifically where the Seeder looks: database/seed_data/notes
        $basePath = database_path('seed_data/notes');
        $topics = ['HTML', 'CSS', 'JS', 'PHP'];

        // 2. Find "loose" markdown files in the root notes folder
        // We filter out directories so we only get files
        if (!File::exists($basePath)) {
            $this->error("Directory not found: $basePath");
            return 1;
        }

        $files = collect(File::files($basePath))->filter(function ($file) {
            return $file->getExtension() === 'md';
        });

        if ($files->isEmpty()) {
            $this->info("No new .md files found in root of $basePath to organize.");
            // We can still ask if they want to run the seeder anyway
            if ($this->confirm('Do you want to run the packager and seeder anyway?', true)) {
                $this->runSeedingProcess();
            }
            return 0;
        }

        $this->info("Found " . $files->count() . " new note(s). Let's sort them!");

        foreach ($files as $file) {
            $filename = $file->getFilename();
            $this->newLine();
            $this->line("Processing: <comment>$filename</comment>");

            // 3. Ask user for the Category
            $topic = $this->choice(
                "Which topic does '$filename' belong to?",
                $topics
            );

            // 4. Ensure Topic Directory Exists
            $targetDir = "$basePath/$topic";
            $targetImagesDir = "$targetDir/pictures";

            if (!File::exists($targetDir)) {
                File::makeDirectory($targetDir, 0755, true);
            }
            if (!File::exists($targetImagesDir)) {
                File::makeDirectory($targetImagesDir, 0755, true);
            }

            // 5. Scan Content for Images to Move
            // We read the file to find image links like ![alt](pictures/image.png)
            $content = File::get($file->getPathname());
            
            // Regex to find images inside the markdown
            preg_match_all('/!\[.*?\]\((.*?)\)/', $content, $matches);
            
            if (!empty($matches[1])) {
                foreach ($matches[1] as $imagePath) {
                    // Normalize path separators
                    $imagePath = str_replace('\\', '/', $imagePath);
                    
                    // We only move images that are currently in the root "pictures" folder
                    // i.e., "pictures/my-image.png"
                    if (Str::startsWith($imagePath, 'pictures/')) {
                        $imageName = basename($imagePath);
                        $sourceImage = "$basePath/pictures/$imageName";
                        $destImage = "$targetImagesDir/$imageName";

                        if (File::exists($sourceImage)) {
                            // Move the image to the Topic's picture folder
                            File::move($sourceImage, $destImage);
                            $this->info("   -> Moved image: $imageName");
                        } elseif (File::exists($destImage)) {
                            $this->warn("   -> Image already exists in destination: $imageName");
                        } else {
                            $this->warn("   -> Warning: Image not found at $sourceImage");
                        }
                    }
                }
            }

            // 6. Move the Markdown File
            File::move($file->getPathname(), "$targetDir/$filename");
            $this->info("   -> Moved note to: $topic/$filename");
        }

        // 7. Trigger the Seeder Process
        $this->runSeedingProcess();

        return 0;
    }

    /**
     * Helper to run the package and seed commands
     */
    protected function runSeedingProcess()
    {
        $this->newLine();
        $this->info("---------------------------------------");
        $this->info("File sorting complete. Running packager...");
        
        // This ensures UUIDs are generated and links are valid
        $this->call('notes:package');
        
        $this->info("---------------------------------------");
        $this->info("Running Seeder...");
        
        // This actually puts the data into the DB
        $this->call('db:seed', ['--class' => 'NotesSeeder']);

        $this->info("---------------------------------------");
        $this->info("SUCCESS! All notes imported and seeded.");
    }
}