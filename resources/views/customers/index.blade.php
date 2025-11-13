<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daftar Pelanggan | ARIF-MOTOR</title>

    <!-- Bootstrap & Font Awesome -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
    <style>
        .back-button {
            position: absolute;
            top: 100px;
            left: 20px;
            z-index: 10;
        }
    </style>
</head>
<body class="d-flex flex-column min-vh-100">

    <!-- Header -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-success shadow-sm fixed-top">
        <div class="container-fluid">
            <a class="navbar-brand fw-bold" href="#">ARIF-MOTOR</a>
        </div>
    </nav>

    <!-- Tombol Kembali -->
    <a href="{{ route('dashboard') }}" class="btn btn-outline-success back-button">
        <i class="fa-solid fa-arrow-left"></i> Dashboard
    </a>

    <!-- Main content: Perubahan hanya pada container agar card selalu di tengah -->
    <div class="container flex-grow-1 d-flex justify-content-center align-items-center">
        <div class="w-100" style="max-width: 1000px;">

            <div class="card shadow-lg position-relative">
                <div class="card-body">

                    <!-- Header atas dalam card -->
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <a href="{{ route('customers.create') }}" class="btn btn-success">
                            <i class="fa-solid fa-user-plus"></i> Tambah Pelanggan
                        </a>
                    
                        <form action="{{ route('customers.index') }}" method="GET" class="d-flex">
                            <input type="text" name="search" class="form-control form-control-sm me-2" placeholder="Cari produk..." value="{{ request('search') }}">
                            <button type="submit" class="btn btn-outline-success btn-sm me-2">
                                <i class="fa-solid fa-magnifying-glass"></i>
                            </button>
                            @if(request('search'))
                                <a href="{{ route('customers.index') }}" class="btn btn-outline-secondary btn-sm">
                                    <i class="fa-solid fa-rotate-left"></i>
                                </a>
                            @endif
                        </form>
                    </div>
                    
                    <h3 class="text-success text-center mb-4">
                        <i class="fa-solid fa-users"></i> Daftar Pelanggan
                    </h3><br>

                    @if(session('success'))
                        <div class="alert alert-success">
                            {{ session('success') }}
                        </div>
                    @endif

                    <div class="table-responsive">
                        <table class="table table-bordered align-middle">
                            <thead class="table-success">
                                <tr>
                                    <th>ID</th>
                                    <th>Nama</th>
                                    <th>Alamat</th>
                                    <th>Nomor Telepon</th>
                                    <th>Jenis Kelamin</th>
                                    <th class="text-center" style="width: 160px;">Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse ($customers as $customer)
                                    <tr>
                                        <td>{{ $customer->id }}</td>
                                        <td>{{ $customer->name }}</td>
                                        <td>{{ $customer->address }}</td>
                                        <td>{{ $customer->phone }}</td>
                                        <td>{{ ucfirst($customer->gender) }}</td>
                                        <td class="text-center">
                                            <a href="{{ route('customers.edit', $customer->id) }}" class="btn btn-warning btn-sm">
                                                <i class="fa-solid fa-pen-to-square"></i> Edit
                                            </a>
                                            <form action="{{ route('customers.destroy', $customer->id) }}" method="POST" style="display:inline-block;" onsubmit="return confirm('Yakin ingin menghapus pelanggan ini?')">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" class="btn btn-danger btn-sm">
                                                    <i class="fa-solid fa-trash"></i> Hapus
                                                </button>
                                            </form>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="6" class="text-center">Tidak ada data pelanggan.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>

                </div>
            </div>
        </div>
    </div>

    <!-- Footer -->
    <footer class="bg-success text-white text-center py-3 mt-auto">
        © 2025 ARIF-MOTOR | Kelompok 5
    </footer>

    <!-- Bootstrap Script -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

</body>
</html>
