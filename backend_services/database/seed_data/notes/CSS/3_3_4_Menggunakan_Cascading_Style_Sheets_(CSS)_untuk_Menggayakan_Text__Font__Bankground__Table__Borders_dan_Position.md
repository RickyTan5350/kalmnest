#  3.3.4 Menggunakan Cascading Style Sheets (CSS) untuk Menggayakan Text, Font, Bankground, Table, Borders dan Position
## **1\. Pengenalan CSS (Cascading Style Sheets)**

* **Definisi:** CSS adalah bahasa pengaturcaraan tambahan (*extension*) kepada HTML.  
* **Fungsi:** Ia membenarkan perubahan gaya laman web dan menerangkan persembahan bagi dokumen HTML (contoh: menukar warna teks, latar belakang).

---

## **2\. Cara Penulisan CSS**

Terdapat tiga kaedah untuk memasukkan CSS dalam HTML:

1. **Helaian Gaya Luar (*External Style Sheet*):**  
   * Kod CSS ditulis dalam fail berasingan (contoh: `style1.css`) dan dipanggil menggunakan tag `<link>`.  


```html:src=utama.html
<!DOCTYPE html>
<html>
    <head>
        <title>Penggunaan CSS</title>
        <link rel="stylesheet" type="text/css" href="style1.css">
    </head>

    <body>
        <h1>Laman Web Sekolah</h1>
    </body>
</html>

```
   * **Kelebihan:** Boleh mengawal gaya untuk banyak dokumen serentak dan lebih efisien.  
2. **Helaian Gaya Dalaman (*Internal Style Sheet*):**  
   * Kod CSS ditulis di dalam tag `<style>` yang biasanya diletakkan dalam ruangan `<head>` atau `<body>`.  
```html:src=head.html
<html>
    <head>
        <title>Penggunaan CSS</title>
        <style>
            h1
            {
                color: blue;
            }
        </style>
    </head>

    <body>
        <h1>Laman Web Sekolah</h1>
    </body>
</html>
```
   * Hanya memberi kesan kepada halaman yang sedang dipaparkan sahaja.  
3. **Gaya Dalam Barisan (*Inline Style*):**  
   * Kod CSS ditulis terus pada elemen tag HTML (contoh: `<h1 style="color: blue;">`).
```html:src=inline.html
<html>
    <head>
        <title>Penggunaan CSS</title>
        
    </head>

    <body>
        
        <h1 style="color: blue">Laman Web Sekolah</h1>
    </body>
</html>
```

---

## **3\. Penggayaan Teks dan Fon**

CSS membolehkan pelbagai gaya teks diubah suai:

* **Warna Teks:** Menggunakan sintaks `color: blue;` (atau kod warna heksadesimal).  
* **Jajaran Teks (*Text Align*):** Menetapkan kedudukan teks seperti `text-align: center;` (tengah).  
* **Bayang Teks (*Text Shadow*):** Memberi kesan bayang dengan sintaks `text-shadow: 2px 2px #000000;`.  
* **Keluarga Fon (*Font Family*):** Menukar jenis tulisan, contohnya `font-family: "Arial Black";`.  
* **Saiz Fon (*Font Size*):** Mengubah saiz tulisan, contohnya `font-size: 70;`.  
* **Stail Fon (*Font Style*):** Menukar bentuk tulisan seperti `font-style: italic;` (condong).
```html:src=TukarWarna.html
<html>
  <head>
    <title>Tukar Warna Teks</title>
    <style>
      h1 
      {
        color: red;
      }
    </style>
  </head>

  <body>
    <h1>Laman Web Sekolah</h1>
  </body>
</html>
```

---

## **4\. Penggayaan Latar Belakang (*Background*)**

* **Warna Latar Belakang:** Menggunakan `background-color: lightgreen;` untuk menukar warna keseluruhan halaman.  
```html:src=WarnaLatarBelakang.html
<html>
  <head>
    <title>Warna Latar Belakang</title>
    <style>
      h1 
      {
        background-color: lightgreen;
      }
    </style>
  </head>

  <body>
    <h1>Laman Web Sekolah</h1>
  </body>
</html>
```
* **Imej Latar Belakang:** Menggunakan `background-image: url("gambar.jpg");` untuk meletakkan gambar sebagai latar belakang.  
  * Gambar boleh diambil dari fail komputer atau pautan URL Internet.
```html:src=LatarBelakangImej1.html
<html>
  <head>
    <title>Latar Belakang Imej</title>
    <style>
      h1 
      {
        background-image: url("google_icon.png");
        height: 300px;
      }
    </style>
  </head>

  <body>
    <h1>Laman Web Sekolah</h1>
  </body>
</html>
```
---

## **5\. Penggayaan Jadual (*Tables*)**

CSS digunakan untuk mencantikkan jadual HTML:
```html:src=GayaJadual.html
<html>
    <head>
        <title>Gaya Jadual</title>
        <style>
            table
            {
                border: 1px solid;
            }
        </style>
    </head>
    <body>
        <h1>Laman Web Sekolah</h1>
        <table>
            <tr>
                <th>KANDUNGAN LAMAN WEB</th>
            </tr>
            <tr>
                <td>Pengenalan Sekolah</td>
            </tr>
            <tr>
                <td>Senarai Guru</td>
            </tr>
        </table>
    </body>
</html>
```
* **Border (Garisan):** Menambah garis luar pada jadual dengan sintaks `border: 1px solid;`.  
  * Jenis garisan boleh berupa *Solid, Dotted, Dashed, Inset,* atau *Outset*.  
  * Ketebalan garisan boleh dilaraskan (contoh: `3px`).  

* **Border Collapse:** Menggunakan `border-collapse: collapse;` untuk menjadikan garisan jadual satu garis sahaja (*single border*).  
* **Saiz Jadual:** Menetapkan lebar (`width`) dan tinggi (`height`) dalam peratusan (%) atau piksel.  
* **Padding:** Menambah jarak antara kandungan sel dengan dinding sel menggunakan `padding: 20px;`.  
* **Warna Jadual:** Menukar warna latar dan teks jadual (contoh: `background-color: green; color: white;`).
```html:src=Border.html
<html>
    <head>
        <title>Gaya Border</title>
        <style>
            h1 
            {
                border-style: solid;
                border-width: 5px;
            }
        </style>
    </head>
    <body>
        <h1>Laman Web Sekolah</h1>
    </body>
</html>

```

---

## **6\. Penggayaan Kedudukan (*Position*)**

CSS menetapkan cara elemen disusun dalam halaman web:

1. **Static:** Kedudukan asal (default) mengikut turutan kod HTML. Tidak berubah.  
2. **Relative:** Kedudukan berubah bergantung kepada kedudukan asalnya.  
3. **Absolute:** Elemen bebas diletakkan di mana-mana koordinat (contoh: `top: 20px, left: 20px`) dan tidak mengikut turutan asal.  
4. **Fixed:** Elemen kekal di kedudukan yang sama pada skrin walaupun pengguna menatal (*scroll*) laman web.
```html:src=Position.html
<html>
    <head>
        <title>Tanpa Gaya Position</title>
    </head>
    <body>
        <h1>Laman Web Sekolah (Absolute)</h1>
        <h2>Sekolah 1 (Relative)</h2>
        <h3>Sekolah 2 (Fixed)</h3>
        <h4>Sekolah 3 (Static)</h4>
    </body>
</html>
```
---