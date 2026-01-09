<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\LevelTypeController;

Route::get('/', function () {
    return response()->json([
        'message' => 'Kalmnest API is running',
        'api_health' => url('/api/health'),
        'api_test' => url('/api/test'),
        'status' => 'ok'
    ]);
});

Route::get('/level-type', [LevelTypeController::class, 'store']);