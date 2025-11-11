<?php

namespace App\Http\Controllers;

use App\Http\Requests\CreateAchievementRequest;
use App\Models\Achievement;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class AchievementController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //
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
        // 1. Validation is handled by CreateAchievementRequest.
        $validatedData = $request->validated();
        
        // --- TEMPORARY DEBUGGING OVERRIDE START ---
        
        // 🚨 REPLACE THIS PLACEHOLDER UUID with a known Admin or Teacher UUID.
        $debugUserId = '969aeab2-6b4c-4fc8-841d-5e727fb4e453'; 
        
        // This line temporarily sets the creator ID for debugging.
        $validatedData['created_by'] = $debugUserId; 
        
        // --- TEMPORARY DEBUGGING OVERRIDE END ---

        // To revert to the secure production code, comment out the debug block
        // and uncomment the line below:
        // $validatedData['created_by'] = Auth::id(); 

        try {
            // Create and save the new achievement record.
            // The database trigger will run here, checking the user's role.
            $achievement = Achievement::create($validatedData);

            // 2. Return JSON response with status 201 (Created)
            return response()->json([
                'message' => 'Achievement created successfully (via debug ID).',
                'achievement' => $achievement,
            ], 201);
            
        } catch (Exception $e) {
            
            // 3. Catch the specific error thrown by your database trigger (SQLSTATE '45000').
            if (Str::contains($e->getMessage(), 'Achievement can only be created by an Admin or a Teacher')) {
                return response()->json([
                    'message' => 'Access Denied: The provided user ID (debug or authenticated) is not an Admin or Teacher.',
                ], 403); // 403 Forbidden
            }

            // 4. Generic server error response (e.g., database connection issues)
            return response()->json([
                'message' => 'Failed to create achievement due to a server error.',
                'error' => $e->getMessage()
            ], 500); // 500 Internal Server Error
        }
    }
    // public function store(CreateAchievementRequest $request)
    // {
    //     $validatedData = $request->validated();
    //     // $validated = $request->validate([
    //     //     'achievement_name' => 'required|string|max:100',
    //     //     'title' => 'required|string|max:255',
    //     //     'description' => 'required|string',
    //     //     'associated_level' => 'nullable|uuid|exists:levels,id'
            
    //     // ]);

    //     $validatedData['created_by'] = Auth::id();
    //     $validatedData['created_by'] = '969aeab2-6b4c-4fc8-841d-5e727fb4e453';

    //     try{
    //         $achievement = Achievement::create($validatedData);

    //         return response()->json([
    //             'message' => 'Achievement created successfully.',
    //             'achievement' => $achievement,
    //         ], 201);
    //     }catch (Exception $e){
    //         if (str_contains($e->getMessage(), 'Achievement can only be created by an Admin or a Teacher')) {
    //             return response()->json([
    //                 'message' => 'Access Denied: You must be an Admin or Teacher to create achievements.',
    //             ], 403); // 403 Forbidden: User is unauthorized by role
    //         }

    //         // For any other general database or server error
    //         return response()->json([
    //             'message' => 'Failed to create achievement due to a server error.',
    //         ], 500); // 500 Internal Server Error
    //     }

    //     // $new_achievement = [
    //     //     'achievement_id' => (string) Str::uuid7(),
    //     //     'achievement_name' => $validated['achievement_name'],
    //     //     'title' => $validated['achievement_title'],
    //     //     'description' => $validated['achievement_description'],
    //     //     'level_id' => $validated['level_id'],
    //     //     'created_by' => auth()->id(),
    //     // ];

       
    // }

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
    public function update(Request $request, Achievement $achievement)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Achievement $achievement)
    {
        //
    }
}
