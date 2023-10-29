import 'package:athlosight/screens/notifications_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:athlosight/screens/sign_up_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
   WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(
    InitializerWidget(
      onInitializationComplete: (context) => MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Athlosight',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          accentColor: Colors.deepPurple,
        ),
      ),
      home: SignUpScreen(),
     routes: {
        '/notifications': (context) {
          // Retrieve the passed arguments
          final List<RemoteMessage> notifications =
              ModalRoute.of(context)!.settings.arguments as List<RemoteMessage>;
          final Map<String, dynamic> message =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

          // Return the NotificationScreen with arguments
          return NotificationScreen(
            notifications: notifications,
            message: message,
          );
        },
      },
    );
  }
}

void _handleNotification(BuildContext context, Map<String, dynamic> message) {
  // Handle your notification payload here

  // Navigate to the NotificationScreen
  Navigator.of(context).pushNamed('/notifications', arguments: message);
}

void setupFirebaseMessaging(BuildContext context) {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // When the app is in the foreground and a notification is received
    _handleNotification(context, message.data);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // When the app is in the background or terminated and a notification is clicked
    _handleNotification(context, message.data);
  });
}

class InitializerWidget extends StatefulWidget {
  final Widget Function(BuildContext) onInitializationComplete;

  const InitializerWidget({
    Key? key,
    required this.onInitializationComplete,
  }) : super(key: key);

  @override
  _InitializerWidgetState createState() => _InitializerWidgetState();
}

class _InitializerWidgetState extends State<InitializerWidget> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: FirebaseOptions(
   apiKey: "AIzaSyBdURhve8UdtEbk_b_WmNt6RjMpc0fxMnU",
  authDomain: "athlosight3.firebaseapp.com",
  projectId: "athlosight3",
  storageBucket: "athlosight3.appspot.com",
  messagingSenderId: "404846467635",
  appId: "1:404846467635:web:4f3ca8669f02563e83a146",
  measurementId: "G-DRKP1E64TC",
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          setupFirebaseMessaging(context); // Initialize FirebaseMessaging after Firebase is initialized
          return widget.onInitializationComplete(context);
        }
        return CircularProgressIndicator(); // Show loading indicator while Firebase is initializing
      },
    );
  }
}
