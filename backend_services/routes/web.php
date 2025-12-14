<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\LevelTypeController;

Route::get('/', function () {
    return view('levels');
});

Route::get('/level-type', [LevelTypeController::class, 'store']);