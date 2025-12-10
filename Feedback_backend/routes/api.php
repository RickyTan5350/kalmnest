<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\FeedbackController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\NotesController;
use App\Http\Controllers\AchievementController;


// Auth & Registration
Route::post('/login', [UserController::class, 'login']);
Route::post('/user', [UserController::class, 'store']);
Route::delete('/users/{user}', [UserController::class, 'destroy']);

// Health & Debug
Route::get('/health', function () {
    return response()->json(['status' => 'ok', 'time' => now()]);
});
Route::get('/test', function () {
    return response()->json(['message' => 'Laravel connected successfully!']);
});


Route::middleware('auth:sanctum')->group(function () {

    // Current User Profile
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    Route::post('/logout', [UserController::class, 'logout']);
    Route::put('/users/{user}', [UserController::class, 'update']);
    // --- Achievements Module ---
    Route::prefix('achievements')->group(function () {
        // Student Operations (Progress)
        Route::get('/my-achievements', [AchievementController::class, 'myAchievements']);
        Route::post('/unlock', [AchievementController::class, 'unlock']);

        // Admin/Teacher Operations (Write)
        Route::post('/new', [AchievementController::class, 'store']);
        Route::put('/update/{id}', [AchievementController::class, 'update']);
        Route::post('/delete-batch', [AchievementController::class, 'destroyBatch']);



    });

    // --- Notes Module ---
    // Grouped here assuming you want these protected.
    // If they must be public, move them out of this middleware group.
    Route::prefix('notes')->group(function () {
        Route::post('/', [NotesController::class, 'store']);
        Route::post('/upload', [NotesController::class, 'uploadFile']);
    });

});

// Public Read-Only Views
Route::get('/achievements', [AchievementController::class, 'showAchievementsBrief']);
Route::get('/achievements/{id}', [AchievementController::class, 'getAchievement']);

Route::get('/notes', [NotesController::class, 'showNotesBrief']);
Route::get('/users', [UserController::class, 'index']);
Route::get('/users/{user}', [UserController::class, 'show']);

// Protected Feedback routes (require authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/feedback', [FeedbackController::class, 'index']);
    Route::post('/feedback', [FeedbackController::class, 'store']);
    Route::put('/feedback/{id}', [FeedbackController::class, 'update']);
    Route::delete('/feedback/{id}', [FeedbackController::class, 'destroy']);

    // Get feedback received by a specific student (requires auth)
    Route::get('/feedback/student/{studentId}', [FeedbackController::class, 'getStudentFeedback']);
});

// Backwards-compatible public routes (used during old development phase - remove in future)
// Route::get('/feedback/public', [FeedbackController::class, 'index']);
// Route::post('/feedback/public', [FeedbackController::class, 'store']);

Route::get('/students', [UserController::class, 'getStudents']);
Route::get('/students/{studentId}', [UserController::class, 'getStudent']);
Route::get('/students/{studentId}/stats', [UserController::class, 'getStudentWithStats']);
