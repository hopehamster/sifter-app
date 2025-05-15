import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import 'phone_auth_screen.dart';
import 'bottom_nav.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .signInWithEmail(_emailController.text, _passwordController.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BottomNav()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'user-not-found':
            _error = 'No user found with this email.';
            break;
          case 'wrong-password':
            _error = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            _error = 'Invalid email format.';
            break;
          case 'network-request-failed':
            _error = 'Network error. Please check your connection.';
            break;
          default:
            _error = 'Login failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .signUpWithEmail(_emailController.text, _passwordController.text);
      _emailController.clear();
      _passwordController.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BottomNav()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'email-already-in-use':
            _error = 'This email is already in use.';
            break;
          case 'invalid-email':
            _error = 'Invalid email format.';
            break;
          case 'weak-password':
            _error = 'Password is too weak. Use at least 6 characters.';
            break;
          case 'network-request-failed':
            _error = 'Network error. Please check your connection.';
            break;
          default:
            _error = 'Sign-up failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  Future<void> _skipLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).signInAnonymously();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BottomNav()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to skip login: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2196F3), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/logo.png', height: 50),
                        SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF2196F3)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF2196F3)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: true,
                        ),
                        if (_error != null) ...[
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.all(8),
                            color: Colors.red,
                            child: Text(_error!, style: TextStyle(color: Colors.white)),
                          ),
                        ],
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signInWithEmail,
                              child: Text('Sign In with Email'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: MediaQuery.of(context).size.width * 0.1,
                                  vertical: MediaQuery.of(context).size.height * 0.02,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signUpWithEmail,
                              child: Text('Sign Up with Email'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(
                                  horizontal: MediaQuery.of(context).size.width * 0.1,
                                  vertical: MediaQuery.of(context).size.height * 0.02,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PhoneAuthScreen()),
                                  );
                                },
                          child: Text('Sign In with Phone'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.05,
                              vertical: MediaQuery.of(context).size.height * 0.02,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Image.asset('assets/google.png', height: 30),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isLoading = true;
                                        _error = null;
                                      });
                                      try {
                                        await Provider.of<AuthProvider>(context, listen: false)
                                            .signInWithGoogle();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => BottomNav()),
                                        );
                                      } on FirebaseAuthException catch (e) {
                                        setState(() {
                                          _isLoading = false;
                                          if (e.code == 'network-request-failed') {
                                            _error = 'Network error. Please check your connection.';
                                          } else {
                                            _error = 'Google sign-in failed: ${e.message}';
                                          }
                                        });
                                      } catch (e) {
                                        setState(() {
                                          _isLoading = false;
                                          _error = 'An unexpected error occurred. Please try again.';
                                        });
                                      }
                                    },
                            ),
                            IconButton(
                              icon: Image.asset('assets/apple.png', height: 30),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isLoading = true;
                                        _error = null;
                                      });
                                      try {
                                        await Provider.of<AuthProvider>(context, listen: false)
                                            .signInWithApple();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => BottomNav()),
                                        );
                                      } on FirebaseAuthException catch (e) {
                                        setState(() {
                                          _isLoading = false;
                                          if (e.code == 'network-request-failed') {
                                            _error = 'Network error. Please check your connection.';
                                          } else {
                                            _error = 'Apple sign-in failed: ${e.message}';
                                          }
                                        });
                                      } catch (e) {
                                        setState(() {
                                          _isLoading = false;
                                          _error = 'An unexpected error occurred. Please try again.';
                                        });
                                      }
                                    },
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        TextButton(
                          onPressed: _isLoading ? null : _skipLogin,
                          child: Text(
                            'Skip - Chat Anonymously',
                            style: TextStyle(color: Colors.grey[700], fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}