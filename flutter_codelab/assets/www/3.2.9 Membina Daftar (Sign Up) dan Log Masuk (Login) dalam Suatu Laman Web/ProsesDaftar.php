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
$jenis = $_POST['jenis'];

$sql = "INSERT INTO PENGGUNA (NAMAPENGGUNA, KATALALUAN, JENISPENGGUNA) 
        VALUES ('$namapengguna', '$katalaluan', '$jenis')";

$result = mysqli_query($con, $sql);

// Redirect to login page or admin page after registration
header('location:LogMasuk.php'); 
mysqli_close($con);
?>