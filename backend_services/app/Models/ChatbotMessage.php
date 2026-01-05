<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ChatbotMessage extends Model
{
    use HasUuids;

    protected $primaryKey = 'message_id';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = ['chatbot_session_id', 'role', 'content'];

    public function session()
    {
        return $this->belongsTo(ChatbotSession::class, 'chatbot_session_id', 'chatbot_session_id');
    }
}
