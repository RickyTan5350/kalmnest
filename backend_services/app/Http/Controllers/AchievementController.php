<?php

namespace App\Http\Controllers;

use App\Http\Requests\CreateAchievementRequest;
use App\Http\Requests\DeleteBatchAchievementRequest;
use App\Http\Requests\UnlockAchievementRequest;
use App\Http\Requests\UpdateAchievementRequest;
use App\Models\Achievement;
use Exception;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AchievementController extends Controller
{
    // ==========================================
    // AUTHENTICATION HELPERS
    // ==========================================

    private function isAdminOrTeacher()
    {
        if (!Auth::check()) return false;

        $userRoleName = DB::table('users')
                            ->join('roles', 'users.role_id', '=', 'roles.role_id')
                            ->where('users.user_id', Auth::id())
                            ->value('roles.role_name');

        return $userRoleName === 'Admin' || $userRoleName === 'Teacher';
    }

    private function isStudent()
    {
        if (!Auth::check()) return false;

        $userRoleName = DB::table('users')
                            ->join('roles', 'users.role_id', '=', 'roles.role_id')
                            ->where('users.user_id', Auth::id())
                            ->value('roles.role_name');

        return $userRoleName === 'Student';
    }

    // ==========================================
    // VIEW METHODS (Admin & Teacher Only)
    // ==========================================

    public function showAchievementsBrief()
    {
        // View functions accessible by Admin and Teacher
        if (!$this->isAdminOrTeacher()) {
            return response()->json(['message' => 'Access Denied: Only staff can view the full achievement list.'], 403);
        }

        $totalStudents = DB::table('users')
            ->join('roles', 'users.role_id', '=', 'roles.role_id')
            ->where('roles.role_name', 'Student')
            ->count();

        $achievementBrief = DB::table('achievements')
            ->selectRaw('
                achievements.achievement_id, 
                achievements.achievement_name, 
                achievements.title, 
                achievements.icon, 
                achievements.description,
                (SELECT COUNT(*) FROM achievement_user WHERE achievement_user.achievement_id = achievements.achievement_id) as unlocked_count
            ')
            ->get();

        // Add total_students to every item
        foreach ($achievementBrief as $achievement) {
            $achievement->total_students = $totalStudents;
        }

        return response()->json($achievementBrief);
    }

    public function getAchievement($id) 
    {
        if (!$this->isAdminOrTeacher() && !$this->isStudent()) {
            return response()->json(['message' => 'Access Denied.'], 403);
        }

        // 2. Start the query builder
        $query = DB::table('achievements')
                    ->where('achievements.achievement_id', $id);

        // 3. Conditional Selection based on Role
        if ($this->isStudent()) {
            // STUDENTS: See only what is necessary for the UI
            // Note: We include 'created_at' because your Flutter app uses it as a fallback date
            $query->leftJoin('users', 'achievements.created_by', '=', 'users.user_id')
                ->leftJoin('levels', 'achievements.associated_level', '=', 'levels.level_id')
                ->select(
                    'achievements.achievement_id',
                    'achievements.title',
                    'achievements.description',
                    'achievements.icon',
                    'achievements.associated_level as level', // Aliasing if needed
                    'achievements.associated_level',
                    'achievements.created_at', 
                    'users.name as creator_name',
                    'levels.level_name'
                );
        } else {
            // ADMINS/TEACHERS: See everything (including updated_at, raw IDs, etc.)
            $query->leftJoin('users', 'achievements.created_by', '=', 'users.user_id')
                ->leftJoin('levels', 'achievements.associated_level', '=', 'levels.level_id')
                ->select(
                    'achievements.*', 
                    'users.name as creator_name',
                    'users.email as creator_email', // Example: Admins might need to contact the creator
                    'levels.level_name'
                );
        }

        $achievement = $query->first(); 

        if (!$achievement) {
            return response()->json(['message' => 'Not found'], 404);
        }

        if (!$this->isStudent()) {
             $unlockedCount = DB::table('achievement_user')
                ->where('achievement_id', $id)
                ->count();

            $totalStudents = DB::table('users')
                ->join('roles', 'users.role_id', '=', 'roles.role_id')
                ->where('roles.role_name', 'Student')
                ->count();

            $achievement->unlocked_count = $unlockedCount;
            $achievement->total_students = $totalStudents;
        }

        return response()->json($achievement);
    }

    // public function getLevelsForDropdown()
    // {
    //     // 1. Auth Check (Admin/Teacher only)
    //     if (!$this->isAdminOrTeacher()) {
    //         return response()->json(['message' => 'Access Denied.'], 403);
    //     }

    //     // 2. Fetch only ID and Name
    //     // We use DB::table assuming your table is named 'levels'
    //     $levels = DB::table('levels')
    //                 ->select('level_id', 'level_name') // Adjust 'level_name' if your column is different (e.g., 'title')
    //                 ->orderBy('level_name', 'asc')
    //                 ->get();

    //     return response()->json($levels);
    // }

    // ==========================================
    // MANAGEMENT METHODS (Admin & Teacher Only)
    // ==========================================

    public function store(CreateAchievementRequest $request)
    {
        // if (!$this->isAdminOrTeacher()) {
        //     Log::warning("ACHIEVEMENT_CREATE_AUTH_FAIL: User " . Auth::id());
        //     return response()->json(['message' => 'Access Denied.'], 403);
        // }
        
        $validatedData = $request->validated();
        $validatedData['created_by'] = Auth::id(); 

        try {
            $achievement = Achievement::create($validatedData);

            Log::info("ACHIEVEMENT_CREATED: ID {$achievement->achievement_id} ('{$achievement->achievement_name}') created by User " . Auth::id());

            return response()->json([
                'message' => 'Achievement created successfully.',
                'achievement' => $achievement,
            ], 201);
            
        } catch (Exception $e) {
            // Check for specific DB trigger message safely
            if (Str::contains($e->getMessage(), 'Achievement can only be created by an Admin or a Teacher')) {
                return response()->json(['message' => 'Access Denied by Database.'], 403); 
            }
            
            // SECURITY FIX: Log the error, but return generic message to user
            Log::error('ACHIEVEMENT_CREATE_FAILED: ' . $e->getMessage()); 
            
            return response()->json([
                'message' => 'Failed to create achievement due to a server error.',
            ], 500); 
        }
    }

    public function update(UpdateAchievementRequest $request, $id)
    {
        $achievement = Achievement::where('achievement_id', $id)->first();

        if (!$achievement) {
            return response()->json(['message' => 'Achievement not found'], 404);
        }

        try {
            $validatedData = $request->validate([
                'achievement_name' => [
                    'sometimes', 'string', 'max:100',
                    Rule::unique('achievements', 'achievement_name')->ignore($id, 'achievement_id')
                ],
                'title' => [
                    'sometimes', 'string', 'max:255',
                    Rule::unique('achievements', 'title')->ignore($id, 'achievement_id')
                ],
                'description' => 'sometimes|string',
                'associated_level' => 'nullable|string|max:50', 
                'icon' => 'sometimes|string|max:255',
            ]);

            $achievement->fill($validatedData);
            $achievement->save(); 

            Log::info("ACHIEVEMENT_UPDATED: ID {$id} updated by User " . Auth::id());

            return response()->json([
                'message' => 'Achievement updated successfully.',
                'achievement' => $achievement,
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['message' => 'Validation failed.', 'errors' => $e->errors()], 422);
        } catch (Exception $e) {
            // SECURITY FIX: Log details, return generic message
            Log::error('ACHIEVEMENT_UPDATE_FAILED: ' . $e->getMessage() . ' Request Data: ' . json_encode($request->all()));
            
            return response()->json([
                'message' => 'Failed to update achievement due to a server error.',
            ], 500);
        }
    }

    public function destroyBatch(DeleteBatchAchievementRequest $request)
    {
        if (!$this->isAdminOrTeacher()) {
            return response()->json(['message' => 'Access Denied.'], 403);
        }

        $validatedData = $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'string', 
        ]);

        $idsToDelete = $validatedData['ids'];

        try {
            $deleteCount = Achievement::whereIn('achievement_id', $idsToDelete)->delete();

            if ($deleteCount == 0) {
                return response()->json(['message' => 'No matching achievements found.'], 404);
            }

            Log::info("ACHIEVEMENTS_DELETED: " . count($idsToDelete) . " items deleted by User " . Auth::id());

            return response()->json(['message' => "Successfully deleted $deleteCount achievements."], 200);

        } catch (Exception $e) {
            // SECURITY FIX: Log details, return generic message
            Log::error('ACHIEVEMENT_DELETE_FAILED: ' . $e->getMessage() . ' IDs: ' . json_encode($idsToDelete));
            
            return response()->json([
                'message' => 'Failed to delete achievements due to a server error.',
            ], 500);
        }
    }

    // ==========================================
    // STUDENT METHODS (Student Only)
    // ==========================================

    public function unlock(UnlockAchievementRequest $request)
    {
        $user = $request->user(); 
        
        // FIX: We pass a second array with extra column values (the pivot 'id')
        $user->achievements()->syncWithoutDetaching([
            $request->achievement_id => ['id' => (string) Str::uuid7()]
        ]);

        Log::info("ACHIEVEMENT_UNLOCKED: Achievement {$request->achievement_id} unlocked by Student " . Auth::id());

        return response()->json(['message' => 'Achievement Unlocked!']);
    }

    public function myAchievements(Request $request)
    {
        if (!$this->isStudent()) {
            return response()->json(['message' => 'Access Denied: Only students have achievement progress.'], 403);
        }

        $achievements = $request->user()
                                ->achievements()
                                ->orderBy('achievement_user.created_at', 'desc')
                                ->get();

        return response()->json($achievements);
    }

    // Unused method stubs
    public function index() {}
    public function create() {}
    public function show(Achievement $achievement) {}
    public function edit(Achievement $achievement) {}
    public function destroy(Achievement $achievement) {}
}