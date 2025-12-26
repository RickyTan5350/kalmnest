### 3.2.4 Penggunaan Data yang Diimport daripada Fail Teks untuk Menyelesaikan Masalah

Bahagian ini menerangkan cara memproses data yang banyak menggunakan fail teks (.txt) dan PHP, tanpa perlu memasukkan data satu persatu secara manual.

#### **Kelebihan Menggunakan Fail Teks**

* Memudahkan pemprosesan atau manipulasi data yang banyak.  
* Data disimpan dalam fail (contoh: Notepad) dan boleh diproses terus oleh laman web untuk mencari jumlah, purata, dan sebagainya.  
* Format fail: Data biasanya dipisahkan dengan tanda koma (contoh: `10, 30, 32, 67`).

#### **Fungsi Penting PHP untuk Fail Teks**

Berikut adalah fungsi-fungsi utama yang digunakan dalam atur cara:
```
<?php
  $f = fopen("Nombor.txt","r"); 
  while (!feof($f)) 
  {
    $arrNombor = explode(',',fgets($f)); 
  }
  $bilangan = count($arrNombor); 
  $jumlah = 0;
  for ($x = 0;$x < $bilangan; $x++) 
  {
    print $arrNombor[$x]."<br>"; 
    $jumlah = $jumlah + $arrNombor[$x];
  }
  $purata = $jumlah / $bilangan;
  print "Jumlah = ".$jumlah."<br>";
  print "Nilai Purata = ".$purata."<br>";
  // tutup fail yang telah dibuka
  fclose($f); 
?> //penamat untuk php
```
* **`fopen("NamaFail.txt", "r")`**: Membuka fail teks untuk dibaca (`r` bermaksud *read*).  
* **`feof($f)`**: *End-of-file*. Digunakan dalam gelung (loop) untuk memastikan program membaca data sehingga penghujung fail.  
* **`fgets($f)`**: Membaca baris teks daripada fail.  
* **`explode(separator, string)`**: Memisahkan satu baris teks menjadi beberapa bahagian berdasarkan pemisah (contohnya koma) dan menyimpannya ke dalam tatasusunan (array).  
  * *Contoh:* Teks "Johor, Johor Bahru" dipisahkan menjadi elemen array \[0\]="Johor" dan \[1\]="Johor Bahru".  
* **`count($array)`**: Mengira bilangan elemen dalam tatasusunan.  
* **`fclose($f)`**: Menutup fail teks yang telah dibuka setelah selesai digunakan.

---

### **2\. Contoh Aplikasi Pengaturcaraan**

#### **Contoh 1: Mengira Nilai Purata Nombor**
```
<html>
    <head>
        <title>Senarai Gred Markah</title>
    </head>
    <body>
    <p>Senarai Markah dan Gred</p>
    <?php
        //membuka fail untuk membaca kandungan fail
        $f = fopen("Matematik.txt","r");
        $valid = false; // menilaiwalkan dengan nilai false
        print "<table>";
        print "<th align = 'left' width = '130'>Nama Murid</th>";
        print "<th align = 'center'>Markah</th>";
        print "<th align = 'center'>Gred</th>";
        
        while (!feof($f) )
        {
            $medan = explode (',',fgets($f));
            $nama = $medan[0];
            $markah = $medan[1];
            
            //tentukan gred markah bermula disini
            if ($markah >= 80)
            {
                $gred = "A";
            } elseif ($markah >= 70)
            {
                $gred = "B";
            } elseif ($markah >= 60 )
            {
                $gred = "C";
            } elseif ($markah >= 50)
            {
                $gred = "D";
            } else
            {
                $gred = "E";
            }
            
            print "<tr>";
            print "<td>".$nama."</td>";
            print "<td align = 'center'>".$markah."</td>";
            print "<td align = 'center'>".$gred."</td>";
            print "</tr>";
        } // penamat untuk while
        
        print "</table>";
        fclose($f); // menutup fail yang telah dibuka
    ?> 
    </body>
</html>
```
* **Input:** Fail `Nombor.txt` yang mengandungi senarai nombor (cth: 10, 30, 32...).  
* **Proses:**  
  1. Buka fail `Nombor.txt`.  
  2. Baca setiap nombor dan simpan dalam array menggunakan `explode`.  
  3. Gunakan gelung (loop) untuk menjumlahkan semua nombor.  
  4. Kira purata: `Jumlah / Bilangan`.  
* **Output:** Memaparkan senarai nombor, jumlah keseluruhan, dan nilai purata.

#### **Contoh 2: Menentukan Gred Markah Murid**

* **Input:** Fail `Matematik.txt` yang mengandungi nama murid dan markah (cth: `Norlini,78`).  
* **Syarat Gred:**  
  1. 80 \- 100: **A**  
  2. 70 \- 79: **B**  
  3. 60 \- 69: **C**  
  4. 50 \- 59: **D**  
  5. 0 \- 49: **E**.  
* **Proses:**  
  1. Buka fail dan baca data baris demi baris.  
  2. Pecahkan data kepada **Nama** (`$medan[0]`) dan **Markah** (`$medan[1]`) menggunakan `explode`.  
  3. Gunakan struktur kawalan `if...elseif...else` untuk menentukan gred berdasarkan markah.  
* **Output:** Memaparkan jadual yang mengandungi Nama Murid, Markah, dan Gred.

---



* Dalam senario aktiviti, laman web perlu merekodkan maklumat pengguna dan kata laluan.  
* Borang (Form) digunakan dengan kotak teks untuk 'namapengguna' dan 'katalaluan'.  
* Kotak teks kata laluan akan memaparkan simbol `*` untuk keselamatan.