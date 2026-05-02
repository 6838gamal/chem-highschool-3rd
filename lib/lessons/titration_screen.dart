import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../constants.dart';

enum TitrationType {
  weakStrong,
  strongStrong,
  strongWeak
}

class RealTitrationScreen extends StatefulWidget {
  const RealTitrationScreen({Key? key}) : super(key: key);

  @override
  State<RealTitrationScreen> createState() => _RealTitrationScreenState();
}

class _RealTitrationScreenState extends State<RealTitrationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  TitrationType type = TitrationType.weakStrong;

  String acid = "CH3COOH";
  String base = "NaOH";

  double Ca = 0.1;
  double Va = 25;
  double Cb = 0.1;
  double Ka = 1.8e-5;

  double added = 0;
  double temperature = 25;

  List<FlSpot> curve = [];
  List<Offset> particles = [];
  Random random = Random();

  String reactionInfo = "ابدأ التفاعل لرؤية ما يحدث داخل القنينة";

  double get Ve => (Ca * Va) / Cb;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  double safeLog(double x) => (x <= 0) ? 0 : log(x);

  // ================= PH =================
  double calculatePH(double Vb) {
    double nAcid = Ca * Va / 1000;
    double nBase = Cb * Vb / 1000;
    double total = (Va + Vb) / 1000;

    if (type == TitrationType.strongStrong) {
      if (Vb < Ve) {
        double H = max((nAcid - nBase) / total, 1e-10);
        return -safeLog(H) / ln10;
      } else {
        double OH = max((nBase - nAcid) / total, 1e-10);
        return 14 + (safeLog(OH) / ln10);
      }
    }

    if (type == TitrationType.weakStrong) {
      double pKa = -safeLog(Ka) / ln10;

      if (Vb < Ve) {
        double acidLeft = max(nAcid - nBase, 1e-10);
        double baseFormed = max(nBase, 1e-10);
        return pKa + (safeLog(baseFormed / acidLeft) / ln10);
      } else {
        double OH = max((nBase - nAcid) / total, 1e-10);
        return 14 + (safeLog(OH) / ln10);
      }
    }

    if (Vb < Ve) return 3.2;
    return 11.5;
  }

  // ================= UPDATE =================
  void update(double v) {
    setState(() {
      added = v;

      curve = List.generate(
        (v * 2).toInt(),
        (i) => FlSpot(i / 2, calculatePH(i / 2)),
      );

      generateParticles();
      reactionInfo = getReactionInfo();
    });
  }

  // ================= PARTICLES =================
  void generateParticles() {
    particles = List.generate(25, (i) {
      return Offset(
        random.nextDouble(),
        random.nextDouble(),
      );
    });
  }

  // ================= COLOR =================
  Color getBottleColor() {
    if (type == TitrationType.weakStrong) {
      return Colors.purpleAccent.withOpacity(0.5);
    }
    if (type == TitrationType.strongStrong) {
      return Colors.blueAccent.withOpacity(0.5);
    }
    return Colors.yellowAccent.withOpacity(0.5);
  }

  // ================= EQUATION =================
  String getEquation() {
    if (acid == "CH3COOH") {
      return "CH₃COOH + NaOH → CH₃COONa + H₂O";
    }
    return "HCl + NaOH → NaCl + H₂O";
  }

  // ================= INFO =================
  String getReactionInfo() {
    if (type == TitrationType.strongStrong) {
      return "تعادل كامل: H⁺ + OH⁻ → H₂O";
    }
    if (type == TitrationType.weakStrong) {
      return "محلول منظم قبل نقطة التكافؤ (Buffer Solution)";
    }
    return "قاعدة ضعيفة لا تتأين بالكامل";
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("المعايرة التفاعلية"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "التجربة"),
            Tab(text: "المعمل"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _experimentTab(),
          _labTab(),
        ],
      ),
    );
  }

  // ================= EXPERIMENT =================
  Widget _experimentTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButton<TitrationType>(
            value: type,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                  value: TitrationType.weakStrong,
                  child: Text("ضعيف + قوي (بنفسجي)")),
              DropdownMenuItem(
                  value: TitrationType.strongStrong,
                  child: Text("قوي + قوي (أزرق)")),
              DropdownMenuItem(
                  value: TitrationType.strongWeak,
                  child: Text("قوي + ضعيف (أصفر)")),
            ],
            onChanged: (v) => setState(() {
              type = v!;
              added = 0;
              curve.clear();
            }),
          ),

          const SizedBox(height: 20),

          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: getBottleColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: Icon(Icons.science)),
          ),

          const SizedBox(height: 10),

          Text("pH: ${calculatePH(added).toStringAsFixed(2)}"),

          Slider(
            min: 0,
            max: Ve * 2,
            value: added,
            onChanged: update,
          ),

          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 14,
                lineBarsData: [
                  LineChartBarData(
                    spots: curve,
                    isCurved: true,
                    color: Colors.cyan,
                    barWidth: 3,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= LAB =================
  Widget _labTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          // 🧪 القنينة + الجزيئات
          Stack(
            alignment: Alignment.center,
            children: [

              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: getBottleColor(),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),

              ...particles.map((p) {
                return Positioned(
                  left: 70 + (p.dx * 40),
                  top: 70 + (p.dy * 40),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            "pH: ${calculatePH(added).toStringAsFixed(2)}  |  T: ${temperature.toStringAsFixed(0)}°C",
            style: const TextStyle(color: Colors.white),
          ),

          const SizedBox(height: 10),

          Text(
            reactionInfo,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          // 🎛️ التحكم
          Wrap(
            spacing: 10,
            children: [

              ElevatedButton(
                onPressed: () => setState(() {
                  generateParticles();
                }),
                child: const Text("بدء"),
              ),

              ElevatedButton(
                onPressed: () => setState(() {
                  added += 2;
                  update(added);
                }),
                child: const Text("إضافة قاعدة"),
              ),

              ElevatedButton(
                onPressed: () => setState(() {
                  added -= 2;
                  update(added);
                }),
                child: const Text("إضافة حمض"),
              ),

              ElevatedButton(
                onPressed: () => setState(() {
                  temperature += 10;
                }),
                child: const Text("حرارة"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ⚗️ المعادلة (تحت المعمل)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              getEquation(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
