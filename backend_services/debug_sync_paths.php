<?php
use Illuminate\Support\Facades\File;

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$backendNotesDir = database_path('seed_data/notes');
$frontendAssetsDir = "d:/Github_Project/kalmnest/flutter_codelab/assets/www";

echo "Backend: $backendNotesDir\n";
echo "Frontend: $frontendAssetsDir\n";

$map = [];
$topics = File::directories($backendNotesDir);
foreach ($topics as $topicPath) {
    echo "Topic: " . basename($topicPath) . "\n";
    $files = File::files($topicPath);
    foreach ($files as $file) {
        if ($file->getExtension() === 'md') {
            $name = $file->getFilenameWithoutExtension();
            $map[$name] = basename($topicPath);
            // echo "  Note: '$name'\n";
        }
    }
}

echo "\n--- Checking Frontend Directories ---\n";
$frontendDirs = File::directories($frontendAssetsDir);
foreach ($frontendDirs as $dir) {
    $folderName = basename($dir);
    if (strpos($folderName, '3.1.2') === false) continue; // FILTER ONLY 3.1.2
    
    echo "Frontend Folder: '$folderName' -> ";
    
    if (isset($map[$folderName])) {
        echo "MATCH Found in Topic: " . $map[$folderName] . "\n";
    } else {
        echo "NO MATCH!\n";
        // Fuzzy search
        foreach (array_keys($map) as $noteTitle) {
            $lev = levenshtein($folderName, $noteTitle);
            if ($lev < 10) { // Increased distance check
                echo "   Did you mean: '$noteTitle'? (Dist: $lev)\n";
                echo "   Hex Frontend: " . bin2hex($folderName) . "\n";
                echo "   Hex Backend : " . bin2hex($noteTitle) . "\n";
            }
        }
    }
}
