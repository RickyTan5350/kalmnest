<?php

namespace App\Http\Controllers;

use App\Models\Level;
use App\Models\ClassModel;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Models\level_type;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use App\Models\LevelUser;
use Exception;

class LevelController extends Controller
{
    /**
     * Display all levels, optionally filtered by type and visibility
     */
    public function index(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json(['error' => 'Unauthenticated'], 401);
            }

            $topic = $request->query('topic');

            $user->load('role');
            $roleName = strtolower(trim($user->role?->role_name ?? ''));

            $query = Level::with('level_type');

            if ($topic && $topic != 'All') {
                $query->whereHas('level_type', function ($q) use ($topic) {
                    $q->where('level_type_name', $topic);
                });
            }

            // Filter based on role and visibility
            if ($roleName === 'student') {
                // Students: ONLY see public games in game page (private games only accessible through class)
                // A level is public if it either has no class assignments, or none of its assignments are private
                $query->whereDoesntHave('classes', function($subQ) {
                    $subQ->where('class_levels.is_private', true);
                });
            } elseif ($roleName === 'teacher') {
                // Teachers: See public games OR private games they created
                $query->where(function($q) use ($user) {
                    // Public games (not assigned as private in any class)
                    $q->whereDoesntHave('classes', function($subQ) {
                        $subQ->where('class_levels.is_private', true);
                    })
                    // OR private games created by this teacher (only show to creator)
                    ->orWhere(function($orQ) use ($user) {
                        $orQ->where('created_by', $user->user_id)
                            ->whereHas('classes', function($subQ) {
                                $subQ->where('class_levels.is_private', true);
                            });
                    });
                });
            }
            // Admin: See all games (no filter)

            $levels = $query->get()->map(function ($level) use ($user) {
                // Determine if this level is private (has at least one private assignment)
                // Check if any class assignment has is_private = true
                $isPrivate = DB::table('class_levels')
                    ->where('level_id', $level->level_id)
                    ->where('is_private', true)
                    ->exists();
                
                $isCreatedByMe = $level->created_by === $user->user_id;

                return [
                    'level_id' => $level->level_id,
                    'level_name' => $level->level_name,
                    'level_type' => $level->level_type ? [
                        'level_type_id' => $level->level_type->level_type_id,
                        'level_type_name' => $level->level_type->level_type_name,
                    ] : null,
                    'is_private' => $isPrivate,
                    'is_created_by_me' => $isCreatedByMe,
                    'status' => $isPrivate ? 'private' : 'public',
                ];
            });

