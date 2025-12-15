<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Achievement extends Model
{
    use HasUuids;
    protected $primaryKey = 'achievement_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'achievement_name',
        'title',
        'description',
        'associated_level',
        'created_by',
        'icon'
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function level(){
        return $this->belongsTo(Level::class, 'associated_level', 'level_id');
    }

    public function created_by(){
        return $this->BelongsTo(User::class);
    }
}
