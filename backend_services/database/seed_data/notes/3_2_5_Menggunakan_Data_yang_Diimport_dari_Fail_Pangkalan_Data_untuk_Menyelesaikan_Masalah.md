## 3.2.5 Menggunakan Data yang Diimport dari Fail Pangkalan Data untuk Menyelesaikan Masalah
### **Sambungan PHP ke Pangkalan Data MySQL**

Bahagian ini menerangkan cara menggunakan bahasa penskripan pelayan (PHP) untuk berinteraksi dengan pangkalan data MySQL bagi menyimpan dan mencapai data.

#### **1\. Langkah Utama Capaian Data**

Terdapat empat langkah yang **berturutan (sequential)** yang wajib dilakukan untuk memproses data:

1. Membuat sambungan ke pangkalan data.  
2. Memilih nama pangkalan data.  
3. Membuat pertanyaan (query) SQL.  
4. Menamatkan sambungan.

---

#### **2\. Fungsi-Fungsi Utama PHP untuk Pangkalan Data**

Berikut adalah fungsi-fungsi penting yang digunakan dalam atur cara:

**A. Membuat Sambungan (`mysqli_connect`)**

* Digunakan untuk menyambungkan PHP kepada pelayan pangkalan data.  
* **Sintaks:** `$con = mysqli_connect("hos", "namapengguna", "katalaluan");`.  
* Jika sambungan gagal, fungsi `die()` digunakan untuk memaparkan mesej ralat dan menghentikan proses.

**B. Memilih Pangkalan Data (`mysqli_select_db`)**

* Setelah sambungan berjaya, fungsi ini memilih pangkalan data khusus yang hendak digunakan.  
* **Sintaks:** `mysqli_select_db($con, "namapangkalan data");`.  
* *Contoh:* `mysqli_select_db($con, "dbPelajar");`.

**C. Membuat Pertanyaan/Query (`mysqli_query`)**

* Digunakan untuk melaksanakan arahan SQL (seperti `SELECT`, `INSERT`, dll) bagi mendapatkan atau memanipulasi data.  
* **Sintaks:** `$hasil = mysqli_query($con, "Penyataan SQL");`.  
* *Contoh:* `$hasil = mysqli_query($con, "SELECT * from MURID");`.

**D. Mengambil Data Hasil Query (`mysqli_fetch_array`)**

* Digunakan untuk mengambil data daripada hasil query dan menyimpannya ke dalam bentuk tatasusunan (array).  
* Biasanya digunakan bersama gelung **`while`** untuk menyenaraikan semua rekod yang ditemui satu per satu.  
* **Sintaks:** `$row = mysqli_fetch_array($hasil);`.

**E. Menutup Sambungan (`mysqli_close`)**

* Digunakan untuk memutuskan sambungan dengan pangkalan data setelah semua proses selesai.

---

#### **3\. Contoh Aplikasi: Menyenaraikan Rekod Murid**

Dalam contoh **Senarai.php**, atur cara dibina untuk memaparkan senarai murid dari jadual `MURID` dalam pangkalan data `dbPelajar` ke dalam jadual HTML.
```
<?php
$con = mysqli_connect("localhost", "root", "");
if (!$con) { die('Sambungan Gagal: ' . mysqli_connect_error()); }

mysqli_select_db($con, "dbPelajar");

print "<table border='1'>";
print "<tr><th>No Murid</th><th>Nama</th><th>Kelas</th><th>Negeri Kelahiran</th></tr>";

$hasil = mysqli_query($con, "SELECT * FROM MURID");

while($row = mysqli_fetch_array($hasil))
{
    // FIX: Use expected column names (lowercase)
    $nomurid = $row['nomurid'];      // "id" implies No Murid
    $nama = $row['nama'];       // "nama"
    $kelas = $row['kelas'];     // "kelas"
    $negeri = $row['negerilahir'];   // "negeri" implies Negeri Lahir

    print "<tr>";
    print "<td>".$nomurid."</td>";
    print "<td>".$nama."</td>";
    print "<td>".$kelas."</td>";
    print "<td>".$negeri."</td>";
    print "</tr>";
}
print "</table>";

mysqli_close($con);
?>

```
**Aliran Proses Atur Cara:**

1. **Sambung:** Buka sambungan ke `localhost` menggunakan `root`.  
2. **Pilih DB:** Pilih pangkalan data `dbPelajar`.  
3. **Sediakan Jadual HTML:** Cetak tajuk jadual (No Murid, Nama, Kelas, Negeri).  
4. **Query Data:** Laksanakan `SELECT * FROM MURID`.  
5. **Paparan Berulang (Looping):**  
   * Gunakan `while($row = mysqli_fetch_array($hasil))` untuk membaca setiap baris data.  
   * Simpan data dari array `$row` ke dalam pemboleh ubah (contoh: `$row['NAMA']` ke `$nama`).  
   * Cetak data tersebut ke dalam baris jadual HTML (`<tr><td>...</td></tr>`).  
6. **Tutup:** Tutup sambungan pangkalan data.

-