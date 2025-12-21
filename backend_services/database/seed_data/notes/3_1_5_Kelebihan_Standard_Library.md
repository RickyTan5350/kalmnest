## 3.1.5 Kelebihan Standard Library
### **1\. Struktur Kawalan dalam Ulangan**

Terdapat pernyataan khusus yang boleh digunakan untuk mengawal aliran dalam struktur ulangan:

* **Break & Continue:** Kedua-dua pernyataan ini boleh wujud dalam satu ulangan.  
* **Fungsi `continue`:** Pernyataan `continue` akan melaksanakan penambahan (increment) sebelum syarat ulangan diperiksa semula.

### **2\. Latihan Amali: Penentuan Nombor Genap & Ganjil**

Dokumen tersebut menggariskan satu latihan untuk menggunakan struktur kawalan (urutan, pilihan, dan ulangan) dalam JavaScript.

* **Tugasan:** Hasilkan dokumen HTML dengan JavaScript yang membuat ulangan dari nombor 1 hingga 10\.  
* **Logik Atur Cara:** Setiap ulangan akan memeriksa sama ada nombor tersebut adalah **genap** atau **ganjil**.  
* **Contoh Output:**  
  * 1 ialah nombor ganjil  
  * 2 ialah nombor genap  
  * (dan seterusnya sehingga 10\) .

### **3\. Pengenalan kepada *Standard Library***

*Standard library* adalah koleksi kaedah atau fungsi yang disediakan untuk diguna pakai semasa penulisan kod.

* **Ciri-ciri:**  
  * Ia ditakrifkan dalam spesifikasi bahasa pengaturcaraan.  
  * Merangkumi definisi algoritma biasa, struktur data, dan mekanisme input/output.  
* **Contoh dalam JavaScript:**  
  * **`math.js`:** Untuk fungsi matematik seperti `math.sqrt()` (punca kuasa) dan `math.pow()` (kuasa).  
```
<html>
  <head>
    <script src="math.js"></script>
  </head>
  <body>
    <script>
         document.write("Punca kuasa dua bagi 4 ialah ", math.sqrt(4));
      document.write("<br>3 kuasa 2 ialah ", math.pow(3, 2));
    </script>
  </body>
</html>
```
  * **`date.js`:** Untuk fungsi tarikh seperti `date.now()`.


#### **Kelebihan Menggunakan *Standard Library***

1. **Abstraksi:** Boleh digunakan tanpa perlu mengetahui cara pelaksanaannya secara terperinci (contoh: guna `math.pow` tanpa perlu tahu cara kiraan kuasa manual dibuat).  
2. **Guna Semula:** Boleh dipanggil berulang kali apabila diperlukan.  
3. **Efisiensi Masa:** Mengurangkan masa pembangunan kerana tidak perlu menulis kod asas berulang kali.


---