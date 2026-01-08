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
        
        // 1. Sync to Seed Data (Dev Consistency)
        $targetDir = $seedBaseDir;
        if (!empty($subfolder)) {
            $targetDir .= DIRECTORY_SEPARATOR . $subfolder;
            // Only create seed dir if base seed dir exists (Dev Env)
            if (File::isDirectory($seedBaseDir) && !File::exists($targetDir)) {
                 try { File::makeDirectory($targetDir, 0755, true); } catch (\Exception $e) {}
            }
        }

        if (File::isDirectory($targetDir)) {
            $destPath = $targetDir . DIRECTORY_SEPARATOR . $filename;
            try {
                File::copy($sourcePath, $destPath);
            } catch (\Exception $e) {}
        }

        // 2. Sync to Frontend Assets (Flutter Bundle Synchronization)
        // This ensures the local Flutter assets folder is always up to date with backend changes.
        try {
            $frontendAssetsDir = env('FRONTEND_ASSETS_PATH');

            if ($frontendAssetsDir && File::exists($frontendAssetsDir)) {
                $targetFrontendDir = '';

                // Handle pictures (notes/pictures -> flutter/assets/www/pictures)
                if ($subfolder === 'pictures' || str_ends_with(str_replace(['\\', '/'], DIRECTORY_SEPARATOR, $subfolder), DIRECTORY_SEPARATOR . 'pictures')) {
                    $targetFrontendDir = $frontendAssetsDir . DIRECTORY_SEPARATOR . 'pictures';
                } 
                // Handle assets (Topic/assets/NoteTitle -> flutter/assets/www/NoteTitle)
                elseif (str_contains($subfolder, 'assets')) {
                    $parts = preg_split('/[\\/\\\\]/', $subfolder);
                    $keyIndex = array_search('assets', $parts);
                    if ($keyIndex !== false && isset($parts[$keyIndex + 1])) {
                        $noteTitle = $parts[$keyIndex + 1];
                        $targetFrontendDir = $frontendAssetsDir . DIRECTORY_SEPARATOR . $noteTitle;
                    }
                }

                if (!empty($targetFrontendDir)) {
                    if (!File::exists($targetFrontendDir)) {
                        File::makeDirectory($targetFrontendDir, 0755, true);
                    }
                    $frontendDestPath = $targetFrontendDir . DIRECTORY_SEPARATOR . $filename;
                    File::copy($sourcePath, $frontendDestPath);
                }
            }
        } catch (\Exception $ex) {
            // Log if needed, but fail silently to not block the main process
        }
    }
}
