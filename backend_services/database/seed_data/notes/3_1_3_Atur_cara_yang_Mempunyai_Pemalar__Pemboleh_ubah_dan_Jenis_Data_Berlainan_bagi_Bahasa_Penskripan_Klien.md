## 3.1.3 Atur cara yang Mempunyai Pemalar, Pemboleh ubah dan Jenis Data Berlainan bagi Bahasa Penskripan Klien
### **1\. Asas Bahasa Penskripan Klien (JavaScript)**

JavaScript digunakan dalam dokumen HTML untuk menjadikan laman web lebih dinamik dan interaktif.

#### **A. Pemboleh Ubah (*Variable*)**

* **Definisi:** Ruang ingatan sementara untuk menyimpan nilai semasa atur cara diproses.  
* **Ciri-ciri:** Nilainya boleh berubah-ubah mengikut arahan atur cara.  
* **Pengecam:** Nama yang diberikan kepada pemboleh ubah (contoh: `gajiPekerja`, `namaPelajar`) .  
* **Kata Kunci:** Menggunakan `var` dalam pengisytiharan.

#### **B. Pemalar (*Constant*)**

* **Definisi:** Ruang ingatan untuk menyimpan nilai yang **tetap** dan tidak berubah .  
* **Ciri-ciri:** Nilai ditentukan awal dan kekal sepanjang proses (contoh: nilai Pi \= 3.142, bilangan hari seminggu \= 7\) .  
* **Kata Kunci:** Menggunakan `const`.

#### **C. Jenis Data Asas**

Terdapat tiga jenis data utama dalam JavaScript :

1. **Nombor:** Nilai numerik (contoh: `5`, `100.50`).  
2. **Rentetan (*String*):** Teks yang diapit tanda petik (contoh: `"Ali bin Abu"`, `"BMW 318i"`).  
3. **Boolean:** Nilai logik (`true` atau `false`).

---

### **2\. Algoritma Pengisihan (*Sorting*)**
Dokumen menunjukkan cara mengisih data (nombor atau nama) secara menaik (*ascending*).
#### **A. Isihan Buih (*Bubble Sort*)**
Bubble Sort (Isihan Buih) - Nombor Data
```
<html>
<body>
    <script>
        var banciPenduduk=[5,1,4,3,2]; 1
        var bilNombor = banciPenduduk.length, i, j;
        var sementara = banciPenduduk[0];
        document.write("Senarai bilangan ahli rumah dalam bancian (sebelum diisih):<br>");
        document.write(banciPenduduk);
        document.write("<br><br>Senarai bilangan ahli rumah dalam bancian (selepas diisih secara menaik - Isihan Buih):<br>");
        for (i=0; i<bilNombor-1; i++)
        {
            for (j=0; j<bilNombor-i-1; j++)
            {
                if (banciPenduduk[j] > banciPenduduk[j+1])
                {
                    sementara = banciPenduduk[j];
                    banciPenduduk[j] = banciPenduduk[j+1];
                    banciPenduduk[j+1] = sementara;
                }
            }
        }
        document.write(banciPenduduk);
    </script>
</body>
</html>

```
Bubble Sort (Isihan Buih) - Nama Data
```
<html>
<body>
  <script>
    var namaPesakit = ["Siti Aminah", "Ramasamy A/L Muthusamy", "Ah Chong"]; 
    var bilPesakit = namaPesakit.length, i, j;
    var sementara = namaPesakit[0];
    document.write("Senarai pesakit dalam Klinik SIHAT: (sebelum diisih):<br>");
    document.write(namaPesakit);
    document.write("<br><br>Senarai pesakit dalam Klinik SIHAT: (selepas diisih secara menaik- Isihan Buih):<br>");
    for (i=0; i<bilPesakit-1; i++)
    {
      for (j=0; j<bilPesakit-i-1;j++)
      {
        if (namaPesakit[j] > namaPesakit[j+1])
        {
          sementara=namaPesakit[j];
          namaPesakit[j] = namaPesakit[j+1];
          namaPesakit[j+1] = sementara;
        }
      }
    }
    document.write(namaPesakit);
  </script>
</body>
</html>
```
* **Konsep:** Membandingkan dua item bersebelahan dan menukar kedudukan (*swap*) jika susunannya salah. Proses ini diulang sehingga tiada lagi pertukaran diperlukan .  
* **Contoh:** Mengisih bilangan ahli rumah atau nama pesakit mengikut abjad.

#### **B. Isihan Pilih (*Selection Sort*)**
Selection Sort (Isihan Pilih) - String Data
```
<html>
<body>
<script>
    var namaPesakit=["Siti Aminah", "Ramasamy A/L Muthusamy", "Ah Chong"]; // 1
    var i,j,min,sementara;
    var bilPesakit = namaPesakit.length;
    document.write("Senarai pesakit dalam Klinik SIHAT: (sebelum diisih):<br>");
    document.write(namaPesakit);
    document.write("<br><br>Senarai pesakit dalam Klinik SIHAT: (selepas diisih secara menaik - Isihan Pilih):<br>");
    
    // 2
    for (i = 0; i < bilPesakit - 1; i++)
    {
        min = i;
        for(j = i+1; j < bilPesakit; j++)
        {
            if (namaPesakit[j] < namaPesakit[min])
            {
                min = j;
            }
        }
        if (min != i){
            sementara = namaPesakit[i];
            namaPesakit[i] = namaPesakit[min];
            namaPesakit[min] = sementara;
        }
    }
    document.write(namaPesakit);
</script>
</body>
</html>
```
* **Konsep:** Mencari nilai minimum dalam senarai dan menukarnya dengan item pada kedudukan semasa. Ia "memilih" item yang betul untuk diletakkan pada tempatnya .  
* **Contoh:** Mengisih nama pesakit secara menaik.

