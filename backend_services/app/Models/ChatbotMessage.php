<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatbotMessage extends Model
{
    use \Illuminate\Database\Eloquent\Concerns\HasUuids;
    protected $primaryKey = 'message_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['message_id', 'chatbot_session_id', 'role', 'content'];

    public function session()
    {
        return $this->belongsTo(ChatbotSession::class, 'chatbot_session_id', 'chatbot_session_id');
    }
}
