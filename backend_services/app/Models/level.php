<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class Level extends Model
{
    use HasUuids;

    protected $primaryKey = 'level_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'level_name',
        'level_type_id',
        'level_data',
        'win_condition',
        'created_by',
        'timer'
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    // Relationship to level_type
    public function level_type()
    {
        return $this->belongsTo(level_type::class, 'level_type_id', 'level_type_id');
    }

    // Relationship to classes (many-to-many through class_levels)
    public function classes()
    {
        return $this->belongsToMany(ClassModel::class, 'class_levels', 'level_id', 'class_id')
                    ->withPivot('is_private', 'created_at', 'updated_at')
                    ->withTimestamps();
    }

    // Relationship to creator (user who created this level)
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by', 'user_id');
    }
}
