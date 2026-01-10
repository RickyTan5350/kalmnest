<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->trustProxies(at: '*');
        // Enable CORS - use both Laravel's HandleCors and custom middleware for reliability
        $middleware->api(prepend: [
            \App\Http\Middleware\CorsMiddleware::class,
            \Illuminate\Http\Middleware\HandleCors::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Add CORS headers to exception responses
        $exceptions->render(function (\Throwable $e, $request) {
            if ($request->is('api/*')) {
                $origin = $request->headers->get('Origin');
                $vercelPattern = '#^https://kalmnest-.*\.vercel\.app$#';
                
                $response = response()->json([
                    'message' => 'Server error',
                    'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
                ], 500);
                
                // Add CORS headers to error response
                if ($origin && preg_match($vercelPattern, $origin)) {
                    $response->headers->set('Access-Control-Allow-Origin', $origin);
                    $response->headers->set('Access-Control-Allow-Credentials', 'true');
                } elseif ($origin) {
                    $response->headers->set('Access-Control-Allow-Origin', $origin);
                    $response->headers->set('Access-Control-Allow-Credentials', 'true');
                }
                
                $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
                $response->headers->set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin, X-XSRF-TOKEN');
                
                return $response;
            }
        });
    })->create();
