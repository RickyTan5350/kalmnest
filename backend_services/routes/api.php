<?php

use App\Http\Controllers\AchievementController;
use App\Http\Controllers\NotesController;
use App\Http\Controllers\FileController;
use App\Http\Controllers\LevelController;
use App\Http\Controllers\ClassController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UserController;
use App\Http\Requests\DeleteUserRequest;
/*
|--------------------------------------------------------------------------
| Public Routes (No Authentication Required)
|--------------------------------------------------------------------------
*/

// Auth & Registration
Route::post('/login', [UserController::class, 'login'])->name('login');
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
| Protected Routes (Requires Sanctum Token)
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {

    // Current User Profile
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
Route::post('/logout', [UserController::class, 'logout']);
// --- User Management (CRUD/View) ---
    // All roles (Admin/Teacher/Student) can view list/search/filter
Route::prefix('users')->group(function () {
        // List/Search/Filter (GET /api/users)
        Route::get('/', [UserController::class, 'index']); 
        // User lists for class management (MUST be before /{user} route to avoid route model binding conflict)
        Route::get('/teachers', [UserController::class, 'getTeachers']); // Get all teachers
        Route::get('/students', [UserController::class, 'getStudents']); // Get all students
        // View single profile (GET /api/users/{user})
        Route::get('/{user}', [UserController::class, 'show']); 
        // Update profile (PUT /api/users/{user})
        Route::put('/{user}', [UserController::class, 'update']); 
        // Delete account (DELETE /api/users/{user})
        Route::delete('/{user}', [UserController::class, 'destroy']); 
    });
    // --- Current Logged-in User ---
    Route::get('/user', fn(Request $request) => $request->user());
    Route::post('/logout', [UserController::class, 'logout']);

    // ✅ NEW ROUTE: Get role of logged-in user
    Route::get('/user/role', function (Request $request) {
        $user = $request->user()->load('role');
        return response()->json([
            'user_id' => $user->user_id,
            'name' => $user->name,
            'email' => $user->email,
            'role_name' => $user->role?->role_name ?? 'N/A',
        ]);
    });
 // --- Classes Module ---
    Route::prefix('classes')->group(function () {
        Route::get('/', [ClassController::class, 'index']); // List classes (role-based)
        Route::post('/', [ClassController::class, 'store']); // Create class (admin only)
        Route::get('/{id}', [ClassController::class, 'show']); // Get class details
        Route::put('/{id}', [ClassController::class, 'update']); // Update class (admin only)
        Route::delete('/{id}', [ClassController::class, 'destroy']); // Delete class (admin only)
    });
    
    // Class statistics
    Route::get('/classes-count', [ClassController::class, 'getCount']); // Get class count
    Route::get('/classes-stats', [ClassController::class, 'getStats']); // Get class stats

    /*
    |--------------------------------------------------------------------------
    | Achievements Module
    |--------------------------------------------------------------------------
    */
    Route::prefix('achievements')->group(function () {

        // Student Operations
        Route::get('/my-achievements', [AchievementController::class, 'myAchievements']);
        Route::post('/unlock', [AchievementController::class, 'unlock']);

        // Admin/Teacher Operations
        Route::post('/new', [AchievementController::class, 'store']);
        Route::put('/update/{id}', [AchievementController::class, 'update']);
        Route::post('/delete-batch', [AchievementController::class, 'destroyBatch']);

        // Public endpoint inside prefix
        Route::get('/', [AchievementController::class, 'showAchievementsBrief']);

        // Change '/achievements/{id}' to '/{id}' (This maps to /api/achievements/{id})
        Route::get('/{id}', [AchievementController::class, 'getAchievement']);
    });

    // --- Notes Module ---
    // REMOVED: The 'notes' group was deleted from here because it was 
    // overriding the public routes above and causing the "Unauthenticated" error.

    /*
    |--------------------------------------------------------------------------
    | Levels (Game)
    |--------------------------------------------------------------------------
    */
    Route::get('/levels', [LevelController::class, 'index']);
    Route::post('/create-level', [LevelController::class, 'store']);
    Route::get('/clear-files', [LevelController::class, 'clearLevelFiles']);
    Route::put('/levels/{levelId}', [LevelController::class, 'update']);
    Route::delete('/levels/{levelId}', [LevelController::class, 'destroy']);
    Route::get('/level/{levelId}', [LevelController::class, 'singleLevel']);
});


/*
|--------------------------------------------------------------------------
| Public Read-Only Routes
|--------------------------------------------------------------------------
*/




// --- 2. WILDCARD ROUTES (MUST BE AT THE BOTTOM) ---
// These catch urls like /notes/1, /notes/50, etc.

Route::get('/notes/{id}', [NotesController::class, 'show']); 
Route::get('/notes/{id}/content', [NotesController::class, 'getNoteContent']);
Route::put('/notes/{id}', [NotesController::class, 'update']);
Route::delete('/notes/{id}', [NotesController::class, 'destroy']);
// Level data I/O
Route::post('/save-data/{dataType}/{type}', [LevelController::class, 'saveData']);
Route::get('/get-data/{dataType}/{type}', [LevelController::class, 'getData']);
Route::post('/save-index/{type}', [LevelController::class, 'saveToIndexFile']);
