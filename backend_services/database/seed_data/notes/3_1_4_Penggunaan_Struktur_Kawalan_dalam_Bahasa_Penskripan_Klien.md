## 3.1.4 Penggunaan Struktur Kawalan dalam Bahasa Penskripan Klien
### **1\. Pengenalan Struktur Kawalan**

Struktur kawalan digunakan untuk mengawal aliran atur cara dalam satu blok kod. Ia menentukan sama ada sesuatu pernyataan dilaksanakan, dilangkau, atau diulang.

Terdapat tiga jenis struktur kawalan utama dalam JavaScript:

* **Berjujukan** (Sequence)  
* **Pilihan** (Selection)  
* **Ulangan** (Repetition/Looping)

  ---

  ### **2\. Struktur Kawalan Jujukan (Sequence)**

Struktur ini melaksanakan arahan satu per satu mengikut tertib baris demi baris tanpa sebarang syarat.
```
<html>
  <head>
    <title>Struktur Kawalan Jujukan</title>
  </head>
  <body>
    <script>
      var namaAnda;
      namaAnda = "Siti Aminah";
      document.write("Hello " + namaAnda);
    </script>
  </body>
</html>

```

* **Ciri-ciri:**  
  * Melibatkan input, proses (seperti pengiraan), dan output.  
* **Contoh Input/Output:**  
  * Input: `prompt("Masukkan nama:")`.  
  * Output: `document.write()` atau `window.alert()`.  
* **Operator Aritmetik:** Campur (+), Tolak (-), Darab (\*), Bahagi (/), dan Modulus (%).
```
<html>
  <head>
    <title>Struktur Kawalan Jujukan</title>
  </head>
  <body>
    <script>
      var tahunsemasa, tahunLahir, umur;
      tahunsemasa = 2017;
      tahunLahir = 1973;
      umur = tahunsemasa - tahunLahir;
      document.write("Umur Anda: " + umur);
    </script>
  </body>
</html>
```
  ---

  ### **3\. Struktur Kawalan Pilihan (Selection)**

Struktur ini memerlukan pernyataan bersyarat untuk menentukan langkah seterusnya. Ia menggunakan **Ungkapan Logik** yang menghasilkan nilai *Boolean* (`true` atau `false`).

**Jenis Pernyataan:**

1. **`if`**: Melaksanakan kod jika syarat adalah *Benar* (True).  
```
<html>
  <head>
    <title>Struktur Kawalan Pilihan</title>
  </head>
  <body>
    <script>
      var noPelajar;
      // 1
      noPelajar = prompt("No. Pelajar: ");
      // 2
      if (noPelajar == 123)
      // 3
      document.write("Anda adalah pelajar Sekolah Taman ABC");
    </script>
  </body>
</html>
```
2. **`if...else`**: Melaksanakan Blok A jika *Benar*, dan Blok B jika *Palsu*.  
```
<html>
  <head>
    <title>Struktur Kawalan Pilihan</title>
  </head>
  <body>
    <script>
      var noPelajar;
      noPelajar = prompt("No. Pelajar: "); // 1
      if (noPelajar == 123) // 2
        document.write("Anda adalah pelajar Sekolah Taman ABC"); // 3
      else
        document.write("Anda BUKAN pelajar Sekolah Taman ABC"); // 4
    </script>
  </body>
</html>
```
3. **`if...else if...else`**: Menguji berbilang syarat.
```
<html>
  <body>
    <script>
      // 1: Variable declaration and initialization
      var markahPeperiksaan = 67, gred;

      // 2: Multi-selection control structure (Nested if-else)
      if (markahPeperiksaan >= 0 && markahPeperiksaan <= 39) {
          gred = "Gred G";
      } else {
          if (markahPeperiksaan >= 40 && markahPeperiksaan <= 44) {
              gred = "Gred E";
          } else {
              if (markahPeperiksaan >= 45 && markahPeperiksaan <= 49) {
                  gred = "Gred D";
              } else {
                  if (markahPeperiksaan >= 50 && markahPeperiksaan <= 59) {
                      gred = "Gred C";
                  } else {
                      if (markahPeperiksaan >= 60 && markahPeperiksaan <= 64) {
                          gred = "Gred C+";
                      } else {
                          if (markahPeperiksaan >= 65 && markahPeperiksaan <= 69) {
                              gred = "Gred B";
                          } else {
                              if (markahPeperiksaan >= 70 && markahPeperiksaan <= 74) {
                                  gred = "Gred B+";
                              } else {
                                  if (markahPeperiksaan >= 75 && markahPeperiksaan <= 79) {
                                      gred = "Gred A-";
                                  } else {
                                      if (markahPeperiksaan >= 80 && markahPeperiksaan <= 89) {
                                          gred = "Gred A";
                                      } else {
                                          if (markahPeperiksaan >= 90 && markahPeperiksaan <= 100) {
                                              gred = "Gred A+";
                                          }
                                      }
                                  }
                              }
                          }
                      }
                  }
              }
          }
      }

      // 3: Output display
      document.write("Markah Peperiksaan: " + markahPeperiksaan + " (" + gred + ")");
    </script>
  </body>
</html>
```

