## 3.2.8 Melaksanakan Beberapa Bentuk Pertanyaan (Ouery) Pangkalan Data
### **1\. Jenis Pertanyaan Pangkalan Data (SQL Queries)**

Maklumat dalam pangkalan data diperoleh semula menggunakan mekanisme pertanyaan atau *Structured Query Language* (SQL). Terdapat dua jenis pertanyaan utama:

* **Pertanyaan Tindakan (Action Queries):**  
  * Digunakan untuk mengubah atau memanipulasi data dan struktur.  
  * Tugas termasuk: Mencipta jadual baharu, menambah, mengemas kini, atau menghapuskan data.  
* **Pertanyaan Memilih (Selection Queries):**  
  * Digunakan untuk mengambil data sedia ada dari pangkalan data untuk dipaparkan, dicetak, atau disimpan tanpa mengubah data asal.

---

### **2\. Contoh Arahan SQL**

Berikut adalah contoh sintaks SQL yang terdapat dalam dokumen:

#### **A. Membina Jadual (Create Table)**

* **Jadual MURID:**  
  * Mencipta jadual dengan medan: `NOMURID` (kunci unik), `NAMA`, `KELAS`, dan `NEGERILAHIR` .  
```
<?php
include 'setup_db.php';

// SQL to create table MURID
$sql = "CREATE TABLE MURID (
    NOMURID int(11) DEFAULT NULL,
    NAMA varchar(30) DEFAULT NULL,
    KELAS varchar(15) DEFAULT NULL,
    NEGERILAHIR varchar(15) DEFAULT NULL,
    UNIQUE KEY NOMURID (NOMURID)
)";

if ($conn->query($sql) === TRUE) {
    echo "Table MURID created successfully";
} else {
    echo "Error creating table: " . $conn->error;
}

$conn->close();
?>

```
* **Jadual PENGGUNA:**  
  * Mencipta jadual dengan medan: `NAMAPENGGUNA`, `KATALALUAN`, dan `JENISPENGGUNA`.
```
<?php
include 'setup_db.php';

// SQL to create table PENGGUNA
$sql = "CREATE TABLE PENGGUNA (
    NAMAPENGGUNA varchar(10) NOT NULL,
    KATALALUAN varchar(10) NOT NULL,
    JENISPENGGUNA int(1) NOT NULL
)";

if ($conn->query($sql) === TRUE) {
    echo "Table PENGGUNA created successfully";
} else {
    echo "Error creating table: " . $conn->error;
}

$conn->close();
?>
```

#### **B. Menambah Data (Insert Into)**

* Arahan untuk memasukkan data pelajar ke dalam jadual MURID:  
  * `INSERT INTO MURID VALUES("1", "Siti Khadijah Sofia", "4 Bistari 1", "Kedah");`.
```
<?php
// Include the connection file
include 'setup_db.php';

// Data extracted from the image
$data = [
    ["1", "Siti Khadijah Sofia", "4 Bistari 1", "Kedah"],
    ["2", "Amri bin Yahya", "4 Bistari 2", "Johor"]
];

foreach ($data as $row) {
    // Escape strings to prevent SQL errors with names like 'bin'
    $nomurid = $conn->real_escape_string($row[0]);
    $nama = $conn->real_escape_string($row[1]);
    $kelas = $conn->real_escape_string($row[2]);
    $negeri = $conn->real_escape_string($row[3]);

    $sql = "INSERT INTO MURID (NOMURID, NAMA, KELAS, NEGERILAHIR) 
            VALUES ('$nomurid', '$nama', '$kelas', '$negeri')";

    if ($conn->query($sql) === TRUE) {
        echo "Record for $nama added successfully.<br>";
    } else {
        echo "Error: " . $sql . "<br>" . $conn->error . "<br>";
    }
}

$conn->close();
?>
```
#### **C. Memilih Data (Select)**

