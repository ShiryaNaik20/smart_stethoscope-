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
    setState(() {
      reports = data;
    });
  }

  Future<void> deleteReport(int id) async {
    await DatabaseHelper.instance.deleteReport(id);
    loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Reports"),
      ),
      body: reports.isEmpty
          ? const Center(child: Text("No reports saved yet."))
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(report['name'] ?? "No Name"),
                    subtitle: Text(
                      "Patient ID: ${report['patientId'] ?? ""}\n"
                      "Type: ${report['type'] ?? ""}\n"
                      "Result: ${report['result'] ?? ""}",
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✏ EDIT BUTTON
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditReportScreen(report: report),
                              ),
                            );
                            loadReports(); // refresh after edit
                          },
                        ),

                        // 🗑 DELETE BUTTON
                        IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Report"),
                                content: const Text(
                                    "Are you sure you want to delete this report?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      deleteReport(report['id']);
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );
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
