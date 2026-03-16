import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'screens/dashboard/class_management_screen.dart';
import 'screens/dashboard/grade_entry_screen.dart';
import 'screens/dashboard/manager_student_list_screen.dart';
import 'screens/dashboard/student_grades_screen.dart';
import 'screens/dashboard/student_management_screen.dart';

Future<void> _ensureDefaultAdminUser() async {
  await FirebaseFirestore.instance.collection('users').doc('ad min').set({
    'username': 'ad min',
    'email': 'ad min',
    'password': 'admin',
    'role': 'Quản trị',
    'name': 'Administrator',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _ensureDefaultAdminUser();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Management',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const StudentManagementScreen(),
        '/manager-dashboard': (context) => const ManagerStudentListScreen(),
        '/class-management': (context) => const ClassManagementScreen(),
        '/grade-entry': (context) => const GradeEntryScreen(),
        '/student-grades': (context) => const StudentGradesScreen(),
      },
    );
  }
}
