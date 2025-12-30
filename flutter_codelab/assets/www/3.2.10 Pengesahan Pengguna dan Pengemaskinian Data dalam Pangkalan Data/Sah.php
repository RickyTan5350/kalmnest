<?php
session_start();


?>
<!DOCTYPE html>
<html>
<head>
    <title>Laman Utama</title>
    <style>
        .banner { background-color: #4CAF50; color: white; text-align: center; font-size: 12px; width: 400px; }
        .box { border: 2px solid #888; width: 400px; text-align: center; margin-top: 10px; padding: 20px 0; }
        h1 { margin: 0; padding: 0; }
    </style>
</head>
<body>
    <div class="banner">Selamat Datang</div>
    
    <?php if (isset($_SESSION['PenggunaSah']) && $_SESSION['PenggunaSah'] == 1): ?>
        <div class="box">
            <h1>Tahniah!!</h1>
            <hr>
            <h2>Anda Pengguna Yang Sah</h2>
        </div>
    <?php else: ?>
        <div class="box">
            <h1>Maaf</h1>
            <hr>
            <h2>Anda Pengguna Tidak Sah</h2>
        </div>
    <?php endif; ?>

    <br>
    <a href="Pengesahan.php">Kembali ke Login</a>
</body>
</html>