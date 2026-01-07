<?php
// This will help you see errors if they exist
error_reporting(E_ALL);
ini_set('display_errors', 1);
?>
<html>
<head>
    <title>Log Masuk</title>
</head>
<body>
    <table border="1"> <tr>
            <td style="background-color:#00FF00;" align="center">Selamat Datang</td>
            <td style="background-color:#00FF00;" align="center">Log Masuk</td>
        </tr>
        <tr>
             <td>
                <img src="LogoKelab.png" style="width: 150px" alt="Logo Missing">
             </td>
            <td width="60%">
                <form action="ProsesMasuk.php" method="POST">
                    <table>
                        <tr>
                            <td>Nama Pengguna</td>
                            <td><input name="namapengguna" size="10" type="text" required></td>
                        </tr>
                        <tr>
                            <td>Katalaluan</td>
                            <td><input name="katalaluan" size="15" type="password" required></td>
                        </tr>
                        <tr>
                            <td><input name="submit" value="Masuk" type="submit"></td>
                        </tr>
                    </table>
                </form>
            </td>
        </tr>
    </table>
</body>
</html>