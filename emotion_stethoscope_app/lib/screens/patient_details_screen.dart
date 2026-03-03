import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'recording_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String mode;

  const PatientDetailsScreen({super.key, required this.mode});

  @override
  State<PatientDetailsScreen> createState() =>
      _PatientDetailsScreenState();
}

class _PatientDetailsScreenState
    extends State<PatientDetailsScreen> {

  final TextEditingController nameController =
      TextEditingController();
  final TextEditingController ageController =
      TextEditingController();

  String? selectedGender;

  bool isValidName(String name) {
    final RegExp nameRegex = RegExp(r'^[a-zA-Z ]+$');
    return nameRegex.hasMatch(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1565C0),
              Color(0xFF42A5F5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [

                const SizedBox(height: 30),

                const Text(
                  "Patient Information",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [

                      const Icon(
                        Icons.medical_information,
                        size: 50,
                        color: Color(0xFF1565C0),
                      ),

                      const SizedBox(height: 25),

                      TextField(
                        controller: nameController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z ]')),
                        ],
                        decoration: InputDecoration(
                          labelText: "Patient Name",
                          prefixIcon:
                              const Icon(Icons.person),
                          filled: true,
                          fillColor:
                              Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: ageController,
                        keyboardType:
                            TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: "Age",
                          prefixIcon: const Icon(
                              Icons.calendar_today),
                          filled: true,
                          fillColor:
                              Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        items: const [
                          DropdownMenuItem(
                              value: "Male",
                              child: Text("Male")),
                          DropdownMenuItem(
                              value: "Female",
                              child: Text("Female")),
                          DropdownMenuItem(
                              value: "Other",
                              child: Text("Other")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Gender",
                          prefixIcon:
                              const Icon(Icons.wc),
                          filled: true,
                          fillColor:
                              Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF1565C0),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      25),
                            ),
                          ),
                          onPressed: () {

                            if (nameController.text.isEmpty ||
                                ageController.text.isEmpty ||
                                selectedGender == null) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Fill all details"),
                                ),
                              );
                              return;
                            }

                            if (!isValidName(
                                nameController.text)) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Only English letters allowed"),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecordingScreen(
                                  mode: widget.mode,
                                  name:
                                      nameController.text,
                                  age: ageController.text,
                                  gender:
                                      selectedGender!,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Proceed to Recording",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}