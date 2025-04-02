import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'otp_screen.dart';

/*
* LoginWithPhone class allows user to enter
* name and phone number to receive OTP
* */
class LoginWithPhone extends StatefulWidget {
  const LoginWithPhone({super.key});

  @override
  State<LoginWithPhone> createState() => _LoginWithPhoneState();
}

class _LoginWithPhoneState extends State<LoginWithPhone> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  final _log = Logger('LoginWithPhone');

  @override
  void initState() {
    super.initState();
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
  }
  // validate the phone and name entered data
  Future<void> _verifyPhone() async {
    final phoneNumber = _phoneController.text.trim();
    final userName = _nameController.text.trim();

    // Basic validation
    if (phoneNumber.isEmpty || userName.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please enter a phone number/user name",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }

    // Ensure phone number starts with +
    final formattedNumber =
        phoneNumber.startsWith('+') ? phoneNumber : '+$phoneNumber';
    _log.info('Attempting to verify phone number: $formattedNumber');

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          setState(() => _isLoading = false);
          _log.info('Auto verification completed: $credential');
          Fluttertoast.showToast(
              msg: "Auto verification completed",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              textColor: Colors.white,
              fontSize: 16.0);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _log.severe(
              'Verification failed: ${e.message}\nCode: ${e.code}\nDetails: ${e.stackTrace}');
          String errorMessage = 'Verification failed';

          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'The phone number format is incorrect';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Please try again later';
              break;
            case 'operation-not-allowed':
              errorMessage = 'Phone authentication is not enabled';
              break;
            default:
              errorMessage = e.message ?? 'An unknown error occurred';
          }

          Fluttertoast.showToast(
              msg: errorMessage,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              textColor: Colors.white,
              fontSize: 16.0);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          _log.info('OTP sent to $formattedNumber');
          Fluttertoast.showToast(
              msg: "OTP sent successfully!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              textColor: Colors.white,
              fontSize: 16.0);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                  verificationId: verificationId,
                  phoneNumber: formattedNumber,
                  userName: userName),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _isLoading = false);
          _log.info('OTP timeout for verification ID: $verificationId');
          Fluttertoast.showToast(
              msg: "OTP timeout",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              textColor: Colors.white,
              fontSize: 16.0);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      _log.severe('Unexpected error during phone verification', e, stackTrace);
      Fluttertoast.showToast(
          msg: "Unexpected error: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login with Phone Number')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(),
                helperText: 'First Name',
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                hintText: 'Enter your phone number (e.g., +1234567890)',
                border: OutlineInputBorder(),
                helperText: 'Include country code with + sign',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyPhone,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
