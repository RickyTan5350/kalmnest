<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return 'Laravel backend is running!';
});

Route::prefix('api')->group(function () {
    require base_path('routes/api.php');
});
