<?php

namespace App\Http\Controllers;

use App\Models\LevelUser;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\File;

class LevelUserController extends Controller
{
    /**
     * Save or update level data for the authenticated user in the level_user table
     * This method is called from Flutter/Unity when a student saves their progress
     * 
     * Creates a new level_user entry if it doesn't exist, or updates existing entry
     * Saves: saved_data, index_files, timer, level_id, user_id
     */
    public function saveLevelData(Request $request, $levelId)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json(['error' => 'Unauthenticated'], 401);
            }

            // Check if level exists
            $levelExists = DB::table('levels')->where('level_id', $levelId)->exists();
            if (!$levelExists) {
                return response()->json(['error' => 'Level not found'], 404);
            }

            $validatedData = $request->validate([
                'saved_data' => 'nullable|string',
                'timer' => 'nullable|integer|min:0', // Validate timer
                'index_files' => 'nullable|string', // Accept index_files as JSON string
            ]);

            $savedData = $validatedData['saved_data'] ?? null;
            $indexFiles = $validatedData['index_files'] ?? null;
            $timer = $validatedData['timer'] ?? 0; // Get timer
            $userId = $user->user_id;

            // Check if entry already exists
            $levelUser = LevelUser::where('level_id', $levelId)
                                  ->where('user_id', $userId)
                                  ->first();

            if ($levelUser) {
                // Update existing entry
                $levelUser->saved_data = $savedData;
                $levelUser->index_files = $indexFiles;
                $levelUser->timer = $timer; // Update timer
                $levelUser->save();

                Log::info("LEVEL_SAVE_UPDATED: Level {$levelId} data updated for User {$userId}");
                
                return response()->json([
                    'message' => 'Level data updated successfully',
                    'level_user_id' => $levelUser->level_user_id,
                ], 200);
            } else {
                // Create new entry
                // If savedData is null, default to level's base data
                if (empty($savedData)) {
                    $savedData = DB::table('levels')->where('level_id', $levelId)->value('level_data');
                }

                $levelUser = LevelUser::create([
                    'level_user_id' => (string) Str::uuid7(),
                    'level_id' => $levelId,
                    'user_id' => $userId,
                    'saved_data' => $savedData,
                    'index_files' => $indexFiles,
                    'timer' => $timer, // Save timer
                ]);

                Log::info("LEVEL_SAVE_CREATED: New entry created for Level {$levelId} and User {$userId} with default/provided data");
                
                return response()->json([
                    'message' => 'Level data saved successfully',
                    'level_user_id' => $levelUser->level_user_id,
                ], 201);
            }
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'error' => 'Validation failed',
                'messages' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('LEVEL_SAVE_ERROR: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json([
                'error' => 'Failed to save level data',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get level data for the authenticated user
     * If entry doesn't exist, creates one with default level_data
     */
    public function getLevelData(Request $request, $levelId)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json(['error' => 'Unauthenticated'], 401);
            }
            $userId = $user->user_id;

            // Check if level exists
            $levelExists = DB::table('levels')->where('level_id', $levelId)->exists();
            if (!$levelExists) {
                return response()->json(['error' => 'Level not found'], 404);
            }

            $levelUser = LevelUser::where('level_id', $levelId)
                                  ->where('user_id', $userId)
                                  ->first();

            if (!$levelUser) {
                // Create new entry with default level_data
                $defaultLevelData = DB::table('levels')->where('level_id', $levelId)->value('level_data');
                
                $levelUser = LevelUser::create([
                    'level_user_id' => (string) Str::uuid7(),
                    'level_id' => $levelId,
                    'user_id' => $userId,
                    'saved_data' => $defaultLevelData,
                    'index_files' => null,
                    'timer' => 0,
                ]);

                Log::info("LEVEL_USER_CREATED_ON_LOAD: New entry created for Level {$levelId} and User {$userId} with default level_data");
            }

            return response()->json([
                'level_user_id' => $levelUser->level_user_id,
                'level_id' => $levelUser->level_id,
                'saved_data' => $levelUser->saved_data,
                'index_files' => $levelUser->index_files,
                'created_at' => $levelUser->created_at,
                'updated_at' => $levelUser->updated_at,
                'timer' => $levelUser->timer, // Return timer
            ], 200);
        } catch (\Exception $e) {
            Log::error('LEVEL_GET_ERROR: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json([
                'error' => 'Failed to get level data',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Unlock achievement when level is completed
     * This method is called from Unity when a student completes a level
     */
    public function completeLevel(Request $request, $levelId, $userId)
    {
        try {
            // Validate level existence
            $levelExists = DB::table('levels')->where('level_id', $levelId)->exists();
            if (!$levelExists) {
                return response()->json(['error' => 'Level not found'], 404);
            }

            $user = User::where('user_id', $userId)->first();
            if (!$user) {
                return response()->json(['error' => 'User not found'], 404);
            }

            // Check if user has role 'Student'
            $userRoleName = DB::table('users')
                            ->join('roles', 'users.role_id', '=', 'roles.role_id')
                            ->where('users.user_id', $userId)
                            ->value('roles.role_name');

            if (strtolower(trim($userRoleName ?? '')) !== 'student') {
                return response()->json([
                    'error' => 'Only students can complete levels'
                ], 403);
            }

            // Find if there is an achievement associated with this level
            $achievement = DB::table('achievements')
                ->where('associated_level', $levelId)
                ->first();

            if ($achievement) {
                 // Directly unlock the achievement
                $user->achievements()->syncWithoutDetaching([
                    $achievement->achievement_id => ['id' => (string) Str::uuid7()]
                ]);

                Log::info("LEVEL_COMPLETED: Level {$levelId} completed by User {$userId}. Achievement {$achievement->achievement_id} unlocked.");
                
                return response()->json([
                    'message' => 'Level completed and achievement unlocked successfully',
                    'achievement_unlocked' => true,
                    'achievement_name' => $achievement->achievement_name
                ], 200);
            }

            Log::info("LEVEL_COMPLETED: Level {$levelId} completed by User {$userId}. No achievement associated.");

            return response()->json([
                'message' => 'Level completed successfully (no achievement associated)',
                'achievement_unlocked' => false
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
             return response()->json([
                'error' => 'Validation failed',
                'messages' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('LEVEL_COMPLETE_ERROR: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json([
                'error' => 'Failed to complete level',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Save level data from files (Unity buffer) to level_user table
     * This mimics LevelController::store but for user progress
     */
    public function storeProgressFromFiles(Request $request, $levelId, $userId)
    {
        try {
            // Check if level exists
            $levelExists = DB::table('levels')->where('level_id', $levelId)->exists();
            if (!$levelExists) {
                return response()->json(['error' => 'Level not found'], 404);
            }

            $levelTypes = ["html", "css", "js", "php"];
            $finalLevelData = [];

            // Read the files from the StreamingAssets buffer
            foreach ($levelTypes as $level_type) {
                $levelDataPath = public_path("unity_build/StreamingAssets/$level_type/levelData.json");
                // We only care about levelData (the progress/code)
                $finalLevelData[$level_type] = file_exists($levelDataPath) ? file_get_contents($levelDataPath) : null;
            }

            $savedData = json_encode($finalLevelData, JSON_PRETTY_PRINT);

            // Update or Create LevelUser entry
            $levelUser = LevelUser::where('level_id', $levelId)
                                  ->where('user_id', $userId)
                                  ->first();

            if ($levelUser) {
                $levelUser->saved_data = $savedData;
                $levelUser->save();
            } else {
                // Check if all levels in savedData are null
                $isAllNull = true;
                foreach ($finalLevelData as $type => $data) {
                    if ($data !== null) {
                        $isAllNull = false;
                        break;
                    }
                }

                // If no file data found, default to level's base data
                if ($isAllNull) {
                    $savedData = DB::table('levels')->where('level_id', $levelId)->value('level_data');
                    Log::info("LEVEL_FILE_SAVE: No buffer files found for Level {$levelId}. Defaulting to level_data.");
                }

                $levelUser = LevelUser::create([
                    'level_user_id' => (string) Str::uuid7(),
                    'level_id' => $levelId,
                    'user_id' => $userId,
                    'saved_data' => $savedData,
                ]);
            }

            return response()->json([
                'message' => 'Level progress saved from files successfully',
                'level_user_id' => $levelUser->level_user_id,
            ], 200);

        } catch (\Exception $e) {
            Log::error('LEVEL_FILE_SAVE_ERROR: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json([
                'error' => 'Failed to save level data from files',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Helper to clear the buffer files
     */
    private function clearLevelFiles()
    {
        $levelTypes = ["html", "css", "js", "php"];
        foreach ($levelTypes as $levelType) {
            $levelDataPath = public_path("unity_build/StreamingAssets/$levelType/levelData.json");
            $winDataPath = public_path("unity_build/StreamingAssets/$levelType/winData.json");
            $indexFilePath = public_path("unity_build/StreamingAssets/$levelType/index.$levelType");
            
            File::put($levelDataPath, '');
            File::put($winDataPath, '');
            File::put($indexFilePath, '');
        }
    }

    /**
     * Get all users who have played a specific level (for Teacher View)
     */
    public function getLevelUsers(Request $request, $levelId)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json(['error' => 'Unauthenticated'], 401);
            }

            // Verify user is teacher or admin
            $user->load('role');
            $roleName = strtolower(trim($user->role?->role_name ?? ''));
            if ($roleName !== 'teacher' && $roleName !== 'admin') {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $users = DB::table('level_user')
                ->join('users', 'level_user.user_id', '=', 'users.user_id')
                ->where('level_user.level_id', $levelId)
                ->select(
                    'users.user_id',
                    'users.name',
                    'users.email',
                    'level_user.created_at as last_played',
                    'level_user.timer as time_remaining',
                    'level_user.saved_data',
                    'level_user.index_files' // Include index_files for preview
                )
                ->orderBy('level_user.updated_at', 'desc')
                ->get();

            return response()->json($users, 200);

        } catch (\Exception $e) {
            Log::error('LEVEL_USERS_GET_ERROR: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch level users'], 500);
        }
    }
}