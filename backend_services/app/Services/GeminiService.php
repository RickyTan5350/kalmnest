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
    public function generateResponse(string $sessionId, string $userMessage, string $userMessageId, string $language = 'en'): string
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

            // Build language instruction based on language preference
            $languageInstruction = $this->getLanguageInstruction($language);
            
            // Prepend language instruction to the user message
            // This ensures AI responds in the correct language
            $messageWithLanguage = $languageInstruction . "\n\n" . $userMessage;
            
            // Use the gemini-2.0-flash model
            $chat = Gemini::generativeModel(model: 'gemini-2.0-flash')
                ->startChat(history: $history);
            
            $response = $chat->sendMessage($messageWithLanguage);

            return $response->text();
        } catch (\Exception $e) {
            Log::error("GeminiService Error: " . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Get language instruction based on language preference.
     * This ensures AI responds in the correct language.
     */
    private function getLanguageInstruction(string $language): string
    {
        switch ($language) {
            case 'ms':
                // Bahasa Malaysia (not Bahasa Indonesia)
                return "Please respond in Bahasa Malaysia (Malay language used in Malaysia). Use Malaysian spelling and terminology. Do not use Bahasa Indonesia.";
            case 'en':
            default:
                return "Please respond in English.";
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
