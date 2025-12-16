<?php

try {
    $user = App\Models\User::where('name', 'like', 'Teacher Alice%')->latest()->first();
    if (!$user) {
        echo "User not found!\n";
        exit;
    }
    echo "Logging in as: " . $user->name . " (" . $user->user_id . ")\n";

    Illuminate\Support\Facades\Auth::login($user);

    $controller = app(App\Http\Controllers\AchievementController::class);
    $response = $controller->showAchievementsBrief();

    echo "Response Content:\n";
    echo $response->getContent();
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}
