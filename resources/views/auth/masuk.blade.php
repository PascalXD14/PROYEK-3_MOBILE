<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Login | ARIF MOTOR</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- Bootstrap 5 CDN -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>

<div class="container-fluid vh-100">
    <div class="row h-100">
        <!-- Kiri: Logo dan Deskripsi -->
        <div class="col-md-6 d-flex flex-column justify-content-center align-items-start bg-success text-white p-5">
            <h1 class="fw-bold">ARIF MOTOR</h1>
            <p class="mt-2">| Belanja Sparepart dan Layanan Service Online</p>
        </div>

        <!-- Kanan: Form Login -->
        <div class="col-md-6 d-flex flex-column justify-content-center align-items-center">
            <div class="w-75">
                <h3 class="text-center text-success mb-4 fw-bold">MASUK</h3>
                <form action="{{ route('masuk') }}" method="POST">
                    @csrf
                    <div class="mb-3">
                        <label for="name" class="form-label">Username</label>
                        <input type="text" class="form-control border-success" id="name" name="name" required>
                    </div>

                    <div class="mb-4">
                        <label for="password" class="form-label">Password</label>
                        <input type="password" class="form-control border-success" id="password" name="password" required>
                    </div>

                    <div class="d-flex justify-content-between">
                        <a href= "" class="btn btn-outline-success">Daftar Akun</a>
                        <button type="submit" class="btn btn-success">Masuk</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- Bootstrap JS Bundle -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

</body>
</html>
