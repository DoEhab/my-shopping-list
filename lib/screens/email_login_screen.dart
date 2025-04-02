import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_shopping_list/screens/user_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/*
LoginWithEmail class allows users to enter their email
and create new account
* */
class LoginWithEmail extends StatefulWidget {
  const LoginWithEmail({
    Key? key,
  }) : super(key: key);

  @override
  State<LoginWithEmail> createState() => _LoginWithEmailScreenState();
}

class _LoginWithEmailScreenState extends State<LoginWithEmail> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
// new users email sign up
  Future<void> _signupWithEmail() async {
    debugPrint('Starting email verification process...');

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      debugPrint('Login error: Email or password is empty');
      Fluttertoast.showToast(
        msg: "Please enter email address",
        gravity: ToastGravity.BOTTOM,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('Attempting to sign up with email: ${_emailController.text}');
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      debugPrint(
          'Successfully created new account with ID: ${credential.user?.uid}');
      await saveUserToFirestore(credential as User, _emailController.text);
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserListScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'weak-password') {
        debugPrint('Error: The password provided is too weak.');
        Fluttertoast.showToast(msg: 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        debugPrint('Error: The account already exists for that email.');
        Fluttertoast.showToast(
            msg: 'An account already exists for that email.');
      }
    } catch (e) {
      debugPrint('Unexpected error during account creation: $e');
      Fluttertoast.showToast(msg: 'An unexpected error occurred');
    }
  }
// existing users login with email
  Future<void> _loginWithEmail() async {
    debugPrint('Starting email login process...');

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      debugPrint('Login error: Email or password is empty');
      Fluttertoast.showToast(
        msg: "Please enter email and password",
        gravity: ToastGravity.BOTTOM,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('Attempting to sign in with email: ${_emailController.text}');

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      if (userCredential.user != null) {
        debugPrint(
            'User successfully logged in with ID: ${userCredential.user?.uid}');
        Fluttertoast.showToast(
          msg: "Successfully logged in!",
          gravity: ToastGravity.BOTTOM,
          textColor: Colors.white,
        );
        // Navigate to home screen after successful login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserListScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      debugPrint('FirebaseAuthException caught: ${e.code}');
      if (e.code == 'user-not-found') {
        Fluttertoast.showToast(msg: 'No user found with this email');
      } else if (e.code == 'wrong-password') {
        debugPrint('Error: Wrong password provided for that user.');
        Fluttertoast.showToast(msg: 'Wrong password provided');
      } else {
        Fluttertoast.showToast(msg: 'Login error: ${e.message}');
      }
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      Fluttertoast.showToast(msg: 'An unexpected error occurred');
    } finally {
      debugPrint('Email login process completed.');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      appBar: AppBar(title: const Text('Enter Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter Your Email',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'Enter Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              maxLength: 26,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter Your Password',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                hintText: 'Enter Password',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              maxLength: 26,
            ),
            const SizedBox(height: 16),
            SizedBox(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginWithEmail,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signupWithEmail,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
//save new users to firebase database
  Future<void> saveUserToFirestore(User user, String name) async {
    debugPrint('Attempting to save user to Firestore...');
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    await users.doc(user.uid).set({
      'id': user.uid,
      'name': name,
      'phone': user.phoneNumber,
    }).then((_) {
      debugPrint("User successfully saved to Firestore");
    }).catchError((error) {
      debugPrint("Error saving user to Firestore: $error");
    });
  }
}
