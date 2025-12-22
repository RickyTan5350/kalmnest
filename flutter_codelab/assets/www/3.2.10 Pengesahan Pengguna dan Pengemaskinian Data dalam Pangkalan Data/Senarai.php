<html>
<head>
    <title>Senarai Maklumat Murid</title>
</head>
<body>
    <p>Senarai Maklumat Murid</p>
    <?php
    // 1. Establish connection
    $con = mysqli_connect("localhost", "root", "");
    if (!$con) {
        die('Sambungan kepada Pangkalan Data Gagal.' . mysqli_connect_error());
    }
    
    // 2. Select database (Using lowercase 'dbpelajar' from your screenshot)
    mysqli_select_db($con, "dbpelajar"); 

    print "<table border='1'>";
    print "<tr>";
    print "<th>No Murid</th>";
    print "<th>Nama</th>";
    print "<th>Kelas</th>";
    print "<th>Negeri Kelahiran</th>";
    print "<th>Tindakan</th>";
    print "</tr>";

    // 3. Query the 'murid' table
    $hasil = mysqli_query($con, "SELECT * FROM murid");

    while($row = mysqli_fetch_array($hasil)) {
        // 4. Map variables to lowercase columns from your database
        $nomurid = $row['id'];
        $nama = $row['nama'];
        $kelas = $row['kelas'];
        $negeri = $row['negeri'];
        
        // 5. Link to KemasKini.php using 'nomurid' as the key
        $lnk = "<a href='KemasKini.php?nomurid=" . urlencode($nomurid) . "'>Kemaskini</a>";
        
        print "<tr>";
        print "<td>$nomurid</td>";
        print "<td>$nama</td>";
        print "<td>$kelas</td>";
        print "<td>$negeri</td>";
        print "<td>$lnk <br><small style='font-size:10px; color:gray;'>($nomurid)</small></td>";
        print "</tr>";
    }
    print "</table>";
    mysqli_close($con);
    ?>
</body>
</html>