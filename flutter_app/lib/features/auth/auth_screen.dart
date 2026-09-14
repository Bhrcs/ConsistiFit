import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? message;
  bool createAccount = false;
  bool submitting = false;

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      setState(() => message = 'Enter an email and a password with at least 6 characters.');
      return;
    }
    setState(() {
      submitting = true;
      message = null;
    });
    try {
      if (createAccount) {
        await Supabase.instance.client.auth.signUp(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      if (!mounted) return;
      setState(() => message = createAccount
          ? 'Account created. Check your email if confirmation is enabled.'
          : 'Signed in.');
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => message = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => message = 'Could not complete sign in. Try again.');
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 50),
              const Text(
                'ConsistiFit',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const Text(
                'Build consistency. Earn your rank.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: submitting ? null : submit,
                child: Text(submitting
                    ? 'Working…'
                    : createAccount
                        ? 'Create account'
                        : 'Sign in'),
              ),
              TextButton(
                onPressed: submitting
                    ? null
                    : () => setState(() => createAccount = !createAccount),
                child: Text(createAccount
                    ? 'Already have an account? Sign in'
                    : 'New here? Create account'),
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(message!),
                ),
            ],
          ),
        ),
      );
}
