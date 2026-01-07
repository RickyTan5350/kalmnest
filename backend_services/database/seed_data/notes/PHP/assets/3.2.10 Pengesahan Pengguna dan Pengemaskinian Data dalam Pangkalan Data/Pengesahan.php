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

<!DOCTYPE html>
<html>
<head>
    <title>Pengesahan Pengguna</title>
    <style>
        .header { background-color: #4CAF50; color: black; text-align: center; padding: 5px; width: 350px; }
        .form-container { font-family: Arial; margin-top: 10px; }
    </style>
</head>
<body>
    <div class="header">Pengesahan Pengguna</div>
    <div class="form-container">
        <form method="POST" action="Pengesahan.php">
            <table>
                <tr>
                    <td>Nama Pengguna</td>
                    <td><input type="text" name="namapengguna"></td>
                </tr>
                <tr>
                    <td>Katalaluan</td>
                    <td><input type="password" name="katalaluan"></td>
                </tr>
                <tr>
                    <td><button type="submit">Sahkan</button></td>
                </tr>
            </table>
        </form>
    </div>
</body>
</html>