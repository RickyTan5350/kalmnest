<?php

namespace App\Services;

use App\Models\ChatbotMessage;
use App\Models\ChatbotSession;
use Gemini\Laravel\Facades\Gemini;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class GeminiService
{
    /**
     * Get or create a chat session.
     */
    public function getOrCreateSession(string $userId, ?string $sessionId, string $messageTitle): ChatbotSession
    {
        if (!$sessionId) {
            return ChatbotSession::create([
                'chatbot_session_id' => (string) Str::uuid(),
                'user_id' => $userId,
                'title' => Str::limit($messageTitle, 40),
            ]);
        }

        return ChatbotSession::where('chatbot_session_id', $sessionId)
            ->where('user_id', $userId)
            ->firstOrFail();
    }

    /**
     * Store a message in the database.
     */
    public function storeMessage(string $sessionId, string $role, string $content): ChatbotMessage
    {
        return ChatbotMessage::create([
            'message_id' => (string) Str::uuid(),
            'chatbot_session_id' => $sessionId,
            'role' => $role,
            'content' => $content,
        ]);
    }

    /**
     * Generate response from Gemini API.
     */
    public function generateResponse(string $sessionId, string $userMessage, string $currentUserMessageId): string
    {
        $history = $this->prepareHistory($sessionId, $currentUserMessageId);

        try {
            $chat = Gemini::generativeModel(model: 'gemini-2.0-flash')
                ->startChat(history: $history);
            
            $result = $chat->sendMessage($userMessage);

            $aiResponse = null;
            if (!empty($result->candidates)) {
                $candidate = $result->candidates[0];
                if (isset($candidate->content->parts[0]->text)) {
                    $aiResponse = $candidate->content->parts[0]->text;
                }
            }

            return $aiResponse ?: '(I encountered a safety filter or an empty response. Please try rephrasing your message.)';
        } catch (\Throwable $e) {
            Log::error("Gemini Interaction Error: " . $e->getMessage(), [
                'exception_class' => get_class($e),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);
            
            throw $e;
        }
    }

    /**
     * Prepare conversation history for Gemini.
     */
    private function prepareHistory(string $sessionId, string $currentUserMessageId): array
    {
        $allMessages = ChatbotMessage::where('chatbot_session_id', $sessionId)
            ->orderBy('created_at', 'asc')
            ->get();

        $history = [];
        foreach ($allMessages as $msg) {
            if ($msg->message_id === $currentUserMessageId) {
                continue;
            }

            $role = $this->standardizeRole($msg->role);
            $content = trim($msg->content ?: '');
            
            if ($content === '') continue;

            if (empty($history)) {
                if ($role === 'user') {
                    $history[] = [
                        'role' => 'user',
                        'parts' => [['text' => $content]],
                    ];
                }
                continue;
            }

            $lastIndex = count($history) - 1;
            if ($history[$lastIndex]['role'] === $role) {
                $history[$lastIndex]['parts'][] = ['text' => "\n" . $content];
            } else {
                $history[] = [
                    'role' => $role,
                    'parts' => [['text' => $content]],
                ];
            }
        }

        // Gemini expects history to end with 'model'
        if (!empty($history) && $history[count($history) - 1]['role'] !== 'model') {
            array_pop($history);
        }

        return $history;
    }

    /**
     * Standardize message roles for Gemini.
     */
    private function standardizeRole(string $role): string
    {
        $rawRole = strtolower(trim($role));
        return match($rawRole) {
            'model', 'ai', 'assistant', 'bot' => 'model',
            default => 'user',
        };
    }
}
