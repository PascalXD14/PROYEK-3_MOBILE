<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daftar Produk</title>

    <!-- Bootstrap & Font Awesome -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
</head>
<body class="bg-light pt-5 d-flex flex-column min-vh-100">

<!-- 🔹 HEADER FIXED ATAS -->
<header class="bg-success text-white fixed-top shadow-sm">
    <div class="container-fluid py-3">
        <div class="d-flex align-items-center ps-3">
            <h3 class="m-0">
                <i class="fa-solid fa-store"></i> ARIF - MOTOR
            </h3>
        </div>
    </div>
</header>

<!-- 🔙 TOMBOL KEMBALI -->
<div class="position-absolute mt-5 ms-3" style="top: 70px;">
    <a href="{{ url('/dashboard') }}" class="btn btn-outline-success">
        <i class="fa-solid fa-arrow-left"></i> Kembali
    </a>
</div>

<!-- 🔹 CONTENT -->
<main class="flex-grow-1 d-flex justify-content-center align-items-center">
    <div class="container mt-5 pt-5">
        <div class="card p-4">
            <h2 class="text-center text-success mb-4">
                <i class="fa-solid fa-box"></i> Daftar Produk
            </h2>

            <div class="mb-3 d-flex justify-content-between align-items-center flex-wrap gap-2">
                <a href="{{ route('products.create') }}" class="btn btn-success">
                    <i class="fa-solid fa-plus"></i> Tambah Produk
                </a>

                <!-- 🔍 SEARCH -->
                <form action="{{ route('products.index') }}" method="GET" class="d-flex">
                    <input type="text" name="search" class="form-control form-control-sm me-2" placeholder="Cari produk..." value="{{ request('search') }}">
                    <button type="submit" class="btn btn-outline-success btn-sm me-2">
                        <i class="fa-solid fa-magnifying-glass"></i>
                    </button>
                    @if(request('search'))
                        <a href="{{ route('products.index') }}" class="btn btn-outline-secondary btn-sm">
                            <i class="fa-solid fa-rotate-left"></i>
                        </a>
                    @endif
                </form>
                
            </div>

            @if(session('success'))
                <div class="alert alert-success">
                    {{ session('success') }}
                </div>
            @endif

            <div class="table-responsive">
                <table class="table table-bordered text-center">
                    <thead class="table-success">
                        <tr>
                            <th>Nama</th>
                            <th>Brand</th>
                            <th>Jenis</th>
                            <th>Stok</th>
                            <th>Harga</th>
                            <th>Gambar</th>
                            <th>Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($products as $product)
                            <tr>
                                <td>{{ $product->name }}</td>
                                <td>{{ $product->brand }}</td>
                                <td>{{ $product->type }}</td>
                                <td>{{ $product->stock }}</td>
                                <td>Rp {{ number_format($product->price, 0, ',', '.') }}</td>
                                <td>
                                    @if($product->image)
                                        <img src="{{ asset('images/' . $product->image) }}" alt="{{ $product->name }}" class="img-thumbnail" style="width: 80px;">
                                    @else
                                        <span class="text-muted">Tidak ada gambar</span>
                                    @endif
                                </td>
                                <td>
                                    <a href="{{ route('products.edit', $product->id) }}" class="btn btn-warning btn-sm">
                                        <i class="fa-solid fa-pen-to-square"></i> Edit
                                    </a>
                                    <form action="{{ route('products.destroy', $product->id) }}" method="POST" class="d-inline">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('Yakin ingin hapus?')">
                                            <i class="fa-solid fa-trash"></i> Hapus
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</main>

<!-- 🔹 FOOTER -->
<footer class="bg-success text-white text-center py-3 mt-auto">
    <p class="mb-0">&copy; 2025 ARIF-MOTOR | kelompok 5</p>
</footer>

<!-- Bootstrap Script -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
