// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:genzgems/screens/forgot_password_screen.dart';
import 'package:genzgems/screens/update_profile_screen.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/verification_screen.dart';
import 'theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return AnimatedTheme(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          data:
              themeNotifier.isDarkTheme ? ThemeData.dark() : ThemeData.light(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Social Media App',
            theme: themeNotifier.isDarkTheme
                ? ThemeData.dark()
                : ThemeData.light(),
            initialRoute: '/',
            routes: {
              '/': (context) => SplashScreen(),
              '/email_verification': (context) => EmailVerificationScreen(),
              '/signup': (context) => SignUpScreen(),
              '/login': (context) => LoginScreen(),
              '/home': (context) => HomeScreen(),
              '/update_profile': (context) => UpdateProfileScreen(),
              '/forgot_password': (context) => ForgotPasswordScreen(),
              '/register': (context) => SignUpScreen(),
            },
          ),
        );
      },
    );
  }
}
