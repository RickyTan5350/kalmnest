<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

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
        $targetPath = $this->argument('path') ?? database_path('seed_data/notes');

        if (!File::isDirectory($targetPath)) {
            $this->error("Directory not found: $targetPath");
            return 1;
        }

        $this->info("Packaging notes recursively in: $targetPath");

        // FIX 1: Use allFiles() instead of files() to scan subfolders (HTML, CSS, etc.)
        $files = File::allFiles($targetPath);
        
        $updatedCount = 0;
        $copiedCount = 0;

        foreach ($files as $file) {
            if ($file->getExtension() !== 'md') {
                continue;
            }

            // FIX 2: Define 'pictures' folder relative to the CURRENT note's folder
            $noteDir = $file->getPath(); 
            $picturesPath = $noteDir . DIRECTORY_SEPARATOR . 'pictures';

            if (!File::exists($picturesPath)) {
                File::makeDirectory($picturesPath, 0755, true);
            }

            $content = File::get($file->getPathname());
            $hasChanges = false;

            // Regex matches your specific URL format
            $pattern = '/!\[(.*?)\]\(((?:https?:\/\/[^\/]+|)?.*?\/storage\/notes\/pictures\/([^\)]+))\)/';
            
            $newContent = preg_replace_callback($pattern, function ($matches) use ($picturesPath, &$copiedCount, &$hasChanges) {
                $altText = $matches[1];
                // $fullUrl = $matches[2]; // Unused
                $serverFilename = basename($matches[3]); 
                $serverFilename = urldecode($serverFilename); // Fixes %20 to space

                $sourcePath = storage_path('app/public/notes/pictures/' . $serverFilename);

                if (File::exists($sourcePath)) {
                    // Logic to clean filename
                    $extension = pathinfo($serverFilename, PATHINFO_EXTENSION);
                    $cleanName = Str::slug(pathinfo($altText, PATHINFO_FILENAME)); 
                    if (empty($cleanName)) $cleanName = pathinfo($serverFilename, PATHINFO_FILENAME);
                    
                    $newFilename = $cleanName . '.' . $extension;

                    // Handle Duplicates
                    $baseNewName = pathinfo($newFilename, PATHINFO_FILENAME);
                    $counter = 1;
                    while (File::exists($picturesPath . DIRECTORY_SEPARATOR . $newFilename)) {
                        // Optimization: Check if it's actually the same file
                        $existingPath = $picturesPath . DIRECTORY_SEPARATOR . $newFilename;
                        if (filesize($existingPath) === filesize($sourcePath)) {
                             break; // Same file, reuse it
                        }
                        $newFilename = $baseNewName . '-' . $counter . '.' . $extension;
                        $counter++;
                    }

                    // Copy file
                    $destPath = $picturesPath . DIRECTORY_SEPARATOR . $newFilename;
                    if (!File::exists($destPath)) {
                        File::copy($sourcePath, $destPath);
                        $this->line("   - Copied: $serverFilename -> pictures/$newFilename");
                        $copiedCount++;
                    }

                    $hasChanges = true;
                    // FIX 3: Return relative link that works inside subfolders
                    return "![$altText](pictures/$newFilename)";

                } else {
                    $this->warn("   - Warning: Source image not found locally: $serverFilename");
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
    }}