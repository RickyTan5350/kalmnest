# 3.3.6 Penggunaan Bahasa Penskripan Pelayan untuk Membina Laman Web yang Boleh Mencapai dan Mengemas kini Data dalam Pangkalan Data

## **1\. Pengenalan Bahasa Penskripan Pelayan**

* **Fungsi Utama:** Digunakan untuk membina laman web yang boleh mencapai dan mengemas kini data di dalam pangkalan data.  
* **Laman Web Interaktif:** Bermaksud laman web yang mempunyai kandungan dinamik dan berubah mengikut permintaan atau carian pengguna.  
* **Contoh:** Laman web biodata murid di mana maklumat dipaparkan berbeza mengikut nombor murid yang dicari .

---

## **2\. Ciri-Ciri Laman Web Interaktif**

Laman web interaktif mempunyai ciri-ciri berikut:

* **Bahasa Pengaturcaraan:** Menggunakan bahasa penskripan pelayan seperti **PHP**, **ASP**, dan lain-lain.  
* **Capaian Pangkalan Data:** Mempunyai kebolehan untuk mencapai (*access*) data yang disimpan dalam pangkalan data.  
* **Kandungan Dinamik:** Kandungan berubah-ubah mengikut input pengguna dan hasil pemprosesan komputer pelayan.  
* **Kemas Kini:** Data dan kandungan laman web sering dikemas kini.

---

## **3\. Elemen Penting Laman Web Interaktif**

Terdapat tiga elemen utama dalam proses interaksi ini:

1. **Pelayar Web (Pengguna):** Tempat pengguna membuat carian atau permintaan maklumat.  
2. **Komputer Pelayan (Server):** Memproses permintaan tersebut menggunakan bahasa penskripan.  
3. **Pangkalan Data:** Tempat data disimpan, dicapai, dan dikemas kini.

---

## **4\. Membina Laman Web dengan Capaian Pangkalan Data**

Proses untuk memaparkan data daripada pangkalan data melibatkan langkah berikut:

### **A. Persediaan Pangkalan Data**

* Perlu ada **jadual (table)** dalam pangkalan data untuk menyimpan maklumat.  
* **Contoh Jadual `MURID`:** Mengandungi lajur seperti `NOMURID`, `NAMA`, `KELAS`, dan `NEGERILAHIR` .

### **B. Arahan SQL (Structured Query Language)**

* Arahan `SELECT` digunakan untuk mencapai data daripada jadual.  
* **Sintaks:** `SELECT lajur FROM jadual`.  
* **Contoh Penggunaan:**  
  * `SELECT * FROM MURID` (Memilih semua data dalam jadual) .  
  * `SELECT NAMA, KELAS FROM MURID` (Memilih lajur tertentu sahaja).

### **C. Sambungan PHP ke Pangkalan Data**

* Sebelum data boleh dicapai, sambungan (*connection*) ke pangkalan data mesti dibuat terlebih dahulu menggunakan kod PHP.  
* **Kod Sambungan:** `mysqli_connect("localhost", "root", "")`.  
* Jika sambungan gagal, mesej ralat akan dipaparkan.

---

## **5\. Contoh Aplikasi Carian Maklumat (PHP)**

Dokumen memberikan contoh dua fail PHP yang bekerjasama untuk sistem carian rekod pelajar:

1. **`Cari.php` (Borang Carian):**  
   * Memaparkan borang untuk pengguna memasukkan **No Murid**.  
   * Menggunakan kaedah `POST` untuk menghantar data ke fail pemproses (`Papar.php`).  

2. **`Papar.php` (Paparan Hasil):**  
   * Menerima **No Murid** yang dihantar dari `Cari.php`.  
   * Membuat sambungan ke pangkalan data (`dbPelajar`).  
   * Menjalankan arahan SQL: `SELECT * FROM MURID WHERE NOMURID = '$nomurid'`.  
   * Memaparkan maklumat pelajar (Nama, Kelas, Negeri) yang sepadan dengan nombor tersebut .
```php:src=Cari.php
<html>
  <head>
    <title>Carian Maklumat</title>
  </head>
  <body>
    <form action = "Papar.php" method="POST">
      <p>No Murid  <input name = "nomurid" type = "text" size = "10">
        <input Type = "submit" Name = "submit" Value = "Cari"> </p>
      <p>Nama Murid  <input name = "nama" type = "text" size = "30"
          disabled = true></p>
      <p>Kelas <input name = "kelas" type = "text" size ="15"
          disabled = true></p>
      <p>Negeri Kelahiran <input name = "negeri" type="text" size = "20"
          disabled = true></p>
    </form>
  </body>
</html>
```