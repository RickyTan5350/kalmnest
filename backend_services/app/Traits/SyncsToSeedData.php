<?php

namespace App\Traits;

use Illuminate\Support\Facades\File;

trait SyncsToSeedData
{
    /**
     * Syncs a file to the seed_data directory.
     *
     * @param string $sourcePath The absolute path to the source file.
     * @param string $filename The filename to save as in seed data.
     * @param string $subfolder Optional subfolder within seed_data/notes (e.g., 'pictures').
     * @return void
     */
    protected function syncFileToSeedData($sourcePath, $filename, $subfolder = '')
    {
        $seedBaseDir = database_path('seed_data/notes');
        
        // Only proceed if the base seed directory exists (Dev environment check)
        if (!File::isDirectory($seedBaseDir)) {
            return;
        }

        $targetDir = $seedBaseDir;
        if (!empty($subfolder)) {
            $targetDir .= DIRECTORY_SEPARATOR . $subfolder;
            if (!File::exists($targetDir)) {
                File::makeDirectory($targetDir, 0755, true);
            }
        }

        $destPath = $targetDir . DIRECTORY_SEPARATOR . $filename;

        try {
            File::copy($sourcePath, $destPath);
        } catch (\Exception $e) {
            // Silently fail or log, as this is a dev-only convenience feature
            // \Log::warning("Failed to sync file to seed data: " . $e->getMessage());
        }
    }
}
