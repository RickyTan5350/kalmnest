<?php
    $nama = $_GET['namapengguna'];
?>
<html>
<head>
    <title>Laman Utama</title>
</head>
<body>
    <table border="1">
        <tr>
            <td style="background-color:#00FF00;" align="center">Selamat Datang</td>
            <td colspan="2" style="background-color:#00FF00;" align="left">
                Nama Pengguna: <?php print $nama; ?>
            </td>
        </tr>
        <tr>
            <td width="40%"><img src="LogoKelab.png" style="width: 150px"></td>
            <td colspan="2" valign="top"></td>
        </tr>
        <tr>
            <td colspan="2" align="right">
                <a href="KelabCatur.php">Log Keluar</a>
            </td>
        </tr>
    </table>
</body>
</html>