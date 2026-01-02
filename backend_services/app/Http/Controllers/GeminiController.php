<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\GeminiService;
use App\Models\ChatbotSession;
use App\Models\ChatbotMessage;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;

class GeminiController extends Controller
{
    protected GeminiService $geminiService;

    public function __construct(GeminiService $geminiService)
    {
        $this->geminiService = $geminiService;
    }

    /**
     * Handles the incoming chat request from the Flutter app, sends it to Gemini,
     * and returns the AI's response.
     */
    public function getResponse(Request $request)
    {
        $request->validate([
            'message' => 'required|string',
            'session_id' => 'nullable|string',
            'language' => 'nullable|string|in:en,ms',
        ]);

        $userMessage = $request->input('message');
        $sessionId = $request->input('session_id');
        $language = $request->input('language', 'en'); // Default to English
        $user = $request->user();

        try {
            // 1. Create or Retrieve Session
            if (!$sessionId) {
                $session = ChatbotSession::create([
                    'chatbot_session_id' => (string) Str::uuid(),
                    'user_id' => $user->user_id,
                    'title' => Str::limit($userMessage, 40),
                ]);
                $sessionId = $session->chatbot_session_id;
            } else {
                $session = ChatbotSession::where('chatbot_session_id', $sessionId)
                    ->where('user_id', $user->user_id)
                    ->firstOrFail();
            }

            // 2. Store User Message
            $currentUserMessage = ChatbotMessage::create([
                'chatbot_session_id' => $sessionId,
                'role' => 'user',
                'content' => $userMessage,
            ]);

            // 3. Interface with Gemini
            $aiResponse = '(AI unavailable due to an internal error...)';
            try {
                // Ensure geminiService is available and use correct property
                $aiResponse = $this->geminiService->generateResponse($sessionId, $userMessage, $currentUserMessage->message_id, $language);
            } catch (\Throwable $e) {
                $aiResponse = '(AI Error: ' . $e->getMessage() . ')';
                Log::error("Gemini Generate Response Error: " . $e->getMessage());
            }

            // 4. Store AI Response
            $this->geminiService->storeMessage($sessionId, 'model', $aiResponse);

            return response()->json([
                'status' => 'success',
                'ai_response' => $aiResponse,
                'session_id' => $sessionId, // Return UUID
            ]);

        } catch (\Throwable $e) {
            Log::error("Gemini Chat Error: " . $e->getMessage(), [
                'exception' => get_class($e),
                'session_id' => $sessionId ?? null,
                'trace' => $e->getTraceAsString(),
            ]);
            return response()->json([
                'status' => 'error',
                'message' => 'AI Chat Error: ' . $e->getMessage(),
                'session_id' => $sessionId ?? null,
                'ai_response' => '(AI unavailable due to an internal error: ' . $e->getMessage() . ')'
            ], 200);
        }
    }

    /**
     * Get all chat sessions for the authenticated user
     */
    public function getSessions(Request $request)
    {
        try {
            $user = $request->user();
            
            $sessions = ChatbotSession::where('user_id', $user->user_id)
                ->with(['messages' => function ($query) {
                    $query->orderBy('created_at', 'desc')->limit(1);
                }])
                ->orderBy('updated_at', 'desc')
                ->get()
                ->map(function ($session) {
                    $lastMessage = $session->messages->first();
                    return [
                        'session_id' => $session->chatbot_session_id,
                        'title' => $session->title,
                        'last_message' => $lastMessage ? Str::limit($lastMessage->content, 50) : $session->title,
                        'created_at' => $session->created_at->toISOString(),
                        'updated_at' => $session->updated_at->toISOString(),
                    ];
                });

            return response()->json($sessions, 200);
        } catch (\Throwable $e) {
            Log::error("Get Sessions Error: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to load sessions: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get messages for a specific session
     */
    public function getMessages(Request $request, $sessionId)
    {
        try {
            $user = $request->user();
            
            // Verify session belongs to user
            $session = ChatbotSession::where('chatbot_session_id', $sessionId)
                ->where('user_id', $user->user_id)
                ->firstOrFail();

            $messages = ChatbotMessage::where('chatbot_session_id', $sessionId)
                ->orderBy('created_at', 'asc')
                ->get()
                ->map(function ($message) {
                    return [
                        'id' => $message->message_id,
                        'message_id' => $message->message_id,
                        'content' => $message->content,
                        'message' => $message->content,
                        'role' => $message->role,
                        'sender' => $message->role === 'user' ? 'user' : 'assistant',
                        'created_at' => $message->created_at->toISOString(),
                    ];
                });

            return response()->json($messages, 200);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Session not found'
            ], 404);
        } catch (\Throwable $e) {
            Log::error("Get Messages Error: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to load messages: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a chat session
     */
    public function deleteSession(Request $request, $sessionId)
    {
        try {
            $user = $request->user();
            
            // Verify session belongs to user
            $session = ChatbotSession::where('chatbot_session_id', $sessionId)
                ->where('user_id', $user->user_id)
                ->firstOrFail();

            // Delete associated messages first
            ChatbotMessage::where('chatbot_session_id', $sessionId)->delete();
            
            // Delete session
            $session->delete();

            return response()->json([
                'status' => 'success',
                'message' => 'Session deleted successfully'
            ], 200);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Session not found'
            ], 404);
        } catch (\Throwable $e) {
            Log::error("Delete Session Error: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to delete session: ' . $e->getMessage()
            ], 500);
        }
    }
}
