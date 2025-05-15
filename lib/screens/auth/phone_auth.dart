import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sifter/providers/auth_provider.dart' as s;
import 'package:sifter/screens/bottomNav/bottom_nav.dart';

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
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        verificationCompleted: (credential) async {
          await Provider.of<s.AuthProvider>(context, listen: false)
              .signInWithPhone(credential.verificationId!, credential.smsCode!);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainScreen()),
          );
        },
        verificationFailed: (e) {
          setState(() {
            _isLoading = false;
            _error = e.message;
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
        _error = e.toString();
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<s.AuthProvider>(context, listen: false)
          .signInWithPhone(_verificationId!, _otpController.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Invalid OTP, please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2196F3)),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 10),
            if (_verificationId == null) ...[
              ElevatedButton(
                onPressed: _sendOtp,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Send OTP'),
              ),
            ],
            if (_verificationId != null) ...[
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2196F3)),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _verifyOtp,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Verify OTP'),
              ),
            ],
            if (_error != null) ...[
              SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
