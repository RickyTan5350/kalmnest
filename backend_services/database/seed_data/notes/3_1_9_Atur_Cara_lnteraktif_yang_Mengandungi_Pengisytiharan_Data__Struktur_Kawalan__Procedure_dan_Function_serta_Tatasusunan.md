## 3.1.9 Atur Cara lnteraktif yang Mengandungi Pengisytiharan Data, Struktur Kawalan, Procedure dan Function serta Tatasusunan
### **1\. Pengenalan Laman Web Interaktif**

* **Definisi**: Laman web interaktif ialah laman web yang membolehkan interaksi antara pengguna dan sistem.  
* **Teknologi Utama**: Dibina menggunakan **HTML/CSS** untuk struktur dan gaya, manakala bahasa **JavaScript** ditambah untuk fungsi interaktif.  
* **Kegunaan JavaScript**: Digunakan untuk animasi, manipulasi imej, interaksi dengan pelayan (server), serta menyimpan dan memproses data pengguna.

---

## **2\. Elemen Interaktif Utama dalam HTML**

Terdapat beberapa tag HTML yang digunakan untuk mencetuskan tindakan interaktif:

### **A. Tag `<button>` (Butang)**
```
<html>
  <body>
    <button onclick =
     "window.alert('Hai!')">
      Klik Sini
    </button>
  </body>
</html>
```
* Digunakan untuk menghasilkan butang yang boleh diklik oleh pengguna.  
* Atribut `onclick` digunakan untuk melaksanakan arahan JavaScript selepas butang ditekan.  
* **Contoh Fungsi**: Memaparkan kotak amaran (*pop-up*) menggunakan arahan `window.alert('Hai!')`.

### **B. Tag `<form>` (Borang)**
```
<html>
  <body>
    <form action="action_page.php"  method= "POST">
      Nama:
      <input type="text" name="namapengguna" value="">
      <input type="submit" value="Hantar">
    </form>
  </body>
</html>
```
* Digunakan untuk mengumpul input atau data daripada pengguna.  
* **Unsur Input**: Termasuk medan teks (*text field*), kotak semak (*checkbox*), butang radio, dan butang hantar (*submit button*).  
* **Proses Data**: Nilai dalam borang dihantar ke halaman tindakan (seperti fail `.php`) apabila pengguna klik butang "Hantar".

### **C. Tag `<a>` (Hyperlink)**

* Membolehkan pengguna beralih ke tapak web atau laman web lain melalui teks atau imej.  
* Boleh digunakan secara terus dengan pautan URL atau digabungkan dengan JavaScript (fungsi `window.open()`) untuk membuka tetingkap/tab baharu.

---

## **3\. Penggunaan Procedure dan Function**

* **Tujuan**: Mengurangkan pengulangan kod dengan membina blok-blok arahan yang boleh dipanggil semula apabila diperlukan.  
* **Subatur Cara**: Sebuah atur cara boleh mempunyai lebih daripada satu fungsi yang saling memanggil antara satu sama lain.  
* **Contoh Aplikasi (Isihan Buih)**:  
```
<html>
<body>

<p>Senarai nombor sebelum diisih: </p>
<button onclick="sebelumIsih()"> Sebelum Isih </button>

<script>
    function sebelumIsih()
    {
        var no = [5, 1, 4, 3, 2];
        document.write(no);
    }
</script>

<p>Senarai nombor selepas diisih (Isihan Buih): </p>
<button onclick="selepasIsih()"> Selepas Isih </button>

<script>
    function selepasIsih()
    {
        var no = [5, 1, 4, 3, 2];
        var panjang = no.length, i, j;
        var sementara;
        
        for (i=0; i<panjang; i++)
        {
            for (j=0; j<panjang-i-1; j++)
            {
                if (no[j] > no[j+1])
                {
                    sementara = no[j];
                    no[j] = no[j+1];
                    no[j+1] = sementara;
                }
            }
        }
        document.write(no);
    }
</script>

</body>
</html>
```
  * Fungsi `sebelumIsih()` memaparkan senarai asal.  
  * Fungsi `selepasIsih()` memanggil fungsi `isihanBuih()` untuk menyusun data.  
  * Fungsi `isihanBuih()` pula memanggil fungsi `tukarKedudukan()` untuk menukar posisi nombor.