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
use App\Http\Requests\UpdateUserRequest;
use App\Http\Requests\DeleteUserRequest;
use Maatwebsite\Excel\Facades\Excel;
use App\Imports\UsersImport;

class UserController extends Controller
{
    /**
     * Display a listing of the resource.
     * Handles Search (by name) and Filtering (by role, status).
     */

    // ==========================================
    // AUTHENTICATION HELPERS
    // ==========================================
private function isAdmin()
    {
        if (!Auth::check()) return false;

        $userRoleName = DB::table('users')
                            ->join('roles', 'users.role_id', '=', 'roles.role_id')
                            ->where('users.user_id', Auth::id())
                            ->value('roles.role_name');

        return $userRoleName === 'Admin';
    }

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
public function update(UpdateUserRequest $request, User $user)
    {
        // 1. Get the validated data
        $validatedData = $request->validated();

        // 2. Handle Role Name to Role ID conversion
        if (isset($validatedData['role_name'])) {
            $roleName = $validatedData['role_name'];
            $role = DB::table('roles')
                        ->where('role_name', $roleName)
                        ->first(['role_id']);

            // If a role is found, replace 'role_name' with 'role_id'
            if ($role) {
                unset($validatedData['role_name']);
                $validatedData['role_id'] = $role->role_id;
            } else {
                // This case should be caught by the 'exists' rule in UpdateUserRequest,
                // but we keep a defensive check.
                return response()->json([
                    'message' => "The role '$roleName' is not valid.",
                ], 422);
            }
        }

        // 3. Update User
        // Note: The User model handles password hashing automatically via the 'casts' property
        try {
            $user->update($validatedData);

            // 4. Return the updated user data
            return response()->json([
                'message' => 'User profile updated successfully.',
                // Reload 'role' in case role_id was changed
                'user' => $user->load('role'),
            ], 200);

        } catch (\Exception $e) {
            Log::error('USER_UPDATE_FAILED: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to update user due to a server error.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
public function destroy(User $user, DeleteUserRequest $request)
    {
        // Authorization (Admin only & no self-deletion) is handled entirely
        // by the DeleteUserRequest Form Request validation that runs before this code.

        // Revoke all Sanctum tokens associated with this user for a clean delete.
        $user->tokens()->delete();

        // The model's delete method triggers the cascade actions defined in migrations
        if ($user->delete()) {
            return response()->json([
                'message' => 'User account and associated data successfully deleted.',
                'user_id' => $user->user_id
            ], 200);
        }

        return response()->json([
            'message' => 'Failed to delete user account.'
        ], 500);
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
        /** @var User $user */
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

    /**
     * Get all teachers for class management dropdowns
     */
    public function getTeachers(): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            Log::warning('getTeachers called without authentication');
            return response()->json([
                'message' => 'Unauthenticated.',
                'data' => []
            ], 401);
        }

        try {
            Log::info('Fetching teachers', [
                'user_id' => $user->user_id,
                'user_role' => $user->role?->role_name ?? 'null'
            ]);

            $teachers = User::whereHas('role', function ($query) {
                $query->whereRaw('LOWER(role_name) = ?', ['teacher']);
            })
            ->select('user_id', 'name', 'email', 'account_status')
            ->orderBy('name')
            ->get();

            Log::info('Teachers fetched successfully', [
                'count' => $teachers->count(),
                'teacher_ids' => $teachers->pluck('user_id')->toArray()
            ]);

            return response()->json([
                'message' => 'Teachers retrieved successfully',
                'data' => $teachers
            ], 200);
        } catch (\Exception $e) {
            Log::error('Error fetching teachers', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            // Return 200 with empty data instead of 500 to prevent frontend errors
            return response()->json([
                'message' => 'Failed to fetch teachers',
                'error' => $e->getMessage(),
                'data' => []
            ], 200);
        }
    }

    /**
     * Get all students for class management dropdowns
     * Returns ALL students regardless of enrollment status in any class
     * This allows admins to see all students when creating/editing classes
     */
    public function getStudents(): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            Log::warning('getStudents called without authentication');
            return response()->json([
                'message' => 'Unauthenticated.',
                'data' => []
            ], 401);
        }

        try {
            Log::info('Fetching students', [
                'user_id' => $user->user_id,
                'user_role' => $user->role?->role_name ?? 'null'
            ]);

            // Get ALL students (both enrolled and not enrolled in any class)
            $students = User::whereHas('role', function ($query) {
                $query->whereRaw('LOWER(role_name) = ?', ['student']);
            })
            ->select('user_id', 'name', 'email', 'account_status')
            ->orderBy('name')
            ->get();

            Log::info('Students fetched successfully', [
                'count' => $students->count(),
                'student_ids' => $students->pluck('user_id')->toArray()
            ]);

            return response()->json([
                'message' => 'Students retrieved successfully',
                'data' => $students
            ], 200);
        } catch (\Exception $e) {
            Log::error('Error fetching students', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            // Return 200 with empty data instead of 500 to prevent frontend errors
            return response()->json([
                'message' => 'Failed to fetch students',
                'error' => $e->getMessage(),
                'data' => []
            ], 200);
        }
    }

    public function import(Request $request)
    {
        try {
            $request->validate([
                'file' => 'required|file|mimes:xlsx,xls,csv',
            ]);
        } catch (ValidationException $e) {
            return response()->json(['message' => 'Validation failed', 'errors' => $e->errors()], 422);
        }
        
        // Ensure the file exists
        if (!$request->hasFile('file')) {
            return response()->json(['message' => 'No file uploaded'], 400);
        }

        // Perform the import
        try {
            Excel::import(new UsersImport, $request->file('file'));
            
            return response()->json([
                'message' => 'User list imported successfully.'
            ], 200);

        } catch (\Exception $e) {
            // Log the detailed error
            \Illuminate\Support\Facades\Log::error("User Import Failed: " . $e->getMessage());
            
            // Return a generic error to the client
            return response()->json([
                'message' => 'File import failed. Please check the file format and structure.',
                'error_detail' => $e->getMessage() 
            ], 500);
        }
    }
}
