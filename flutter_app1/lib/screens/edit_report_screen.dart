import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class EditReportScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const EditReportScreen({super.key, required this.report});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  late TextEditingController nameController;
  late TextEditingController patientIdController;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.report['name'] ?? '');
    patientIdController =
        TextEditingController(text: widget.report['patientId'] ?? '');
  }

  Future<void> updateReport() async {
    await DatabaseHelper.instance.updateReport(
      widget.report['id'],
      {
        'name': nameController.text,
        'patientId': patientIdController.text,
        'type': widget.report['type'],
        'result': widget.report['result'],
      },
    );

    Navigator.pop(context); // go back after update
  }

  @override
  void dispose() {
    nameController.dispose();
    patientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Report"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Patient Name",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: patientIdController,
              decoration: const InputDecoration(
                labelText: "Patient ID",
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: updateReport,
              child: const Text("Update Report"),
            ),
          ],
        ),
      ),
    );
  }
}
