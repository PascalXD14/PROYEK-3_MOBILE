<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Edit Produk</title>

    <!-- Bootstrap & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet">
</head>
<body class="bg-light d-flex flex-column min-vh-100">

<!-- Header -->
<nav class="navbar navbar-dark bg-success shadow-sm">
    <div class="d-flex align-items-center px-3">
        <a class="navbar-brand fw-bold m-0" href="#">
            <i class="bi bi-tools"></i> Edit Produk
        </a>
    </div>
</nav>


<!-- Content -->
<div class="container d-flex justify-content-center align-items-center mt-4 flex-grow-1">
    <div class="card shadow-sm border-0 rounded w-100" style="max-width: 800px;">
        <div class="card-body">
            <h5 class="text-center text-success fw-bold mb-3">Form Edit Produk</h5>
            <hr class="mb-4">

            @if ($errors->any())
                <div class="alert alert-danger py-2 px-3">
                    <ul class="mb-0 small">
                        @foreach ($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <form action="{{ route('products.update', $product->id) }}" method="POST" enctype="multipart/form-data">
                @csrf
                @method('PUT')

                <div class="row">
                    <!-- Kiri -->
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label class="form-label">Nama</label>
                            <input type="text" name="name" class="form-control form-control-sm" value="{{ $product->name }}">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Brand</label>
                            <input type="text" name="brand" class="form-control form-control-sm" value="{{ $product->brand }}">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Jenis</label>
                            <input type="text" name="type" class="form-control form-control-sm" value="{{ $product->type }}">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Deskripsi</label>
                            <textarea name="description" class="form-control form-control-sm" rows="3">{{ $product->description }}</textarea>
                        </div>
                    </div>

                    <!-- Kanan -->
                    <div class="col-md-6">
                        <div class="mb-3">
                            <label class="form-label">Stok</label>
                            <input type="number" name="stock" class="form-control form-control-sm" value="{{ $product->stock }}">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Harga</label>
                            <input type="number" name="price" class="form-control form-control-sm" value="{{ $product->price }}">
                        </div>

                        @if ($product->image)
                            <div class="mb-3">
                                <label class="form-label">Gambar Saat Ini</label><br>
                                <img src="{{ asset('images/' . $product->image) }}" alt="{{ $product->name }}" class="img-thumbnail" style="width: 100px;">
                            </div>
                        @endif

                        <div class="mb-3">
                            <label class="form-label">Gambar (opsional)</label>
                            <input type="file" name="image" class="form-control form-control-sm">
                        </div>
                    </div>
                </div>

                <!-- Tombol -->
                <div class="d-flex justify-content-between mt-3">
                    <a href="{{ route('products.index') }}" class="btn btn-sm btn-secondary">
                        <i class="bi bi-arrow-left"></i> Kembali
                    </a>
                    <button type="submit" class="btn btn-sm btn-success">
                        <i class="bi bi-save"></i> Update
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Footer -->
<footer class="bg-success text-white text-center py-2 mt-auto">
    <small>&copy; 2025 SPARE-M | Kelompok 5</small>
</footer>

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
