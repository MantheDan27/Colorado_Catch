import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../widgets/loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;
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
      appBar: AppBar(title: const Text('Colorado Catch')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const LoadingIndicator()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  ElevatedButton(onPressed: _signInWithGoogle, child: const Text('Sign in with Google')),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      _isRegistering = !_isRegistering;
                      _error = null;
                    }),
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
    );
  }
}
