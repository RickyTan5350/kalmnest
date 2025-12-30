<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "dbPelajar"; 

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
// Note: We leave the connection open here so other files can use $conn
?>