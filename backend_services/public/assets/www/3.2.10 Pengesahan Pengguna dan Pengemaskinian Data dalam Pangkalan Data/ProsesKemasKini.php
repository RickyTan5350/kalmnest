<?php
    $con = mysqli_connect("localhost", "root", "");
    if (!$con) {
        die('Sambungan Gagal: ' . mysqli_connect_error());
    }
    mysqli_select_db($con, "dbpelajar"); // Ensure case matches

    // Use POST as defined in the form method
    $nomurid = $_POST['nomurid'];
    $nama = $_POST['nama'];
    $kelas = $_POST['kelas'];
    $negeri = $_POST['negeri'];

    // SQL updated to match database columns: id, nama, kelas, negeri
    $sql = "UPDATE murid SET 
            nama = '$nama', 
            kelas = '$kelas', 
            negeri = '$negeri' 
            WHERE id = '$nomurid'";

    $result = mysqli_query($con, $sql);
    header('location:Senarai.php'); // Redirect to list page
?>