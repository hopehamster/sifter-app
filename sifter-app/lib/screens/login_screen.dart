import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

enum SignUpMethod { email, otp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showOTPField = false;
  SignUpMethod _selectedSignUpMethod = SignUpMethod.email;
  DateTime? _selectedBirthDate;
  String? _pendingVerificationEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // For sign up, check if birth date is selected
    if (_isSignUp && _selectedBirthDate == null) {
      _showSnackBar('Please select your birth date', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      if (_isSignUp) {
        if (_selectedSignUpMethod == SignUpMethod.otp) {
          await _handleOTPSignUp(authService);
        } else {
          await _handleEmailSignUp(authService);
        }
      } else {
        await _handleSignIn(authService);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleOTPSignUp(AuthService authService) async {
    if (!_showOTPField) {
      // Step 1: Send OTP
      final result = await authService.sendOTPForSignUp(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        birthDate: _selectedBirthDate!,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() {
          _showOTPField = true;
          _pendingVerificationEmail = _emailController.text.trim();
        });
        _showSnackBar(result.message ?? 'OTP sent to your email!');
      } else {
        _showSnackBar(result.error!, isError: true);
      }
    } else {
      // Step 2: Verify OTP and complete sign up
      final result = await authService.verifyOTPAndCreateAccount(
        email: _pendingVerificationEmail!,
        otp: _otpController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        _showSnackBar(result.message ?? 'Account created successfully!');
        // AuthGate will handle navigation
      } else {
        _showSnackBar(result.error!, isError: true);
      }
    }
  }

  Future<void> _handleEmailSignUp(AuthService authService) async {
    final result = await authService.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
      birthDate: _selectedBirthDate!,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      _showSnackBar(result.message ??
          'Account created! Please check your email for verification.');
      setState(() {
        _isSignUp = false;
        _showOTPField = false;
      });
    } else {
      _showSnackBar(result.error!, isError: true);
    }
  }

  Future<void> _handleSignIn(AuthService authService) async {
    final result = await authService.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (result.isSuccess) {
      _showSnackBar(result.message ?? 'Welcome back!');
      // AuthGate will handle navigation
    } else {
      _showSnackBar(result.error!, isError: true);
    }
  }

  Future<void> _resendOTP() async {
    if (_pendingVerificationEmail == null) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.resendOTP(_pendingVerificationEmail!);

      if (result.isSuccess) {
        _showSnackBar(result.message ?? 'OTP resent!');
      } else {
        _showSnackBar(result.error!, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendEmailVerification() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.resendEmailVerification();

      if (result.isSuccess) {
        _showSnackBar(result.message ?? 'Verification email sent!');
      } else {
        _showSnackBar(result.error!, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter your email address', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.resetPassword(email);

      if (result.isSuccess) {
        _showSnackBar(result.message ?? 'Password reset email sent!');
      } else {
        _showSnackBar(result.error!, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your birth date',
      confirmText: 'CONFIRM',
      cancelText: 'CANCEL',
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    print('🔍 Starting guest sign-in process...');
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      print('🔍 AuthService obtained, calling signInAnonymously...');

      // Add direct Firebase debugging
      print('🔍 Testing Firebase connection...');
      final FirebaseAuth auth = FirebaseAuth.instance;
      print('🔍 Firebase Auth instance: ${auth.toString()}');
      print('🔍 Current user: ${auth.currentUser?.uid ?? 'null'}');

      final result = await authService.signInAnonymously();
      print('🔍 signInAnonymously completed. Success: ${result.isSuccess}');
      print('🔍 Message: ${result.message}');
      print('🔍 Error: ${result.error}');

      if (result.isSuccess) {
        print('🎉 Guest sign-in successful!');
        _showSnackBar(result.message ??
            'Welcome! You can create an account anytime in Settings.');
        // AuthGate will handle navigation
      } else {
        print('❌ Guest sign-in failed: ${result.error}');
        _showSnackBar(result.error!, isError: true);
      }
    } catch (e, stackTrace) {
      print('💥 Exception during guest sign-in: $e');
      print('📚 Stack trace: $stackTrace');
      _showSnackBar('Unexpected error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _showOTPField = false;
      _selectedBirthDate = null;
      _pendingVerificationEmail = null;
      _selectedSignUpMethod = SignUpMethod.email;
      _formKey.currentState?.reset();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Account' : 'Sign In'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo/Title
                const SizedBox(height: 32),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sifter Chat',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Location-based chat rooms',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Sign Up Method Selection (Sign Up only)
                if (_isSignUp && !_showOTPField) ...[
                  Text(
                    'Choose your sign-up method:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<SignUpMethod>(
                    segments: const [
                      ButtonSegment(
                        value: SignUpMethod.email,
                        label: Text('Email Sign-Up'),
                        icon: Icon(Icons.email_outlined),
                      ),
                      ButtonSegment(
                        value: SignUpMethod.otp,
                        label: Text('OTP Sign-Up'),
                        icon: Icon(Icons.verified_user_outlined),
                      ),
                    ],
                    selected: {_selectedSignUpMethod},
                    onSelectionChanged: (Set<SignUpMethod> selected) {
                      setState(() {
                        _selectedSignUpMethod = selected.first;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedSignUpMethod == SignUpMethod.otp
                        ? 'Get instant verification with OTP sent to your email'
                        : 'Traditional sign-up with email verification link',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_showOTPField ||
                      _selectedSignUpMethod != SignUpMethod.otp,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Username Field (Sign Up only)
                if (_isSignUp) ...[
                  TextFormField(
                    controller: _usernameController,
                    enabled: !_showOTPField ||
                        _selectedSignUpMethod != SignUpMethod.otp,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (value.trim().length > 20) {
                        return 'Username must be less than 20 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Password Field
                if (!_showOTPField ||
                    _selectedSignUpMethod != SignUpMethod.otp ||
                    _showOTPField) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (_isSignUp && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Birth Date Field (Sign Up only)
                if (_isSignUp &&
                    (!_showOTPField ||
                        _selectedSignUpMethod != SignUpMethod.otp)) ...[
                  InkWell(
                    onTap: _selectBirthDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Birth Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(
                        _selectedBirthDate != null
                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                            : 'Select your birth date',
                        style: _selectedBirthDate != null
                            ? null
                            : TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Required for age verification and NSFW content filtering',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],

                // OTP Field (when verification needed)
                if (_showOTPField) ...[
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.verified_user_outlined),
                      helperText: 'Enter the 6-digit code sent to your email',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the verification code';
                      }
                      if (value.trim().length != 6) {
                        return 'Verification code must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : (_selectedSignUpMethod == SignUpMethod.otp
                                ? _resendOTP
                                : _resendEmailVerification),
                        child: Text(_selectedSignUpMethod == SignUpMethod.otp
                            ? 'Resend OTP'
                            : 'Resend verification email'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit Button
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_getSubmitButtonText()),
                  ),
                ),

                const SizedBox(height: 16),

                // Anonymous Sign In Option
                if (!_isSignUp && !_showOTPField) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleAnonymousSignIn,
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Continue as Guest'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick access • Create account anytime • Limited features',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // Forgot Password (Sign In only)
                if (!_isSignUp && !_showOTPField) ...[
                  TextButton(
                    onPressed: _isLoading ? null : _handleForgotPassword,
                    child: const Text('Forgot Password?'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Toggle Mode
                if (!_showOTPField) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? 'Already have an account? '
                            : 'Don\'t have an account? ',
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _toggleMode,
                        child: Text(_isSignUp ? 'Sign In' : 'Sign Up'),
                      ),
                    ],
                  ),
                ],

                // Back button when showing OTP
                if (_showOTPField) ...[
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _showOTPField = false;
                              _pendingVerificationEmail = null;
                              _otpController.clear();
                            });
                          },
                    child: const Text('← Back to sign up'),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSubmitButtonText() {
    if (_isSignUp) {
      if (_selectedSignUpMethod == SignUpMethod.otp) {
        return _showOTPField ? 'Verify & Create Account' : 'Send OTP';
      } else {
        return 'Create Account';
      }
    } else {
      return 'Sign In';
    }
  }
}
