import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/views/leaderboard.dart';
import 'package:secret_sorcerer/views/profile/edit_profile_screen.dart';
import 'package:secret_sorcerer/views/profile/friends_screen.dart';
import 'package:secret_sorcerer/views/join_lobby_screen.dart';
import 'package:secret_sorcerer/views/lobby_screen.dart';
import 'package:secret_sorcerer/views/profile/profile_screen.dart';
import 'package:secret_sorcerer/views/home_screen.dart';
import 'package:secret_sorcerer/views/login_screen.dart';
import 'package:secret_sorcerer/views/signup_screen.dart';
import 'package:secret_sorcerer/views/game_screen.dart';
import 'package:secret_sorcerer/views/role_reveal_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder:(context, state) => LoginScreen()),
    GoRoute(path: '/signup', builder:(context, state) => SignupScreen()),
    GoRoute(path: '/home', builder:(context, state)=> HomeScreen()),
    GoRoute(path: '/profile', builder:(context, state)=> ProfileScreen()),
    GoRoute(path: '/profile/edit', builder:(context, state)=> EditProfileScreen()),
    GoRoute(path: '/profile/friends', builder:(context, state)=> ManageFriendsScreen()),
    GoRoute(path: '/leaderboard', builder:(context, state)=> LeaderboardView()),
    GoRoute(path: '/lobby/:code', builder: (context, state) => LobbyScreen(code: state.pathParameters['code']!),),
    GoRoute(path: '/game/:code', builder: (context, state) => GameScreen(code: state.pathParameters['code']!),),
    GoRoute(path: '/join', builder:(context, state)=> JoinLobbyScreen()),
    GoRoute(path: '/reveal/:code', builder: (context, state) => RoleRevealScreen(code: state.pathParameters['code']!),),
  ]
);