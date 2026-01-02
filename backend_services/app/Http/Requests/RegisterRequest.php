<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Set to true to allow anyone (unauthenticated users) to register.
        return true; 
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        // Rules based on your User model and database table schema
        return [
            'name' => ['required', 'string', 'max:255', 'unique:users'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'phone_no' => ['required', 'string', 'max:255'],
            'address' => ['required', 'string'],
            // Assuming gender can be 'male', 'female', or any other string
            'gender' => ['required', 'string', 'max:255'], 
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            // Require a role_name on registration and ensure it exists in the roles table
            'role_name' => ['required', 'string', 'max:255', 'exists:roles,role_name'],
        ];
    }
}