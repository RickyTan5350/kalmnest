## 3.3.3 Membina Laman Web Mudah dengan Menggunakan HTML
### **1\. Pengenalan Pembangunan Laman Web**

* **Sejarah Awal (1990):** Laman web pada awalnya hanyalah koleksi dokumen statik yang dihubungkan melalui pautan teks .  
* **Perkembangan Teknologi:** Kini laman web bersifat **interaktif**, membolehkan pengguna menghantar maklumat kepada pelayan untuk diproses (contoh: tempahan hotel, pembelian dalam talian) .  
* **Definisi Interaktif:** Suatu laman web dianggap interaktif jika ia mampu memberi respons kepada tindakan pengguna, contohnya permainan dalam talian.

---

### **2\. Pengenalan HTML (Hypertext Markup Language)**

* **Definisi:** HTML adalah bahasa yang digunakan untuk menulis fail teks bagi membina laman web.  
* **Fungsi:** Menghuraikan kandungan dan struktur dokumen laman web.  
* **Analogi:** HTML diibaratkan sebagai "rangka" kepada struktur laman web.  
* **Editor HTML:** Program seperti **Notepad** digunakan untuk menulis kod HTML .

### **Struktur Asas HTML**

Dokumen HTML terdiri daripada elemen atau *tag* yang menerangkan struktur laman.

* **Tag Berpasangan:** Mempunyai *start tag* (`<tag>`) dan *close tag* (`</tag>`). Contoh: `<html>...</html>` .  
* **Empty Element:** Tag yang tiada penutup. Contoh: `<br>` (baris baharu) dan `<img>` (imej).
```
<html>
    <head>
        <title>Tajuk Laman Web</title>
    </head>
    <body>
        Selamat Datang
    </body>
</html>
```
---

### **3\. Elemen-Elemen Utama HTML**

#### **A. Elemen Heading (Tajuk)**

* Digunakan untuk mentakrifkan tajuk dalam laman web.  
* Terdapat **6 peringkat** saiz tulisan, dari `<h1>` (paling besar/penting) hingga `<h6>` (paling kecil/kurang penting) .
```
<h1>Contoh heading 1</h1>
<h2>Contoh heading 2</h2>
<h3>Contoh heading 3</h3>
<h4>Contoh heading 4</h4>
<h5>Contoh heading 5</h5>
<h6>Contoh heading 6</h6>
```

#### **B. Elemen Header**

* Tag: `<header>...</header>`  
* Digunakan untuk memaparkan pengenalan kandungan atau navigasi.  
* Biasanya mengandungi tajuk (`<h1>`\-`<h6>`), logo, atau maklumat pengarang .
```
<html>
    <head></head>
    <body>
        <header>
            <h1>Nilai-nilai Murni</h1>
            <hr>
            <h4>Definisi Nilai-nilai Murni</h4>
            <h4>Contoh Nilai-nilai Murni</h4>
        </header>
        <p>Nilai-nilai murni sewajarnya diterapkan dalam diri setiap murid 
        sejak awal.</p>
    </body>
</html>
```
#### **C. Elemen Paragraph (Perenggan)**

* Tag: `<p>...</p>`  
* Digunakan untuk menyusun teks dalam bentuk perenggan.
```
<p>Ini ialah perenggan pertama.</p>
<p>Ini ialah perenggan seterusnya.</p>
```
#### **D. Elemen Line Break (Baris Baharu)**

* Tag: `<br>`  
* Digunakan untuk memisahkan teks ke baris baharu tanpa menjarakkan perenggan.
```
<p>Perenggan ini<br>digunakan bersama<br>elemen line break </p>
```
#### **E. Elemen Image (Imej)**

* Tag: `<img>`  
* Merupakan *empty element* (tiada *close tag*).  
* **Atribut Penting:**  
  * `src`: Menentukan URL atau lokasi fail imej.  
  * `width` & `height`: Menetapkan saiz paparan imej .  
* Contoh kod: `<img src="gambar.jpg" style="width:128px;height:128px;">`.
```
<img src="google_icon.jpg" 
style="width:128px;height:128px;">
```
#### **F. Elemen Iframe (Bingkai)**

* Tag: `<iframe>...</iframe>`  
* Digunakan untuk memaparkan dokumen HTML lain (laman web luar) di dalam laman web semasa.  
* Atribut seperti `width` dan `height` digunakan untuk menetapkan saiz bingkai tersebut.
```
<html>
  <head>
    <title>Contoh Atur cara</title>
  </head>
  <body>
    <h2>Tentang Saya</h2>
    <img src="girl.jpg" style="width:128px;height:128px;">
    <p>
      Nama saya Suriana Binti Shuib. Saya berumur 17 tahun. Saya bersekolah di
      Sekolah Menengah Kebangsaan Seri Intan. Saya mempunyai keluarga yang
      bahagia
    </p>
    <p>
      Saya gemar melayari Internet di masa lapang. Namun, tidak semua yang
      berita yang dipaparkan itu betul. Untuk mengetahui kesahihannya, kita boleh
      merujuk kepada laman web
      <a href="http://sebenarnya.my"><h4>sebenarnya.my</h4></a>
    </p>
    <br>
    <center>
      <iframe height="40%" src="http://sebenarnya.my"></iframe>
    </center>
  </body>
</html>
```

---