import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';

class AminesLab extends StatefulWidget {
  const AminesLab({super.key});

  @override
  State<AminesLab> createState() => _AminesLabState();
}

class _AminesLabState extends State<AminesLab> {
  final List<String> amines = ['أمين أولي', 'أمين ثانوي', 'أمين ثالثي'];
  final List<String> structures = ['R-NH₂', 'R₂-NH', 'R₃-N'];
  
  // تتبع حالة كل أمين بشكل منفصل
  final Map<int, bool> protonated = {0: false, 1: false, 2: false};
  final Map<int, double> reactionProgress = {0: 0.0, 1: 0.0, 2: 0.0};

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: amines.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("مختبر الأمينات"),
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            indicatorColor: AppColors.neonBlue,
            tabs: amines.map((e) => Tab(text: e)).toList(),
          ),
        ),
        body: TabBarView(
          children: List.generate(amines.length, (index) => _buildAmineInteractionTab(index)),
        ),
      ),
    );
  }

  Widget _buildAmineInteractionTab(int index) {
    bool isDone = protonated[index]!;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            amines[index],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 30),

          // منطقة التفاعل - ذرة النيتروجين
          DragTarget<String>(
            onAccept: (data) {
              setState(() {
                protonated[index] = true;
                reactionProgress[index] = 1.0;
              });
            },
            builder: (context, candidate, rejected) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? Colors.purple.withOpacity(0.2) : AppColors.glassWhite,
                  border: Border.all(
                    color: isDone ? Colors.purpleAccent : AppColors.neonBlue.withOpacity(0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDone ? Colors.purpleAccent.withOpacity(0.4) : AppColors.neonBlue.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isDone ? structures[index].replaceAll('N', 'N⁺') : structures[index],
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                      ),
                      if (isDone) const Text("(أيون أمونيوم)", style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // البروتون القابل للسحب
          if (!isDone) ...[
            const Text("اسحب البروتون للهجوم على الزوج الإلكتروني للنيتروجين", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            Draggable<String>(
              data: 'H+',
              feedback: _protonWidget(true),
              childWhenDragging: Opacity(opacity: 0.3, child: _protonWidget(false)),
              child: _protonWidget(false),
            ),
          ] else ...[
            _buildSuccessCard(index),
          ],
        ],
      ),
    );
  }

  Widget _protonWidget(bool isFeedback) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
        boxShadow: isFeedback ? [const BoxShadow(color: Colors.redAccent, blurRadius: 20)] : [],
      ),
      child: const Center(
        child: Text("H⁺", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }

  Widget _buildSuccessCard(int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 40),
          const SizedBox(height: 10),
          Text(
            "تمت البروتنة بنجاح! يعمل النيتروجين هنا كقاعدة لويس لأنه يمتلك زوجاً من الإلكترونات غير الرابطة.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.5),
          ),
          TextButton(
            onPressed: () => setState(() {
              protonated[index] = false;
              reactionProgress[index] = 0.0;
            }),
            child: const Text("إعادة التجربة"),
          )
        ],
      ),
    );
  }
}