* **Pilih Semua:** `SELECT * FROM MURID;` (Memaparkan semua data murid).  
* **Pilih Bersyarat:** `SELECT * FROM MURID WHERE NEGERILAHIR = 'KEDAH';` (Memaparkan murid dari Kedah sahaja).  
* **Pilih Medan Tertentu:** `SELECT NAMA, KELAS FROM MURID;` (Hanya memaparkan nama dan kelas).
```
<?php
// Include your connection file
include 'setup_db.php';

// The SQL command to select all records from the MURID table
$sql = "SELECT * FROM MURID";
$result = $conn->query($sql);

echo "<h2>Senarai Murid (Student List)</h2>";

if ($result->num_rows > 0) {
    // Start building the HTML table
    echo "<table border='1' cellpadding='10'>";
    echo "<tr>
            <th>No. Murid</th>
            <th>Nama</th>
            <th>Kelas</th>
            <th>Negeri Lahir</th>
          </tr>";

    // Output data of each row
    while($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row["NOMURID"] . "</td>";
        echo "<td>" . $row["NAMA"] . "</td>";
        echo "<td>" . $row["KELAS"] . "</td>";
        echo "<td>" . $row["NEGERILAHIR"] . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "Tiada data dijumpai (No records found).";
}

$conn->close();
?>

```

---

### **3\. Integrasi SQL dalam PHP (Menapis Data)**

Contoh ini menunjukkan bagaimana membina laman web yang membenarkan pengguna memilih negeri dan memaparkan senarai murid dari negeri tersebut.

#### **Langkah 1: Laman Web Borang (Negeri.php)**
```
<html>
    <body>
        <h3>Senarai Nama Murid Berdasarkan Negeri Kelahiran</h3>
        <form action = "PelajarNegeri.php" method = "POST">
            Pilih Negeri :
            <select id = "PilihanNegeri" name = "Negeri">
                <option value = "Johor">Johor</option>
                <option value = "Kedah">Kedah</option>
                <option value = "Kelantan">Kelantan</option>
                <option value = "Labuan">Labuan</option>
                <option value = "Melaka">Melaka</option>
                <option value = "Negeri Sembilan">Negeri Sembilan</option>
                <option value = "Pahang">Pahang</option>
                <option value = "Perak">Perak</option>
                <option value = "Perlis">Perlis</option>
                <option value = "Pulau Pinang">Pulau Pinang</option>
                <option value = "Sabah">Sabah</option>
                <option value = "Sarawak">Sarawak</option>
                <option value = "Selangor">Selangor</option>
                <option value = "Terengganu">Terengganu</option>
                <option value = "Kuala Lumpur">Kuala Lumpur</option>
            </select>
            <input type = "submit" value = "Proses" name = "submit">
        </form>
    </body>
</html>
```
* Laman ini menyediakan borang HTML untuk pengguna memilih negeri.  
* Menggunakan elemen `<select>` dan `<option>` untuk senarai negeri (contoh: Johor, Kedah, Kelantan) .  
* Apabila butang "Proses" ditekan, data dihantar ke fail `PelajarNegeri.php` menggunakan kaedah `POST`.

#### **Langkah 2: Laman Web Pemprosesan (PelajarNegeri.php)**

* **Sambungan Pangkalan Data:** Menggunakan `mysqli_connect` untuk menyambung ke `localhost` dan `mysqli_select_db` untuk memilih pangkalan data `dbPelajar`.  
* **Menerima Input:** Mengambil nilai negeri yang dipilih pengguna menggunakan `$namaNegeri = $_POST["Negeri"];`.  
* **Melaksanakan SQL:**  
  * Arahan SQL dibina: `SELECT * FROM MURID WHERE NEGERILAHIR = '$namaNegeri'`.  
  * Pertanyaan dijalankan menggunakan `mysqli_query`.  
* **Memaparkan Hasil:**  
  * Menggunakan gelung `while` dan `mysqli_fetch_array` untuk memaparkan setiap baris data (No Murid, Nama, Kelas) ke dalam jadual HTML .

---