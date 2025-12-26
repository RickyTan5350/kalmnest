## 3.1.8 Penggunaan Tatasusunan (Array) dalam Bahasa Penskripan Klien
### **1\. Pengenalan Tatasusunan (*Array*)**

Tatasusunan digunakan untuk menyimpan satu senarai nilai di dalam satu pemboleh ubah sahaja.

* **Konsep:** Sama seperti konsep tatasusunan yang dipelajari semasa Tingkatan 4\.  
* **Indeks:** Setiap nilai dalam tatasusunan dirujuk menggunakan nombor indeks yang bermula dengan **0**.  
  * Indeks 0 \= Nilai pertama.  
  * Indeks 1 \= Nilai kedua, dan seterusnya.

### **2\. Pengisytiharan & Memberi Nilai**

Terdapat cara khusus untuk mengisytiharkan tatasusunan dalam JavaScript:

* **Sintaks Asas:** `var nama_tatasusunan = [unsur1, unsur2, ...];`.  
* **Contoh:** `var no = [5, -1, 4, 12, 8];`. 

* **Input Pengguna:** Nilai boleh dimasukkan oleh pengguna melalui `prompt` dan disimpan ke dalam indeks tertentu (contoh: `no[0] = input;`).

### **3\. Pemprosesan Tatasusunan**

Dokumen ini menunjukkan tiga jenis pemprosesan utama yang boleh dilakukan ke atas tatasusunan:

#### **A. Mendapatkan Jumlah (Sum)**
```
<html>
<body>
<script>
    // Pengisytiharan pemboleh ubah
    var no = [5, -1, 4, 12, 8];
    var jumlah = 0;

    // Menambah nilai menggunakan indeks array secara manual
    jumlah = no[0] + no[1] + no[2] + no[3] + no[4];

    // Mencetak hasil
    document.write(jumlah);
</script>
</body>
</html>
```
* Operasi aritmetik untuk mencampur semua nilai dalam senarai.  
* Boleh dilakukan secara manual (satu per satu) atau menggunakan **gelung `for`** untuk lebih efisien.
```
<html>
  <body>
    <script>
      var no = [5, -1, 4, 12, 8];
      var jumlah = 0;
      var i;

      for (i=0; i<5; i++)
      {
        jumlah = jumlah + no[i];
      }

      document.write (jumlah);
    </script>
  </body>
</html>
```

#### **B. Carian (*Search*)**

* Mencari nilai tertentu dalam senarai.  
* **Kaedah:** Menggunakan gelung `for` untuk menyemak setiap indeks, dan struktur kawalan `if` untuk membandingkan nilai (contoh: `if (no[i] == 12)`).
```
<html>
  <body>
    <script>
      var no = [5, -1, 4, 12, 8];
      var i;

      for(i=0; i<5; i++)
      {
        if (no[i] == 12)
          document.write (no[i] + " dijumpai");
      }
    </script>
  </body>
</html>
```

#### **C. Isihan (*Sort*)**
```
<html>
  <body>
    <script>
      // 1. Initialization
      var no = [5, -1, 4, 12, 8];
      var i, j, sementara;

      // 2. Display Original List
      document.write("Senarai asal: ");
      for(i=0; i<5; i++)
      {
        document.write(" " + no[i]);
      }
      document.write("<br><br>");

      // 3. Linear Search Logic
      // This checks if the value 12 exists in the array
      for(i=0; i<5; i++)
      {
        if (no[i] == 12)
          document.write(no[i] + " dijumpai<br>");
      }

      // 4. Bubble Sort Logic
      // Nested loops compare adjacent elements and swap them if needed
      for(i=0; i<5-1; i++) 
      {
        for(j=0; j<5-i-1; j++) 
        {
          if (no[j] > no[j+1]) 
          {
            // The "sementara" variable holds the value during the swap
            sementara = no[j];
            no[j] = no[j+1];
            no[j+1] = sementara;
          }
        }
      }

      // 5. Display Sorted List
      document.write("<br>Senarai nombor (telah diisih secara menaik): <br><br>");
      for(i=0; i<5; i++)
      {
        document.write(" " + no[i]);
      }
    </script>
  </body>
</html>
```
* Menyusun semula senarai nombor, contohnya secara menaik (kecil ke besar).  
* **Algoritma:** Menggunakan kaedah **Isihan Buih** (*Bubble Sort*).  
* **Logik:** Menggunakan gelung bersarang (*nested loop*) dan pemboleh ubah `sementara` untuk menukar kedudukan (*swap*) jika nombor depan lebih besar dari nombor belakang.