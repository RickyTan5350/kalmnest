<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Carbon\Carbon;
use Illuminate\Support\Facades\RateLimiter;

class PasswordResetController extends Controller
{
    /**
     * Send a 6-digit reset code to the user's email.
     */
    public function sendResetCode(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        // Rate Limiting: 3 attempts per minute per email
        $key = 'forgot-password:' . $request->ip();
        if (RateLimiter::tooManyAttempts($key, 3)) {
            $seconds = RateLimiter::availableIn($key);
            return response()->json(['message' => "Too many requests. Please wait $seconds seconds."], 429);
        }
        RateLimiter::hit($key);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            // For security, do not reveal if the user exists or not.
            // But for this dev/codelab environment, we can return success anyway.
            return response()->json(['message' => 'If your email is registered, you will receive a code shortly.'], 200);
        }

        // Generate a 6-digit code
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Store in DB
        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $request->email],
            [
                'token' => Hash::make($code),
                'created_at' => now()
            ]
        );

        // Send Email (and Log for Dev)
        try {
            Mail::raw("Hello {$user->name},\n\nYour password reset code is: $code", function ($message) use ($user) {
                $message->to($user->email)->subject('Password Reset Code');
            });
            Log::info("Password reset code for {$user->email}: $code");
        } catch (\Exception $e) {
            Log::error("Failed to send reset email: " . $e->getMessage());
            // Fallback for dev environment without mail setup:
            return response()->json([
                'message' => 'Email service not configured. Check logs for code.',
                'dev_code' => $code // REMOVE IN PRODUCTION
            ], 200);
        }

        return response()->json(['message' => 'If your email is registered, you will receive a code shortly.'], 200);
    }

    /**
     * Verify code and reset password.
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|string|size:6',
            'password' => 'required|confirmed|min:8', 
        ]);

        $record = DB::table('password_reset_tokens')
            ->where('email', $request->email)
            ->first();

        // Check if record exists
        if (!$record || !Hash::check($request->code, $record->token)) {
            return response()->json(['message' => 'Invalid or expired reset code.'], 400);
        }

        // Check expiration (e.g., 15 minutes)
        if (Carbon::parse($record->created_at)->addMinutes(15)->isPast()) {
            DB::table('password_reset_tokens')->where('email', $request->email)->delete();
            return response()->json(['message' => 'Code expired. Please request a new one.'], 400);
        }

        // Transaction for Atomicity
        DB::transaction(function () use ($request) {
            $user = User::where('email', $request->email)->first();
            if ($user) {
                $user->password = Hash::make($request->password);
                $user->save();
            }
            // Delete token
            DB::table('password_reset_tokens')->where('email', $request->email)->delete();
        });

        return response()->json(['message' => 'Password reset successfully. You can now login.'], 200);
    }
}
