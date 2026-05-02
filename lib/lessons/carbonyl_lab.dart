import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';

class AldehydesKetonesLab extends StatefulWidget {
  const AldehydesKetonesLab({super.key});

  @override
  State<AldehydesKetonesLab> createState() => _AldehydesKetonesLabState();
}

class _AldehydesKetonesLabState extends State<AldehydesKetonesLab> with TickerProviderStateMixin {
  String selectedMolecule = "aldehyde";
  String selectedReagent = "";
  String result = "اختر المركب والكاشف ثم ابدأ التفاعل";
  bool reacting = false;

  late AnimationController shakeController;
  late Animation<double> shake;
  late AnimationController bubbleController;
  final Random random = Random();
  List<Offset> bubbles = [];

  @override
  void initState() {
    super.initState();

    // إعداد حركة الاهتزاز للمزيج التفاعلي
    shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    shake = Tween<double>(begin: -3, end: 3).animate(shakeController);

    // إعداد حركة الفقاعات عند التفاعل
    bubbleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..addListener(() {
        if (reacting) {
          setState(() {
            bubbles = List.generate(12, (index) {
              return Offset(
                random.nextDouble() * 180 + 20,
                220 - (bubbleController.value * 240),
              );
            });
          });
        }
      });
  }

  void runReaction() {
    if (selectedReagent.isEmpty) {
      setState(() => result = "⚠️ الرجاء اختيار كاشف أولاً");
      return;
    }

    setState(() {
      reacting = true;
      result = "جارِ التفاعل...";
    });

    shakeController.repeat(reverse: true);
    bubbleController.repeat();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        reacting = false;
        shakeController.stop();
        bubbleController.stop();
        bubbles.clear();

        if (selectedMolecule == "aldehyde") {
          if (selectedReagent == "tollens") {
            result = "✨ النتيجة: تكون مرآة فضية (تأكسد الألدهيد)";
          } else {
            result = "🧪 النتيجة: تكون راسب أحمر آجري (راسب النحاس)";
          }
        } else {
          result = "❌ لا يحدث تفاعل: الكيتونات لا تتأكسد بهذه الكواشف";
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("مختبر مجموعة الكربونيل"), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildMoleculeSelector(),
              const SizedBox(height: 30),
              _buildLabEnvironment(),
              const SizedBox(height: 30),
              _buildReagentSelector(),
              const SizedBox(height: 40),
              _buildActionButtons(),
              const SizedBox(height: 30),
              _buildResultDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabEnvironment() {
    return AnimatedBuilder(
      animation: shake,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(reacting ? shake.value : 0, 0),
          child: Container(
            width: 200,
            height: 250,
            decoration: BoxDecoration(
              color: reacting ? Colors.orange.withOpacity(0.3) : AppColors.glassWhite,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
                topRight: Radius.circular(10),
                topLeft: Radius.circular(10),
              ),
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [
                BoxShadow(
                  color: reacting ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    selectedMolecule == "aldehyde" ? "CH₃CHO" : "CH₃COCH₃",
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ),
                ...bubbles.map((b) => Positioned(
                  left: b.dx,
                  top: b.dy,
                  child: CircleAvatar(radius: 4, backgroundColor: Colors.white.withOpacity(0.5)),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoleculeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _choiceChip("ألدهيد", "aldehyde"),
        const SizedBox(width: 15),
        _choiceChip("كيتون", "ketone"),
      ],
    );
  }

  Widget _choiceChip(String label, String value) {
    bool isSelected = selectedMolecule == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() {
        selectedMolecule = value;
        result = "اختر التفاعل";
      }),
      selectedColor: AppColors.neonBlue,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  Widget _buildReagentSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _reagentButton("كاشف تولنز", "tollens"),
        const SizedBox(width: 15),
        _reagentButton("محلول فيهلنغ", "fehling"),
      ],
    );
  }

  Widget _reagentButton(String label, String value) {
    bool isSelected = selectedReagent == value;
    return ElevatedButton(
      onPressed: () => setState(() => selectedReagent = value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.neonBlue : AppColors.glassWhite,
        foregroundColor: isSelected ? Colors.white : Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: reacting ? null : runReaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text("بدء التفاعل الكيميائي", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
      ),
      child: Text(
        result,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    shakeController.dispose();
    bubbleController.dispose();
    super.dispose();
  }
}
