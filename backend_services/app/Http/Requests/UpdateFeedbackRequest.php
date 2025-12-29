<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use App\Models\Feedback;

class UpdateFeedbackRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     * Only Teachers and Admins can update feedback.
     * Teachers can only update their own feedback.
     */
    public function authorize(): bool
    {
        $user = Auth::user();
        if (!$user) {
            return false;
        }

        $user->load('role');
        $userRole = $user->role->role_name ?? 'Student';

        // Students cannot update feedback
        if (!in_array($userRole, ['Teacher', 'Admin'])) {
            return false;
        }

        // Get the feedback being updated
        $feedbackId = $this->route('id');
        $feedback = Feedback::where('feedback_id', $feedbackId)->first();

        if (!$feedback) {
            return false;
        }

        // Admins can update any feedback
        if ($userRole === 'Admin') {
            return true;
        }

        // Teachers can only update their own feedback
        return $feedback->teacher_id === $user->user_id;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'topic_id' => 'sometimes|required|string|exists:topics,topic_id',
            'title' => 'sometimes|required|string|max:255',
            'comment' => 'sometimes|required|string|max:5000',
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
            'topic_id.required' => 'The feedback topic is required.',
            'topic_id.exists' => 'The selected topic does not exist.',
            'comment.required' => 'The feedback comment is required.',
            'comment.max' => 'The comment cannot exceed 5000 characters.',
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
            'comment' => 'feedback',
        ];
    }
}
