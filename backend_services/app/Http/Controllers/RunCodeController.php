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

        if (!file_exists(dirname($tempPath))) {
            mkdir(dirname($tempPath), 0755, true);
        }

        // Write code to file
        file_put_contents($tempPath, $code);

        try {
            // 1. Syntax Check
            $syntaxCheck = new Process(['php', '-l', $tempPath]);
            $syntaxCheck->run();

            if (!$syntaxCheck->isSuccessful()) {
                $error = $syntaxCheck->getErrorOutput();
                $error = str_replace($tempPath, 'your code', $error);
                return response()->json(['output' => $error]);
            }

            // 2. Execution
            $process = new Process(['php', '-f', $tempPath]);
            $process->setTimeout(5);
            $process->run();

            // Capture output
            $output = $process->getOutput();
            $errorOutput = $process->getErrorOutput();

            return response()->json([
                'output' => !empty($output) ? $output : $errorOutput
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