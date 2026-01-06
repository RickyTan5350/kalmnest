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

        // --- SESSION PERSISTENCE ---
        // If frontend provides a session ID, use it to create a persistent temp directory
        $providedSessionId = $request->input('php_session_id');
        if (!empty($providedSessionId)) {
            // Validate ID format to prevent path traversal
             if (!preg_match('/^[\w-]+$/', $providedSessionId)) {
                $providedSessionId = 'invalid_session';
             }
             $uniqueId = $providedSessionId;
             $tempDirName = 'run_' . $uniqueId;
             $shouldPersist = true;
        } else {
             $uniqueId = Str::random(10);
             $tempDirName = 'run_' . $uniqueId;
             $shouldPersist = false;
        }
        
        $tempDir = storage_path('app/temp/' . $tempDirName);

        // reuse existing directory if persistent
        if (!file_exists($tempDir)) {
            mkdir($tempDir, 0777, true);
        } else {
            // If it exists and we are reusing, we don't need to copy everything again?
            // Actually users might EDIT files in the frontend, so we SHOULD overwrite files.
            // But we should NOT delete other files (like sessions if they were stored here, 
            // though session files are usually in /tmp).
        }


        try {
            // --- 0. COPY COMPANION ASSETS (If context_id provided) ---
            $contextId = $request->input('context_id');
            
            // --- 0.1 COPY SHARED SETUP_DB (Always) ---
            // Ensure the shared setup_db.php is available in the temp root
            $setupDbPath = base_path('../flutter_codelab/assets/setup_db.php');
            if (file_exists($setupDbPath)) {
                copy($setupDbPath, $tempDir . '/setup_db.php');
            }

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

            // --- 0. PREPARE DATA ---
            $formData = $request->input('form_data');
            $getData = $request->input('get_data'); // New: Query Params

            // --- 4. INJECT MOCKS (POST, GET, HEADERS) ---
            // We inject a special prelude to handle $_POST, $_GET, and capture Link Headers.
            // Since we are running in CLI, headers() don't work natively. 
            // We use register_shutdown_function to inspect headers_list() and emit JS redirect.
            
            $fileToInject = $mainFileToRun;
            // If it's the legacy generated file, we just prepend to $code before writing.
            // But here we are likely dealing with existing files or $mainFileToRun determined above.
            
            // We only inject if it's a PHP file
            if (str_ends_with($mainFileToRun, '.php')) {
                 $mockCode = "<?php\n";
                 // DEBUG INJECTION
                 if (!empty($getData)) {
                    error_log("RunCodeController: Injecting GET Data: " . print_r($getData, true));
                 } else {
                    error_log("RunCodeController: No GET Data to inject.");
                 }
                 
                 // 0. FORCE SESSION ID
                 // If we have a provided session ID, force PHP to use it.
                 // This ensures that session_start() picks up the same session across requests.
                 if (!empty($providedSessionId)) {
                     $mockCode .= "if(session_status() === PHP_SESSION_NONE) {\n";
                     $mockCode .= "  session_save_path('" . addslashes($tempDir) . "');\n";
                     $mockCode .= "  session_id('$providedSessionId');\n";
                     $mockCode .= "}\n";
                 }

                 // 1. MOCK $_SERVER REQUEST METHOD
                 if (!empty($formData)) {
                    $mockCode .= "\$_SERVER['REQUEST_METHOD'] = 'POST';\n";
                    $mockCode .= "\$_POST = " . var_export($formData, true) . ";\n";
                 } else {
                    $mockCode .= "\$_SERVER['REQUEST_METHOD'] = 'GET';\n";
                 }

                 // 2. MOCK $_GET
                 if (!empty($getData) && is_array($getData)) {
                    $mockCode .= "\$_GET = " . var_export($getData, true) . ";\n";
                    // Also merge into $_REQUEST
                    $mockCode .= "\$_REQUEST = array_merge(\$_REQUEST, \$_GET);\n";
                 }
                 if (!empty($formData) && is_array($formData)) {
                    $mockCode .= "\$_REQUEST = array_merge(\$_REQUEST, \$_POST);\n";
                 }

                 // 3. HEADER REDIRECT POLYFILL
                 // CLI mode doesn't support header(), but we can capture it using xdebug if available,
                 // or just reliance on standard output buffering usually doesn't catch 'header()'.
                 // WAIT: In CLI, header() is usually ignored. 
                 // We can use `ob_start` and check `headers_list()` IF php-cgi is used, but php-cli ignores it.
                 // BETTER APPROACH: We can't easily intercept proper header() logic in strict CLI without an extension.
                 // HOWEVER, many users might use `echo "<script>..."` which works.
                 // IF they use strictly header("Location: ..."), it fails in CLI.
                 // FIX: We can redefine the header function? No, 'header' is a language construct/core function.
                 // We can try to rely on the fact that if they use `header` it might just print nothing.
                 // BUT: The user SPECIFICALLY asked for this.
                 // Trick: Run with `php-cgi` if available? No, we use `php`.
                 // Alternative: Overwrite `header` using namespaces? Too complex for user code.
                 // BEST EFFORT: We actually can't intercept `header()` in `php -f` easily if it doesn't emit.
                 // BUT, let's try to add a user-land helper check or just tell them? 
                 // No, let's see if `headers_list()` works in CLI. It usually returns empty.
                 // The user's code uses `header("Location: ...")`.
                 // We will try to wrap execution or use a custom "runner script" that includes the file.
                 
                 // RUNNER SCRIPT APPROACH
                 // Instead of running the file directly, we run a wrapper that includes the file.
                 // This wrapper can attempt to catch things.
                 // But capturing `header()` calls in pure PHP CLI is impossible without runkit/uopz.
                 // WAIT: `php-cgi` might be installed? Usually not on standard windows installs unless xampp.
                 // Let's assume standard `php` executable.
                 
                 // RE-READING: User uses `header("Location: Sah.php")`.
                 // If that executes in CLI, it does nothing and exits.
                 // If we can't patch it, we can't support it. 
                 // UNLESS we use string replacement on the source code to replace `header(` with `custom_header(`.
                 // This is a "Dirty" but effective hack for this context.
                 
                 $mockCode .= "if (!function_exists('custom_header_polyfill')) {\n";
                 $mockCode .= "  function custom_header_polyfill(\$h) {\n";
                 $mockCode .= "    if (stripos(\$h, 'Location:') === 0) {\n";
                 $mockCode .= "      \$url = trim(substr(\$h, 9));\n";
                 $mockCode .= "      echo \"<script>var msg = 'FLUTTER_WEB_BRIDGE:' + JSON.stringify({action:'link_click', data:{url:'\$url'}}); if(window.parent !== window){ window.parent.postMessage(msg, '*'); } console.log(msg);</script>\";\n";
                 $mockCode .= "    }\n";
                 $mockCode .= "  }\n";
                 $mockCode .= "}\n";
                 $mockCode .= "?>\n";

                 // We need to READ the file content and REPLACE `header(` with `custom_header_polyfill(`
                 // This is aggressive but necessary for `run_code_page` emulation of a server.
                 
                 $originalContent = file_get_contents($mainFileToRun);
                 
                 // Apply Replacement safely (avoid replacing comments if possible, but regex is fine for now)
                 // Matches `header` followed by optional whitespace and `(`
                 // We use a regex that tries to match function call context.
                 $patchedContent = preg_replace(
                    '/\bheader\s*\(/i', 
                    'custom_header_polyfill(', 
                    $originalContent
                 );

                 // Write the patched content + mocks
                 file_put_contents($mainFileToRun, $mockCode . $patchedContent);
            }
            
            // --- 5. LINT CHECK ---
            $lintProcess = new Process(['php', '-l', $mainFileToRun]);
            $lintProcess->run();
            
            if (!$lintProcess->isSuccessful()) {
                $error = $lintProcess->getOutput();
                // Clean up any leaked temp paths in error message
                $error = str_replace($mainFileToRun, basename($mainFileToRun), $error);
                return response()->json(['output' => "Syntax Error: " . $error]);
            }

            // --- 6. EXECUTE ---
            $cwd = $tempDir; 
            
            $process = new Process(['php', '-f', $mainFileToRun], $cwd);
            $process->setTimeout(10);
            $process->run();

            $output = $process->getOutput();
            $errorOutput = $process->getErrorOutput();

            // Ensure output is UTF-8 compatible to prevent 500 JSON errors
            if ($output) {
                // If contains invalid UTF-8, ignore errors and substitute
                $output = mb_convert_encoding($output, 'UTF-8', 'UTF-8');
            }
            if ($errorOutput) {
                 $errorOutput = mb_convert_encoding($errorOutput, 'UTF-8', 'UTF-8');
            }

            // --- 6.5 RESTORE MAIN FILE CONTENT (Undo Injection) ---
            // We must undo the mock injection so that the 'clean' file is returned to frontend,
            // unless the script itself modified it.
            // But we actually MODIFIED the logic (replaced header). We definitely want to restore.
            if (isset($originalContent) && file_exists($mainFileToRun)) {
                file_put_contents($mainFileToRun, $originalContent);
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
                        $ext = strtolower(pathinfo($fullPath, PATHINFO_EXTENSION));
                        $content = file_get_contents($fullPath);
                        $isBinary = in_array($ext, ['png', 'jpg', 'jpeg', 'gif', 'ico', 'pdf', 'zip']);

                        if ($isBinary) {
                            $content = base64_encode($content);
                        } else {
                            // Ensure UTF-8 for text files
                            $content = mb_convert_encoding($content, 'UTF-8', 'UTF-8');
                        }
                        
                        $simulatedFiles[] = [
                            'name' => $f,
                            'content' => $content,
                            'is_binary' => $isBinary
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
            if (isset($tempDir) && is_dir($tempDir)) {
                if (!isset($shouldPersist) || !$shouldPersist) {
                    $this->deleteDirectory($tempDir);
                }
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

    /**
     * Serve a file from public/storage via API to bypass CORS on static files.
     */
    public function getFile(Request $request) {
        try {
            $path = $request->query('path');
            if (!$path) {
                return response()->json(['error' => 'Path required'], 400);
            }

            // Prevent traversal
            if (str_contains($path, '..')) {
                return response()->json(['error' => 'Invalid path'], 403);
            }

            // We assume path is relative to public folder (e.g. assets/www/...)
            $fullPath = public_path($path);

            if (file_exists($fullPath)) {
                return response()->file($fullPath);
            }

            return response()->json(['error' => 'File not found: ' . $path], 404);
        } catch (\Exception $e) {
             return response()->json(['error' => 'Server Error serving file: ' . $e->getMessage()], 500);
        }
    }
}