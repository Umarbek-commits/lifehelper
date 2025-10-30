import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LifeHelperApp());
}

class LifeHelperApp extends StatelessWidget {
  const LifeHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeHelper',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF9F8F6),
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<UserCredential?> _signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const TaskPage();
        }
        return Scaffold(
          backgroundColor: const Color(0xFFF9F8F6),
          body: Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Войти через Google"),
              onPressed: () async {
                await _signInWithGoogle();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final TextEditingController _taskController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  int totalPoints = 0;
  String motivationText = "";

  @override
  void initState() {
    super.initState();
    _loadUserPoints();
  }

  Future<void> _loadUserPoints() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      setState(() {
        totalPoints = doc['points'] ?? 0;
      });
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'name': user!.displayName, 'points': 0});
    }
  }

  Future<void> _updateUserPoints(int points) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'points': points});
  }

  Future<void> _addTask() async {
    if (_taskController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('tasks').add({
      'title': _taskController.text,
      'completed': false,
      'points': 10,
      'userId': user!.uid,
    });

    _taskController.clear();
  }

  Future<void> _toggleTask(String id, bool completed, int points) async {
    await FirebaseFirestore.instance.collection('tasks').doc(id).update({
      'completed': !completed,
    });

    if (!completed) {
      setState(() {
        totalPoints += points;
        motivationText = _getRandomMotivation();
      });
    } else {
      setState(() {
        totalPoints -= points;
      });
    }

    await _updateUserPoints(totalPoints);
  }

  Future<void> _deleteTask(String id) async {
    await FirebaseFirestore.instance.collection('tasks').doc(id).delete();
  }

  String _getRandomMotivation() {
    final messages = [
      "Отлично! 💪 Один шаг ближе к цели!",
      "Ты молодец! Продолжай в том же духе! 🔥",
      "Супер! Ещё одна победа! 🏆",
      "Так держать! 🌟",
      "Твоя дисциплина приносит результат! 🚀",
    ];
    messages.shuffle();
    return messages.first;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('LifeHelper ✅'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Задачи"),
              Tab(text: "Рейтинг"),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  "Баллы: $totalPoints",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildTasksTab(),
            _buildLeaderboardTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    return Column(
      children: [
        if (motivationText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              motivationText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.orange,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    labelText: 'Введите задачу...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addTask,
                child: const Text('Добавить'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('userId', isEqualTo: user!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final tasks = snapshot.data!.docs;

              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final title = task['title'];
                  final completed = task['completed'];
                  final points = task['points'];

                  return Card(
                    color: completed ? Colors.green[50] : Colors.white,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(
                        title,
                        style: TextStyle(
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text('Баллы: $points'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              completed
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: Colors.orange,
                            ),
                            onPressed: () =>
                                _toggleTask(task.id, completed, points),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTask(task.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final name = users[index]['name'];
            final points = users[index]['points'];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    index == 0 ? Colors.amber : Colors.orangeAccent,
                child: Text("${index + 1}"),
              ),
              title: Text(name ?? "Без имени"),
              trailing: Text(
                "$points очков",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }
}
