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
        $user->load('role');
        // Case-insensitive check for 'Admin' role
        return Str::lower($user->role?->role_name ?? '') === 'admin';
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array|string>
     */
    public function rules(): array
    {
        return [
            'class_name' => [
                'required',
                'string',
                'min:3',
                'max:100',
                function ($attribute, $value, $fail) {
                    // Case-insensitive uniqueness check
                    $exists = \App\Models\ClassModel::whereRaw('LOWER(class_name) = LOWER(?)', [trim($value)])
                        ->exists();
                    if ($exists) {
                        $fail('The classname is already exist. Please choose a different name.');
                    }
                },
            ],
            'teacher_id' => 'nullable|string|exists:users,user_id',
            'description' => [
                'required',
                'string',
                'max:500',
                function ($attribute, $value, $fail) {
                    if ($value === null || trim($value) === '') {
                        $fail('The description field is required.');
                        return;
                    }
                    // Count words (split by whitespace and filter empty strings)
                    $words = array_filter(preg_split('/\s+/', trim($value)));
                    $wordCount = count($words);
                    if ($wordCount < 10) {
                        $fail('The description must contain at least 10 words.');
                    }
                },
            ],
            'admin_id' => 'nullable|string|exists:users,user_id',
            'focus' => 'nullable|string|in:HTML,CSS,JavaScript,PHP',
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
            'class_name.required' => 'Class name is required.',
            'class_name.min' => 'Class name must be at least 3 characters.',
            'class_name.max' => 'Class name cannot exceed 100 characters.',
            'class_name.unique' => 'The classname is already exist. Please choose a different name.',
            'teacher_id.exists' => 'The selected teacher does not exist.',
            'description.required' => 'Description is required.',
            'description.max' => 'Description cannot exceed 500 characters.',
            'admin_id.exists' => 'The selected admin does not exist.',
            'focus.in' => 'Focus must be one of: HTML, CSS, JavaScript, PHP.',
            'student_ids.array' => 'The students must be provided as a list.',
            'student_ids.*.exists' => 'One or more selected students do not exist.',
        ];
    }
}