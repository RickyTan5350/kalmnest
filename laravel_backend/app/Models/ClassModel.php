<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Str;

class ClassModel extends Model
{
    use HasFactory;

    protected $table = 'classes';
    protected $primaryKey = 'class_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'class_name',
        'teacher_id',
        'description',
        'admin_id',
    ];

    // Automatically generate UUID
    protected static function boot()
    {
        parent::boot();
        static::creating(function ($model) {
            $model->class_id = (string) Str::uuid();
        });
    }
}
