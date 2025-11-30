<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
// removed BelongsTo

/**
 * App\Models\Achievement
 *
 * @property string $achievement_id
 * @property string $achievement_name
 * @property string $title
 * @property string|null $description
 * @property string $type
 * @property string $level_id
 * @property string $created_by
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * (removed property-read)
 * (removed property-read)
 */

class Achievement extends Model
{
    use HasFactory, HasUuids;

    // ... (primaryKey, incrementing, keyType remain the same)

    /**
     * Get the columns that should receive a unique identifier.
     * Use this to ensure 'achievement_id' is generated as a UUIDv7.
     *
     * @return array<int, string>
     */
    public function uniqueIds(): array
    {
        return ['achievement_id'];
    }

    /**
     * The attributes that should be cast.
     * Cast from string-based CHAR(36) UUIDs to string in PHP.
     *
     * @var array<string, string>
     */
    protected $casts = [
        // Changed to 'string' since the DB column is now CHAR(36)
        'achievement_id' => 'string', 
        'level_id' => 'string', 
        'created_by' => 'string',
    ];

    // ... (fillable and relationships remain the same)
}