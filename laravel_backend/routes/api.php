<?php


use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ClassController;

Route::get('/classes', [ClassController::class, 'indexApi']);
Route::get('/classes/{id}', [ClassController::class, 'showApi']);
Route::post('/classes', [ClassController::class, 'storeApi']);
Route::put('/classes/{id}', [ClassController::class, 'updateApi']);
Route::delete('/classes/{id}', [ClassController::class, 'destroyApi']);
Route::get('/test', fn() => response()->json(['status' => 'API OK']));
