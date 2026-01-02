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
        ]);

        $userMessage = $request->input('message');
        $sessionId = $request->input('session_id');
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
            // We use the service to store cleanly, assuming StoreMessage exists in service
            // Based on view_file of GeminiService, it DOES exist: storeMessage($sessionId, $role, $content)
            $savedMessage = $this->geminiService->storeMessage($sessionId, 'user', $userMessage);

            // 3. Generate AI Response
            // Service method: generateResponse(string $sessionId, string $userMessage, string $userMessageId)
            $aiResponseText = $this->geminiService->generateResponse($sessionId, $userMessage, (string)$savedMessage->id);

            // 4. Store AI Response (Note: generateResponse in service might NOT store the response automatically? 
            // Checking GeminiService code: it returns $response->text() but DOES NOT call storeMessage for the AI response.
            // So we must store it here.)
            $this->geminiService->storeMessage($sessionId, 'model', $aiResponseText);

            return response()->json([
                'status' => 'success',
                'ai_response' => $aiResponseText,
                'session_id' => $sessionId, // Return UUID
            ]);

        } catch (\Exception $e) {
            Log::error("Gemini Controller Error: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while processing your request.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function getSessions(Request $request)
    {
        $sessions = ChatbotSession::where('user_id', $request->user()->user_id)
            ->orderBy('updated_at', 'desc')
            ->get();
            
        return response()->json($sessions); // Return list directly or wrapped? 
        // Diff showed: return response()->json(['status' => 'success', 'sessions' => $sessions]);
        // I will stick to that format.
        // Actually, let's match the diff's format:
        /*
        return response()->json([
            'status' => 'success',
            'sessions' => $sessions
        ]);
        */
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
