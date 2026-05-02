import 'package:flutter/material.dart';
import 'constants.dart';
import 'custom_drawer.dart';
import 'lessons/bonding_lesson.dart'; // ملف تجميعي لتسهيل الاستيراد
import 'lessons/gas_laws_lesson.dart';
import 'lessons/chemistry_lab_lesson.dart';
import 'lessons/equilibrium_lesson.dart';
import 'lessons/ph_lesson.dart';
import 'lessons/salts_lab_screen.dart';
import 'lessons/titration_screen.dart';
import 'lessons/organic_lesson.dart';
import 'lessons/carbonyl_lab.dart';
import 'lessons/carboxylic_drag_lab.dart';
import 'lessons/ester_lab.dart';
import 'lessons/amines_lab.dart';

class HomeScreen extends StatelessWidget {
  final String studentName;
  const HomeScreen({super.key, required this.studentName});

  final List<Map<String, dynamic>> units = const [
    {"title": "بنية النواة واستقرارها", "icon": Icons.blur_on, "id": "bonding"},
    {"title": " الغازات ", "icon": Icons.waves, "id": "gas_lab"},
    {"title": " سرعة التفاعل الكيميائي ", "icon": Icons.precision_manufacturing, "id": "chem_lab"},
    {"title": "التوازن الكيميائي  ", "icon": Icons.air, "id": "equil_lab"},
    {"title": " الحموض والأسس", "icon": Icons.functions, "id": "chemistry_ph"},
    {"title": " المحاليل المائية للأملاح ", "icon": Icons.speed, "id": "salts_lab"},
    {"title": "المعايرة الحجمية ", "icon": Icons.trending_up, "id": "titration_lab"},
    {"title": "الأغوال", "icon": Icons.opacity, "id": "organic_lab"},
    {"title": "الألدهيدات والكيتونات ", "icon": Icons.straighten, "id": "carbonyl_lab"},
    {"title": " الحموض العضوية الكربوكسيلية ", "icon": Icons.science, "id": "carboxy_lab"},
    {"title": "مشتقات الحموض الكربوكسيلية ", "icon": Icons.bubble_chart, "id": "ester_lab"},
    {"title": "الأمينات", "icon": Icons.reorder, "id": "amines_lab"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("المختبر الذكي", style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      drawer: CustomDrawer(studentName: studentName),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: units.length,
        itemBuilder: (context, index) {
          final item = units[index];
          return _buildLessonCard(context, item['title'], item['icon'], item['id']);
        },
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, String title, IconData icon, String id) {
    return InkWell(
      onTap: () => _navigateToLesson(context, id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.neonBlue.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.neonBlue),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLesson(BuildContext context, String id) {
    Widget page;
    switch (id) {
      case "bonding": page = const BondingScreen(); break;
      case "amines_lab": page = const AminesLab(); break;
      case "chem_lab": page = const ChemistryLabScreen(); break;
      case "gas_lab": page = const GasLawsScreen(); break;
      case "salts_lab": page = const SaltLabAllInOne(); break;
      case "equil_lab": page = const EquilibriumScreen(); break;
      case "chemistry_ph": page = const HamoothWaAsasPage(); break;
      case "ester_lab": page = const DerivativesLab(); break;
      case "titration_lab": page = const RealTitrationScreen(); break;
      case "organic_lab": page = const AlcoholScreen(); break;
      case "carbonyl_lab": page = const AldehydesKetonesLab(); break;
      case "carboxy_lab": page = const CarboxylicDragLab(); break;
      default: page = const Scaffold(body: Center(child: Text("قيد التطوير")));
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }
}
