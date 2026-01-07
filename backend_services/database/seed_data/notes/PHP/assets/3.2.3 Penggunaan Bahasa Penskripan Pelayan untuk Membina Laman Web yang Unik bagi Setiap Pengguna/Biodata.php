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
            $f = fopen("Biodata.txt","r");
            $valid = false;
            print "<table>";
            while (!feof($f))
            {
                $medan = explode(',', fgets($f));
                $user = $medan[0];
                $pass = $medan[1];
                $namapenuh = $medan[2];
                $kelas = $medan[3];
                $jantina = $medan[4];
                $negeri = $medan[5];

                if (strcmp($nama, $user) == 0)
                {
                    if (strcmp($katalaluan, $pass) == 0)
                    {
                        print "<tr>";
                        print "<td>NAMA</td>";
                        print "<td>".$namapenuh."</td>";
                        print "</tr>";
                        print "<tr>";
                        print "<td>KELAS</td>";
                        print "<td>".$kelas."</td>";
                        print "</tr>";
                        print "<tr>";
                        print "<td>JANTINA</td>";
                        print "<td>".$jantina."</td>";
                        print "</tr>";
                        print "<tr>";
                        print "<td>NEGERI LAHIR</td>";
                        print "<td>".$negeri."</td>";
                        print "</tr>";
                        $jumpa = True;
                        break;
                    }
                }
            } //penamat while
            print "</table>";

            if ($jumpa != True)
            {
                print "Rekod Tidak Dijumpai";
            }
            fclose($f); //menutup fail teks
        ?>
    </body>
</html>