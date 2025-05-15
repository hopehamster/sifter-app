import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'bottom_nav.dart';

class PhoneAuthScreen extends StatefulWidget {
  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _isLoading = false;
  String? _error;

  Future<void> _sendOtp() async {
    final phoneNumber = _phoneController.text.trim();
    if (!phoneNumber.startsWith('+') || phoneNumber.length < 10) {
      setState(() {
        _error = 'Please enter a valid phone number with country code (e.g., +1 for USA).';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          await Provider.of<AuthProvider>(context, listen: false)
              .signInWithPhone(credential.verificationId!, credential.smsCode!);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BottomNav()),
          );
        },
        verificationFailed: (e) {
          setState(() {
            _isLoading = false;
            if (e.code == 'invalid-phone-number') {
              _error = 'Invalid phone number format.';
            } else if (e.code == 'network-request-failed') {
              _error = 'Network error. Please check your connection.';
            } else {
              _error = 'Failed to send OTP: ${e.message}';
            }
          });
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _error = 'Please enter a 6-digit OTP.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .signInWithPhone(_verificationId!, _otpController.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BottomNav()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'invalid-verification-code') {
          _error = 'Invalid OTP. Please try again.';
        } else if (e.code == 'network-request-failed') {
          _error = 'Network error. Please check your connection.';
        } else {
          _error = 'Failed to verify OTP: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number (e.g., +1234567890)',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2196F3)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 10),
                    if (_verificationId == null) ...[
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Send OTP'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.05,
                            vertical: MediaQuery.of(context).size.height * 0.02,
                          ),
                        ),
                      ),
                    ],
                    if (_verificationId != null) ...[
                      TextField(
                        controller: _otpController,
                        decoration: InputDecoration(
                          labelText: 'Enter OTP (6 digits)',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF2196F3)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Verify OTP'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.05,
                            vertical: MediaQuery.of(context).size.height * 0.02,
                          ),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      SizedBox(height: 10),
                      Text(_error!, style: TextStyle(color: Colors.red)),
                    ],
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
    );
  }
}