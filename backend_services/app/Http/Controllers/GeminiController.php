<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Gemini\Laravel\Facades\Gemini;
use Illuminate\Support\Facades\Log;
use App\Models\ChatbotSession;
use App\Models\ChatbotMessage;
use App\Services\GeminiService;
use Illuminate\Support\Str;

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
            'message' => 'required|string|max:1000',
            'session_id' => 'nullable|uuid',
        ]);

        $userMessage = $request->input('message');
        $sessionId = $request->input('session_id');
        $user = $request->user();

        try {
            // 1. Get or Create Session
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
                $aiResponse = $this->geminiService->generateResponse($sessionId, $userMessage, $currentUserMessage->message_id);
            } catch (\Throwable $e) {
                $aiResponse = '(AI Error: ' . $e->getMessage() . ')';
                Log::error("Gemini Generate Response Error: " . $e->getMessage());
            }

            // 4. Store AI Response
            $this->geminiService->storeMessage($sessionId, 'model', $aiResponse);

            return response()->json([
                'status' => 'success',
                'ai_response' => $aiResponse,
                'session_id' => $sessionId,
            ], 200);

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

    public function getSessions(Request $request)
    {
        $sessions = ChatbotSession::where('user_id', $request->user()->user_id)
            ->orderBy('updated_at', 'desc')
            ->get();
            
        return response()->json([
            'status' => 'success',
            'sessions' => $sessions
        ]);
    }

    public function getMessages(Request $request, $sessionId)
    {
        $session = ChatbotSession::where('chatbot_session_id', $sessionId)
            ->where('user_id', $request->user()->user_id)
            ->firstOrFail();
            
        $messages = ChatbotMessage::where('chatbot_session_id', $sessionId)
            ->orderBy('created_at', 'asc')
            ->get();
            
        return response()->json([
            'status' => 'success',
            'messages' => $messages
        ]);
    }

    public function deleteSession(Request $request, $sessionId)
    {
        $session = ChatbotSession::where('chatbot_session_id', $sessionId)
            ->where('user_id', $request->user()->user_id)
            ->firstOrFail();
            
        $session->delete();
        
        return response()->json([
            'status' => 'success',
            'message' => 'Session deleted successfully'
        ]);
    }
}
