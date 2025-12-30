<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ChatbotSession extends Model
{
    use HasUuids;

    protected $fillable = ['id', 'user_id', 'title'];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }

    public function messages()
    {
        return $this->hasMany(ChatbotMessage::class, 'chatbot_session_id', 'id');
    }
}
