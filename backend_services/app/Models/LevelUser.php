<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class LevelUser extends Model
{
    use HasUuids;

    protected $primaryKey = 'level_user_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $table = 'level_user';

    protected $fillable = [
        'level_id',
        'user_id',
        'saved_data',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    // Relationship to Level
    public function level()
    {
        return $this->belongsTo(Level::class, 'level_id', 'level_id');
    }

    // Relationship to User
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }
}
