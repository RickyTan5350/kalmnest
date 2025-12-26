## 3.2.6 Melakukan Pengesahsahihan (Validation) pada Data Input daripada Pengguna
### **1\. Pengesahsahihan Data Input (Data Validation)**

Pengesahsahihan data adalah proses penting untuk memastikan data yang dimasukkan melalui borang adalah sah sebelum diproses atau disimpan.

* **Tujuan:** Mengelakkan ralat semasa proses penyimpanan data ke dalam pangkalan data.  
* **Lokasi Proses:** Dilakukan pada komputer pelayan (*server*) menggunakan bahasa penskripan pelayan (seperti PHP).  
* **Kelebihan:** Menjadikan laman web lebih responsif. Jika pengesahsahihan gagal, borang tidak akan dihantar dan pengguna akan menerima maklum balas ralat.  
* **Medan Wajib:** Bukan semua medan input wajib diisi. Medan bertanda "\*" biasanya wajib diisi; jika dibiarkan kosong, pendaftaran akan gagal.

---

### **2\. Cara-Cara Lazim Pengesahsahihan**

Terdapat empat kaedah utama untuk menyemak input pengguna:

1. **Semakan Kekosongan:** Memastikan medan wajib tidak dibiarkan kosong.  
2. **Semakan Format:** Memastikan data mematuhi format yang ditetapkan (contohnya format e-mel atau nombor telefon).  
3. **Semakan Julat/Nilai:** Memastikan angka mematuhi kriteria tertentu (contohnya markah antara 0 hingga 100).  
4. **Semakan Penghantaran:** Menyemak sama ada borang (*form*) telah dihantar ke pelayan.

---

### **3\. Penerangan Kod PHP (DaftarPelajar.php)**

Berikut adalah fungsi kod-kod penting dalam fail `DaftarPelajar.php` untuk memproses borang:
```
<html>
<head>
    <title>Daftar Maklumat Murid Baru</title>
    <style>
        .error {color: #FF0000;}
    </style>
</head>
<body>
<?php
// Initialize error variables
$errName = $errNoMurid = $errEmail = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // 1. Validate Name
    if (empty($_POST["Nama"])) {
        $errName = "Sila Masukkan Nama";
    } else {
        $errName = "";
    }

    // 2. Validate Student Number
    if (empty($_POST["NoMurid"])) {
        $errNoMurid = "Sila Masukkan Nombor Murid";
    } else {
        $errNoMurid = "";
    }

    // 3. Validate Email
    if (empty($_POST["email"])) {
        $errEmail = "Sila Masukkan email";
    } else {
        $email = $_POST["email"];
        // Check if email format is valid
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errEmail = "Alamat email dimasukkan tidak mengikut format";
        } else {
            $errEmail = "";
        }
    }
}
?>

<h1>Daftar Maklumat Murid Baru</h1>
<form method="POST" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>">
    <table>
        <tr>
            <td>No Murid *</td>
            <td>
                <input name="NoMurid" type="text" size="5">
                <span class="error"><?php echo $errNoMurid;?></span>
            </td>
        </tr>
        <tr>
            <td>Nama Murid *</td>
            <td>
                <input name="Nama" type="text" size="30">
                <span class="error"><?php echo $errName;?></span>
            </td>
        </tr>
        <tr>
            <td>Alamat</td>
            <td><textarea name="Alamat" rows="4" cols="50"></textarea></td>
        </tr>
        <tr>
            <td>No Telefon</td>
            <td><input name="Telefon" type="text" size="10"></td>
        </tr>
        <tr>
            <td>E-mail *</td>
            <td>
                <input name="email" type="text" size="30">
                <span class="error"><?php echo $errEmail;?></span>
            </td>
        </tr>
        <tr>
            <td><input type="submit" name="submit" value="Daftar"></td>
        </tr>
    </table>
</form>
</body>
</html>

```
* **`$_SERVER["REQUEST_METHOD"] == "POST"`**: Digunakan untuk memeriksa sama ada borang telah dihantar (*submitted*) ke pelayan.  
* **`empty($_POST["Nama"])`**: Memeriksa sama ada medan 'Nama' telah diisi atau kosong.  
  * Jika kosong, pemboleh ubah `$errName` akan menyimpan mesej ralat "Sila Masukkan Nama".  
  * Fungsi yang sama digunakan untuk memeriksa medan `NoMurid`.  
* **`filter_var($email, FILTER_VALIDATE_EMAIL)`**: Digunakan untuk memeriksa sama ada e-mel yang dimasukkan mengikut format yang sah.  
  * Jika format salah, mesej "Alamat email dimasukkan tidak mengikut format" akan disimpan dalam `$errEmail`.  
* **Paparan Ralat (CSS):** Mesej ralat (seperti `$errName`, `$errEmail`) akan dipaparkan dengan tulisan berwarna merah menggunakan kod CSS `.error {color: #FF0000;}`.  
* **`htmlspecialchars()`**: Fungsi keselamatan yang menukarkan abjad khas kepada entiti HTML untuk mengelakkan isu keselamatan (seperti *code injection*).  
  * Contoh penukaran: `&` menjadi `&amp;`, `"` menjadi `&quot;`, `<` menjadi `&lt;`.

---