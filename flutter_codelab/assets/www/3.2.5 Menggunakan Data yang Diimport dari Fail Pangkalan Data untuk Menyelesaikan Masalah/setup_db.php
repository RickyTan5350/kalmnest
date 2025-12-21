<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "dbPelajar";

// Create connection
$conn = new mysqli($servername, $username, $password);

// Check connection
if ($conn->connect_error) {
  die("Connection failed: " . $conn->connect_error);
}

// Create database if not exists
$conn->query("CREATE DATABASE IF NOT EXISTS $dbname");
$conn->select_db($dbname);

// Create table if not exists
$sql = "CREATE TABLE IF NOT EXISTS MURID (
id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
nama VARCHAR(30) NOT NULL,
umur INT(3) NOT NULL,
kelas VARCHAR(10),
negeri VARCHAR(20)
)";

if ($conn->query($sql) === TRUE) {
  echo "Table MURID ready.<br>";
} else {
  echo "Error creating table: " . $conn->error;
}

// --- INSERT SAMPLE VALUES ---
// We use INSERT IGNORE to avoid errors if running multiple times (based on ID if defined, or just standard insert)
// Since we have auto-increment ID, we just insert.
// To prevent endless duplicates for this demo, we check count first or just insert.
// User asked to "insert some sample values", so we will provide a script that explicit inserts them.

$users = [
    ['Ali Bin Abu', 16, '4 Sains', 'Johor'],
    ['Siti Aminah', 15, '3 Bijak', 'Selangor'],
    ['Tan Mei Ling', 17, '5 Bestari', 'Penang'],
    ['Muthusamy', 16, '4 Sains', 'Perak'],
    ['Khadijah', 15, '3 Amanah', 'Kedah']
];

foreach ($users as $u) {
    $nama = $u[0];
    $umur = $u[1];
    $kelas = $u[2];
    $negeri = $u[3]; // Added extra field for fun/completeness matching typical biodata
    
    // Check existence by Name to allow re-run without duplicates
    $check = $conn->query("SELECT * FROM MURID WHERE nama='$nama'");
    if ($check->num_rows == 0) {
        $sql = "INSERT INTO MURID (nama, umur, kelas, negeri) VALUES ('$nama', '$umur', '$kelas', '$negeri')";
        if ($conn->query($sql) === TRUE) {
            echo "Inserted: $nama<br>";
        } else {
            echo "Error: " . $sql . "<br>" . $conn->error;
        }
    } else {
        echo "Skipped: $nama (Already exists)<br>";
    }
}

$conn->close();
?>
