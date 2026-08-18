import 'package:ethicfin/providers/task_provider.dart';
import 'package:ethicfin/screens/task_list_screen.dart';
import 'package:ethicfin/services/connectivity_service.dart';
import 'package:ethicfin/services/firestore_service.dart';
import 'package:ethicfin/services/local_storage_service.dart';
import 'package:ethicfin/services/task_repository.dart';
import 'package:ethicfin/utils/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  final localStorageService = LocalStorageService();
  await localStorageService.init();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {

    debugPrint('Firebase initialization skipped: $e');
  }

  final connectivityService = ConnectivityService();
  await connectivityService.init();

  final taskRepository = TaskRepository(
    firestoreService: FirestoreService(),
    localStorageService: localStorageService,
    connectivityService: connectivityService,
  );

  runApp(TaskManagerApp(
    taskRepository: taskRepository,
    connectivityService: connectivityService,
  ));
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({
    super.key,
    required this.taskRepository,
    required this.connectivityService,
  });

  final TaskRepository taskRepository;
  final ConnectivityService connectivityService;

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider(
        repository: widget.taskRepository,
        connectivityService: widget.connectivityService,
      ),
      child: MaterialApp(
        title: 'Task Manager',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: TaskListScreen(onToggleTheme: _toggleTheme),
      ),
    );
  }
}
