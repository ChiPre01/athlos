import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationScreen extends StatelessWidget {
  final List<RemoteMessage> notifications;
  final Map<String, dynamic> message; // Add this line

  const NotificationScreen({
    Key? key,
    required this.notifications,
    required this.message, // Add this line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          RemoteMessage notification = notifications[index];
          return ListTile(
            title: Text(notification.notification?.title ?? 'Notification Title'),
            subtitle: Text(notification.notification?.body ?? 'Notification Body'),
          );
        },
      ),
    );
  }
}
