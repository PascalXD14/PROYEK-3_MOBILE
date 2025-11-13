<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;


class AuthController extends Controller
{
    public function showLoginForm() {
        return view('auth.masuk');
    }

    public function masuk(Request $request)
    {
        $credentials = $request->only('name', 'password');
    
        if (Auth::attempt($credentials)) {
            $request->session()->regenerate();
            return redirect()->intended('dashboard');
        }
    
        // Tambahkan debug ini
        dd('Login gagal', $request->all(), User::where('name', $request->input('name'))->first());
    
        return back()->withErrors([
            'name' => 'Name atau password salah.',
        ])->withInput();
    }
    


    public function logout() {
        Auth::logout();
        return redirect('/masuk');
    }
}
