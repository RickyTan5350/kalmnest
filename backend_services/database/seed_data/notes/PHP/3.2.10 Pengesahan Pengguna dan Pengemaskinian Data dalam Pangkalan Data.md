## 3.2.10 Pengesahan Pengguna dan Pengemaskinian Data dalam Pangkalan Data

### **1\. Pengesahan Pengguna (User Verification)**

Pengesahan pengguna adalah ciri keselamatan penting dalam pembangunan laman web untuk melindungi pangkalan data.
```php:src=Pengesahan.php
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
```

* **Definisi & Tujuan:**  
  * Ia merupakan ciri keselamatan data yang menentukan capaian pengguna dalam laman web.  
  * Tujuannya adalah untuk membataskan pengguna daripada melakukan sebarang perubahan tanpa kebenaran ke atas pangkalan data.  
  * Peringkat pengguna yang berbeza (contoh: pekerja syarikat) mempunyai hak capaian yang berbeza.  
* **Keperluan:**  
  * Memerlukan satu jadual dalam pangkalan data yang menyimpan **nama pengguna** dan **kata laluan**.  
* **Proses Pengesahan:**  
  * **Input:** Pengguna memasukkan nama dan kata laluan pada laman `Pengesahan.php`.  
  * **Pemprosesan:** Fail `Sahkan.php` menyemak input tersebut dengan rekod dalam pangkalan data.  
  * **Keputusan:**  
    * Jika data **berpadanan**, pengguna berjaya masuk (status sah).  
    * Jika **tidak**, paparan ralat atau "Pengguna Tidak Sah" akan muncul.  
* **Penggunaan Kod:**  
  * Fungsi `session_start()` digunakan untuk memulakan sesi.  
  * Pemboleh ubah `$_SESSION['PenggunaSah']` digunakan untuk menetapkan status pengguna (0 untuk tidak sah, 1 untuk sah).

---

### **2\. Pengemaskinian Data (Updating Data)**

Proses mengemas kini rekod sedia ada dalam pangkalan data memerlukan langkah pencarian dan pemilihan rekod terlebih dahulu.
  2. **Pilih Rekod (`Kemaskini.php`):**  
     * Menerima ID murid menggunakan kaedah `$_GET['nomurid']`.  
     * Melakukan carian SQL (`SELECT * FROM MURID WHERE NOMURID =...`) untuk mendapatkan data terkini.  
     * Memaparkan borang yang telah diisi dengan data asal menggunakan atribut `value` dalam tag input.  


* **Aliran Proses:**  
  1. **Senaraikan Rekod (`Senarai.php`):**  
     * Memaparkan semua rekod dalam jadual (contoh: No Murid, Nama, Kelas).  
     * Setiap rekod mempunyai pautan "Kemaskini" yang menghantar ID unik (contoh: `nomurid`)melalui URL.  
```php:src=Senarai.php
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

```
  3. **Simpan Perubahan (`ProsesKemaskini.php`):**  
     * Menerima data yang telah diubah menggunakan kaedah `$_POST` .  
     * Melaksanakan arahan SQL `UPDATE` untuk menyimpan perubahan ke dalam pangkalan data.  
     * Pengguna dibawa kembali ke laman senarai selepas selesai (`header('location:Senarai.php')`).

---