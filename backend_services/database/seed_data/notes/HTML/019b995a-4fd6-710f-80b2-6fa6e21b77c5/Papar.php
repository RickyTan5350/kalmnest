<html>
  <head>
    <title>Papar Rekod</title>
  </head>
  <body>
  <?php
    $nomurid = $_POST['nomurid'];
    $con = mysqli_connect("localhost", "root", "");
    
    if (!$con) {
      die('Sambungan kepada Pangkalan Data Gagal: ' . mysqli_connect_error());
    }

    mysqli_select_db($con, "dbpelajar");

    // 1. Updated 'NOMURID' to 'id' to match your phpMyAdmin screenshot
    $hasil = mysqli_query($con, "SELECT * FROM murid WHERE id = '".$nomurid."'");
    $row = mysqli_fetch_array($hasil);

    // 2. Updated array keys to lowercase to match database columns
    $nama = $row ? htmlspecialchars($row['nama'], ENT_QUOTES) : "";
    $kelas = $row ? htmlspecialchars($row['kelas'], ENT_QUOTES) : "";
    $negeri = $row ? htmlspecialchars($row['negeri'], ENT_QUOTES) : "";
  ?>

  <h2>Hasil Carian</h2>
  <form>
    <p>No Murid: <input type="text" value="<?php echo $nomurid; ?>" disabled></p>
    <p>Nama Murid: <input type="text" value="<?php echo $nama; ?>" disabled></p>
    <p>Kelas: <input type="text" value="<?php echo $kelas; ?>" disabled></p>
    <p>Negeri: <input type="text" value="<?php echo $negeri; ?>" disabled></p>
  </form>

  <a href="Cari.php">Cari Lagi</a>
  </body>
</html>