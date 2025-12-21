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
            // This allows the script to read files like 'LogMasuk.txt' if they exist in assets
            $contextId = $request->input('context_id');
            if ($contextId) {
                // Adjust this matching your folder structure
                // backend_services/../../flutter_codelab/assets/www/{ID}
                $rawPath = base_path('../flutter_codelab/assets/www/' . $contextId);
                $sourceDir = realpath($rawPath);
                
                if ($sourceDir && is_dir($sourceDir)) {
                    // Method to copy recursively
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

                    // Determine main file: either explicitly set, or the first PHP file
                    if ($fileName === $entryPoint || ($mainFileToRun === null && str_ends_with($fileName, '.php'))) {
                         $mainFileToRun = $tempDir . '/' . $fileName;
                    }
                }
            }

            // --- 2. BACKWARD COMPATIBILITY / SINGLE FILE MODE ---
            // If we have 'code' but no specific file list, treat it as a single file run
            if (empty($files) && !empty($code)) {
                $filename = 'php_run_' . $uniqueId . '.php';
                $mainFileToRun = $tempDir . '/' . $filename;
                
                // Form Data Mocking (Only meaningful for single file "PHP mock" mode usually)
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

            // --- 3. LINT CHECK (On the main file) ---
            $lintProcess = new Process(['php', '-l', $mainFileToRun]);
            $lintProcess->run();
            
            if (!$lintProcess->isSuccessful()) {
                // Return just the error message
                $error = $lintProcess->getOutput();
                // Clean up path from error message for security/clarity
                $error = str_replace($mainFileToRun, basename($mainFileToRun), $error);
                return response()->json(['output' => $error]);
            }

            // --- 4. PREPARE EXECUTION ---
            $debugInfo = "";
            $contextId = $request->input('context_id');
            // Default CWD is the temp dir so files can include each other relatively
            $cwd = $tempDir; 

            // If context_id is provided, we might want to allow access to those assets.
            // However, for multi-file run, usually the user provides the context.
            // If we strictly need asset access, we might need to symlink or copy.
            // For now, let's Stick to temp dir as CWD for user files isolation.
            
            // Execute
            $process = new Process(['php', '-f', $mainFileToRun], $cwd);
            $process->setTimeout(10); // 10 seconds timeout
            $process->run();

            // Capture output
            $output = $process->getOutput();
            $errorOutput = $process->getErrorOutput();

            return response()->json([
                'output' => $debugInfo . (!empty($output) ? $output : $errorOutput)
            ]);

        } catch (\Exception $e) {
            return response()->json(['output' => 'Execution Error: ' . $e->getMessage()], 500);
        } finally {
            // Cleanup: Delete the temp folder and all files
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