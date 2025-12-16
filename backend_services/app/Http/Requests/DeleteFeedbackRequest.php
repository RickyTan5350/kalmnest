<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use App\Models\Feedback;

class DeleteFeedbackRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     * Only Teachers and Admins can delete feedback.
     * Teachers can only delete their own feedback.
     */
    public function authorize(): bool
    {
        $user = Auth::user();
        if (!$user) {
            return false;
        }

        $user->load('role');
        $userRole = $user->role->role_name ?? 'Student';

        // Students cannot delete feedback
        if (!in_array($userRole, ['Teacher', 'Admin'])) {
            return false;
        }

        // Get the feedback being deleted
        $feedbackId = $this->route('id');
        $feedback = Feedback::where('feedback_id', $feedbackId)->first();

        if (!$feedback) {
            return false;
        }

        // Admins can delete any feedback
        if ($userRole === 'Admin') {
            return true;
        }

        // Teachers can only delete their own feedback
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
            // No validation rules needed for delete
        ];
    }
}
