<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Http\Requests\RegisterRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    /**
     * Handle an incoming registration request.
     */
    public function register(RegisterRequest $request)
    {
        $validatedData = $request->validated();
        
        // 1. Find the role_id based on the submitted role_name
        $role = DB::table('roles')
                    ->where('role_name', $validatedData['role_name'])
                    ->first();

        // 2. Create the new user
        // The password will be automatically hashed by the User model's casts
        // The user_id UUID will be generated manually as HasUuids is used but auto-incrementing is false
        $user = User::create([
            'user_id' => (string) Str::uuid7(),
            'role_id' => $role->role_id,
            'name' => $validatedData['name'],
            'email' => $validatedData['email'],
            'phone_no' => $validatedData['phone_no'],
            'address' => $validatedData['address'],
            'gender' => $validatedData['gender'],
            'password' => $validatedData['password'],
            'account_status' => 'active', // Default status for new accounts
        ]);

        // 3. Generate a Sanctum token for immediate API authentication
        $token = $user->createToken('auth_token')->plainTextToken;

        // 4. Return the response
        return response()->json([
            'message' => 'Account created successfully.',
            'user' => [
                'user_id' => $user->user_id,
                'name' => $user->name,
                'email' => $user->email,
                'role_name' => $validatedData['role_name'],
                'account_status' => $user->account_status,
            ],
            'token' => $token,
        ], 201); // 201 Created Status
    }
}