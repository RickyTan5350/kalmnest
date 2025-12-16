<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;

class StoreFeedbackRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     * Only Teachers and Admins can create feedback.
     */
    public function authorize(): bool
    {
        $user = Auth::user();
        if (!$user) {
            return false;
        }

        $user->load('role');
        $userRole = $user->role->role_name ?? 'Student';

        return in_array($userRole, ['Teacher', 'Admin']);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'topic' => ['required', 'string', 'max:255'],
            'comment' => ['required', 'string', 'max:5000'],
            'student_id' => ['required', 'string', 'exists:users,user_id'],
        ];
    }

    /**
     * Get custom error messages for validator errors.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'topic.required' => 'The feedback topic is required.',
            'topic.max' => 'The topic cannot exceed 255 characters.',
            'comment.required' => 'The feedback comment is required.',
            'comment.max' => 'The comment cannot exceed 5000 characters.',
            'student_id.required' => 'A student must be selected.',
            'student_id.exists' => 'The selected student does not exist.',
        ];
    }

    /**
     * Get custom attributes for validator errors.
     *
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'student_id' => 'student',
            'comment' => 'feedback',
        ];
    }
}
