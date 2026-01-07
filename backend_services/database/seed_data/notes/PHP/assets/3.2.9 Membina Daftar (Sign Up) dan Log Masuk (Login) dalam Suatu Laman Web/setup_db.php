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

// Create PENGGUNA table for auth
$sql = "CREATE TABLE IF NOT EXISTS PENGGUNA (
    ID INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    NAMAPENGGUNA VARCHAR(50) NOT NULL UNIQUE,
    KATALALUAN VARCHAR(255) NOT NULL,
    JENISPENGGUNA VARCHAR(20) NOT NULL
)";

if ($conn->query($sql) !== TRUE) {
  die("Error creating table PENGGUNA: " . $conn->error);
}

// Optional: Insert admin user if empty
$check = $conn->query("SELECT * FROM PENGGUNA WHERE NAMAPENGGUNA='admin'");
if ($check->num_rows == 0) {
    // Determine password hashing or plain - Note example used plain compare
    // Note 3.2.9 ProsesMasuk uses: WHERE ... KATALALUAN = '$katalaluan' (Plain text comparison! Security risk but follows curriculum)
    $sql = "INSERT INTO PENGGUNA (NAMAPENGGUNA, KATALALUAN, JENISPENGGUNA) VALUES ('admin', '1234', 'GURU')";
    $conn->query($sql);
}

?>
