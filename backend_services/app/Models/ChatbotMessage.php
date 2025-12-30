<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatbotMessage extends Model
{
    protected $fillable = ['chatbot_session_id', 'role', 'content'];

    public function session()
    {
        return $this->belongsTo(ChatbotSession::class, 'chatbot_session_id', 'id');
    }
}
