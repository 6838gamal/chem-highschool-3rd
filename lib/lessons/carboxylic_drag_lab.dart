import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';

class CarboxylicDragLab extends StatefulWidget {
  const CarboxylicDragLab({super.key});

  @override
  State<CarboxylicDragLab> createState() => _CarboxylicDragLabState();
}

class _CarboxylicDragLabState extends State<CarboxylicDragLab> {
  Offset acidPos = const Offset(80, 150);
  Offset waterPos = const Offset(220, 350);
  bool reactionTriggered = false;
  double ph = 7.0;

  // تغيير لون الخلفية تدريجياً بناءً على الحموضة
  Color getDynamicBackground() {
    if (ph < 4.5) return Colors.red.withOpacity(0.15);
    if (ph < 7.0) return Colors.orange.withOpacity(0.1);
    return AppColors.background;
  }

  void checkReaction() {
    double distance = (acidPos - waterPos).distance;
    // إذا اقترب الحمض من الماء بمسافة أقل من 100 بكسل يحدث التفكك
    if (distance < 100) {
      setState(() {
        reactionTriggered = true;
        ph = 3.5; // قيمة تقريبية لحمض ضعيف
      });
    } else {
      setState(() {
        reactionTriggered = false;
        ph = 7.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getDynamicBackground(),
      appBar: AppBar(
        title: const Text("تفكك الحموض الكربوكسيلية"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildInstructionHeader(),
          
          // جزيء الماء (H2O) - هدف ثابت أو قابل للسحب
          Positioned(
            left: waterPos.dx,
            top: waterPos.dy,
            child: _draggableMolecule("H₂O", Colors.blueAccent, (offset) {
              setState(() => waterPos = offset);
              checkReaction();
            }),
          ),

          // جزيء الحمض (R-COOH)
          Positioned(
            left: acidPos.dx,
            top: acidPos.dy,
            child: _draggableMolecule("R-COOH", Colors.redAccent, (offset) {
              setState(() => acidPos = offset);
              checkReaction();
            }),
          ),

          // عرض معادلة التفاعل عند التقارب
          if (reactionTriggered) _buildReactionEquation(),

          // لوحة معلومات الـ pH والقوانين
          _buildInfoPanel(),
        ],
      ),
    );
  }

  Widget _buildInstructionHeader() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text(
          "قم بسحب جزيء الحمض نحو جزيء الماء لبدء التفكك",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _draggableMolecule(String formula, Color color, Function(Offset) onMove) {
    return Draggable(
      feedback: _moleculeUI(formula, color, true),
      childWhenDragging: Opacity(opacity: 0.3, child: _moleculeUI(formula, color, false)),
      onDragEnd: (details) {
        // تحويل الإحداثيات العالمية إلى إحداثيات الـ Stack
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localOffset = renderBox.globalToLocal(details.offset);
        onMove(localOffset);
      },
      child: _moleculeUI(formula, color, false),
    );
  }

  Widget _moleculeUI(String label, Color color, bool isFeedback) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: isFeedback ? 20 : 10, spreadRadius: 2)
          ],
          border: Border.all(color: Colors.white30),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildReactionEquation() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "R-COOH + H₂O ⇌ R-COO⁻ + H₃O⁺",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "تفكك الحمض الكربوكسيلي في الماء",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("درجة الحموضة (pH):", style: TextStyle(color: Colors.white70)),
                Text(
                  ph.toStringAsFixed(1),
                  style: TextStyle(
                    color: ph < 7 ? Colors.redAccent : AppColors.neonBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 25),
            const Text(
              "📌 قاعدة كيميائية: الحموض الكربوكسيلية هي حموض ضعيفة، تتفكك جزئياً في الماء لتعطي أيونات الهيدرونيوم.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
