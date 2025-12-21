<html>
<head>
    <title>Log Masuk</title>
    <?php
        $nama = $_POST['namapengguna'];
        $katalaluan = $_POST['katalaluan'];
        $jumpa = False;
    ?>
</head>
<body>
    <p>Biodata Murid</p>

 <?php
    $f = fopen("Biodata.txt","r"); // 1. Opens file for reading
    $valid = false;
    print "<table>";
    while (!feof($f)) // 2. Loops until end of file
    {
        $medan = explode (',', fgets ($f)); // 3. Splits line by comma
        
        $user = $medan[0];
        $pass = $medan[1];
        $namapenuh = $medan[2];
        $kelas = $medan[3];
        $jantina = $medan[4];
        $negeri = $medan[5];
        
        if (strcmp($nama,$user)==0) // 4. Compares username
        {
            if (strcmp($katalaluan,$pass)==0) // 5. Compares password
            {
                // Displays data in a table if matched
                print "<tr><td>NAMA</td><td>".$namapenuh."</td></tr>";
                print "<tr><td>KELAS</td><td>".$kelas."</td></tr>";
                print "<tr><td>JANTINA</td><td>".$jantina."</td></tr>";
                print "<tr><td>NEGERI LAHIR</td><td>".$negeri."</td></tr>";
                $jumpa = True;
                break;
            }
        }
    }
    print "</table>";
    if ($jumpa != True)
        print "Rekod Tidak Dijumpai";
    fclose ($f);
?>
</body>
</html>   
