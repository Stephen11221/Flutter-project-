import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:trail/firebase_options.dart';
import 'package:trail/screens/admin_home.dart';
import 'package:trail/screens/login_screen.dart';
import 'package:trail/screens/register_screen.dart';
import 'package:trail/screens/reset_password_screen.dart';
import 'package:trail/screens/user_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Role Based Login',
      theme: ThemeData(useMaterial3: true),
      home: const RoleBasedHome(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/admin': (_) => const AdminStoryScreen(),
        '/userHome': (_) => const UserHome(),
        '/reset': (_) => const ResetPasswordScreen(),
      },
    );
  }
}

class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        if (user.email == 'admin@gmail.com') {
          return const AdminStoryScreen();
        }
        return const UserHome();
      },
    );
  }
}
