import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../main.dart'; // ✅ IMPORTANT for HomeScreen

class SaveReportScreen extends StatefulWidget {
  final String result;
  final String mode;

  const SaveReportScreen({
    super.key,
    required this.result,
    required this.mode,
  });

  @override
  State<SaveReportScreen> createState() => _SaveReportScreenState();
}

class _SaveReportScreenState extends State<SaveReportScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();

  void saveData() async {
    if (nameController.text.isEmpty || idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    await DatabaseHelper.instance.insertReport({
      'name': nameController.text,
      'patientId': idController.text,
      'type': widget.mode,
      'result': widget.result,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data Stored Successfully")),
    );

    // ✅ Go directly to Dashboard and clear back stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Form"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Patient Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: "Patient ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "Result: ${widget.result}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveData,
                child: const Text("Store in Database"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}