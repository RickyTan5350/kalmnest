import 'models.dart';

final User user_0 = User(   //create user
  name: const Name(first: 'Pei', last: 'En'),
  avatarUrl: 'assets/avatar_1.png',
  lastActive: DateTime.now(), 
);
final User user_1 = User(
  name: const Name(first: 'Hong', last: 'Xiang'),
  avatarUrl: 'assets/avatar_2.png',
  lastActive: DateTime.now().subtract(const Duration(minutes: 10)), //user last active time
);
final User user_2 = User(
  name: const Name(first: 'Manisha', last: 'K'),
  avatarUrl: 'assets/avatar_3.png',
  lastActive: DateTime.now().subtract(const Duration(minutes: 20)),
);

final List<Email> emails = [    //email
  Email(
    sender: user_1,
    recipients: [],
    subject: 'sub1',
    content: 'content1',
  ),
  Email(
    sender: user_2,
    recipients: [],
    subject: 'sub2',
    content:
        'con2',
  ),
  
];

final List<Email> replies = [
  Email(
    sender: user_2,
    recipients: [user_1, user_2],
    subject: 'Dinner Club',
    content:
        'con3',
  ),
  Email(
    sender: user_0,
    recipients: [user_0, user_2],
    subject: 'Dinner Club',
    content:
        'con4',
  ),
];
