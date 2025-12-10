<?php

namespace App\Http\Controllers;

use App\Models\Feedback;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class FeedbackController extends Controller
{
    /**
     * Get all feedback (filtered by role)
     * - Teachers: see only feedback they created
     * - Admins: see all feedback
     * - Students: see only feedback where they are the recipient (student_id)
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'error' => 'Unauthenticated'
                ], 401);
            }

            $user->load('role');
            $userRole = $user->role->role_name ?? 'Student';

            // Create base query
            $query = Feedback::with(['teacher', 'student']);

            // Role-based filtering
            if ($userRole === 'Admin') {
                // Admins see ALL feedback
                if ($request->has('teacher_id')) {
                    $query->where('teacher_id', $request->query('teacher_id'));
                }
            } else if ($userRole === 'Teacher') {
                // Teachers see only their own feedback
                $query->where('teacher_id', $user->user_id);
            } else {
                // Students see only feedback where they are the recipient
                $query->where('student_id', $user->user_id);
            }

            // Execute query with formatting
            $feedbacks = $query
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($feedback) {
                    return [
                        'feedback_id'  => $feedback->feedback_id,
                        'student_id'   => $feedback->student_id,
                        'student_name' => $feedback->student->name ?? 'Unknown',
                        'teacher_id'   => $feedback->teacher_id,
                        'teacher_name' => $feedback->teacher->name ?? 'Unknown',
                        'topic'        => $feedback->topic,
                        'feedback'     => $feedback->comment,
                        'created_at'   => $feedback->created_at->toIso8601String(),
                    ];
                });

            return response()->json([
                'success' => true,
                'data' => $feedbacks,
            ]);
        } catch (\Exception $e) {
            Log::error('FEEDBACK_INDEX_ERROR: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Failed to fetch feedbacks',
                'message' => $e->getMessage(),
            ], 500);
        }
    }


    /**
     * Store a new feedback
     * - Only Teachers and Admins can create feedback
     * - The authenticated user becomes the teacher_id
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'error' => 'Unauthenticated'
                ], 401);
            }

            $user->load('role');
            $userRole = $user->role->role_name ?? 'Student';

            // Only Teachers and Admins can create feedback
            if ($userRole !== 'Teacher' && $userRole !== 'Admin') {
                return response()->json([
                    'success' => false,
                    'error' => 'Forbidden',
                    'message' => 'Only teachers and admins can create feedback.'
                ], 403);
            }

            // Validate input
            $validated = $request->validate([
                'topic' => 'required|string|max:255',
                'comment' => 'required|string|max:5000',
                'student_id' => 'required|string|exists:users,user_id',
            ]);

            // Create feedback with authenticated user as teacher
            $feedback = Feedback::create([
                'teacher_id' => $user->user_id,
                'student_id' => $validated['student_id'],
                'topic' => $validated['topic'],
                'comment' => $validated['comment'],
            ]);

            // Load relations
            $feedback->load('student', 'teacher');

            return response()->json([
                'success' => true,
                'message' => 'Feedback created successfully',
                'data' => [
                    'feedback_id' => $feedback->feedback_id,
                    'student_name' => $feedback->student->name ?? null,
                    'student_id' => $feedback->student_id,
                    'teacher_name' => $feedback->teacher->name ?? null,
                    'teacher_id' => $feedback->teacher_id,
                    'topic' => $feedback->topic,
                    'feedback' => $feedback->comment,
                    'created_at' => $feedback->created_at->toIso8601String(),
                ],
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'error' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('FEEDBACK_STORE_ERROR: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Failed to create feedback',
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get feedback received by a student
     * - Students can only see their own feedback
     * - Teachers/Admins can see feedback for any student
     */
    public function getStudentFeedback(Request $request, $studentId): JsonResponse
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'error' => 'Unauthenticated'
                ], 401);
            }

            $user->load('role');
            $userRole = $user->role->role_name ?? 'Student';

            // Students can only view their own feedback
            if ($userRole === 'Student' && $user->user_id !== $studentId) {
                return response()->json([
                    'success' => false,
                    'error' => 'Forbidden',
                    'message' => 'Students can only view their own feedback.'
                ], 403);
            }

            $feedbacks = Feedback::where('student_id', $studentId)
                ->with('teacher')
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($feedback) {
                    return [
                        'feedback_id' => $feedback->feedback_id,
                        'teacher_name' => $feedback->teacher->name ?? 'Unknown',
                        'teacher_id' => $feedback->teacher_id,
                        'topic' => $feedback->topic,
                        'feedback' => $feedback->comment,
                        'created_at' => $feedback->created_at->toIso8601String(),
                    ];
                });

            return response()->json([
                'success' => true,
                'data' => $feedbacks,
            ]);
        } catch (\Exception $e) {
            Log::error('FEEDBACK_GET_STUDENT_ERROR: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Failed to fetch student feedbacks',
                'message' => $e->getMessage(),
            ], 500);
        }
    }
    // PUT /feedback/{id}
    public function update(Request $request, $id)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'error' => 'Unauthenticated'
                ], 401);
            }

            $user->load('role');
            $userRole = $user->role->role_name ?? 'Student';

            // Only Teachers and Admins can update feedback
            if ($userRole !== 'Teacher' && $userRole !== 'Admin') {
                return response()->json([
                    'success' => false,
                    'error' => 'Forbidden',
                    'message' => 'Only teachers and admins can update feedback.'
                ], 403);
            }

            $feedback = Feedback::where('feedback_id', $id)->firstOrFail();

            // Restrict teachers to editing only their own feedback
            if ($userRole === 'Teacher' && $feedback->teacher_id !== $user->user_id) {
                return response()->json([
                    'success' => false,
                    'error' => 'Forbidden',
                    'message' => 'Teachers can only edit their own feedback.'
                ], 403);
            }

            $request->validate([
                'topic'   => 'required|string|max:255',
                'comment' => 'required|string|max:5000',
            ]);

            $feedback->update([
                'topic' => $request->topic,
                'comment' => $request->comment,
            ]);

            $feedback->load('student', 'teacher');

            return response()->json([
                'success' => true,
                'message' => 'Feedback updated successfully',
                'data' => [
                    'feedback_id' => $feedback->feedback_id,
                    'student_name' => $feedback->student->name ?? null,
                    'student_id' => $feedback->student_id,
                    'teacher_name' => $feedback->teacher->name ?? null,
                    'teacher_id' => $feedback->teacher_id,
                    'topic' => $feedback->topic,
                    'feedback' => $feedback->comment,
                    'created_at' => $feedback->created_at->toIso8601String(),
                ],
            ], 200);
        } catch (\Exception $e) {
            Log::error('FEEDBACK_UPDATE_ERROR: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Failed to update feedback',
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    // DELETE /feedback/{id}
    public function destroy($id)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'error' => 'Unauthenticated'
                ], 401);
            }

            $user->load('role');
            $userRole = $user->role->role_name ?? 'Student';

            // Only Teachers and Admins can delete feedback
            if ($userRole !== 'Teacher' && $userRole !== 'Admin') {
                return response()->json([
                    'success' => false,
                    'error' => 'Forbidden',
                    'message' => 'Only teachers and admins can delete feedback.'
                ], 403);
            }

            $feedback = Feedback::where('feedback_id', $id)->firstOrFail();

            // Restrict teachers to deleting only their own feedback
            if ($userRole === 'Teacher' && $feedback->teacher_id !== $user->user_id) {
                return response()->json([
                    'success' => false,
                    'error' => 'Forbidden',
                    'message' => 'Teachers can only delete their own feedback.'
                ], 403);
            }

            $feedback->delete();

            return response()->json([
                'success' => true,
                'message' => 'Feedback deleted successfully',
            ], 200);
        } catch (\Exception $e) {
            Log::error('FEEDBACK_DELETE_ERROR: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Failed to delete feedback',
                'message' => $e->getMessage(),
            ], 500);
        }
    }
}
