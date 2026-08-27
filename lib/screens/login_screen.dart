import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../theme/colorado_catch_theme.dart';
import '../widgets/loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialRegistering = false});

  /// Pre-selects create-account vs. sign-in mode — set by which onboarding
  /// CTA the user tapped ("Start fishing" vs. "I already have an account").
  final bool initialRegistering;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late bool _isRegistering = widget.initialRegistering;
  String? _error;

  Future<void> _submitEmail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isRegistering) {
        await authService.registerWithEmail(email, password);
        await analytics.logEvent('sign_up', {'method': 'email'});
      } else {
        await authService.signInWithEmail(email, password);
        await analytics.logLogin('email');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await authService.signInWithGoogle();
      await analytics.logLogin('google');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const LoadingIndicator()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      _isRegistering ? 'Create your account' : 'Welcome back',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegistering
                          ? 'Set up an account to start logging catches.'
                          : 'Sign in to pick up where you left off.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitEmail,
                      child: Text(_isRegistering ? 'Create Account' : 'Sign in with Email'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _signInWithGoogle, child: const Text('Sign in with Google')),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() {
                        _isRegistering = !_isRegistering;
                        _error = null;
                      }),
                      style: TextButton.styleFrom(foregroundColor: AppColors.forest),
                      child: Text(_isRegistering
                          ? 'Already have an account? Sign in'
                          : "Don't have an account? Create one"),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ]
                  ],
                ),
        ),
      ),
    );
  }
}
