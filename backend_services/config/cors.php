<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    | To learn more: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => array_filter([
        // Vercel frontend domains
        'https://kalmnest-one.vercel.app',
        'https://kalmnest-git-main-tan-li-jis-projects.vercel.app',
        'https://kalmnest-mclv2vdnk-tan-li-jis-projects.vercel.app',
        // Additional frontend URLs from environment
        env('FRONTEND_URL'),
        // Local development
        'http://localhost',
        'http://localhost:3000',
        'http://127.0.0.1:8000',
        'https://kalmnest.test',
    ]),

    'allowed_origins_patterns' => [
        // Allow all Vercel preview deployments
        '#^https://kalmnest-.*\.vercel\.app$#',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => true,

];
