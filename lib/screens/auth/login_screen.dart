import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'auth_service.dart';
import 'package:provider/provider.dart';
import 'package:sifter/providers/auth_provider.dart';
import 'package:sifter/screens/auth/phone_auth.dart';
import 'package:sifter/screens/bottomNav/bottom_nav.dart';
import 'package:sifter/screens/auth/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (_isLogin) {
        await auth.login(_emailController.text, _passwordController.text);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MainScreen()));
      } else {
        await auth.login(_emailController.text, _passwordController.text);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MainScreen()));
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      print('errror $e');
    } catch (e) {
      setState(() => _errorMessage = 'An unknown error occurred');
      print('errror $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Login to your account' : 'Sign up to get started',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _isLogin ? 'Login' : 'Sign Up',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignupScreen()));
                        // setState(() {
                        //   // _isLogin = !_isLogin;
                        //   _errorMessage = null;
                        // });
                      },
                      child: Text(
                        _isLogin
                            ? 'Don\'t have an account? Sign Up'
                            : 'Already have an account? Login',
                        // style: GoogleFonts.poppins(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (_) => PhoneAuthScreen()),
              //     );
              //   },
              //   child: Text('Sign In with Phone'),
              // ),
              // SizedBox(height: 10),
              // Column(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     IconButton(
              //       color: Colors.blue,
              //       icon: Image.asset('assets/google.png', height: 30),
              //       onPressed: () async {
              //         try {
              //           await Provider.of<AuthProvider>(context, listen: false)
              //               .signInWithGoogle();
              //           Navigator.pushReplacement(
              //             context,
              //             MaterialPageRoute(builder: (_) => MainScreen()),
              //           );
              //         } catch (e) {
              //           setState(() => _errorMessage = e.toString());
              //         }
              //       },
              //     ),
              //     IconButton(
              //       color: Colors.blue,
              //       icon: Icon(
              //         Icons.apple,
              //         color: Colors.black,
              //         size: 40,
              //       ),
              //       onPressed: () async {
              //         try {
              //           await Provider.of<AuthProvider>(context, listen: false)
              //               .signInWithApple();
              //           Navigator.pushReplacement(
              //             context,
              //             MaterialPageRoute(builder: (_) => MainScreen()),
              //           );
              //         } catch (e) {
              //           setState(() => _errorMessage = e.toString());
              //         }
              //       },
              //     ),
              // ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
