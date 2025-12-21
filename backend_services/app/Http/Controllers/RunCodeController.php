<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\Process\Process;

class RunCodeController extends Controller
{
    public function execute(Request $request)
    {
        $code = $request->input('code');
        $files = $request->input('files'); // Expecting array of {name: "filename.ext", content: "..."}
        $entryPoint = $request->input('entry_point');

        if (empty($code) && empty($files)) {
            return response()->json(['output' => 'No code or files provided.'], 400);
        }

        // Create a unique temporary directory for this execution
        $uniqueId = Str::random(10);
        $tempDirName = 'run_' . $uniqueId;
        $tempDir = storage_path('app/temp/' . $tempDirName);

        if (!file_exists($tempDir)) {
            mkdir($tempDir, 0777, true);
        }

        try {
            // --- 0. COPY COMPANION ASSETS (If context_id provided) ---
            $contextId = $request->input('context_id');
            if ($contextId) {
                // Adjust this matching your folder structure
                $rawPath = base_path('../flutter_codelab/assets/www/' . $contextId);
                $sourceDir = realpath($rawPath);
                
                if ($sourceDir && is_dir($sourceDir)) {
                    \Illuminate\Support\Facades\File::copyDirectory($sourceDir, $tempDir);
                }
            }

            $mainFileToRun = null;

            // --- 1. HANDLE FILES ---
            if (!empty($files) && is_array($files)) {
                foreach ($files as $file) {
                    $fileName = $file['name'] ?? 'unknown.txt';
                    $fileContent = $file['content'] ?? '';
                    file_put_contents($tempDir . '/' . $fileName, $fileContent);

                    // Determine main file
                    if ($fileName === $entryPoint || ($mainFileToRun === null && str_ends_with($fileName, '.php'))) {
                         $mainFileToRun = $tempDir . '/' . $fileName;
                    }
                }
            }

            // --- 2. FIND ENTRY POINT (Fallback checks) ---
            // If main file is still not found, check if the entry point exists on disk (e.g. copied from assets)
            if (!$mainFileToRun && $entryPoint) {
                // 1. Try exact path
                $potentialPath = $tempDir . '/' . $entryPoint;
                if (file_exists($potentialPath)) {
                    $mainFileToRun = $potentialPath;
                } else {
                    // 2. Try just the basename (robustness against frontend sending paths)
                    $basename = basename($entryPoint);
                    $potentialPathBase = $tempDir . '/' . $basename;
                    if (file_exists($potentialPathBase)) {
                        $mainFileToRun = $potentialPathBase;
                    }
                }
            }

            // --- 3. SINGLE FILE FALLBACK ---
            if (empty($files) && !empty($code)) {
                $filename = 'php_run_' . $uniqueId . '.php';
                $mainFileToRun = $tempDir . '/' . $filename;
                
                // Form Data Mocking for legacy single-file mode
                $formData = $request->input('form_data');
                if (!empty($formData) && is_array($formData)) {
                    $mockCode = "<?php\n";
                    $mockCode .= "\$_SERVER['REQUEST_METHOD'] = 'POST';\n";
                    $mockCode .= "\$_POST = " . var_export($formData, true) . ";\n";
                    $mockCode .= "?>\n";
                    $code = $mockCode . $code;
                }
                
                file_put_contents($mainFileToRun, $code);
            }

            if (!$mainFileToRun) {
                return response()->json(['output' => 'No executable PHP file found.'], 400);
            }

            // --- 4. INJECT POST MOCKING (If form data exists) ---
            $formData = $request->input('form_data');
            // Only inject if we haven't already injected for single-file mode above (detected by checking content match, or just do it safely)
            // For multi-file execution or asset execution, we need this.
            // Be careful not to double-inject if it was legacy single file.
            // Legacy single file writes to $mainFileToRun with injected code.
            // So we only inject here if it's NOT the legacy path result, OR we just check if it needs valid injection.
            // Actually, simpler: The single-file block creates a NEW file. The multi-file/asset block uses EXISTING/UPLOADED files.
            // So if we are in multi-file mode (files not empty OR entry point found on disk), we inject.
            
            // Refinement: If it came from legacy single file block, we already injected.
            // If it came from Asset or Files, we haven't.
            // We can check if 'files' was provided OR if we found an asset file.
            $isLegacySingleFile = (empty($files) && !empty($code) && str_contains($mainFileToRun, 'php_run_'));

            if (!$isLegacySingleFile && !empty($formData) && is_array($formData)) {
                $mockCode = "<?php\n";
                $mockCode .= "\$_SERVER['REQUEST_METHOD'] = 'POST';\n";
                $mockCode .= "\$_POST = " . var_export($formData, true) . ";\n";
                $mockCode .= "?>\n";
                
                $currentContent = file_get_contents($mainFileToRun);
                file_put_contents($mainFileToRun, $mockCode . $currentContent);
            }

            // --- 5. LINT CHECK ---
            $lintProcess = new Process(['php', '-l', $mainFileToRun]);
            $lintProcess->run();
            
            if (!$lintProcess->isSuccessful()) {
                $error = $lintProcess->getOutput();
                $error = str_replace($mainFileToRun, basename($mainFileToRun), $error);
                return response()->json(['output' => $error]);
            }

            // --- 6. EXECUTE ---
            $cwd = $tempDir; 
            
            $process = new Process(['php', '-f', $mainFileToRun], $cwd);
            $process->setTimeout(10);
            $process->run();

            $output = $process->getOutput();
            $errorOutput = $process->getErrorOutput();

            // --- 6.5 RESTORE MAIN FILE CONTENT (Undo Injection) ---
            // We must undo the mock injection so that the 'clean' file is returned to frontend,
            // unless the script itself modified it (which is rare/hard to distinguish, but restoring 
            // original pre-injection content is the safest bet for 'Session Persistence' of OTHER files).
            if (isset($currentContent) && !$isLegacySingleFile && file_exists($mainFileToRun)) {
                file_put_contents($mainFileToRun, $currentContent);
            }

            // --- 7. CAPTURE MODIFIED FILES ---
            // Scan the temp dir for files to return for session persistence
            $simulatedFiles = [];
            
            // Only scan if directory still exists (it should)
            if (is_dir($tempDir)) {
                $filesOnDisk = scandir($tempDir);
                foreach ($filesOnDisk as $f) {
                    if ($f === '.' || $f === '..') continue;
                    
                    // Skip the generated wrapper if it exists (for legacy single file mode)
                    if (str_starts_with($f, 'php_run_')) continue;

                    $fullPath = $tempDir . '/' . $f;
                    if (is_file($fullPath)) {
                        $simulatedFiles[] = [
                            'name' => $f,
                            'content' => file_get_contents($fullPath)
                        ];
                    }
                }
            }

            return response()->json([
                'output' => (!empty($output) ? $output : $errorOutput),
                'files' => $simulatedFiles
            ]);

        } catch (\Exception $e) {
            return response()->json(['output' => 'Execution Error: ' . $e->getMessage()], 500);
        } finally {
            if (is_dir($tempDir)) {
                $this->deleteDirectory($tempDir);
            }
        }
    }

    private function deleteDirectory($dir) {
        if (!file_exists($dir)) {
            return true;
        }
        if (!is_dir($dir)) {
            return unlink($dir);
        }
        foreach (scandir($dir) as $item) {
            if ($item == '.' || $item == '..') {
                continue;
            }
            if (!$this->deleteDirectory($dir . DIRECTORY_SEPARATOR . $item)) {
                return false;
            }
        }
        return rmdir($dir);
    }
}