class Subtask {
  String title;
  bool done;

  Subtask({required this.title, this.done = false});

  Map<String, dynamic> toMap() => {
    'title': title,
    'done': done ? 1 : 0,
  };

  factory Subtask.fromMap(Map<String, dynamic> map) => Subtask(
    title: map['title'] ?? '',
    done: map['done'] == 1,
  );

  Subtask copy() => Subtask(title: title, done: done);
}
