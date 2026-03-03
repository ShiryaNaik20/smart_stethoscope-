import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class EditReportScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const EditReportScreen({Key? key, required this.report})
      : super(key: key);

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  late TextEditingController resultController;

  @override
  void initState() {
    super.initState();
    resultController =
        TextEditingController(text: widget.report['result']);
  }

  Future<void> updateReport() async {
    await DatabaseHelper.instance.updateReport({
      'id': widget.report['id'],
      'patientName': widget.report['patientName'],
      'patientId': widget.report['patientId'],
      'testType': widget.report['testType'],
      'result': resultController.text,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Report")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: resultController,
              decoration:
                  const InputDecoration(labelText: "Result"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateReport,
              child: const Text("Update"),
            )
          ],
        ),
      ),
    );
  }
}