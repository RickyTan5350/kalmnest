<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
class File extends Model
{
    use HasFactory, HasUuids;

    /**
     * The primary key associated with the table.
     * Laravel defaults to 'id', so we must specify 'file_id'.
     */
    protected $primaryKey = 'file_id';

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'file_path',
        'type',
    ];

    /**
     * Relationship: A File can be used in multiple Notes (or one).
     * Since the foreign key 'file_id' is on the 'notes' table,
     * the File "has many" Notes.
     */
    public function note(): BelongsTo
    {
        return $this->belongsTo(Notes::class, 'note_id', 'note_id');
    }
}