<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Laravel\Sanctum\Sanctum;
use App\Models\PersonalAccessToken;

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
        // Force HTTPS ONLY if the request is coming via Expose/Ngrok (signaled by our header)
        // or if explicitly in production.
        if (config('app.env') !== 'local' || request()->header('X-Forwarded-Proto') === 'https') {
             \Illuminate\Support\Facades\URL::forceScheme('https');
        }

        Sanctum::usePersonalAccessTokenModel(PersonalAccessToken::class);
    }
}
