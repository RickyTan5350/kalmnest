<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;

class PackageNotes extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'notes:package {path? : The directory containing the markdown files to package}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Scans note files for linked images, copies them to the seed directory, and updates links to be relative.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        // Default to the standard seed data path if not provided
        $targetPath = $this->argument('path') ?? database_path('seed_data/notes');

        if (!File::isDirectory($targetPath)) {
            $this->error("Directory not found: $targetPath");
            return 1;
        }

        $this->info("Packaging notes in: $targetPath");

        $files = File::files($targetPath);
        $updatedCount = 0;
        $copiedCount = 0;

        foreach ($files as $file) {
            if ($file->getExtension() !== 'md') {
                continue;
            }

            $content = File::get($file->getPathname());
            $originalContent = $content;
            $hasChanges = false;

            // Regex to find images: ![alt](url)
            // We look for URLs that contain '/storage/uploads/' which indicates they are served from this app
            $pattern = '/!\[(.*?)\]\((.*?\/storage\/uploads\/(.*?))\)/';

            $newContent = preg_replace_callback($pattern, function ($matches) use ($targetPath, &$copiedCount, &$hasChanges) {
                $altText = $matches[1];
                $fullUrl = $matches[2];
                $filename = $matches[3]; // The actual filename part after .../uploads/

                // 1. Locate the source file in local storage
                // We assume the standard storage location
                $sourcePath = storage_path('app/public/uploads/' . $filename);

                if (File::exists($sourcePath)) {
                    // 2. Copy the file to the seed directory if it doesn't already exist
                    $destPath = $targetPath . DIRECTORY_SEPARATOR . $filename;
                    
                    if (!File::exists($destPath)) {
                        File::copy($sourcePath, $destPath);
                        $this->line("   - Copied: $filename");
                        $copiedCount++;
                    }

                    // 3. Mark that we are changing the link
                    $hasChanges = true;

                    // 4. Return the new relative link format
                    return "![$altText]($filename)";
                } else {
                    $this->warn("   - Warning: Could not find source image for: $filename");
                    // Return original if we can't find the file
                    return $matches[0];
                }
            }, $content);

            if ($content !== $newContent) {
                File::put($file->getPathname(), $newContent);
                $this->info("Updated links in: " . $file->getFilename());
                $updatedCount++;
            }
        }

        $this->info("Packaging Complete!");
        $this->info(" - Files copied: $copiedCount");
        $this->info(" - Notes updated: $updatedCount");

        return 0;
    }
}
