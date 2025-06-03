import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'main_app_screen.dart';

enum SignUpMethod { phone }

enum LoginMode { signIn, signUp }

class LoginScreen extends ConsumerStatefulWidget {
  final LoginMode initialMode;

  const LoginScreen({super.key, this.initialMode = LoginMode.signIn});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showOTPField = false;
  bool _showPasswordCreation = false;
  SignUpMethod _selectedSignUpMethod = SignUpMethod.phone;
  DateTime? _selectedBirthDate;
  String? _pendingVerificationEmail;

  @override
  void initState() {
    super.initState();
    // Set initial mode based on constructor parameter
    _isSignUp = widget.initialMode == LoginMode.signUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _otpController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    print('🔍 LoginScreen: _handleSubmit() called');
    print('🔍 LoginScreen: _isSignUp = $_isSignUp');
    print('🔍 LoginScreen: _showOTPField = $_showOTPField');

    if (!_formKey.currentState!.validate()) {
      print('🔍 LoginScreen: Form validation failed');
      return;
    }

    // For sign up, check if birth date is selected
    if (_isSignUp && _selectedBirthDate == null) {
      print('🔍 LoginScreen: Birth date not selected');
      _showSnackBar('Please select your birth date', isError: true);
      return;
    }

    print('🔍 LoginScreen: Setting loading state to true');
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      print('🔍 LoginScreen: AuthService obtained');

      if (_isSignUp) {
        print('🔍 LoginScreen: Calling _handlePhoneSignUp');
        await _handlePhoneSignUp(authService);
      } else {
        print('🔍 LoginScreen: Calling _handleSignIn');
        await _handleSignIn(authService);
      }
    } catch (e, stackTrace) {
      print('💥 LoginScreen: Exception in _handleSubmit: $e');
      print('📚 LoginScreen: Stack trace: $stackTrace');
      if (mounted) {
        _showSnackBar('Unexpected error: $e', isError: true);
      }
    } finally {
      print('🔍 LoginScreen: Setting loading state to false');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePhoneSignUp(AuthService authService) async {
    print('🔍 LoginScreen: _handlePhoneSignUp() called');
    print(
        '🔍 LoginScreen: _showOTPField = $_showOTPField, _showPasswordCreation = $_showPasswordCreation');

    if (!_showOTPField && !_showPasswordCreation) {
      // Step 1: Send OTP to phone
      final phoneNumber = _phoneController.text.trim();
      print(
          '🔍 LoginScreen: Sending OTP to phone: ${phoneNumber.length} characters');

      try {
        final result = await authService.signUpWithPhone(
          phone: phoneNumber,
        );
        print('🔍 LoginScreen: signUpWithPhone completed');
        print('🔍 LoginScreen: Success: ${result.isSuccess}');

        if (!mounted) return;

        if (result.isSuccess) {
          print('🔍 LoginScreen: Setting _showOTPField to true');
          setState(() {
            _showOTPField = true;
          });
          _showSnackBar(result.message ?? 'OTP sent to your phone!');
        } else {
          print('🔍 LoginScreen: signUpWithPhone failed: ${result.error}');
          _showSnackBar(result.error!, isError: true);
        }
      } catch (e, stackTrace) {
        print('💥 LoginScreen: Exception in phone OTP send: $e');
        print('📚 LoginScreen: Stack trace: $stackTrace');
        if (mounted) {
          _showSnackBar('Error sending OTP: $e', isError: true);
        }
      }
    } else if (_showOTPField && !_showPasswordCreation) {
      // Step 2: Verify OTP and proceed to password creation
      print('🔍 LoginScreen: Verifying OTP: ${_otpController.text.trim()}');

      try {
        final result = await authService.verifyPhoneOTP(
          otp: _otpController.text.trim(),
        );
        print('🔍 LoginScreen: verifyPhoneOTP completed');
        print('🔍 LoginScreen: Success: ${result.isSuccess}');

        if (!mounted) return;

        if (result.isSuccess) {
          print('🔍 LoginScreen: OTP verified, showing password creation');
          setState(() {
            _showOTPField = false;
            _showPasswordCreation = true;
          });
          _showSnackBar('Phone verified! Now create your password.');
        } else {
          _showSnackBar(result.error!, isError: true);
        }
      } catch (e, stackTrace) {
        print('💥 LoginScreen: Exception in OTP verification: $e');
        print('📚 LoginScreen: Stack trace: $stackTrace');
        if (mounted) {
          _showSnackBar('Error verifying OTP: $e', isError: true);
        }
      }
    } else if (_showPasswordCreation) {
      // Step 3: Complete account creation with password
      print('🔍 LoginScreen: Creating account with password');

      try {
        // Show more detailed progress
        _showSnackBar('Creating your account...', isError: false);

        final result = await authService.completePhoneSignUpWithPassword(
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          birthDate: _selectedBirthDate!,
        );
        print('🔍 LoginScreen: completePhoneSignUpWithPassword completed');
        print('🔍 LoginScreen: Success: ${result.isSuccess}');

        if (!mounted) return;

        if (result.isSuccess) {
          _showSnackBar('🎉 Account created successfully! Welcome to Sifter!');

          // Give Firebase time to update auth state
          await Future.delayed(const Duration(milliseconds: 1000));

          // Check authentication state
          if (mounted) {
            final currentUser = FirebaseAuth.instance.currentUser;
            print(
                '🔍 LoginScreen: Current user after account creation: ${currentUser?.uid ?? 'null'}');
            print(
                '🔍 LoginScreen: User is anonymous: ${currentUser?.isAnonymous ?? true}');

            if (currentUser != null && !currentUser.isAnonymous) {
              print(
                  '🔍 LoginScreen: User properly authenticated, AuthGate should handle navigation');
              // Clear form state
              setState(() {
                _isSignUp = false;
                _showOTPField = false;
                _showPasswordCreation = false;
                _selectedBirthDate = null;
                _formKey.currentState?.reset();
                _otpController.clear();
                _passwordController.clear();
                _confirmPasswordController.clear();
                _usernameController.clear();
                _phoneController.clear();
              });

              // AuthGate should handle navigation automatically
              // If it doesn't after 2 seconds, manually navigate
              await Future.delayed(const Duration(seconds: 2));

              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                print('🔍 LoginScreen: Manual navigation to MainAppScreen');
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const MainAppScreen()),
                );
              }
            } else {
              print(
                  '❌ LoginScreen: User creation may have failed - still anonymous or null');
              _showSnackBar(
                  'Account creation completed but login failed. Please try signing in.',
                  isError: true);
            }
          }
        } else {
          _showSnackBar(result.error!, isError: true);
        }
      } catch (e, stackTrace) {
        print('💥 LoginScreen: Exception in password creation: $e');
        print('📚 LoginScreen: Stack trace: $stackTrace');
        if (mounted) {
          _showSnackBar('Error creating account: $e', isError: true);
        }
      }
    }
  }

  Future<void> _handleSignIn(AuthService authService) async {
    // Use phone + password for sign-in
    final phoneNumber = _phoneController.text.trim();
    final password = _passwordController.text;
    print(
        '🔍 LoginScreen: Attempting phone sign-in with: ${phoneNumber.length} characters');

    try {
      final result = await authService.signInWithPhoneAndPassword(
        phone: phoneNumber,
        password: password,
      );

      if (result.isSuccess) {
        _showSnackBar(result.message ?? 'Welcome back!');
        // AuthGate will handle navigation
      } else {
        _showSnackBar(result.error!, isError: true);
      }
    } catch (e) {
      _showSnackBar('Error signing in: $e', isError: true);
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      // For phone OTP, resend by calling signUpWithPhone again
      final result = await authService.signUpWithPhone(
        phone: _phoneController.text.trim(),
      );

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
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Please enter your phone number', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      // For now, show a message about password reset
      _showSnackBar(
          'Password reset via phone is coming soon. Contact support for help.');
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
      _showPasswordCreation = false;
      _selectedBirthDate = null;
      _pendingVerificationEmail = null;
      _selectedSignUpMethod = SignUpMethod.phone;
      _formKey.currentState?.reset();

      // Clear all text controllers
      _otpController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _usernameController.clear();
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth > 600 ? 48.0 : 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo/Title
                    SizedBox(height: constraints.maxHeight > 600 ? 24 : 16),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: constraints.maxHeight > 600 ? 80 : 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sifter Chat',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                    SizedBox(height: constraints.maxHeight > 600 ? 32 : 20),

                    // Phone Field (for both Sign-In and Sign-Up)
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone_outlined),
                        helperText: _isSignUp
                            ? 'Enter with country code: +1234567890 or 1234567890'
                            : 'Use "Continue as Guest" for quick access',
                        hintText: '+1234567890',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        // Basic length validation - detailed validation happens in AuthService
                        final cleanValue =
                            value.replaceAll(RegExp(r'[^\d+]'), '');
                        if (cleanValue.length < 10) {
                          return 'Phone number must be at least 10 digits';
                        }
                        if (cleanValue.length > 15) {
                          return 'Phone number too long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field (Sign In only)
                    if (!_isSignUp && !_showOTPField) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          helperText: 'Enter your account password',
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
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Username Field (Password creation step only)
                    if (_showPasswordCreation) ...[
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                          helperText: 'Choose a unique username',
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
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Create Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          helperText: 'At least 6 characters',
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
                            return 'Please create a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Birth Date Field (Sign Up only)
                    if (_isSignUp && !_showPasswordCreation) ...[
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                          helperText:
                              'Enter the 6-digit code sent to your phone',
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
                            onPressed: _isLoading ? null : _resendOTP,
                            child: const Text('Resend OTP'),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_getSubmitButtonText()),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Anonymous Sign In Option
                    if (!_isSignUp) ...[
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Add some spacing before the bottom elements
                    SizedBox(height: constraints.maxHeight > 600 ? 32 : 16),

                    // Forgot Password (Sign In only)
                    if (!_isSignUp &&
                        !_showOTPField &&
                        !_showPasswordCreation) ...[
                      TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Toggle Mode
                    if (!_showOTPField && !_showPasswordCreation) ...[
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

                    // Back button when showing OTP or password creation
                    if (_showOTPField || _showPasswordCreation) ...[
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  if (_showPasswordCreation) {
                                    // Go back to OTP step
                                    _showPasswordCreation = false;
                                    _showOTPField = true;
                                    _passwordController.clear();
                                    _confirmPasswordController.clear();
                                    _usernameController.clear();
                                  } else if (_showOTPField) {
                                    // Go back to phone entry
                                    _showOTPField = false;
                                    _otpController.clear();
                                  }
                                });
                              },
                        child: Text(_showPasswordCreation
                            ? '← Back to verification'
                            : '← Back to phone entry'),
                      ),
                    ],

                    // Bottom padding
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getSubmitButtonText() {
    if (_isSignUp) {
      if (_showPasswordCreation) {
        return 'Create Account';
      } else if (_showOTPField) {
        return 'Verify Code';
      } else {
        return 'Send Verification Code';
      }
    } else {
      return 'Sign In';
    }
  }
}
