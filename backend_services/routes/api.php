<?php

use App\Http\Controllers\AchievementController;
use App\Http\Controllers\NotesController;
use App\Http\Controllers\FileController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UserController;

/*
|--------------------------------------------------------------------------
| Public Routes (No Authentication Required)
|--------------------------------------------------------------------------
*/

// Auth & Registration
Route::post('/login', [UserController::class, 'login']);
Route::post('/user', [UserController::class, 'store']); // Registration

// --- 1. SPECIFIC ROUTES (MUST BE AT THE TOP) ---
// These are public so your Flutter app can access them without a token.

Route::get('/notes', [NotesController::class, 'showNotesBrief']);
Route::get('/notes/search', [NotesController::class, 'search']); 
Route::post('/notes', [NotesController::class, 'store']);         // <--- This is the active Create Note route
Route::post('/notes/upload', [NotesController::class, 'uploadFile']); // <--- This is the active Upload route

Route::post('/achievements/new', [AchievementController::class, 'store']);
Route::get('/achievements', [AchievementController::class, 'showAchievementsBrief']);

Route::post('/files/upload-batch', [FileController::class, 'uploadBatch']);
Route::post('/files/upload-independent', [FileController::class, 'uploadIndependent']);

// Health & Debug
Route::get('/health', function () {
    return response()->json(['status' => 'ok', 'time' => now()]);
});
Route::get('/test', function () {
    return response()->json(['message' => 'Laravel connected successfully!']);
});


/*
|--------------------------------------------------------------------------
| Protected Routes (Requires Login / Sanctum Token)
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {

    // Current User Profile
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    Route::post('/logout', [UserController::class, 'logout']);

   // --- Achievements Module ---
    Route::prefix('achievements')->group(function () {
        // Student Operations (Progress)
        Route::get('/my-achievements', [AchievementController::class, 'myAchievements']);
        Route::post('/unlock', [AchievementController::class, 'unlock']);
       
        // Admin/Teacher Operations (Write)
        Route::post('/new', [AchievementController::class, 'store']);
        Route::put('/update/{id}', [AchievementController::class, 'update']);
        Route::post('/delete-batch', [AchievementController::class, 'destroyBatch']);
        
        // --- FIX BELOW ---
        // Change '/achievements' to '/' (This maps to /api/achievements)
        Route::get('/', [AchievementController::class, 'showAchievementsBrief']);

        // Change '/achievements/{id}' to '/{id}' (This maps to /api/achievements/{id})
        Route::get('/{id}', [AchievementController::class, 'getAchievement']);
    });

    // --- Notes Module ---
    // REMOVED: The 'notes' group was deleted from here because it was 
    // overriding the public routes above and causing the "Unauthenticated" error.

});

// Public Read-Only Views


Route::get('/users', [UserController::class, 'index']);
Route::get('/users/{user}', [UserController::class, 'show']);


// --- 2. WILDCARD ROUTES (MUST BE AT THE BOTTOM) ---
// These catch urls like /notes/1, /notes/50, etc.

Route::get('/notes/{id}', [NotesController::class, 'show']); 
Route::get('/notes/{id}/content', [NotesController::class, 'getNoteContent']);
Route::put('/notes/{id}', [NotesController::class, 'update']);
Route::delete('/notes/{id}', [NotesController::class, 'destroy']);