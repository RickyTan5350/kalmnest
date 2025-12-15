<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class level_type extends Model
{
    use HasUuids;
    protected $primaryKey = 'level_type_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'level_type_name'
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function level(){
        return $this->hasMany(level::class);
    }
}
