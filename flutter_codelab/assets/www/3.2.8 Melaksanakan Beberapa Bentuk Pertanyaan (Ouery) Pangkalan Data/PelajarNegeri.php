<body>
<?php
    $namaNegeri = $_POST["Negeri"];
    $con = mysqli_connect("localhost","root","");
    
    if (!$con) {
        die('Sambungan kepada Pangkalan Data Gagal'.mysqli_connect_error());
    }
    
    mysqli_select_db($con,"dbsekolah");
    
    print "<h3>Senarai Nama Murid Berdasarkan Negeri Kelahiran</h3>";
    print "<h3>Negeri : ".$namaNegeri."</h3>";
    print "<table border = '1'>";
    print "<tr>";
    print "<th>No Murid</th>";
    print "<th>Nama</th>";
    print "<th>Kelas</th>";
    print "</tr>";
    
    $sql = "SELECT * FROM MURID WHERE NEGERILAHIR = '".$namaNegeri."'";
    echo $sql;
    
    $result = mysqli_query($con,$sql);
    
    while ($row = mysqli_fetch_array($result)) {
        $nomurid = $row['NOMURID'];
        $nama = $row['NAMA'];
        $kelas = $row['KELAS'];
        
        print "<tr>";
        print "<td>".$nomurid."</td>";
        print "<td>".$nama."</td>";
        print "<td>".$kelas."</td>";
        print "</tr>";
    }
    
    print "</table>";
?>
<?php
    mysqli_close($con);
?>
</body>