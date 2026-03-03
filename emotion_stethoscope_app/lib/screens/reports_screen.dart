import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'edit_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    final data = await DatabaseHelper.instance.getReports();
    setState(() => reports = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Reports")),
      body: reports.isEmpty
          ? const Center(child: Text("No reports found"))
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(report['patientName']),
                    subtitle: Text(
                      "ID: ${report['patientId']}\n"
                      "Type: ${report['testType']}\n"
                      "Result: ${report['result']}",
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blue),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditReportScreen(
                                        report: report),
                              ),
                            );
                            loadReports();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper.instance
                                .deleteReport(report['id']);
                            loadReports();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}