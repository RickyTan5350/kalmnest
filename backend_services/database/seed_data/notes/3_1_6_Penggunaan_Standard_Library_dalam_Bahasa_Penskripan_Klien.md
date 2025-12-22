## 3.1.6 Penggunaan Standard Library dalam Bahasa Penskripan Klien

### **1\. Kelebihan Menggunakan *Standard Library***

![mathjs.png](https://kalmnest.test/storage/uploads/1766250910_mathjs.png)

https://mathjs.org/


Penggunaan *Standard Library* memberikan dua manfaat utama dalam pembangunan atur cara:

* **Boleh Guna Semula:** Fungsi boleh digunakan berulang kali dalam atur cara dengan hanya memanggil fungsinya apabila diperlukan.  
* **Menjimatkan Masa:** Mengurangkan masa pembangunan kerana pengatur cara tidak perlu menulis pernyataan kod yang sama berulang kali.

---

### **2\. Pustaka math.js**

math.js ialah *standard library* yang kerap digunakan dalam JavaScript untuk fungsi *built-in* (binaan dalam) dan pemalar matematik.

#### **A. Cara Memuatkan math.js ke dalam HTML**

Terdapat dua cara untuk menghubungkan math.js dengan laman web anda:

**Cara 1: Muat Turun Fail (Download)**
```
<html>
    <head>
        <script src="math.js"></script>
    </head>
    <body>
        <script>
            // Fixed the line breaks inside the document.write strings
            document.write("Punca kuasa dua bagi 4 ialah ", math.sqrt(4)); 
            document.write("<br>3 kuasa 2 ialah ", math.pow(3, 2));
        </script>
    </body>
</html>
```
1. Muat turun fail .js daripada laman web rasmi ([http://mathjs.org](http://mathjs.org/)) atau menggunakan pengurus pakej seperti npm atau bower.  
2. Simpan fail tersebut dalam folder projek.  
3. Pautkan dalam tag \<head\> menggunakan atribut src:  
   \<script src="math.js"\>\</script\>.

**Cara 2: Pautan CDN (Tanpa Muat Turun)**
```
<html>
    <head>
        <script src="http://cdnjs.cloudflare.com/ajax/libs/mathjs/3.7.0/math.min.js"></script>
    </head>
    <body>
        <script>
            // These strings must NOT have manual 'Enter' key presses inside the quotes
            document.write("Punca kuasa dua bagi 4 ialah ", math.sqrt(4)); 
            document.write("<br>3 kuasa 2 ialah ", math.pow(3, 2));
        </script>
    </body>
</html>
```
1. Gunakan pautan URL daripada penyedia CDN (contohnya: cdnjs.cloudflare.com).  
2. Masukkan pautan tersebut terus ke dalam atribut src:  
   \<script src="http://cdnjs.cloudflare.com/ajax/libs/mathjs/3.7.0/math.min.js"\>\</script\>.

#### **B. Senarai Fungsi Utama math.js**

Jadual berikut menyenaraikan fungsi yang disediakan:

| Fungsi | Kegunaan |
| :---- | :---- |
| math.add(x, y) | Menambah dua nombor. |
| math.divide(x, y) | Membahagi dua nombor. |
| math.subtract(x, y) | Menolak dua nombor. |
| math.pow(x, y) | Mengira kuasa bagi nombor ($x^y$). |
| math.sqrt(x) | Mengira punca kuasa dua bagi nombor ($\\sqrt{x}$). |
| math.cube(x) | Mendarab tiga nombor yang sama ($x \\times x \\times x$). |
| math.sort(x) | Mengisih unsur-unsur dalam satu matriks. |

#### **C. Langkah Penggunaan dalam Kod**

1. **Tetapkan Sumber:** Pada bahagian \<head\>, pastikan fail math.js telah dipanggil.  
2. **Panggil Fungsi:** Gunakan fungsi dalam skrip.  
   * Contoh math.sqrt(4): Mengira punca kuasa dua bagi 4\.  
   * Contoh math.pow(3, 2\): Mengira 3 kuasa 2\.  
3. **Papar Hasil:** Gunakan document.write() untuk memaparkan output.

---

### **3\. Pustaka date.js**

date.js adalah *standard library* yang digunakan untuk operasi berkaitan tarikh dan masa.

#### **A. Fungsi Utama date.js**

| Fungsi | Kegunaan |
| :---- | :---- |
| Date.today() | Menghasilkan tarikh hari ini. |
| Date.parse('today') | Menukar bentuk objek kepada bentuk objek Date. |
| Date.today().add().days() | Menambah bilangan hari kepada tarikh hari ini. |

#### **B. Contoh Penggunaan**

Kod berikut memaparkan tarikh hari ini:

JavaScript

```
<html>
    <head>
        <script src="date.js"></script>
    </head>
    <body>
        <script>
            // Date.today() is a specific function from the date.js library
            var hariIni = Date.today();
            
            // Outputs the date to the browser
            document.write(hariIni);
        </script>
    </body>
</html>
```

Fungsi Date.today() akan mengenal pasti butiran tarikh dan masa terkini untuk dipaparkan.

---