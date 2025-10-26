import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/views/firebase_test.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder:(context, state) => FirebaseTestView())
  ]
);