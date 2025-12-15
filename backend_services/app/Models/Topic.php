<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Topic extends Model
{
    use HasUuids;
    //
    protected $primaryKey = 'topic_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'topic_name',
       
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function notes(){
        return $this->hasMany(Notes::class);
    }
}
