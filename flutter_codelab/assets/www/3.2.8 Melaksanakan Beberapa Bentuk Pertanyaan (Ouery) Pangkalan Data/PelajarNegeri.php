<?php
// 1. Check if data was actually posted
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST["Negeri"])) {
    
    $negeri = $_POST["Negeri"];

    // 2. Database Connection
    if (file_exists("setup_db.php")) {
        include "setup_db.php";
    } else {
        include "../../setup_db.php";
    }
    
    // Assumes your setup_db.php defines $conn
    $con = $conn; 

    if ($con->connect_error) {
        die("Connection failed: " . $con->connect_error);
    }

    echo "<body>";
    echo "<h3>Hasil Carian</h3>";
    echo "<p>Negeri: <strong>$negeri</strong></p>";
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr bgcolor='#eeeeee'><th>No Murid</th><th>Nama</th><th>Kelas</th></tr>";
    
    // 3. The Query (Fixed 'negeri' column name based on your screenshot)
    $sql = "SELECT * FROM murid WHERE negeri = '$negeri'";
    $result = mysqli_query($con, $sql);
    
    if ($result && mysqli_num_rows($result) > 0) {
        while ($row = mysqli_fetch_array($result)) {
            echo "<tr>";
            echo "<td>".$row['id']."</td>";
            echo "<td>".$row['nama']."</td>";
            echo "<td>".$row['kelas']."</td>";
            echo "</tr>";
        }
    } else {
        echo "<tr><td colspan='3' align='center'>Tiada data murid untuk negeri $negeri.</td></tr>";
    }
    
    echo "</table>";
    echo "<br><a href='CarianNegeri.php'>Kembali ke Carian</a>";
    echo "</body>";

    mysqli_close($con);
} else {
    // Redirect back if page is accessed directly without POST data
    header("Location: CarianNegeri.php");
    exit();
}
?>