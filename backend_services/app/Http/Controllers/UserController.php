<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Http\Requests\RegisterRequest;
use Illuminate\Http\Request; 
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class UserController extends Controller
{
    /**
     * Display a listing of the resource.
     * Handles Search (by name) and Filtering (by role, status).
     */
    public function index(Request $request)
    {
        $query = User::with('role'); // Eager load role relationship

        // 1. Search by Name (US010-02)
        if ($request->has('search') && $request->search != null) {
            $search = $request->input('search');
            $query->where('name', 'like', "%{$search}%");
        }

        // 2. Filter by Account Status (US010-01)
        if ($request->has('account_status') && $request->account_status != null) {
            $status = $request->input('account_status');
            $query->where('account_status', $status);
        }

        // 3. Filter by Role Name (US010-01)
        if ($request->has('role_name') && $request->role_name != null) {
            $roleName = $request->input('role_name');
            $query->whereHas('role', function ($q) use ($roleName) {
                $q->where('role_name', $roleName);
            });
        }

        $users = $query->get();

        return response()->json([
            'message' => 'Users retrieved successfully',
            'data' => $users
        ], 200);
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
    public function store(RegisterRequest $request)
    {
        Log::info('--- USER STORE METHOD REACHED ---');

        // 1. Get the validated data
        $validatedData = $request->validated();
        
        // 2. Find the role_id based on the submitted role_name
        $roleName = $validatedData['role_name'];
        $role = DB::table('roles')
                    ->where('role_name', $roleName)
                    ->first(['role_id']);

        // Check if the role was found
        if (!$role) {
            return response()->json([
                'message' => "The role '$roleName' is not valid.",
            ], 422); 
        }

        // 3. Replace 'role_name' with 'role_id'
        unset($validatedData['role_name']);
        $validatedData['role_id'] = $role->role_id;
        
        // Set default status
        $validatedData['account_status'] = 'active';

        // Manual UUID generation
        $validatedData['user_id'] = (string) Str::uuid7();

         try {
            // 4. Create User
            $user = User::create($validatedData);

            // Generate token
            $token = $user->createToken('auth_token')->plainTextToken;

            // 5. Return JSON response
            return response()->json([
                'message' => 'Account created successfully.',
                'user' => [
                    'user_id' => $user->user_id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role_id' => $user->role_id,
                    'account_status' => $user->account_status,
                ],
                'token' => $token,
            ], 201);
            
        } catch (\Exception $e) {
            Log::error('USER_CREATE_FAILED: ' . $e->getMessage()); 
            return response()->json([
                'message' => 'Failed to create user due to a server error.',
                'error' => $e->getMessage()
            ], 500); 
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(User $user)
    {
        return response()->json($user->load('role'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(User $user)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, User $user)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(User $user)
    {
        //
    }

    public function login(Request $request)
    {
        // 1. Validate the incoming request data
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
            'device_name' => 'required', // Required by Sanctum for naming the token
        ]);

        // 2. Attempt to authenticate the user
        if (! Auth::attempt($request->only('email', 'password'))) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        // 3. Get the authenticated user
        $user = Auth::user();
        $user->load('role');

        // 4. Revoke existing tokens for better security (optional but recommended)
        $user->tokens()->where('name', $request->device_name)->delete();

        // 5. Create a new Sanctum token (The 'plainTextToken' is sent to Flutter)
        $token = $user->createToken($request->device_name)->plainTextToken;

        // 6. Return the user data and the token
        return response()->json([
            'message' => 'Login successful.',
            'user' => $user, // Send user data (e.g., role, name) to the client
            'token' => $token,
        ], 200);
    }

    public function logout(Request $request): JsonResponse
    {
        // Revoke the token that was used to authenticate the current request
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully. Your session has been terminated.'
        ], 200);
    }

    
}