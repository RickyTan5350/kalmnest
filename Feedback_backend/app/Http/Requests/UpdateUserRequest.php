<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateUserRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Typically, only admins, or the user themselves, should update profiles.
        // For simplicity, we'll return true here, assuming middleware handles the rest.
        return true; 
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