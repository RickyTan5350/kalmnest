## 3.2.9 Membina Daftar (Sign Up) dan Log Masuk (Login)dalam Suatu Laman Web
### **1\. Pengenalan Pendaftaran & Log Masuk**

Kebanyakan laman web moden memerlukan pengguna mendaftar sebagai ahli yang sah untuk mengakses maklumat tertentu.

* **Tujuan:** Mengehadkan akses data (seperti gambar, video, artikel) hanya kepada ahli berdaftar.  
* **Contoh:** Laman web kelab sekolah, portal pekerja, dan media sosial.  
* **Proses:** Pengguna perlu mendaftar (Sign Up) dahulu, kemudian pengesahan dilakukan semasa Log Masuk (Login) untuk membenarkan akses.

---

### **2\. Membina Laman Pendaftaran (Sign Up)**

Bahagian ini menerangkan cara membina borang untuk pengguna baharu mendaftar keahlian.

#### **A. Halaman Borang Pendaftaran (`DaftarAhli.php`)**
```
<html>
<head>
    <title>Daftar Ahli Baru</title>
</head>
<body>
    <form action="ProsesDaftar.php" method="POST">
        <table border="0">
            <tr>
                <td style="background-color:#00FF00;" align="center">Selamat Datang</td>
                <td style="background-color:#00FF00;" align="center">Daftar Ahli Baru</td>
            </tr>
            <tr>
                <td><img src="LogoKelab.png" style = "width: 150px; height: 150px"></td>
                <td width="63%">
                    <table>
                        <tr>
                            <td>Nama Pengguna</td>
                            <td><input name="namapengguna" size="18" type="text"></td>
                        </tr>
                        <tr>
                            <td>Katalaluan</td>
                            <td><input name="katalaluan" size="15" type="password"></td>
                        </tr>
                        <tr>
                            <td>Jenis Keahlian</td>
                            <td>
                                <select name="jenis">
                                    <option value="Ahli Biasa">Ahli Biasa</option>
                                    <option value="Pengerusi">Pengerusi</option>
                                    <option value="Pentadbir">Pentadbir</option>
                                </select>
                            </td>
                        </tr>
                        <tr>
                            <td><input name="submit" value="Daftar" type="submit"></td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </form>
</body>
</html>
```

Ini adalah antaramuka pengguna untuk memasukkan butiran pendaftaran.

* **Elemen Borang:**  
  * Menggunakan tag `<form>` dengan `method="POST"` dan `action="ProsesDaftar.php"`.  
  * **Nama Pengguna:** Input jenis teks (`type="text"`).  
  * **Katalaluan:** Input jenis kata laluan (`type="password"`).  
  * **Jenis Keahlian:** Menu pilihan (`<select>`) yang mengandungi pilihan seperti "Ahli Biasa", "Pengerusi", dan "Pentadbir" .  
  * **Butang Hantar:** Input jenis `submit` dengan label "Daftar".

#### **B. Pemprosesan Pendaftaran (`ProsesDaftar.php`)**

Fail ini menerima data dari borang dan menyimpannya ke dalam pangkalan data.

* **Sambungan:** Menyambung ke pangkalan data `dbPelajar` .  
* **Terima Data:** Mengambil data `namapengguna`, `katalaluan`, dan `Ahli` menggunakan `$_POST` .  
* **Simpan Data (SQL):** Menggunakan arahan `INSERT INTO` untuk menambah rekod baharu ke dalam jadual `PENGGUNA` .  
* **Lencongan:** Jika berjaya, pengguna dibawa ke laman `Admin.php`.

---

### **3\. Membina Laman Log Masuk (Login)**

Bahagian ini menerangkan cara membina sistem untuk ahli yang sudah berdaftar masuk ke laman web.

#### **A. Halaman Borang Log Masuk (`LogMasuk.php`)**

Antaramuka untuk pengguna memasukkan nama dan kata laluan .

* **Elemen Borang:**  
  * Menggunakan tag `<form>` dengan `method="POST"` dan `action="ProsesMasuk.php"`.  
  * Input untuk **Nama Pengguna** dan **Katalaluan** .  
  * Butang "Masuk" untuk menghantar data.

#### **B. Pemprosesan Log Masuk (`ProsesMasuk.php`)**

Fail ini menyemak sama ada pengguna wujud dalam pangkalan data.

* **Semakan Data (SQL):** Menggunakan arahan `SELECT * FROM PENGGUNA` di mana nama pengguna dan kata laluan sepadan dengan input pengguna.  
* **Pengesahan:**  
  * Menggunakan `mysqli_num_rows($rekod)` untuk mengira jumlah rekod yang ditemui.  
  * **Jika Berjaya (`$hasil > 0`):** Pengguna dibawa ke laman `Masuk.php` dan nama pengguna dihantar melalui URL (`Masuk.php?namapengguna=...`).  
  * **Jika Gagal:** Pengguna dikembalikan semula ke laman `LogMasuk.php`.

---

### **4\. Halaman Ahli (`Masuk.php`)**

Ini adalah laman yang dipaparkan setelah pengguna berjaya log masuk.

* **Paparan Maklumat:**  
  * Mengambil nama pengguna daripada URL menggunakan `$_GET['namapengguna']`.  
  * Memaparkan mesej "Selamat Datang" dan nama pengguna tersebut .  
* **Log Keluar:** Menyediakan pautan "Log Keluar" yang menghala ke `KelabCatur.php` .