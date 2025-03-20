import 'package:e_shopping_list/screens/user_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String userName;

  const OTPScreen({
    Key? key,
    required this.verificationId,
    required this.phoneNumber,
    required this.userName,
  }) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter OTP",
        gravity: ToastGravity.TOP,
        textColor: Colors.black,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final uName = widget.userName;

      if (userCredential.user != null) {
        await saveUserToFirestore(userCredential.user!, uName);
        Fluttertoast.showToast(
          msg: "Successfully logged in!",
          gravity: ToastGravity.TOP,
          textColor: Colors.black,
        );
        // Navigate to home screen or next screen after successful login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserListScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Verification failed';

      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP code';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Invalid verification ID';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred';
      }

      Fluttertoast.showToast(
        msg: errorMessage,
        gravity: ToastGravity.TOP,
        textColor: Colors.black,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "An unexpected error occurred",
        gravity: ToastGravity.TOP,
        textColor: Colors.black,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the verification code sent to ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                hintText: 'Enter OTP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            SizedBox(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveUserToFirestore(User user, String name) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    await users.doc(user.uid).set({
      'id': user.uid,
      'name': name,
      'phone': user.phoneNumber,
    }).then((_) {
      print("User saved to Firestore");
    }).catchError((error) {
      print("Error saving user: $error");
    });
  }
}
