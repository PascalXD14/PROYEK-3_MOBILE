<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Models\products;
use App\Models\Pesanan;
use Illuminate\Support\Facades\Auth;

class AdminController extends Controller
{
    public function index()
    {
        $totalPelanggan = Customer::count();
        $totalProduk = products::count();

        return view('admin.dashboard', [
            'totalPelanggan' => $totalPelanggan,
            'totalProduk' => $totalProduk,
        ]);
    }
}
