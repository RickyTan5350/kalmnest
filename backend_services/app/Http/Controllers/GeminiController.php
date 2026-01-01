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

<<<<<<< HEAD
            // 3. Interface with Gemini
            $aiResponse = '(AI unavailable due to an internal error...)';
            try {
                // Ensure geminiService is available and use correct property
                $aiResponse = $this->geminiService->generateResponse($sessionId, $userMessage, $currentUserMessage->message_id);
            } catch (\Throwable $e) {
                $aiResponse = '(AI Error: ' . $e->getMessage() . ')';
                Log::error("Gemini Generate Response Error: " . $e->getMessage());
            }
=======
            // 3. Prepare History for Gemini
            $history = ChatbotMessage::where('chatbot_session_id', $sessionId)
                ->orderBy('created_at', 'asc')
                ->get()
                ->map(fn($msg) => [
                    'role' => $msg->role, // 'user' or 'model'
                    'parts' => [['text' => $msg->content]],
                ])
                ->toArray();
>>>>>>> 1e29cd39243df63e678e99d98d8e5e02b763c68f

            // 4. Interface with Gemini using chat (multi-turn)
            $chat = Gemini::generativeModel(model: 'gemini-3-pro-preview')->startChat(history: array_slice($history, 0, -1));
            $result = $chat->sendMessage($userMessage);
            $aiResponse = $result->text();

            // 5. Store AI Response
            ChatbotMessage::create([
                'chatbot_session_id' => $sessionId,
                'role' => 'model',
                'content' => $aiResponse,
            ]);

            return response()->json([
                'status' => 'success',
                'ai_response' => $aiResponse,
                'session_id' => $sessionId,
            ], 200);

        } catch (\Exception $e) {
            Log::error("Gemini Chat Error: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Could not process the chat. Please try again later.'
            ], 500);
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
