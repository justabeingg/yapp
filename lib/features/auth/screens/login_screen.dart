import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import 'package:gap/gap.dart';

enum _AuthMode { login, register, forgotPassword }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthMode _mode = _AuthMode.login;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _resetEmailSent = false;
  bool _registrationSent = false; // NEW

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || (_mode != _AuthMode.forgotPassword && password.isEmpty)) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() { _loading = true; _errorMessage = null; });

    try {
      final authService = ref.read(authProvider);

      if (_mode == _AuthMode.register) {
        await authService.signUp(email: email, password: password);
        if (mounted) setState(() => _registrationSent = true);
      } else if (_mode == _AuthMode.login) {
        await authService.signIn(email: email, password: password);
      } else if (_mode == _AuthMode.forgotPassword) {
        await authService.resetPassword(email);
        if (mounted) setState(() => _resetEmailSent = true);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseError(String error) {
    if (error.contains('Invalid login credentials')) return 'Wrong email or password';
    if (error.contains('Email not confirmed')) return 'Please confirm your email first';
    if (error.contains('User already registered')) return 'Account already exists. Try logging in';
    if (error.contains('weak password')) return 'Password must be at least 6 characters';
    return 'Something went wrong. Try again';
  }

  @override
  Widget build(BuildContext context) {
    // Show confirmation screen after registration
    if (_registrationSent) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(48),
                Text('yapp',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.primary,
                      fontSize: 52,
                      letterSpacing: -3,
                    )),
                const Spacer(),
                const Text('📬', style: TextStyle(fontSize: 64)),
                const Gap(24),
                Text('Confirm your email',
                    style: AppTextStyles.headlineLarge),
                const Gap(12),
                Text(
                  'We sent a confirmation link to\n${_emailController.text.trim()}\n\nTap the link in the email to activate your account, then come back and log in.',
                  style: AppTextStyles.bodyLarge,
                ),
                const Gap(32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => setState(() {
                      _registrationSent = false;
                      _mode = _AuthMode.login;
                      _passwordController.clear();
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('I confirmed, take me to login',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.white)),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(48),
              Text('yapp',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 52,
                    letterSpacing: -3,
                  )),
              const Gap(8),
              Text(
                _mode == _AuthMode.login
                    ? 'Welcome back.'
                    : _mode == _AuthMode.register
                        ? 'Join the chaos.'
                        : 'Reset your password.',
                style: AppTextStyles.bodyMedium,
              ),
              const Gap(48),

              if (_mode == _AuthMode.forgotPassword && _resetEmailSent) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📬', style: TextStyle(fontSize: 32)),
                      const Gap(12),
                      Text('Check your inbox',
                          style: AppTextStyles.headlineMedium),
                      const Gap(6),
                      Text(
                        'We sent a reset link to ${_emailController.text.trim()}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                TextButton(
                  onPressed: () => setState(() {
                    _mode = _AuthMode.login;
                    _resetEmailSent = false;
                  }),
                  child: Text('Back to login',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.primary)),
                ),
              ] else ...[
                _label('Email'),
                const Gap(8),
                _textField(
                  controller: _emailController,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const Gap(16),

                if (_mode != _AuthMode.forgotPassword) ...[
                  _label('Password'),
                  const Gap(8),
                  _textField(
                    controller: _passwordController,
                    hint: _mode == _AuthMode.register
                        ? 'Min 6 characters'
                        : 'Your password',
                    obscure: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const Gap(8),
                  if (_mode == _AuthMode.login)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(
                            () => _mode = _AuthMode.forgotPassword),
                        child: Text('Forgot password?',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.primary)),
                      ),
                    ),
                ],

                if (_errorMessage != null) ...[
                  const Gap(8),
                  Text(_errorMessage!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.error)),
                ],

                const Gap(24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleEmailAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _mode == _AuthMode.login
                                ? 'Log In'
                                : _mode == _AuthMode.register
                                    ? 'Create Account'
                                    : 'Send Reset Link',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white),
                          ),
                  ),
                ),

                const Gap(32),

                if (_mode != _AuthMode.forgotPassword)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() {
                        _mode = _mode == _AuthMode.login
                            ? _AuthMode.register
                            : _AuthMode.login;
                        _errorMessage = null;
                      }),
                      child: Text(
                        _mode == _AuthMode.login
                            ? "Don't have an account? Sign up"
                            : 'Already have an account? Log in',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.labelLarge);

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium,
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
