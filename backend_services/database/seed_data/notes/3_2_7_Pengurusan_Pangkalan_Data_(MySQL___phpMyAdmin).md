## **3.2.7 Pengurusan Pangkalan Data (MySQL & phpMyAdmin)**

Bahagian ini merangkumi empat aspek utama dalam pengurusan pangkalan data menggunakan aplikasi **phpMyAdmin**, iaitu sebuah antara muka grafik (GUI) berasaskan web untuk MySQL.

![xampp.png](https://kalmnest.test/storage/uploads/1766307225_xampp.png)
https://www.apachefriends.org/




### **1\. Membina Pangkalan Data**

![xampp_control_panel.png](https://kalmnest.test/storage/uploads/1766307225_xampp_control_panel.png)


Sebelum membina pangkalan data, pastikan **Web Server Apache** dan **MySQL** telah dilancarkan melalui tetingkap **XAMPP Control Panel**.

**Langkah-langkah:**


* Buka pelayar web dan taip `http://localhost/dashboard`.  
* Klik pada menu **phpMyAdmin**.  

![membina_pangkalan_data.png](https://kalmnest.test/storage/uploads/1766307248_membina_pangkalan_data.png)

* Klik menu **Databases** pada bahagian kiri atas.  
* Masukkan nama pangkalan data (contoh: `dbPelajar`) dalam ruangan **Create database**.  

![dbpelajar.png](https://kalmnest.test/storage/uploads/1766307910_dbpelajar.png)

* Pilih **Collation** (piawaian penyusunan huruf/angka), disyorkan memilih `utf8_general_ci`.  
* Klik butang **Create**.

---

### **2\. Mengemas kini Pangkalan Data**

Proses ini dilakukan apabila terdapat keperluan untuk mengubah atau menambah medan dalam jadual pangkalan data.

**Langkah-langkah:**

* Login ke **phpMyAdmin** dan pilih pangkalan data yang ingin dikemas kini.  
* Klik menu **Structure**.  

![menambah.png](https://kalmnest.test/storage/uploads/1766308032_menambah.png)

* **Untuk Mengubah:** Klik pada bahagian **'Change'** pada medan yang berkenaan.  
* **Untuk Menghapuskan:** Klik pada bahagian **'Drop'** pada medan yang ingin dibuang.

---

### **3\. Membuat Sandaran (Backup)**

Sandaran data sangat penting untuk menjamin keselamatan data sekiranya berlaku kerosakan atau kehilangan.

**Langkah-langkah (Menggunakan arahan 'Export'):**

![export.png](https://kalmnest.test/storage/uploads/1766308442_export.png)



* Pilih pangkalan data yang ingin disandarkan (contoh: `dbPelajar`).  
* Klik menu **Export**.  
* Taip nama fail sandaran di ruangan **'New Template'** (contoh: `dbPelajarBackup`).  
![exportDetails.png](https://kalmnest.test/storage/uploads/1766308442_exportDetails.png)
* **Tip:** Sebaiknya namakan fail dengan format `Backup-NamaDB_Tarikh_Masa` (contoh: `Backup-dbPelajar_2016-12-31_08_45_11.sql`) untuk memudahkan pengecaman fail terkini.  
* Klik butang **Go**. Fail berformat `.sql` akan dicipta.

---

### **4\. Memulihkan (Restore) Pangkalan Data**

Proses mengembalikan pangkalan data kepada keadaan asal berdasarkan fail sandaran yang terkini.

**Langkah-langkah (Menggunakan arahan 'Import'):**

* Pilih nama pangkalan data yang ingin dipulihkan.  
* Klik menu **Import**.  
* Pada bahagian **"File to import"**, klik **Choose File**.  

![import.png](https://kalmnest.test/storage/uploads/1766308442_import.png)

* Cari dan pilih fail sandaran `.sql` yang telah disimpan sebelum ini.  
* Klik butang **Go** untuk memulakan proses pemulihan.