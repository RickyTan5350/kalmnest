<?php

namespace App\Http\Controllers;

use App\Http\Requests\CreateAchievementRequest;
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
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        
    }

    public function showAchievementsBrief(){
        $achievementBrief = DB::table('achievements')
                                ->select('achievement_id', 'title', 'icon', 'description')
                                ->get();

        return response()->json($achievementBrief);
    }

    public function getAchievement($id) {
    $achievement = DB::table('achievements')
                    // Perform a left join with the 'users' table on created_by = user_id
                    ->leftJoin('users', 'achievements.created_by', '=', 'users.user_id')
                    // Select all columns from 'achievements' (*)
                    // AND select the 'name' from the 'users' table, aliased as 'creator_name'
                    ->select('achievements.*', 'users.name as creator_name')
                    ->where('achievements.achievement_id', $id)
                    ->first(); // Returns the object directly, or null
    // Check if it exists before returning
    if (!$achievement) {
        return response()->json(['message' => 'Not found'], 404);
    }

    return response()->json($achievement);
}
    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(CreateAchievementRequest $request)
    {
        // 1. Authorization Check (API Layer)
        if (!Auth::check()) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $userId = Auth::id();

        // Retrieve the role name for the authenticated user
        $userRoleName = DB::table('users')
                            ->join('roles', 'users.role_id', '=', 'roles.role_id')
                            ->where('users.user_id', $userId)
                            ->value('roles.role_name');

        // Check if the user is an Admin or Teacher
        if ($userRoleName !== 'Admin' && $userRoleName !== 'Teacher') {
            Log::warning("ACHIEVEMENT_CREATE_AUTH_FAIL: User $userId attempted to create achievement with role: $userRoleName");
            return response()->json([
                'message' => 'Access Denied: Only Admins or Teachers can create achievements.',
            ], 403); // 403 Forbidden
        }
        
        // 2. Process validated data and set creator
        $validatedData = $request->validated();
        
        // Use the authenticated user's ID for created_by
        $validatedData['created_by'] = $userId; 

        try {
            // 3. Create the achievement (DB trigger provides final defense)
            $achievement = Achievement::create($validatedData);

            // 4. Return success response
            return response()->json([
                'message' => 'Achievement created successfully.',
                'achievement' => $achievement,
            ], 201);
            
        } catch (Exception $e) {
            
            // 5. Catch the specific error from your SQL trigger (if the DB check fails)
            if (Str::contains($e->getMessage(), 'Achievement can only be created by an Admin or a Teacher')) {
                // Although the API check should prevent this, we handle the DB exception defensively.
                Log::warning('ACHIEVEMENT_AUTH_FAILED (DB Triggered): ' . $e->getMessage());
                return response()->json([
                    'message' => 'Access Denied: The database rejected the operation. You are not authorized.',
                ], 403); 
            }

            // 6. Generic server error response
            Log::error('ACHIEVEMENT_CREATE_FAILED: ' . $e->getMessage()); 
            return response()->json([
                'message' => 'Failed to create achievement due to a server error.',
                'error' => $e->getMessage()
            ], 500); 
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(Achievement $achievement)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Achievement $achievement)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
   public function update(Request $request, $id)
    {
        // 1. Find the Achievement
        $achievement = Achievement::where('achievement_id', $id)->first();

        if (!$achievement) {
            return response()->json(['message' => 'Achievement not found'], 404);
        }

        // 2. Validate the Request
        // We use 'sometimes' so the user can update just one field if they want.
        try {
            $validatedData = $request->validate([
                'achievement_name' => [
                    'sometimes', 
                    'string', 
                    'max:100',
                    // Ensure name is unique, IGNORING the current record's ID
                    Rule::unique('achievements', 'achievement_name')->ignore($id, 'achievement_id')
                ],
                'title' => 'sometimes|string|max:255',
                'description' => 'sometimes|string',
                // Adjust table name/column if your levels table is different
                'associated_level' => 'nullable|string|max:50', 
                'icon' => 'sometimes|string|max:255',
            ]);

            // 3. Update the Model
            // The fill() method updates only the fields present in $validatedData
            $achievement->fill($validatedData);
            
            // If you want to track who updated it, uncomment below:
            // $achievement->updated_by = Auth::id(); 

            $achievement->save();

            // 4. Return JSON Response
            return response()->json([
                'message' => 'Achievement updated successfully.',
                'achievement' => $achievement,
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            // Specific handling for validation errors (422)
            return response()->json([
                'message' => 'Validation failed.',
                'errors' => $e->errors(),
            ], 422);
        } catch (Exception $e) {
            // General server error
            \Log::error('ACHIEVEMENT_UPDATE_FAILED: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to update achievement due to a server error.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // POST /api/achievements/unlock
    public function unlock(Request $request)
    {
        $request->validate(['achievement_id' => 'required|exists:achievements,achievement_id']);
        
        $user = $request->user(); // Get current logged in user
        
        // syncWithoutDetaching ensures we don't crash if they try to unlock it twice
        // It simply ignores duplicates
        $user->achievements()->syncWithoutDetaching([$request->achievement_id]);

        return response()->json(['message' => 'Achievement Unlocked!']);
    }

    // GET /api/my-achievements
    public function myAchievements(Request $request)
    {
        // Fetch user's achievements and order by most recently unlocked
        $achievements = $request->user()
                                ->achievements()
                                ->orderBy('achievement_user.created_at', 'desc')
                                ->get();

        return response()->json($achievements);
    }
    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Achievement $achievement)
    {
        //
    }

     public function destroyBatch(Request $request)
    {
        // 1. Validate that 'ids' is an array and each item in it is a string (or uuid)
        $validatedData = $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'string', // Use 'uuid' if your IDs are UUIDs
        ]);

        $idsToDelete = $validatedData['ids'];

        try {
            // 2. Delete all achievements where 'achievement_id' is in the array
            // NOTE: This assumes an Admin can delete any achievement.
            // For role-based security, you'd check the user's role first.
            $deleteCount = Achievement::whereIn('achievement_id', $idsToDelete)->delete();

            if ($deleteCount == 0) {
                return response()->json([
                    'message' => 'No matching achievements found to delete.',
                ], 404); // 404 Not Found
            }

            return response()->json([
                'message' => "Successfully deleted $deleteCount achievements.",
            ], 200); // 200 OK

        } catch (Exception $e) {
            \Log::error('ACHIEVEMENT_DELETE_FAILED: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to delete achievements due to a server error.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
