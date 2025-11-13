<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tambah Produk</title>

    <!-- Bootstrap & Font Awesome -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
</head>
<body class="bg-light d-flex flex-column min-vh-100">

    <div class="bg-success text-white py-2 px-3 fs-6 fw-bold">ARIF-M</div>

    <div class="container d-flex justify-content-center align-items-center flex-grow-1">
        <div class="card p-2 shadow-sm" style="max-width: 360px; width: 100%;">
            <h6 class="text-center text-success mb-2"><i class="fa fa-box"></i> Tambah Produk</h6>

            @if ($errors->any())
                <div class="alert alert-danger p-2 mb-2">
                    <ul class="mb-0 small">
                        @foreach ($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <form action="{{ route('products.store') }}" method="POST" enctype="multipart/form-data">
                @csrf

                <input type="text" name="name" class="form-control form-control-sm mb-1" placeholder="Nama" value="{{ old('name') }}">
                <input type="text" name="brand" class="form-control form-control-sm mb-1" placeholder="Brand" value="{{ old('brand') }}">
                <input type="text" name="type" class="form-control form-control-sm mb-1" placeholder="Jenis" value="{{ old('type') }}">
                <input type="text" name="description" class="form-control form-control-sm mb-1" placeholder="Deskripsi" value="{{ old('description') }}">
                <input type="number" name="stock" class="form-control form-control-sm mb-1" placeholder="Stok" value="{{ old('stock') }}">
                <input type="number" name="price" class="form-control form-control-sm mb-1" placeholder="Harga" value="{{ old('price') }}">
                <input type="file" name="image" class="form-control form-control-sm mb-2">

                <div class="d-flex justify-content-between">
                    <a href="{{ route('products.index') }}" class="btn btn-sm btn-secondary">
                        <i class="fa fa-arrow-left"></i>
                    </a>
                    <button type="submit" class="btn btn-sm btn-success">
                        <i class="fa fa-save"></i>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <footer class="bg-success text-white text-center py-1 small mt-auto">
        ©2025 | ARIF-M | KELOMPOK 5
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
