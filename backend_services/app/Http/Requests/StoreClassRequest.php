<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class StoreClassRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     * Only Admins can create classes.
     */
    public function authorize(): bool
    {
        $user = Auth::user();
        if (!$user) {
            return false;
        }
        // Case-insensitive check for 'Admin' role
        return Str::lower($user->role->role_name) === 'admin';
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array|string>
     */
    public function rules(): array
    {
        return [
            'class_name' => 'required|string|max:100',
            'teacher_id' => 'nullable|string|exists:users,user_id',
            'description' => 'nullable|string',
            'admin_id' => 'nullable|string|exists:users,user_id',
            'student_ids' => 'nullable|array',
            'student_ids.*' => 'string|exists:users,user_id',
        ];
    }

    /**
     * Get custom messages for validator errors.
     *
     * @return array
     */
    public function messages(): array
    {
        return [
            'class_name.required' => 'Please enter a class name.',
            'teacher_id.exists' => 'The selected teacher does not exist.',
            'admin_id.exists' => 'The selected admin does not exist.',
            'student_ids.array' => 'The students must be provided as a list.',
            'student_ids.*.exists' => 'One or more selected students do not exist.',
        ];
    }
}