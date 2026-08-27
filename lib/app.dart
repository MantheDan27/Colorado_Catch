import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/catch_service.dart';
import 'services/fish_id_service.dart';
import 'services/firestore_service.dart';
import 'services/push_service.dart';
import 'services/storage_service.dart';
import 'theme/colorado_catch_theme.dart';
import 'widgets/loading_indicator.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
        Provider(create: (_) => StorageService()),
        Provider(create: (_) => PushService()),
        Provider(create: (_) => AnalyticsService(FirebaseAnalytics.instance)),
        Provider(create: (context) => CatchService(context.read<FirestoreService>())),
        Provider(create: (_) => FishIdService(clientId: fishialClientId, clientSecret: fishialClientSecret)),
      ],
      child: MaterialApp(
        title: 'Colorado Catch',
        theme: buildColoradoCatchTheme(),
        home: const AuthenticationWrapper(),
      ),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _initialized = false;
  bool _showSplash = true;
  // Which of the onboarding screen's two CTAs was tapped — "Start fishing"
  // pre-selects account creation, "I already have an account" pre-selects
  // sign-in. Only meaningful once _showSplash flips false.
  bool _startInRegisterMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeServices();
      _initialized = true;
    }
  }

  Future<void> _initializeServices() async {
    final pushService = Provider.of<PushService>(context, listen: false);
    await pushService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onStartFishing: () => setState(() {
          _showSplash = false;
          _startInRegisterMode = true;
        }),
        onHaveAccount: () => setState(() {
          _showSplash = false;
          _startInRegisterMode = false;
        }),
      );
    }

    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return LoginScreen(initialRegistering: _startInRegisterMode);
      },
    );
  }
}
