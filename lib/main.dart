import 'package:e_shopping_list/screens/login_screen.dart';
import 'package:e_shopping_list/screens/user_list_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/*
 This is main function of the s-shopping app.
 it runs the app through rendering the main widget
*/
void main() async {
  //Firebase initialization
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Shopping List',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const InitializationWrapper(),
    );
  }
}

/*
 This class initializes the firebase application
 based on the platform
*/
class InitializationWrapper extends StatelessWidget {
  const InitializationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // if firebase is initialized successfully
    // it checks the user session
    // otherwise it shoes an error
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error initializing Firebase: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          checkUserSession(context);
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  /*
 checkUserSession function checks if the user is signed in.
 if signed in the user navigates to the lists screen
 otherwise the user is redirected to the login screen
*/
  void checkUserSession(BuildContext context) {
    FirebaseAuth auth = FirebaseAuth.instance;

    Future.delayed(Duration(seconds: 2), () {
      User? user = auth.currentUser; // Check inside the delay

      if (user != null) {
        // Navigate to UserListScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UserListScreen(),
          ),
        );
      } else {
        // Navigate to Login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Login(),
          ),
        );
      }
    });
  }
}