            return response()->json($levels);
        } catch (Exception $e) {
            Log::error('Error fetching levels: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json([
                'error' => 'Failed to fetch levels',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function singleLevel(Request $request, $levelId)
    {
        $level = Level::with('level_type')->find($levelId);

        if (!$level) {
            return response()->json(['error' => 'Level not found'], 404);
        }

        // Logic for Students: Ensure LevelUser entry exists
        $user = Auth::user();
        if ($user) {
            $user->load('role');
            $roleName = strtolower(trim($user->role?->role_name ?? ''));

            if ($roleName === 'student') {
                $existingEntry = LevelUser::where('level_id', $levelId)
                    ->where('user_id', $user->user_id)
                    ->exists();

                if (!$existingEntry) {
                    LevelUser::create([
                        'level_user_id' => (string) Str::uuid7(),
                        'level_id' => $levelId,
                        'user_id' => $user->user_id,
                        'saved_data' => null,
                    ]);
                    Log::info("LEVEL_INIT: Auto-created level_user entry for User {$user->user_id} on Level {$levelId}");
                } else {
                    Log::info("LEVEL_INIT: Entry already exists for User {$user->user_id} on Level {$levelId}");
                }
            }
        }

        // Removed file writing - data will be returned in JSON response for Unity to save locally
        // Level data and win condition are already included in the response below

        $result = [
            'level_id' => $level->level_id,
            'level_name' => $level->level_name,
            'level_type' => $level->level_type ? [
                'level_type_id' => $level->level_type->level_type_id,
                'level_type_name' => $level->level_type->level_type_name,
            ] : null,
            'level_data' => $level->level_data,
            'win_condition' => $level->win_condition,
        ];

        return response()->json($result);
    }


    /**
     * Store a new level
     */
    public function store(Request $request)
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json(['error' => 'Unauthenticated'], 401);
        }

        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        // Only teachers and admins can create games
        if ($roleName !== 'teacher' && $roleName !== 'admin') {
            return response()->json(['error' => 'Unauthorized. Only teachers and admins can create games.'], 403);
        }

        $request->validate([
            'level_name' => 'required|string|filled',
            'level_type_name' => 'required|string',
        ]);

        $levelType = level_type::where('level_type_name', $request->level_type_name)->first();
        if (!$levelType) {
            return response()->json(['error' => 'Level type not found'], 404);
        }

        // $levelDataPath = public_path("unity_build/StreamingAssets/$levelType/levelData.json");
        // $winDataPath = public_path("unity_build/StreamingAssets/$levelType/winData.json");

        // if (!file_exists($levelDataPath) || !file_exists($winDataPath)) {
        //     return response()->json(['error' => 'Required JSON file not found'], 404);
        // }

        // $levelDataContent = file_get_contents($levelDataPath);
        // $winDataContent = file_get_contents($winDataPath);

        // $dataToBePassed = [
        //     'level_name' => $request->level_name,
        //     'level_type_id' => $levelType->level_type_id,
        //     'level_data' => $levelDataContent,
        //     'win_condition' => $winDataContent,
        // ];

        $levelTypes = ["html", "css", "js", "php"];
        $finalLevelDataArr = [];
        $finalWinDataArr = [];

        // Priority 1: Use data passed from Flutter (from 'temp' saving)
        if ($request->has('level_data') && $request->has('win_condition')) {
            $dataToBePassed = [
                'level_name' => $request->level_name,
                'level_type_id' => $levelType->level_type_id,
                'level_data' => $request->level_data,
                'win_condition' => $request->win_condition,
                'created_by' => $user->user_id,
            ];
        } else {
            // Priority 2: Fall back to existing public folder logic (if any)
            foreach ($levelTypes as $level_type) {
                $levelDataPath = public_path("unity_build/StreamingAssets/$level_type/levelData.json");
                $winDataPath = public_path("unity_build/StreamingAssets/$level_type/winData.json");

                $finalLevelDataArr[$level_type] = file_exists($levelDataPath) ? file_get_contents($levelDataPath) : null;
                $finalWinDataArr[$level_type] = file_exists($winDataPath) ? file_get_contents($winDataPath) : null;
            }

            $dataToBePassed = [
                'level_name' => $request->level_name,
                'level_type_id' => $levelType->level_type_id,
                'level_data' => json_encode($finalLevelDataArr, JSON_PRETTY_PRINT),
                'win_condition' => json_encode($finalWinDataArr, JSON_PRETTY_PRINT),
                'created_by' => $user->user_id,
            ];
        }


        try {
            $level = Level::create($dataToBePassed);
            $this->clearLevelFiles();

            return response()->json([
                'message' => 'Level created successfully',
                'level' => $level,
            ], 201);

        } catch (Exception $e) {
            //\Log::error('LEVEL_CREATE_FAILED: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to create level due to server error.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update a level
     */
    public function update(Request $request, $levelId)
    {
        $request->validate([
            'level_name' => 'required|string|filled',
            'level_type_name' => 'required|string|exists:level_types,level_type_name',
        ]);

        $level = Level::find($levelId);
        if (!$level) {
            return response()->json(['error' => 'Level not found'], 404);
        }

        $levelType = level_type::where('level_type_name', $request->level_type_name)->first();
        if (!$levelType) {
            return response()->json(['error' => 'Level type not found'], 404);
        }

        $levelTypes = ["html", "css", "js", "php"];
        $finalLevelData = [];
        $finalWinData = [];

        foreach ($levelTypes as $level_type) {
            $levelDataPath = public_path("unity_build/StreamingAssets/$level_type/levelData.json");
            $winDataPath = public_path("unity_build/StreamingAssets/$level_type/winData.json");

            $finalLevelData[$level_type] = file_exists($levelDataPath) ? file_get_contents($levelDataPath) : null;
            $finalWinData[$level_type] = file_exists($winDataPath) ? file_get_contents($winDataPath) : null;
        }

        $dataToBePassed = [
            'level_name' => $request->level_name,
            'level_type_id' => $levelType->level_type_id,
            'level_data' => json_encode($finalLevelData, JSON_PRETTY_PRINT),
            'win_condition' => json_encode($finalWinData, JSON_PRETTY_PRINT),
        ];

        $level->update($dataToBePassed);
        $level->refresh(); // ensures we return the updated model
        $this->clearLevelFiles();
        return response()->json(['message' => 'Level updated', 'level' => $level]);
    }


    /**
     * Delete a level
     */
    public function destroy($levelId)
    {
        $level = Level::find($levelId);
        if (!$level)
            return response()->json(['error' => 'Level not found'], 404);
        $levelType = $level->level_type->level_type_name;
        $level->delete();
        $this->clearLevelFiles();
        return response()->json(['message' => 'Level deleted']);
    }
    public function clearLevelFiles()
    {
        $levelTypes = ["html", "css", "js", "php"];
        foreach ($levelTypes as $levelType) {
            $levelDataPath = public_path("unity_build/StreamingAssets/$levelType/levelData.json");
            $winDataPath = public_path("unity_build/StreamingAssets/$levelType/winData.json");
            $indexFilePath = public_path("unity_build/StreamingAssets/$levelType/index.$levelType");
            // File::ensureDirectoryExists($levelDataPath);
            // File::ensureDirectoryExists($winDataPath);
            // File::ensureDirectoryExists($indexFilePath);
            File::put($levelDataPath, '');
            File::put($winDataPath, '');
            File::put($indexFilePath, '');
        }
    }

    /**
     * Save index file data - returns data to client for local storage
     * Data is sent from Unity and returned so Unity can save it locally
     */
    public function saveToIndexFile(Request $request, $type)
    {
        // Instead of saving to server, return the data so Unity can save it locally
        $indexData = $request->getContent();
        
        return response()->json([
            'status' => 'success',
            'message' => 'Index data received - save to local device',
            'type' => $type,
            'data' => $indexData,
        ], 200);
    }

    /**
     * Save data - returns data to client for local storage
     * Data is sent from Unity and returned so Unity can save it locally
     */
    public function saveData(Request $request, $dataType, $type)
    {
        // Instead of saving to server, return the data so Unity can save it locally
        $data = $request->getContent();
        
        return response()->json([
            'status' => 'success',
            'message' => 'Data received - save to local device',
            'dataType' => $dataType,
            'type' => $type,
            'data' => $data,
        ], 200);
    }

    /**
     * Get data - retrieves from database instead of public folder
     * For students: 
     *   - levelData: returns saved_data from level_user table (student's progress)
     *   - winData: returns win_condition from levels table
     * For level creation/editing: returns data from levels table if level_id provided
     */
    public function getData(Request $request, $dataType, $type) {
        try {
            $user = Auth::user();
            $levelId = $request->query('level_id');
            $levelType = strtolower($type);
            
            if (!$levelId) {
                return response()->json(null, 200)
                    ->header('Content-Type', 'application/json');
            }
            
            // Get the level
            $level = Level::find($levelId);
            if (!$level) {
                return response()->json(['error' => 'Level not found'], 404);
            }
            
            $levelDataObj = json_decode($level->level_data, true);
            $winDataObj = json_decode($level->win_condition, true);
            
            // Handle winData - always get from level (win condition doesn't change per user)
            if ($dataType === 'win' && isset($winDataObj[$levelType])) {
                $winData = $winDataObj[$levelType];
                return response($winData, 200)
                    ->header('Content-Type', 'application/json');
            }
            
            // Handle levelData - for students, try to get from level_user.saved_data first
            if ($dataType === 'level') {
                if ($user) {
                    $user->load('role');
                    $roleName = strtolower(trim($user->role?->role_name ?? ''));
                    
                    // For students, check if they have saved progress
                    if ($roleName === 'student') {
                        $levelUser = LevelUser::where('level_id', $levelId)
                                              ->where('user_id', $user->user_id)
                                              ->first();
                        
                        if ($levelUser && $levelUser->saved_data) {
                            $savedData = json_decode($levelUser->saved_data, true);
                            
                            // saved_data structure: {"html": "...", "css": "...", ...}
                            if (isset($savedData[$levelType]) && $savedData[$levelType] !== null) {
                                return response($savedData[$levelType], 200)
                                    ->header('Content-Type', 'application/json');
                            }
                        }
                    }
                }
                
                // Fallback: return level data from level table (initial/empty state)
                if (isset($levelDataObj[$levelType])) {
                    return response($levelDataObj[$levelType], 200)
                        ->header('Content-Type', 'application/json');
                }
            }
            
            // Return null if not found
            return response()->json(null, 200)
                ->header('Content-Type', 'application/json');
        } catch (\Exception $e) {
            Log::error('GET_DATA_ERROR: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to retrieve data'], 500);
        }
    }
}