---

### **3\. Algoritma Carian (*Searching*)**

#### **Carian Perduaan (*Binary Search*)**
Binary Search (Carian Perduaan) - String Data
```
<html>
<body>
  <script>
    var namaPesakit=["Ah Chong", "Ramasamy A/L Muthusamy", "Siti Aminah"]; 
    var namaPesakitCarian="Ramasamy A/L Muthusamy";
    var indeksAwal = 0, indeksAkhir = namaPesakit.length - 1,
        indeksTengah = Math.floor((indeksAkhir + indeksAwal)/2);
    document.write("Senarai pesakit dalam Klinik SIHAT :<br>");
    document.write(namaPesakit);
    document.write("<br><br>Nama Pesakit Yg DiCari: ", namaPesakitCarian);
    
    while(namaPesakit[indeksTengah] != namaPesakitCarian && indeksAwal < indeksAkhir)
    {
      if (namaPesakit[indeksTengah] > namaPesakitCarian)
      {
        indeksAkhir = indeksTengah - 1;
      }
      else
      {
        if (namaPesakit[indeksTengah] < namaPesakit)
        {
          indeksAwal = indeksTengah + 1;
        }
      }
      indeksTengah = Math.floor((indeksAkhir + indeksAwal)/2);
    }
    
    if (namaPesakit[indeksTengah]==namaPesakitCarian)
    {
      document.write(" (masih dalam giliran.)"); 
    }
  </script>
</body>
</html>
```
* **Syarat Utama:** Senarai data **mesti diisih** terlebih dahulu (contohnya mengikut abjad) sebelum carian boleh dilakukan.  
* **Konsep:**  
  1. Mencari item di tengah-tengah senarai (`indeksTengah`).  
  2. Jika item tengah adalah yang dicari, carian tamat.  
  3. Jika tidak, senarai dibahagi dua. Carian diteruskan hanya pada separuh bahagian yang relevan (kiri atau kanan) .  
* **Kelebihan:** Lebih pantas berbanding menyemak satu per satu.

---

### **4\. Struktur Data Barisan (*Queue*)**

Dokumen menerangkan konsep "Masuk Dahulu, Keluar Dahulu" (FIFO \- *First In, First Out*) menggunakan arahan khusus dalam JavaScript.

* **Fungsi `unshift()`:** Digunakan untuk **memasukkan** item baharu ke dalam barisan (permulaan array).  
```
<html>
  <body>
    <script>
      var queueNo = [], noBaru, noKeluar;

      noBaru = 5.5;
      queueNo.unshift(noBaru);
      document.write("<br>Nombor Baru Masuk: ", noBaru);

      noBaru = -1.3;
      queueNo.unshift(noBaru);
      document.write("<br>Nombor Pelajar Masuk: ", noBaru);

      noBaru = 12.95;
      queueNo.unshift(noBaru);
      document.write("<br>Nombor Pelajar Masuk: ", noBaru);

      document.write("<br><br>Senarai Nombor Pelajar Terkini Dalam Giliran (Queue):<br>---------------------------------------");
      document.write("<br>", queueNo);

      noKeluar = queueNo.pop();
      document.write("<br><br>Nombor Pelajar Dikeluarkan: ", noKeluar);

      document.write("<br><br>Senarai Nombor Terkini Dalam Giliran (Queue):<br>---------------------------------------");
      document.write("<br>", queueNo);
    </script>
  </body>
</html>
```
* **Fungsi `pop()`:** Digunakan untuk **mengeluarkan** item yang paling awal dimasukkan (item terakhir dalam array selepas proses unshift).  
```
<html>
  <body>
    <script>
      var queueNama = [], namaBaru, namaKeluar;

      namaBaru = "Siti Maimunah";
      queueNama.unshift(namaBaru);
      document.write("<br>Nama Pesakit Baru Masuk: ", namaBaru);

      namaBaru = "Ramasamy A/L Muthusamy";
      queueNama.unshift(namaBaru);
      document.write("<br>Nama Pesakit Masuk: ", namaBaru);

      namaBaru = "Ah Chong";
      queueNama.unshift(namaBaru);
      document.write("<br>Nama Pesakit Masuk: ", namaBaru);

      document.write("<br><br>Senarai Nama Pesakit Terkini Dalam Giliran (Queue):<br>---------------------------------------");
      document.write("<br>", queueNama);

      namaKeluar = queueNama.pop();
      document.write("<br><br>Nama Pesakit Dikeluarkan: ", namaKeluar);

      document.write("<br><br>Senarai Nama Pesakit Terkini Dalam Giliran (Queue):<br>---------------------------------------");
      document.write("<br>", queueNama);
    </script>
  </body>
</html>
```