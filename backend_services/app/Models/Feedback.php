<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Feedback extends Model
{
    use HasFactory, HasUuids;

    protected $primaryKey = 'feedback_id';
    protected $keyType = 'string';
    public $incrementing = false;
    protected $table = 'feedbacks';

    protected $fillable = [
        'feedback_id',
        'student_id',
        'teacher_id',
        'topic_id',
        'title',
        'comment',
    ];

    /**
     * Get the topic this feedback is related to
     */
    public function topic()
    {
        return $this->belongsTo(Topic::class, 'topic_id', 'topic_id');
    }

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get the student who received this feedback
     */
    public function student()
    {
        return $this->belongsTo(User::class, 'student_id', 'user_id');
    }

    /**
     * Get the teacher who gave this feedback
     */
    public function teacher()
    {
        return $this->belongsTo(User::class, 'teacher_id', 'user_id');
    }
}
