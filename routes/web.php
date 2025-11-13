<?php

use App\Http\Controllers\ProductController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CustommerController;
use App\Http\Controllers\AdminController;

Route::get('/', function () {
    return view('welcome');
});

// Login/logout
Route::get('/masuk', [AuthController::class, 'showLoginForm'])->name('masuk'); 
Route::post('/masuk', [AuthController::class, 'masuk']);
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

// Hanya dashboard yang pakai auth
Route::middleware('auth')->group(function () {
    Route::get('/dashboard', [AdminController::class, 'index'])->name('dashboard');
});

// Customers tanpa middleware auth
Route::resource('/customers', CustommerController::class);
Route::resource('products', ProductController::class);

