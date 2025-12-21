<?php
$con = mysqli_connect("localhost","root","");
if (!$con)
{
    die('Sambungan kepada Pangkalan Data Gagal'.mysqli_connect_error());
}
mysqli_select_db($con,"dbsekolah");
$namapengguna = $_POST['namapengguna'];
$katalaluan = $_POST['katalaluan'];
$jenis = $_POST['jenis'];
$sql = "INSERT INTO PENGGUNA (NAMAPENGGUNA, KATALALUAN, JENISPENGGUNA)
        VALUES ('$namapengguna', '$katalaluan', '$jenis')";
print $sql;
$result = mysqli_query($con,$sql);
header('location:Admin.php');
mysqli_close($con);
?>