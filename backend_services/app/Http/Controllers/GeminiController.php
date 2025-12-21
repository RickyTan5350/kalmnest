<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Gemini\Laravel\Facades\Gemini;
use Illuminate\Support\Facades\Log;
use App\Models\ChatbotSession;
use App\Models\ChatbotMessage;
use Illuminate\Support\Str;

class GeminiController extends Controller
{
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
                    'id' => (string) Str::uuid(),
                    'user_id' => $user->user_id,
                    'title' => Str::limit($userMessage, 40),
                ]);
                $sessionId = $session->id;
            } else {
                $session = ChatbotSession::where('id', $sessionId)
                    ->where('user_id', $user->user_id)
                    ->firstOrFail();
            }

            // 2. Store User Message
            ChatbotMessage::create([
                'chatbot_session_id' => $sessionId,
                'role' => 'user',
                'content' => $userMessage,
            ]);

            // 3. Prepare History for Gemini
            $history = ChatbotMessage::where('chatbot_session_id', $sessionId)
                ->orderBy('created_at', 'asc')
                ->get()
                ->map(fn($msg) => [
                    'role' => $msg->role, // 'user' or 'model'
                    'parts' => [['text' => $msg->content]],
                ])
                ->toArray();

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
}
