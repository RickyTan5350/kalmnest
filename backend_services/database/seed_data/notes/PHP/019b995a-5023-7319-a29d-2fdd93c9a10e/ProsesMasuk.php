<?php
if (file_exists("setup_db.php")) {
    include "setup_db.php";
} else {
    include "../../setup_db.php";
}
$con = $conn;

if ($con->connect_error) {
    die("Connection failed: " . $con->connect_error);
}
// setup_db.php already selects 'dbPelajar'

$namapengguna = $_POST['namapengguna'];
$katalaluan = $_POST['katalaluan'];

$rekod = mysqli_query($con, "SELECT * FROM PENGGUNA WHERE NAMAPENGGUNA = '$namapengguna' AND KATALALUAN = '$katalaluan'");
$hasil = mysqli_num_rows($rekod);

if ($hasil > 0) {
    header("location:Masuk.php?namapengguna=" . $namapengguna);
} else {
    header("location:LogMasuk.php"); // Kembali ke laman log masuk jika gagal
}
?>