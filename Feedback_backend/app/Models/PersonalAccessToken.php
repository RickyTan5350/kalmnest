<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Laravel\Sanctum\PersonalAccessToken as SanctumPersonalAccessToken;

class PersonalAccessToken extends SanctumPersonalAccessToken
{
    use HasUuids;

    protected $primaryKey = 'token_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'tokenable_id' => 'string',
        ]);
    }

    protected static function boot(): void
    {
        parent::boot();

        // Generate a UUID for token_id if not already set
        static::creating(function ($model) {
            if (empty($model->token_id)) {
                $model->token_id = (string) \Illuminate\Support\Str::uuid();
            }
        });
    }
}
