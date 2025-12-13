<?php

namespace App\Http\Requests;

use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth; 
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class UpdateUserRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
public function authorize(): bool
    {
        // 1. Check if user is logged in
        if (!Auth::check()) {
            return false; 
        }

        // 2. Get the role name of the currently authenticated user
        $userRoleName = DB::table('users')
                            ->join('roles', 'users.role_id', '=', 'roles.role_id')
                            ->where('users.user_id', Auth::id())
                            ->value('roles.role_name');

        // The request is authorized only if the user is an Admin.
        return $userRoleName === 'Admin'; 
    }

    protected function failedAuthorization()
    {
        // Throws a 403 Forbidden exception with a custom message.
        throw new AuthorizationException('Only Admins can update user profiles.');
    }
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        // The 'user' is injected by route model binding via {user} in the route.
        // We use $this->route('user') to get the User model instance.
        $userId = $this->route('user')->user_id;

        return [
            // Basic User fields
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'email' => [
                'sometimes', // Only validate if present
                'required', 
                'email',
                'max:255',
                // Ensure email is unique, but ignore the current user's ID
                Rule::unique('users', 'email')->ignore($userId, 'user_id'),
            ],
            'phone_no' => ['sometimes', 'required', 'string', 'max:255'],
            'address' => ['sometimes', 'required', 'string'],
            'gender' => ['sometimes', 'required', 'string', 'in:Male,Female,Other'],
            'password' => ['nullable', 'string', 'min:8'], // Nullable allows updating without changing password
            'account_status' => ['sometimes', 'required', 'in:active,inactive'],

            // Role update (if changing user roles)
            'role_name' => ['nullable', 'string', 'exists:roles,role_name'],
        ];
    }
}