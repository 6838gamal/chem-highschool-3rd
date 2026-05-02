import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';

class DerivativesLab extends StatefulWidget {
  const DerivativesLab({super.key});

  @override
  State<DerivativesLab> createState() => _DerivativesLabState();
}

class _DerivativesLabState extends State<DerivativesLab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double temperature = 25;
  bool catalyst = false;

  // عدادات الجزيئات في النظام
  int acid = 5;
  int alcohol = 5;
  int ester = 0;
  int water = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // تغيير لون الخلفية بناءً على درجة الحرارة
  Color getBgColor() {
    if (temperature < 35) return AppColors.background;
    if (temperature < 60) return Colors.orange.withOpacity(0.1);
    return Colors.red.withOpacity(0.15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBgColor(),
      appBar: AppBar(
        title: const Text("مشتقات الحموض الكربوكسيلية"),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonBlue,
          tabs: const [
            Tab(text: "الأسترة"),
            Tab(text: "التحلل"),
            Tab(text: "التوازن"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEsterTab(),
          _buildHydrolysisTab(),
          _buildEquilibriumTab(),
        ],
      ),
    );
  }

  // --- محرك بناء التبويبات ---

  Widget _buildEsterTab() {
    return _baseLabLayout(
      instruction: "اسحب (Acid + Alcohol) للمنطقة لتكوين الإستر",
      reactionZoneLabel: "منطقة تكوين الإستر",
      targetData: ["acid", "alcohol"],
      onReaction: (data) {
        setState(() {
          if (data == "acid" && acid > 0) acid--;
          if (data == "alcohol" && alcohol > 0) alcohol--;
          ester++;
          water++;
        });
      },
      inventory: [
        _draggableMolecule("Acid", acid, Colors.redAccent, "acid"),
        _draggableMolecule("Alcohol", alcohol, Colors.blueAccent, "alcohol"),
      ],
      stats: "Ester: $ester | H₂O: $water",
    );
  }

  Widget _buildHydrolysisTab() {
    return _baseLabLayout(
      instruction: "اسحب (Ester) إلى منطقة الماء لتفكيكه",
      reactionZoneLabel: "منطقة التحلل المائي",
      targetData: ["ester"],
      onReaction: (data) {
        setState(() {
          if (ester > 0) {
            ester--;
            water--;
            acid++;
            alcohol++;
          }
        });
      },
      inventory: [
        _draggableMolecule("Ester", ester, Colors.purpleAccent, "ester"),
      ],
      stats: "Acid: $acid | Alcohol: $alcohol",
    );
  }

  Widget _buildEquilibriumTab() {
    return _baseLabLayout(
      instruction: "توازن ديناميكي: التفاعل يسير في الاتجاهين",
      reactionZoneLabel: "وعاء الاتزان",
      targetData: ["acid", "alcohol", "ester"],
      onReaction: (data) {
        // منطق التوازن يمكن تعقيده هنا بناءً على الحرارة
      },
      inventory: [
        _draggableMolecule("Acid", acid, Colors.redAccent, "acid"),
        _draggableMolecule("Alcohol", alcohol, Colors.blueAccent, "alcohol"),
        _draggableMolecule("Ester", ester, Colors.purpleAccent, "ester"),
      ],
      stats: "نظام متزن حرارياً",
    );
  }

  // --- أدوات الواجهة المشتركة ---

  Widget _baseLabLayout({
    required String instruction,
    required String reactionZoneLabel,
    required List<String> targetData,
    required Function(String) onReaction,
    required List<Widget> inventory,
    required String stats,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(instruction, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          
          // منطقة التفاعل (Drag Target)
          DragTarget<String>(
            onAccept: onReaction,
            builder: (context, _, __) => Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.biotech, color: Colors.white24, size: 50),
                  Text(reactionZoneLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(stats, style: TextStyle(color: AppColors.neonBlue, fontSize: 18)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Wrap(spacing: 15, children: inventory),
          
          const Spacer(),
          _buildControlsPanel(),
        ],
      ),
    );
  }

  Widget _draggableMolecule(String label, int count, Color color, String data) {
    return Draggable<String>(
      data: data,
      feedback: _moleculeUI(label, color, true),
      childWhenDragging: Opacity(opacity: 0.3, child: _moleculeUI("$label ($count)", color, false)),
      child: count > 0 ? _moleculeUI("$label ($count)", color, false) : const SizedBox(),
    );
  }

  Widget _moleculeUI(String label, Color color, bool isFeedback) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isFeedback ? [BoxShadow(color: color, blurRadius: 15)] : [],
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildControlsPanel() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.hot_tub, color: Colors.orangeAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Slider(
                  value: temperature,
                  min: 10, max: 100,
                  activeColor: Colors.orangeAccent,
                  onChanged: (v) => setState(() => temperature = v),
                ),
              ),
              Text("${temperature.toInt()}°C", style: const TextStyle(color: Colors.white)),
            ],
          ),
          SwitchListTile(
            title: const Text("إضافة حمض H₂SO₄ (محفز)", style: TextStyle(color: Colors.white, fontSize: 14)),
            value: catalyst,
            onChanged: (v) => setState(() => catalyst = v),
            activeColor: AppColors.neonBlue,
          ),
        ],
      ),
    );
  }
}
