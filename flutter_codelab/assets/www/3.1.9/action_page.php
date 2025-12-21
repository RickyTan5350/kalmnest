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
    if (isset($_GET['namapengguna'])) {
        // Retrieve the data from the 'namapengguna' input field
        $nama = htmlspecialchars($_GET['namapengguna']);
        
        // Display the result matching your example output
        echo "namapengguna=" . $nama;
    } else {
        echo "No data received.";
    }
    ?>

    <p>The server has processed your input and returned this answer.</p>

</body>
</html>