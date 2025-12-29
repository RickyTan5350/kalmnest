<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreFeedbackRequest;
use App\Http\Requests\UpdateFeedbackRequest;
use App\Http\Requests\DeleteFeedbackRequest;
use App\Services\FeedbackService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class FeedbackController extends Controller
{
    protected FeedbackService $feedbackService;

    public function __construct(FeedbackService $feedbackService)
    {
        $this->feedbackService = $feedbackService;
    }

    /**
     * Get all feedback (filtered by role)
     * - Teachers: see only feedback they created
     * - Admins: see all feedback
     * - Students: see only feedback where they are the recipient (student_id)
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return $this->unauthorizedResponse();
            }

            $filters = $request->only(['teacher_id', 'topic_id']);
            $feedbacks = $this->feedbackService->getFeedbacksByRole($user, $filters);
            $formattedFeedbacks = $this->feedbackService->formatFeedbackCollection($feedbacks);

            return $this->successResponse($formattedFeedbacks);
        } catch (\Exception $e) {
            Log::error('FEEDBACK_INDEX_ERROR: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch feedbacks', $e->getMessage());
        }
    }

    /**
     * Store a new feedback
     * - Only Teachers and Admins can create feedback
     * - The authenticated user becomes the teacher_id
     *
     * @param StoreFeedbackRequest $request
     * @return JsonResponse
     */
    public function store(StoreFeedbackRequest $request): JsonResponse
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return $this->unauthorizedResponse();
            }

            $validated = $request->validated();
            $feedback = $this->feedbackService->createFeedback($validated, $user->user_id);
            $formattedFeedback = $this->feedbackService->formatFeedback($feedback);

            return $this->successResponse(
                $formattedFeedback,
                'Feedback created successfully',
                201
            );
        } catch (\Exception $e) {
            Log::error('FEEDBACK_STORE_ERROR: ' . $e->getMessage());
            return $this->errorResponse('Failed to create feedback', $e->getMessage());
        }
    }

    /**
     * Get feedback received by a student
     * - Students can only see their own feedback
     * - Teachers/Admins can see feedback for any student
     *
     * @param Request $request
     * @param string $studentId
     * @return JsonResponse
     */
    public function getStudentFeedback(Request $request, string $studentId): JsonResponse
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return $this->unauthorizedResponse();
            }

            // Check authorization
            if (!$this->feedbackService->canAccessStudentFeedback($user, $studentId)) {
                return $this->forbiddenResponse('Students can only view their own feedback.');
            }

            $feedbacks = $this->feedbackService->getStudentFeedback($studentId);
            $formattedFeedbacks = $this->feedbackService->formatFeedbackCollection($feedbacks, false);

            return $this->successResponse($formattedFeedbacks);
        } catch (\Exception $e) {
            Log::error('FEEDBACK_GET_STUDENT_ERROR: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch student feedbacks', $e->getMessage());
        }
    }

    /**
     * Update an existing feedback
     * - Only Teachers and Admins can update feedback
     * - Teachers can only edit their own feedback
     *
     * @param UpdateFeedbackRequest $request
     * @param string $id
     * @return JsonResponse
     */
    public function update(UpdateFeedbackRequest $request, string $id): JsonResponse
    {
        try {
            $validated = $request->validated();
            $feedback = $this->feedbackService->updateFeedback($id, $validated);
            $formattedFeedback = $this->feedbackService->formatFeedback($feedback);

            return $this->successResponse(
                $formattedFeedback,
                'Feedback updated successfully'
            );
        } catch (\Exception $e) {
            Log::error('FEEDBACK_UPDATE_ERROR: ' . $e->getMessage());
            return $this->errorResponse('Failed to update feedback', $e->getMessage());
        }
    }

    /**
     * Delete a feedback
     * - Only Teachers and Admins can delete feedback
     * - Teachers can only delete their own feedback
     *
     * @param DeleteFeedbackRequest $request
     * @param string $id
     * @return JsonResponse
     */
    public function destroy(DeleteFeedbackRequest $request, string $id): JsonResponse
    {
        try {
            $this->feedbackService->deleteFeedback($id);

            return $this->successResponse(
                null,
                'Feedback deleted successfully'
            );
        } catch (\Exception $e) {
            Log::error('FEEDBACK_DELETE_ERROR: ' . $e->getMessage());
            return $this->errorResponse('Failed to delete feedback', $e->getMessage());
        }
    }

    // ==================== Helper Response Methods ====================

    /**
     * Return a success JSON response
     *
     * @param mixed $data
     * @param string $message
     * @param int $statusCode
     * @return JsonResponse
     */
    private function successResponse($data = null, string $message = '', int $statusCode = 200): JsonResponse
    {
        $response = ['success' => true];

        if ($message) {
            $response['message'] = $message;
        }

        if ($data !== null) {
            $response['data'] = $data;
        }

        return response()->json($response, $statusCode);
    }

    /**
     * Return an error JSON response
     *
     * @param string $error
     * @param string $message
     * @param int $statusCode
     * @return JsonResponse
     */
    private function errorResponse(string $error, string $message = '', int $statusCode = 500): JsonResponse
    {
        $response = [
            'success' => false,
            'error' => $error,
        ];

        if ($message) {
            $response['message'] = $message;
        }

        return response()->json($response, $statusCode);
    }

    /**
     * Return an unauthorized JSON response
     *
     * @return JsonResponse
     */
    private function unauthorizedResponse(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'error' => 'Unauthenticated'
        ], 401);
    }

    /**
     * Return a forbidden JSON response
     *
     * @param string $message
     * @return JsonResponse
     */
    private function forbiddenResponse(string $message = 'Forbidden'): JsonResponse
    {
        return response()->json([
            'success' => false,
            'error' => 'Forbidden',
            'message' => $message
        ], 403);
    }
}
