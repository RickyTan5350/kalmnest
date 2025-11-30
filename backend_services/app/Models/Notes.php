<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Notes extends Model
{
    use HasUuids;
    //
    protected $primaryKey = 'note_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'topic_id',
        'title',
        'file_path',
        'created_by',
        'visibility',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'note_visibility' => 'boolean',
        ];
    }

    public function topics(){
        return $this->belongsTo(Topic::class);
    }

    public function createdBy(){
        return $this->belongsTo(User::class, 'note_created_by', 'id');
    }
}
