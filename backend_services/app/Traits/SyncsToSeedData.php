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

        // 2. Sync to Public Assets (Web Runtime Persistence)
        // Mapping: <Topic>/assets/<NoteTitle>  ->  public/assets/www/<NoteTitle>
        // Mapping: pictures -> public/assets/www/pictures
        
        try {
            $publicBase = public_path('assets/www');
            if (!File::exists($publicBase)) {
                File::makeDirectory($publicBase, 0755, true);
            }

            $publicDestDir = '';

            if ($subfolder === 'pictures') {
                $publicDestDir = $publicBase . DIRECTORY_SEPARATOR . 'pictures';
            } elseif (str_contains($subfolder, 'assets')) {
                 // Extract Note Title from "Topic/assets/NoteTitle"
                 // Note: We use DIRECTORY_SEPARATOR agnostic regex or simple explode
                 $parts = preg_split('/[\\/\\\\]/', $subfolder);
                 // Expected: [Topic, assets, NoteTitle]
                 $keyIndex = array_search('assets', $parts);
                 if ($keyIndex !== false && isset($parts[$keyIndex + 1])) {
                     $noteTitle = $parts[$keyIndex + 1];
                     $publicDestDir = $publicBase . DIRECTORY_SEPARATOR . $noteTitle;
                 }
            }

            if (!empty($publicDestDir)) {
                if (!File::exists($publicDestDir)) {
                    File::makeDirectory($publicDestDir, 0755, true);
                }
                $publicDestPath = $publicDestDir . DIRECTORY_SEPARATOR . $filename;
                File::copy($sourcePath, $publicDestPath);
                // \Log::info("DEBUG: Synced to Public Assets: $publicDestPath");
            }

        } catch (\Exception $ex) {
            // \Log::error("Failed to sync to public assets: " . $ex->getMessage());
        }
    }
}
