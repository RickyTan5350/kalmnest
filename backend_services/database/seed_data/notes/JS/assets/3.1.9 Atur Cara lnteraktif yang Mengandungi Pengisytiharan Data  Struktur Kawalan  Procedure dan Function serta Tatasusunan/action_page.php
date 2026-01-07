<!DOCTYPE html>
<html>
<head>
    <title>Submitted Form Data</title>
</head>
<body>

    <h2>Submitted Form Data</h2>
    <p>Your input was received as:</p>

    <?php
    // Check if the form was submitted using the GET method (default for your HTML)
    if (isset($_POST['namapengguna'])) {
        // Retrieve the data from the 'namapengguna' input field
        $nama = htmlspecialchars($_POST['namapengguna']);
        
        // Display the result matching your example output
        echo "namapengguna=" . $nama;
    } else {
        echo "No data received.";
    }
    ?>


</body>
</html>