<?php

namespace App\Services;

use App\Models\ChatbotSession;
use App\Models\ChatbotMessage;
use Gemini\Data\Content;
use Gemini\Enums\Role;
use Gemini\Laravel\Facades\Gemini;
use Illuminate\Support\Facades\Log;

class GeminiService
{
    /**
     * Generates a response from Gemini based on the session history and new message.
     */
    public function generateResponse(string $sessionId, string $userMessage, string $userMessageId): string
    {
        try {
            // Retrieve history for the session
            $history = ChatbotMessage::where('chatbot_session_id', $sessionId)
                ->orderBy('created_at', 'asc')
                ->get()
                ->map(function ($msg) {
                    $role = $msg->role === 'user' ? Role::USER : Role::MODEL;
                    return Content::parse(part: $msg->content, role: $role);
                })
                ->toArray();

            // Use the gemini-2.0-flash model
            $chat = Gemini::generativeModel(model: 'gemini-2.0-flash')->startChat(history: $history);
            $response = $chat->sendMessage($userMessage);

            return $response->text();
        } catch (\Exception $e) {
            Log::error("GeminiService Error: " . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Stores a message in the database.
     */
    public function storeMessage(string $sessionId, string $role, string $content): ChatbotMessage
    {
        return ChatbotMessage::create([
            'chatbot_session_id' => $sessionId,
            'role' => $role,
            'content' => $content,
        ]);
    }
}
