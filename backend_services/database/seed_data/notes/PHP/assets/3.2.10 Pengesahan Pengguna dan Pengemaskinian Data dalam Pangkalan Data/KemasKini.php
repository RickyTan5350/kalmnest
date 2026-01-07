<html>
<head>
    <title>Kemaskini Maklumat Murid</title>
</head>
<body>
<?php
    // 1. Establish connection
    $con = mysqli_connect("localhost", "root", "");
    if (!$con) {
        die('Sambungan kepada Pangkalan Data Gagal: ' . mysqli_connect_error());
    }
    
    // 2. Select database (Matches your screenshot)
    mysqli_select_db($con, "dbpelajar"); 

    // 3. Check for the 'nomurid' key sent from Senarai.php
    echo "<pre>DEBUG GET (KemasKini): "; print_r($_GET); echo "</pre>";
    if (isset($_GET['nomurid'])) {
        $noM = $_GET['nomurid'];
        
        // 4. Fetch specific student record using 'id' column
        $sql = "SELECT * FROM murid WHERE id = '$noM'";
        $result = mysqli_query($con, $sql);
        $row = mysqli_fetch_array($result);

        // 5. Handle potential empty results to avoid "null" errors
        if ($row) {
            $nama = htmlspecialchars($row['nama'], ENT_QUOTES); 
            $kelas = $row['kelas'];
            $negeri = $row['negeri'];
        } else {
            die("Ralat: Rekod murid dengan ID '$noM' tidak dijumpai.");
        }
    } else {
        die("Ralat: ID murid tidak diterima dari senarai. Sila pastikan anda klik dari halaman Senarai.php.");
    }
?>

    <form action="ProsesKemasKini.php" method="POST">
        <p>No Murid : <b><?php echo $noM; ?></b></p>
        
        <input type="hidden" name="nomurid" value='<?php echo $noM; ?>'>
        
        <p>Nama Murid: 
            <input name="nama" type="text" value='<?php echo $nama; ?>'>
        </p>
        <p>Kelas: 
            <input name="kelas" type="text" size="15" value='<?php echo $kelas; ?>'> 
        </p>
        <p>Negeri Kelahiran: 
            <input name="negeri" type="text" size="20" value='<?php echo $negeri; ?>'>
        </p>
        <p><input type="submit" value="Kemaskini"></p>
    </form>
</body>
</html>