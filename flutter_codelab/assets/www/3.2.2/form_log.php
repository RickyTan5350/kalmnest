<!DOCTYPE html>
<html>
<head>
<title>Log Masuk Form</title>
<style>
body { font-family: sans-serif; padding: 20px; }
input[type=text] { padding: 8px; width: 100%; box-sizing: border-box; }
input[type=submit] { padding: 10px 20px; background: #007bff; color: white; border: none; cursor: pointer; margin-top: 10px; }
.log-entry { margin-top: 20px; padding: 10px; background: #f0f0f0; border-left: 4px solid #007bff; }
</style>
</head>
<body>

<h3>Sila Masukkan Nama</h3>

<form method="post" action="">
  <label for="Name">Nama:</label><br>
  <input type="text" id="Name" name="Name" required><br>
  <input type="submit" name="Submit" value="Masuk">
</form>

<?php
if (isset($_POST['Submit'])) {
    $name = htmlspecialchars($_POST['Name']);
    $date = date("d/m/Y h:i:s a");
    // Add newline character to the end
    $log = $name . ":" . $date . "\n";
    
    $fileVal = "LogMasuk.txt";

    // Open file in append mode
    $f = fopen($fileVal, "a");
    if ($f) {
        fwrite($f, $log);
        fclose($f);
        echo "<div class='log-entry'><strong>Berjaya!</strong><br>Data direkodkan: $log</div>";
        
        // Optional: Read back the file to show history
        echo "<h4>Sejarah Log:</h4><pre>";
        if(file_exists($fileVal)) {
            echo file_get_contents($fileVal);
        }
        echo "</pre>";
    } else {
        echo "<div style='color:red'>Gagal membuka fail.</div>";
    }
}
?>

</body>
</html>
