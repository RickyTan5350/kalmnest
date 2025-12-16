<?php
// Autoload
require __DIR__.'/vendor/autoload.php';

// Bootstrap App
$app = require_once __DIR__.'/bootstrap/app.php';

// Bootstrap Kernel
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Http\Request;

// Debug Logic
try {
    // Find the latest Alice (same user used in previous test)
    $user = App\Models\User::where('name', 'like', 'Teacher Alice%')
        ->where('email', 'like', 'alice_%@test.com')
        ->latest()
        ->first();
        
    if (!$user) {
        echo "User not found!\n";
        exit;
    }
    echo "Logging in as: " . $user->name . " (" . $user->user_id . ")\n";
    echo "Role: " . ($user->role ? $user->role->role_name : 'No Role') . "\n";

    Illuminate\Support\Facades\Auth::login($user);

    $controller = app(App\Http\Controllers\ClassController::class);
    
    // Create a mock request
    $request = Request::create('/api/classes', 'GET');
    
    // Explicitly call the method
    $response = $controller->index($request);

    echo "Response Status: " . $response->getStatusCode() . "\n";
    echo "Response Content:\n";
    
    $content = json_decode($response->getContent(), true);
    if (json_last_error() === JSON_ERROR_NONE) {
        print_r($content);
    } else {
        echo $response->getContent();
    }

} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}
