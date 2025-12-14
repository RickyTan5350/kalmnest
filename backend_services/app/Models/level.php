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
        'win_condition'
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
}
