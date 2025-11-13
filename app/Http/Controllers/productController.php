<?php

namespace App\Http\Controllers;

use App\Models\products;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->input('search');

        $products = products::when($search, function ($query, $search) {
            return $query->where('name', 'like', '%' . $search . '%')
                        ->orWhere('brand', 'like', '%' . $search . '%')
                        ->orWhere('type', 'like', '%' . $search . '%');
        })->get();

        return view('products.index', compact('products'));
    }

    public function create()
    {
        return view('products.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'brand' => 'required',
            'type' => 'required',
            'stock' => 'required|integer',
            'price' => 'required|integer',
            'image' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);
    
        $data = $request->all();
    
        if ($request->hasFile('image')) {
            $imageName = time().'.'.$request->image->extension();
            $request->image->move(public_path('images'), $imageName);
            $data['image'] = $imageName;
        }
    
        products::create($data);
        return redirect('/products')->with('success', 'Produk berhasil ditambahkan.');
    }
    
    public function edit(products $product)
    {
        return view('products.edit', compact('product'));
    }

    public function update(Request $request, products $product)
    {
        $request->validate([
            'name' => 'required',
            'brand' => 'required',
            'type' => 'required',
            'stock' => 'required|integer',
            'price' => 'required|integer',
            'image' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);
    
        $data = $request->all();
    
        if ($request->hasFile('image')) {
            $imageName = time().'.'.$request->image->extension();
            $request->image->move(public_path('images'), $imageName);
            $data['image'] = $imageName;
        }
    
        $product->update($data);
        return redirect('/products')->with('success', 'Produk berhasil diubah.');
    }

    public function destroy(products $product)
    {
        $product->delete();
        return redirect('/products')->with('success', 'Produk berhasil dihapus.');
    }
}
