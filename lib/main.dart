import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:togetherapart/pages/call_page.dart';
import 'package:togetherapart/pages/call_screen.dart';
import 'package:togetherapart/pages/create_post_screen.dart';
import 'package:togetherapart/pages/home_screen.dart';
import 'package:togetherapart/pages/calendar_screen.dart';
import 'package:togetherapart/pages/account_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
      apiKey: "AIzaSyATtnhpjxaRzmQfWcR5MdB53WJXQenSWy4",
      appId: "1:136156591893:web:db8d1ab449f38dfe615b1c",
      messagingSenderId: "136156591893",
      projectId: "togetherapart-cd369",
      authDomain: "togetherapart-cd369.firebaseapp.com",
      storageBucket: "togetherapart-cd369.appspot.com",
    ));
  } else {
    await Firebase.initializeApp();
  }

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TogetherApart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade300),
        useMaterial3: true,
      ),
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/',
      routes: {
        '/': (context) => const MyHomePage(),
        '/sign-in': (context) {
          return SignInScreen(
            providers: providers,
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                Navigator.pushReplacementNamed(context, '/');
              }),
            ],
          );
        },
        '/call': (context) => const CallPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TogetherApart'),
          centerTitle: true,
          backgroundColor: Colors.red.shade300,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (value) => setState(() {
            currentIndex = value;
          }),
          indicatorColor: Colors.blue.shade300,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: const [
            NavigationDestination(
              selectedIcon: Icon(Icons.call),
              icon: Icon(Icons.call_outlined),
              label: 'Call',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.add),
              icon: Icon(Icons.add),
              label: 'Post',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.person),
              icon: Icon(Icons.person_outline_outlined),
              label: 'Journey',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.calendar_month),
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Calendar',
            ),
          ],
        ),
        body: <Widget>[
          const CallScreen(),
          const CreatePostScreen(),
          const HomeScreen(),
          const AccountScreen(),
          const CalendarScreen(),
        ][currentIndex],
      ),
    );
  }
}