**Operator yang digunakan:**

* **Operator Hubungan:** `==` (sama), `!=` (tidak sama), `>`, `<`, `>=`, `<=`.  
* **Operator Logikal:**  
  * **AND (`&&`):** Semua syarat mesti benar.  
  * **OR (`||`):** Salah satu syarat mesti benar.  
  * **NOT (`!`):** Menyongsangkan nilai boolean.  
    ---

    ### **4\. Struktur Kawalan Ulangan (Looping)**

Mengulang satu blok kod selagi syarat dipenuhi. Terdapat dua kategori utama:

#### **A. Ulangan Berasaskan Pembilang (`for`)**
```
<html>
  <body>
    <script>
      var pembilang;
      // 1: The for loop structure
      for (pembilang = 1; pembilang <= 3; pembilang++) 
      {
          // 5: Statement to repeat
          document.write("Salam Sejahtera!<br>"); 
      }
    </script>
  </body>
</html>
```

Digunakan apabila bilangan ulangan sudah diketahui. Sintaks `for` mempunyai tiga komponen:

1. **Nilai awal:** Permulaan pembilang (cth: `i = 1`).  
2. **Nilai tamat (Syarat):** Menentukan bila ulangan berhenti (cth: `i <= 3`).  
3. **Nilai kemas kini:** Mengubah nilai pembilang (cth: `i++`).

* **`break`**: Memberhentikan ulangan serta-merta. 
```
<html>
<body>
    <script>
        var pembilang;
        for (pembilang = 1; pembilang <= 3; pembilang++)
        {
            document.write("Salam Sejahtera!<br>"); // 1
            if (pembilang == 2) // 2: Condition to interrupt
            {
                break;
            }
        }
    </script>
</body>
</html>
```
* **`continue`**: Melangkau lelaran semasa dan meneruskan ke ulangan seterusnya.
```
<html>
<body>
    <script>
        var pembilang;
        for (pembilang = 1; pembilang <= 3; pembilang++)
        {
            document.write("Salam Sejahtera!<br>"); // 1
            if (pembilang == 2) // 2: Condition to interrupt
            {
                continue;
            }
        }
    </script>
</body>
</html>
```

  #### **B. Ulangan Berasaskan Syarat (`while` & `do...while`)**
##### (syarat dipenuhi) nilai awal bagi pembolehubah ulang ialah 1

```
<html>
  <body>
    <script>
      var ulang=1; 
      do{
        document.write("Salam Sejahtera!<br>"); 
        ulang++; 
      }while(ulang<=3); 
    </script>
  </body>
</html>
```
##### (syarat tidak dipenuhi) nilai awal bagı pembolehubah ulang ialah 4

```
<html>
  <body>
    <script>
      var ulang=4;
      do{
        document.write("Salam Sejahtera!<br>");
        ulang++;
      }while(ulang<=3);
    </script>
  </body>
</html>
```

Digunakan apabila bilangan ulangan bergantung kepada syarat.

* **`while`**: Semak syarat **dahulu** sebelum laksanakan kod. Jika syarat salah dari awal, kod tidak akan dijalankan langsung.  
```
<html>
  <body>
    <script>
      var ulang=1; 1
      while(ulang<=3) 2
      {
        document.write("Salam Sejahtera!<br>"); 3
        ulang++; 4
      }
    </script>
  </body>
</html>
```
  ---