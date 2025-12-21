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

        if (empty($code)) {
            return response()->json(['output' => 'No code provided.'], 400);
        }

        $filename = 'php_run_' . Str::random(10) . '.php';
        $tempPath = storage_path('app/temp/' . $filename);

        // 1. Prepare Content
        $code = $request->input('code');
        $formData = $request->input('form_data');

        // --- PHP POST MOCKING ---
        if (!empty($formData) && is_array($formData)) {
            $mockCode = "<?php\n";
            $mockCode .= "\$_SERVER['REQUEST_METHOD'] = 'POST';\n";
            $mockCode .= "\$_POST = " . var_export($formData, true) . ";\n";
            $mockCode .= "?>\n";
            
            // Remove existing <?php from user code if it exists at the start
            // to avoid nested/double opening tags which might be weird, 
            // but actually standard PHP handles multiple blocks fine.
            // Best to just prepend.
            $code = $mockCode . $code;
        }
        // ------------------------

        // Basic syntax check (lint)
        $lintFile = tempnam(sys_get_temp_dir(), 'lint') . '.php';
        file_put_contents($lintFile, $code);
        $lintProcess = new Process(['php', '-l', $lintFile]);
        $lintProcess->run();
        
        if (!$lintProcess->isSuccessful()) {
            unlink($lintFile);
            // Return just the error message, stripped of filename
            $error = $lintProcess->getOutput();
            return response()->json(['output' => $error]);
        }
        unlink($lintFile); // Lint file clean up

        // Write actual execution file
        $tempPath = tempnam(sys_get_temp_dir(), 'php_code') . '.php';
        file_put_contents($tempPath, $code);

        try {
            // 1. Syntax Check (This is now redundant due to the lint check above, but keeping for now)
            $syntaxCheck = new Process(['php', '-l', $tempPath]);
            $syntaxCheck->run();

            if (!$syntaxCheck->isSuccessful()) {
                $error = $syntaxCheck->getErrorOutput();
                $error = str_replace($tempPath, 'your code', $error);
                return response()->json(['output' => $error]);
            }

            $debugInfo = "";
            $contextId = $request->input('context_id');
            $cwd = null;

            if ($contextId) {
                // Adjust this path relative to your Laravel install
                // D:\Github_Project\kalmnest\backend_services\..\flutter_codelab\...
                $rawPath = base_path('../flutter_codelab/assets/www/' . $contextId);
                $targetDir = realpath($rawPath);
                
                if ($targetDir && is_dir($targetDir)) {
                    $cwd = $targetDir;
                    $debugInfo .= "DEBUG: CWD set to: $targetDir<br>";
                } else {
                     $debugInfo .= "DEBUG: Path resolution failed.<br>";
                     $debugInfo .= "Raw: $rawPath<br>";
                     $debugInfo .= "Real: " . var_export($targetDir, true) . "<br>";
                }
            } else {
                $debugInfo .= "DEBUG: No context_id received.<br>";
            }

            $process = new Process(['php', '-f', $tempPath], $cwd);
            $process->setTimeout(5);
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
            if (file_exists($tempPath)) {
                unlink($tempPath);
            }
        }
    } // End of execute method
} // End of class