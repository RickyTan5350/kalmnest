<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    @csrf
    <form action = '/level-type' method = "GET">
    <h4>level name</h4>
        <input type = "text" name = "level_type_name">
        <button>submit</button>
    </form>
</body>
</html>