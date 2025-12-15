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
            // Look for URLs containing /storage/uploads/
            // Group 1: Alt Text
            // Group 2: Full URL
            // Group 3: Filename (everything after the last / in the URL)
            $pattern = '/!\[(.*?)\]\(((?:https?:\/\/[^\/]+|)?.*?\/storage\/uploads\/([^\)]+))\)/';
            
            // Debug check for matches
            if (preg_match_all($pattern, $content, $debugMatches)) {
                $this->info("   Found " . count($debugMatches[0]) . " image links in " . $file->getFilename());
            } else {
                // $this->warn("   No image links found in " . $file->getFilename());
            }

            $newContent = preg_replace_callback($pattern, function ($matches) use ($targetPath, &$copiedCount, &$hasChanges) {
                $altText = $matches[1];
                $fullUrl = $matches[2];
                $serverFilename = basename($matches[3]); // The UUID filename on server
                $serverFilename = urldecode($serverFilename);

                // 1. Locate the source file in local storage
                $sourcePath = storage_path('app/public/uploads/' . $serverFilename);

                if (File::exists($sourcePath)) {
                    // 2. Determine the new human-readable filename from Alt Text
                    // If Alt Text looks like a filename (has extension), use it.
                    // Otherwise, use Alt Text + extension from server filename.
                    
                    $extension = pathinfo($serverFilename, PATHINFO_EXTENSION);
                    $cleanName = Str::slug(pathinfo($altText, PATHINFO_FILENAME)); // Slugify the name part
                    
                    // If alt text was empty or failed slugify, fallback to part of UUID
                    if (empty($cleanName)) {
                        $cleanName = pathinfo($serverFilename, PATHINFO_FILENAME);
                    }

                    // Construct new filename
                    // Check if altText actually had an extension
                    $altExtension = pathinfo($altText, PATHINFO_EXTENSION);
                    if ($altExtension && strtolower($altExtension) === strtolower($extension)) {
                         // Alt text was "Image.png", use it directly (but sanitized)
                         $newFilename = $cleanName . '.' . $extension;
                    } else {
                         // Alt text was "My Image", append extension
                         $newFilename = $cleanName . '.' . $extension;
                    }

                    // 3. Handle duplicate filenames in the target directory
                    // If "Image.png" exists, try "Image-1.png", etc.
                    $baseNewName = pathinfo($newFilename, PATHINFO_FILENAME);
                    $counter = 1;
                    while (File::exists($targetPath . DIRECTORY_SEPARATOR . $newFilename)) {
                        // Check if it's the SAME file content (md5 check) to avoid needless renaming?
                        // For simplicity, if it exists, assume we might need a unique name unless we want to overwrite.
                        // But wait, if we run this script multiple times, we want it to be stable.
                        
                        // optimization: if target file exists and has same size/hash, reuse it.
                        $existingPath = $targetPath . DIRECTORY_SEPARATOR . $newFilename;
                        if (filesize($existingPath) === filesize($sourcePath)) {
                             // Assume same file
                             break;
                        }

                        $newFilename = $baseNewName . '-' . $counter . '.' . $extension;
                        $counter++;
                    }

                    // 4. Copy the file
                    $destPath = $targetPath . DIRECTORY_SEPARATOR . $newFilename;
                    if (!File::exists($destPath)) {
                        File::copy($sourcePath, $destPath);
                        $this->line("   - Copied: $serverFilename -> $newFilename");
                        $copiedCount++;
                    }

                    // 5. Mark changes
                    $hasChanges = true;

                    // 6. Return relative link with original Alt Text (preserved) but pointing to new filename
                    return "![$altText]($newFilename)";

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
    }
}
