import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:reminder/dialog_screen.dart';
import 'package:reminder/fcm_service.dart';

class NotificationScheduler extends StatefulWidget {
  const NotificationScheduler({super.key});

  @override
  State<NotificationScheduler> createState() => _NotificationSchedulerState();
}

class _NotificationSchedulerState extends State<NotificationScheduler> {
  TimeOfDay? selectedTime;
  final TextEditingController taskController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController pickedTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schedule Notification")),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Title",
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Description",
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: pickedTimeController,
                  readOnly: true,
                  onTap: () => _selectTime(context),
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.alarm),
                    border: OutlineInputBorder(),
                    labelText: "Scheduled Time",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await FCMService().sendNotification();
                FCMService().saveToFirebase(
                    context,
                    selectedTime,
                    taskController,
                    descriptionController,
                    pickedTimeController);
              },
              child: const Text("Save To Database"),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var tasks = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var taskDoc = tasks[index];
                    var taskData = taskDoc.data() as Map<String, dynamic>;
                    Timestamp timestamp = taskData['time'];
                    DateTime localTime = timestamp.toDate();

                    return ListTile(
                      title: Text(taskData['task']),
                      subtitle: Text(
                        "${taskData['description']} - ${localTime.hour}:${localTime.minute}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editTask(
                                taskDoc,
                                context,
                                taskController,
                                descriptionController,
                                selectedTime),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              taskDoc.reference.delete();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void editTask(
      DocumentSnapshot taskDoc,
      BuildContext context,
      TextEditingController taskController,
      TextEditingController descriptionController,
      TimeOfDay? selectedTime) async {
    var taskData = taskDoc.data() as Map<String, dynamic>;

    taskController.text = taskData['task'];
    descriptionController.text = taskData['description'];
    Timestamp timestamp = taskData['time'];
    DateTime localTime = timestamp.toDate();
    selectedTime = TimeOfDay(hour: localTime.hour, minute: localTime.minute);
    pickedTimeController.text = "${localTime.hour}:${localTime.minute}";
    FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      builder: (context) => DialogScreen(
        taskDoc: taskDoc,
        taskController: taskController,
        descriptionController: descriptionController,
        pickedTimeController: pickedTimeController,
        selectedTime: selectedTime,
        localTime: localTime,
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        pickedTimeController.text = picked.format(context);
      });
    }
  }
}
