<!DOCTYPE html>
<html>
<head>
    <title>Class List</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="p-5">
    <div class="container">
        <h2>Class List</h2>
        @if(session('success'))
            <div class="alert alert-success">{{ session('success') }}</div>
        @endif

        <table class="table table-bordered mt-3">
            <thead>
                <tr>
                    <th>Class ID</th>
                    <th>Class Name</th>
                    <th>Teacher ID</th>
                    <th>Description</th>
                    <th>Admin ID</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                @foreach($classes as $class)
                <tr>
                    <td>{{ $class->class_id }}</td>
                    <td>{{ $class->class_name }}</td>
                    <td>{{ $class->teacher_id }}</td>
                    <td>{{ $class->description }}</td>
                    <td>{{ $class->admin_id }}</td>
                    <td>
                        <button class="btn btn-warning btn-sm" disabled>Edit</button>
                        <button class="btn btn-danger btn-sm" disabled>Delete</button>
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>

        <a href="{{ route('classes.create') }}" class="btn btn-primary mt-3">Create New Class</a>
    </div>
</body>
</html>
