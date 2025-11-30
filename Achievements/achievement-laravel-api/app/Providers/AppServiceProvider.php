<?php

namespace App\Providers;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\ServiceProvider;


class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Blueprint::macro('binaryUuid', function (string $column = 'id') {
            // This is the core logic: it chains the orderedUuid() and binary() methods.
            // orderedUuid() is preferred as it's time-sortable (UUIDv7).
            return $this->uuid($column)->binary();
        });
    }
}
