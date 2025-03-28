import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class FCMService {
  static const String _fcmUrl =
      "https://fcm.googleapis.com/v1/projects/reminder-bde6a/messages:send";

  Future<AuthClient> obtainAuthenticatedClient() async {
    String jsonString =
        await rootBundle.loadString('assets/service-account.json');
    Map<String, dynamic> serviceAccountCred = jsonDecode(jsonString);

    final accountCredentials =
        ServiceAccountCredentials.fromJson(serviceAccountCred);

    final scopes = ["https://www.googleapis.com/auth/cloud-platform"];

    AuthClient client =
        await clientViaServiceAccount(accountCredentials, scopes);
    debugPrint("Client: ${client.credentials.accessToken.data}");
    return client;
  }

  Future<void> sendNotification() async {
    AuthClient client = await obtainAuthenticatedClient();
    try {
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${client.credentials.accessToken.data}",
        },
        body: jsonEncode({
          "message": {
            "topic": "all",
            "data": {"story_id": "story_12345"},
            "android": {
              "priority": "high",
            },
            "apns": {
              "payload": {
                "aps": {"category": "NEW_MESSAGE_CATEGORY"}
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("response:${response.body}");
        debugPrint("Notification sent successfully");
      } else {
        debugPrint("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Error sending FCM notification: $e");
    }
  }

  Future<void> saveToFirebase(
      BuildContext context,
      TimeOfDay? selectedTime,
      TextEditingController taskController,
      TextEditingController descriptionController,
      TextEditingController pickedTimeController) async {
    if (selectedTime == null || taskController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter task details and time")),
      );
      return;
    }
    DateTime now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    await FirebaseFirestore.instance.collection('tasks').add({
      'time': Timestamp.fromDate(scheduledTime),
      'createdAt': FieldValue.serverTimestamp(),
      'task': taskController.text,
      'description': descriptionController.text,
    });

    taskController.clear();
    descriptionController.clear();
    pickedTimeController.clear();
    selectedTime = null;
  }
}
