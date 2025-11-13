<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ARIF-MOTOR | Dashboard</title>

    <!-- Bootstrap CSS & FontAwesome -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
</head>
<body style="background-color: #e5f0e5;">

    <!-- Sidebar -->
    <div class="d-flex">
        <div id="sidebar" class="bg-success text-white p-3 position-fixed top-0 start-0 vh-100" 
                style="width: 260px; transform: translateX(-100%); transition: transform 0.3s; z-index: 1060;">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h2 class="h5 fw-bold">ARIF-MOTOR</h2>
                <button id="closeSidebar" class="btn btn-sm btn-light text-success">
                    <i class="fa-solid fa-arrow-left"></i>
                </button>
            </div>
            <ul class="nav flex-column gap-2">
                <li class="nav-item">
                    <a href="{{ route('customers.index') }}" class="btn btn-success text-start w-100">
                        <i class="fa-solid fa-users me-2"></i> Kelola Pelanggan
                    </a>
                </li>

                <li class="nav-item">
                    <a href="{{ route('products.index') }}" class="btn btn-success text-start w-100">
                        <i class="fa-solid fa-box me-2"></i> Kelola Produk
                    </a>
                </li>                
                
                {{-- 
                <li class="nav-item">
                    <a href="{{ route('pesanan.index') }}" class="btn btn-success text-start w-100">
                        <i class="fa-solid fa-shopping-cart me-2"></i> Manage Orders
                    </a>
                </li>
                --}}
            </ul>
        </div>

        <!-- Main Content -->
        <div class="flex-grow-1" style="margin-left: 0;" id="mainContent">
            <!-- Navbar -->
            <nav class="navbar navbar-expand-lg navbar-dark bg-success px-3 position-sticky top-0" style="z-index: 1050;">
                <button id="toggleSidebar" class="btn btn-outline-light me-2">
                    <i class="fa-solid fa-bars"></i>
                </button>
                <div class="navbar-brand fw-bold">Dashboard Admin</div>
                <div class="ms-auto">
                    <button class="btn btn-danger" data-bs-toggle="modal" data-bs-target="#logoutModal">
                        <i class="fa-solid fa-sign-out-alt me-1"></i> Logout
                    </button>
                </div>
            </nav>

            <div class="container mt-4">
                <div class="card shadow text-center">
                    <div class="card-body">
                        <h2 class="card-title text-success fw-bold">Selamat Datang <strong>{{ Auth::user()->name }}</strong>!</h2>
                        <p class="mt-3 fs-5 text-muted">Segala kelola ada disini</p>

                        <div class="row mt-4 justify-content-center">
                            <!-- Total Customer -->
                            <div class="col-md-4">
                                <div class="card text-white bg-success mb-3 shadow">
                                    <div class="card-body">
                                        <i class="fa-solid fa-users fa-2x"></i>
                                        <p class="mt-2 mb-1">Total Customers</p>
                                        <h3 class="fw-bold">{{ $totalPelanggan }}</h3>
                                    </div>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="card text-white bg-success mb-3 shadow">
                                    <div class="card-body">
                                        <i class="fa-solid fa-box fa-2x"></i>
                                        <p class="mt-2 mb-1">Total Products</p>
                                        <h3 class="fw-bold">{{ $totalProduk }}</h3>
                                    </div>
                                </div>
                            </div>
                            
                            {{-- 
                            <div class="col-md-4">
                                <div class="card text-white bg-success mb-3 shadow">
                                    <div class="card-body">
                                        <i class="fa-solid fa-shopping-cart fa-2x"></i>
                                        <p class="mt-2 mb-1">Total Orders</p>
                                        <h3 class="fw-bold">{{ $totalPesanan }}</h3>
                                    </div>
                                </div>
                            </div>
                            --}}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal Logout -->
    <div class="modal fade" id="logoutModal" tabindex="-1" aria-labelledby="logoutModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Konfirmasi Logout</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body text-center">
                    <p class="fs-5">Apakah Anda yakin ingin logout?</p>
                </div>
                <div class="modal-footer justify-content-center">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                    <form id="logout-form" action="{{ route('logout') }}" method="POST">
                        @csrf
                        <button type="submit" class="btn btn-danger">Ya, Logout</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS (Wajib Jangan Dihapus) -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <!-- Sidebar Script -->
    <script>
        const sidebar = document.getElementById("sidebar");
        const toggleSidebar = document.getElementById("toggleSidebar");
        const closeSidebar = document.getElementById("closeSidebar");

        toggleSidebar.addEventListener("click", () => {
            sidebar.style.transform = "translateX(0)";
        });

        closeSidebar.addEventListener("click", () => {
            sidebar.style.transform = "translateX(-100%)";
        });

        document.addEventListener("click", function(event) {
            if (!sidebar.contains(event.target) && !toggleSidebar.contains(event.target)) {
                sidebar.style.transform = "translateX(-100%)";
            }
        });
    </script>

    
</body>
</html>
