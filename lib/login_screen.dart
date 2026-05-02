import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.science, size: 80, color: Color(0xFF00E5FF)),
              const SizedBox(height: 30),
              TextField(controller: controller, decoration: const InputDecoration(labelText: "اسم الطالب", border: OutlineInputBorder())),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(studentName: controller.text))),
                child: const Text("دخول"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
