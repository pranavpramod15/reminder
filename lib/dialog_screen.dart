import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reminder/fcm_service.dart';

class DialogScreen extends StatefulWidget {
  final DocumentSnapshot taskDoc;
  final TextEditingController taskController;
  final TextEditingController descriptionController;
  final TextEditingController pickedTimeController;
  final TimeOfDay? selectedTime;
  final DateTime localTime;

  const DialogScreen({
    super.key,
    required this.taskDoc,
    required this.taskController,
    required this.descriptionController,
    required this.pickedTimeController,
    required this.selectedTime,
    required this.localTime,
  });

  @override
  State<DialogScreen> createState() => _DialogScreenState();
}

class _DialogScreenState extends State<DialogScreen> {
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        widget.pickedTimeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Task"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.taskController,
            decoration: const InputDecoration(labelText: "Title"),
          ),
          TextField(
            controller: widget.descriptionController,
            decoration: const InputDecoration(labelText: "Description"),
          ),
          TextField(
            controller: widget.pickedTimeController,
            readOnly: true,
            onTap: () => _selectTime(context),
            decoration: const InputDecoration(labelText: "Scheduled Time"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.taskController.clear();
            widget.descriptionController.clear();
            widget.pickedTimeController.clear();
            selectedTime = null;
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (selectedTime == null) return;
            DateTime updatedTime = DateTime(
              widget.localTime.year,
              widget.localTime.month,
              widget.localTime.day,
              selectedTime!.hour,
              selectedTime!.minute,
            );

            await FCMService().sendNotification();
            await widget.taskDoc.reference.update({
              'task': widget.taskController.text,
              'description': widget.descriptionController.text,
              'time': Timestamp.fromDate(updatedTime),
            });

            widget.taskController.clear();
            widget.descriptionController.clear();
            widget.pickedTimeController.clear();
            selectedTime = null;
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
