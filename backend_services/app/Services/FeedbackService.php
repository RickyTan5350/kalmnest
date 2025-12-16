<?php

namespace App\Services;

use App\Models\Feedback;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class FeedbackService
{
    /**
     * Get feedbacks filtered by user role
     *
     * @param User $user
     * @param array $filters
     * @return \Illuminate\Database\Eloquent\Collection
     */
    public function getFeedbacksByRole(User $user, array $filters = [])
    {
        $user->load('role');
        $userRole = $user->role->role_name ?? 'Student';

        // Create base query
        $query = Feedback::with(['teacher', 'student']);

        // Role-based filtering
        if ($userRole === 'Admin') {
            // Admins see ALL feedback
            if (isset($filters['teacher_id'])) {
                $query->where('teacher_id', $filters['teacher_id']);
            }
        } elseif ($userRole === 'Teacher') {
            // Teachers see only their own feedback
            $query->where('teacher_id', $user->user_id);
        } else {
            // Students see only feedback where they are the recipient
            $query->where('student_id', $user->user_id);
        }

        return $query->orderBy('created_at', 'desc')->get();
    }

    /**
     * Get feedbacks for a specific student
     *
     * @param string $studentId
     * @return \Illuminate\Database\Eloquent\Collection
     */
    public function getStudentFeedback(string $studentId)
    {
        return Feedback::where('student_id', $studentId)
            ->with('teacher')
            ->orderBy('created_at', 'desc')
            ->get();
    }

    /**
     * Create a new feedback
     *
     * @param array $data
     * @param string $teacherId
     * @return Feedback
     */
    public function createFeedback(array $data, string $teacherId): Feedback
    {
        $feedback = Feedback::create([
            'teacher_id' => $teacherId,
            'student_id' => $data['student_id'],
            'topic' => $data['topic'],
            'comment' => $data['comment'],
        ]);

        // Load relations
        $feedback->load('student', 'teacher');

        return $feedback;
    }

    /**
     * Update an existing feedback
     *
     * @param string $feedbackId
     * @param array $data
     * @return Feedback
     */
    public function updateFeedback(string $feedbackId, array $data): Feedback
    {
        $feedback = Feedback::where('feedback_id', $feedbackId)->firstOrFail();

        $feedback->update([
            'topic' => $data['topic'],
            'comment' => $data['comment'],
        ]);

        $feedback->load('student', 'teacher');

        return $feedback;
    }

    /**
     * Delete a feedback
     *
     * @param string $feedbackId
     * @return bool
     */
    public function deleteFeedback(string $feedbackId): bool
    {
        $feedback = Feedback::where('feedback_id', $feedbackId)->firstOrFail();
        return $feedback->delete();
    }

    /**
     * Format feedback data for API response
     *
     * @param Feedback $feedback
     * @param bool $includeStudentName
     * @return array
     */
    public function formatFeedback(Feedback $feedback, bool $includeStudentName = true): array
    {
        $data = [
            'feedback_id' => $feedback->feedback_id,
            'teacher_id' => $feedback->teacher_id,
            'teacher_name' => $feedback->teacher->name ?? 'Unknown',
            'topic' => $feedback->topic,
            'feedback' => $feedback->comment,
            'created_at' => $feedback->created_at->toIso8601String(),
        ];

        if ($includeStudentName) {
            $data['student_id'] = $feedback->student_id;
            $data['student_name'] = $feedback->student->name ?? 'Unknown';
        }

        return $data;
    }

    /**
     * Format a collection of feedbacks for API response
     *
     * @param \Illuminate\Database\Eloquent\Collection $feedbacks
     * @param bool $includeStudentName
     * @return array
     */
    public function formatFeedbackCollection($feedbacks, bool $includeStudentName = true): array
    {
        return $feedbacks->map(function ($feedback) use ($includeStudentName) {
            return $this->formatFeedback($feedback, $includeStudentName);
        })->toArray();
    }

    /**
     * Check if user can access student's feedback
     *
     * @param User $user
     * @param string $studentId
     * @return bool
     */
    public function canAccessStudentFeedback(User $user, string $studentId): bool
    {
        $user->load('role');
        $userRole = $user->role->role_name ?? 'Student';

        // Teachers and Admins can view any student's feedback
        if (in_array($userRole, ['Teacher', 'Admin'])) {
            return true;
        }

        // Students can only view their own feedback
        return $user->user_id === $studentId;
    }
}
