<?php
session_start();

// Initialize session if not set
if (!isset($_SESSION['PenggunaSah'])) {
    $_SESSION['PenggunaSah'] = 0;
}

// 1. Connection to Database
$con = mysqli_connect("localhost", "root", "");

if (!$con) {
    die('Sambungan kepada Pangkalan Data Gagal: ' . mysqli_connect_error());
}

mysqli_select_db($con, "dbPelajar");

// 2. Logic to process form submission
if (isset($_POST['namapengguna'])) {
    $namapengguna = $_POST['namapengguna'];
    $katalaluan = $_POST['katalaluan'];

    $srekod = mysqli_query($con, "SELECT * FROM PENGGUNA WHERE NAMAPENGGUNA = '$namapengguna' AND KATALALUAN = '$katalaluan'");
    $shasil = mysqli_num_rows($srekod);

    if ($shasil > 0) {
    $_SESSION['PenggunaSah'] = 1;
    $_SESSION['nama'] = $namapengguna; // Passing name
    $_SESSION['pass'] = $katalaluan;   // Passing password
    header("Location: Sah.php");
    exit();

    } else {
        $_SESSION['PenggunaSah'] = 0;
        header("Location: Sah.php");
        exit();
    }
}
mysqli_close($con);
?>

