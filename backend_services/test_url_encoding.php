<?php

use Illuminate\Support\Facades\Storage;

echo "--- Testing URL Encoding ---\n";

$path = 'uploads/file with spaces.png';
$storageUrl = Storage::url($path);
echo "Storage::url('$path'): " . $storageUrl . "\n";

$fullUrl = url($storageUrl);
echo "url(...): " . $fullUrl . "\n";

$encodedPath = str_replace('%2F', '/', rawurlencode($path));
echo "Manual Encode: " . url(Storage::url($encodedPath)) . "\n";
