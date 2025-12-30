<?php
use Illuminate\Support\Facades\File;

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$backendNotesDir = database_path('seed_data/notes');
$frontendAssetsDir = "d:/Github_Project/kalmnest/flutter_codelab/assets/www";
$targetFolder = "3.1.2 Atur Cara dan Carta Alir bagi Bahasa Penskripan Klien";
$topic = "JS";

echo "Target: $targetFolder\n";
echo "Topic: $topic\n";

$sourceDir = "$frontendAssetsDir/$targetFolder";
$destDir = "$backendNotesDir/$topic/assets/$targetFolder";

if (!File::exists($sourceDir)) {
    echo "ERROR: Source does not exist: $sourceDir\n";
    exit;
} else {
    echo "Source Exists.\n";
}

if (!File::exists($destDir)) {
    echo "Dest does not exist. Creating...\n";
    try {
        File::makeDirectory($destDir, 0755, true);
        echo "Dest Created.\n";
    } catch (\Exception $e) {
        echo "ERROR Creating Dest: " . $e->getMessage() . "\n";
    }
} else {
    echo "Dest Exists.\n";
}

$files = File::allFiles($sourceDir);
foreach ($files as $file) {
    echo "Found file: " . $file->getRelativePathname() . "\n";
    $destPath = "$destDir/" . $file->getRelativePathname();
    try {
        File::copy($file->getPathname(), $destPath);
        echo "Copied to: $destPath\n";
    } catch (\Exception $e) {
        echo "Copy Failed: " . $e->getMessage() . "\n";
    }
}
