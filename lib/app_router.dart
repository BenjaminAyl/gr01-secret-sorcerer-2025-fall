import 'package:go_router/go_router.dart';
//import 'package:secret_sorcerer/views/firebase_test.dart';
import 'package:secret_sorcerer/views/home_screen.dart';
import 'package:secret_sorcerer/views/login_screen.dart';
import 'package:secret_sorcerer/views/signup_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder:(context, state) => LoginScreen()),
    GoRoute(path: '/signup', builder:(context, state) => SignupScreen()),
    GoRoute(path: '/home', builder:(context, state)=> HomeScreen())
  ]
);