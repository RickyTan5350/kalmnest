<?php

namespace App\Http\Controllers;

use App\Http\Requests\GetGeminiResponseRequest;
use App\Models\ChatbotMessage;
use App\Models\ChatbotSession;
use App\Services\GeminiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class GeminiController extends Controller
{
    protected GeminiService $geminiService;

    public function __construct(GeminiService $geminiService)
    {
        $this->geminiService = $geminiService;
    }

    /**
     * Get all chat sessions for the current user.
     */
    public function getSessions(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json(['status' => 'error', 'message' => 'Unauthorized'], 401);
            }

            $sessions = ChatbotSession::where('user_id', $user->user_id)
                ->orderBy('updated_at', 'desc')
                ->get();

            return response()->json([
                'status' => 'success',
                'sessions' => $sessions
            ], 200);
        } catch (\Exception $e) {
            Log::error("Get Chat Sessions Error: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => 'Could not fetch history.'], 500);
        }
    }

    /**
     * Get all messages for a specific session.
     */
    public function getSessionMessages(Request $request, $sessionId): JsonResponse
    {
        try {
            $user = $request->user();
            $session = ChatbotSession::where('chatbot_session_id', $sessionId)
                ->where('user_id', $user->user_id)
                ->firstOrFail();

            $messages = ChatbotMessage::where('chatbot_session_id', $sessionId)
                ->orderBy('created_at', 'asc')
                ->get();

            return response()->json([
                'status' => 'success',
                'messages' => $messages
            ], 200);
        } catch (\Exception $e) {
            Log::error("Get Chat Messages Error: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => 'Could not fetch messages.'], 500);
        }
    }

    /**
     * Delete a chat session and its messages.
     */
    public function deleteSession(Request $request, $sessionId): JsonResponse
    {
        try {
            $user = $request->user();
            $session = ChatbotSession::where('chatbot_session_id', $sessionId)
                ->where('user_id', $user->user_id)
                ->firstOrFail();

            $session->delete();

            return response()->json([
                'status' => 'success',
                'message' => 'Chat history cleared.'
            ], 200);
        } catch (\Exception $e) {
            Log::error("Delete Chat Session Error: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => 'Could not clear history.'], 500);
        }
    }

    /**
     * Handles the incoming chat request from the Flutter app, sends it to Gemini,
     * and returns the AI's response.
     */
    public function getResponse(GetGeminiResponseRequest $request): JsonResponse
    {
        $userMessage = $request->input('message');
        $sessionId = $request->input('session_id');
        $user = $request->user();

        try {
            // 1. Get or Create Session
            $session = $this->geminiService->getOrCreateSession($user->user_id, $sessionId, $userMessage);
            $sessionId = $session->chatbot_session_id;

            // 2. Store User Message
            $currentUserMessage = $this->geminiService->storeMessage($sessionId, 'user', $userMessage);

            // 3. Interface with Gemini
            $aiResponse = '(AI unavailable due to an internal error, but you can continue the conversation.)';
            try {
                $aiResponse = $this->geminiService->generateResponse($sessionId, $userMessage, $currentUserMessage->message_id);
            } catch (\Throwable $e) {
                // We catch but keep going to store the error message if needed, 
                // or just leave the default fallback response.
            }

            // 4. Store AI Response
            $this->geminiService->storeMessage($sessionId, 'model', $aiResponse);

            return response()->json([
                'status' => 'success',
                'ai_response' => $aiResponse,
                'session_id' => $sessionId,
            ], 200);

        } catch (\Throwable $e) {
            Log::error("Gemini Chat Error: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Could not process the chat. Please try again later.',
                'session_id' => $sessionId ?? null,
                'ai_response' => '(AI unavailable due to an internal error, but you can continue the conversation.)'
            ], 200);
        }
    }
}
