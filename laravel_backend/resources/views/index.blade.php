<div>
    @if (count($task))
        <div>There are tasks:</div>
        @foreach ($task as $task1)
            <a href="{{ route('tasks.show', ['id' => $task1->id]) }}">
                {{ $id }} - {{ $task1->title }}
            </a>
            <br>
        @endforeach
    @else
        <div>There are no tasks.</div>
    @endif
</div>
