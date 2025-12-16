<?php
// Autoload
require __DIR__.'/vendor/autoload.php';

// Bootstrap App
$app = require_once __DIR__.'/bootstrap/app.php';

// Bootstrap Kernel
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Debug Logic
try {
    // Find the latest Alice created by our unique seeder
    $user = App\Models\User::where('name', 'like', 'Teacher Alice%')
        ->where('email', 'like', 'alice_%@test.com')
        ->latest()
        ->first();
        
    if (!$user) {
        echo "User not found!\n";
        exit;
    }
    echo "Logging in as: " . $user->name . " (" . $user->user_id . ")\n";

    Illuminate\Support\Facades\Auth::login($user);

    $controller = app(App\Http\Controllers\AchievementController::class);
    // Explicitly call the method
    $response = $controller->showAchievementsBrief();

    echo "Response Content:\n";
    echo $response->getContent();
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}
