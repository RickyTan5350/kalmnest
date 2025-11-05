<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class UserController extends Controller
{
    // Register user
    public function register(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email|unique:users',
            'name' => 'required|string|max:255',
            'phone_no' => 'required',
            'address' => 'required',
            'gender' => 'required',
            'password' => 'required|min:6',
            'role_id' => 'required|exists:roles,role_id'
        ]);

        $validated['password'] = Hash::make($validated['password']);

        $user = User::create($validated);
        return response()->json(['message' => 'User registered successfully', 'data' => $user], 201);
    }

    // View all users
    public function index()
    {
        return response()->json(User::with('role')->get());
    }

    // Simple login (for test)
    public function login(Request $request)
    {
        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages(['email' => ['Invalid credentials.']]);
        }

        return response()->json(['message' => 'Login successful', 'user' => $user]);
    }
}
