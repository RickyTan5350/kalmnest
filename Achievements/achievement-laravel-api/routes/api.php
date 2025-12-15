<?php
use App\Http\Controllers\Api\V1\AchievementController;
use Illuminate\Support\Facades\Route;

// Grouping API routes under 'v1' prefix
Route::prefix('v1')->group(function () {
    // Resource routing for Achievements:
    // GET /api/v1/achievements (index)
    // POST /api/v1/achievements (store)
    // GET /api/v1/achievements/{id} (show)
    // PUT/PATCH /api/v1/achievements/{id} (update)
    // DELETE /api/v1/achievements/{id} (destroy)
    Route::apiResource('achievements', AchievementController::class);
});