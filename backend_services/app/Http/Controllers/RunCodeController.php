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

        // Create a unique temporary file
        $filename = 'php_run_' . Str::random(10) . '.php';
        $tempPath = storage_path('app/temp/' . $filename);

        // Ensure temp directory exists
        if (!file_exists(dirname($tempPath))) {
            mkdir(dirname($tempPath), 0755, true);
        }

        // Write code to file
        file_put_contents($tempPath, $code);

        try {
            // Check syntax first
            $syntaxCheck = new Process(['php', '-l', $tempPath]);
            $syntaxCheck->run();

            if (!$syntaxCheck->isSuccessful()) {
                // Return syntax error, stripped of the filename for cleaner output
                $error = $syntaxCheck->getOutput(); 
                $error = str_replace($tempPath, 'input code', $error);
                return response()->json(['output' => $error]);
            }

            // Execute the code
            // Timeout after 5 seconds to prevent infinite loops
            $process = new Process(['php', '-f', $tempPath]);
            $process->setTimeout(5);
            $process->run();

            if ($process->isSuccessful()) {
                return response()->json(['output' => $process->getOutput()]);
            } else {
                return response()->json(['output' => $process->getErrorOutput()]);
            }

        } catch (\Exception $e) {
            return response()->json(['output' => 'Execution Error: ' . $e->getMessage()], 500);
        } finally {
            // Clean up
            if (file_exists($tempPath)) {
                unlink($tempPath);
            }
        }
    }
}
