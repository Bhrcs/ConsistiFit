import 'package:flutter/foundation.dart';
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
          data: <String, dynamic>{'display_name': email.text.split('@').first},
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

  Future<void> socialLogin(OAuthProvider provider) async {
    setState(() {
      submitting = true;
      message = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb ? null : 'consistifit://login-callback',
      );
    } on AuthException catch (error) {
      if (mounted) setState(() => message = error.message);
    } catch (_) {
      if (mounted) setState(() => message = 'This sign-in provider still needs its provider credentials configured.');
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> sendReset() async {
    if (email.text.trim().isEmpty) {
      setState(() => message = 'Enter your email first.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email.text.trim());
      if (mounted) setState(() => message = 'Password reset email sent.');
    } on AuthException catch (error) {
      if (mounted) setState(() => message = error.message);
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
            children: <Widget>[
              const SizedBox(height: 42),
              Text('CONSISTENCY, RANKED', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
              const Text('ConsistiFit', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
              const Text('Build consistency. Earn your rank.', style: TextStyle(color: Colors.white60)),
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
                onSubmitted: (_) => submit(),
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: submitting ? null : submit,
                child: Text(submitting ? 'Working…' : createAccount ? 'Create account' : 'Sign in'),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      onPressed: submitting ? null : () => setState(() => createAccount = !createAccount),
                      child: Text(createAccount ? 'I already have an account' : 'Create account'),
                    ),
                  ),
                  Expanded(child: TextButton(onPressed: submitting ? null : sendReset, child: const Text('Forgot password?'))),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(children: <Widget>[Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR')), Expanded(child: Divider())]),
              ),
              OutlinedButton.icon(
                onPressed: submitting ? null : () => socialLogin(OAuthProvider.google),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: submitting ? null : () => socialLogin(OAuthProvider.apple),
                icon: const Icon(Icons.apple),
                label: const Text('Continue with Apple'),
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(message!),
                ),
              const SizedBox(height: 20),
              const Text('Social sign-in buttons become active after the matching provider credentials are enabled in Supabase.', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      );
}
