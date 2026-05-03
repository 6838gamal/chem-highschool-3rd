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
    generateParticles();
  }

  double safeLog(double x) => x <= 0 ? 0 : log(x);

  // ================= PH =================
  double calculatePH(double Vb) {
    double nAcid = Ca * Va / 1000;
    double nBase = Cb * Vb / 1000;
    double total = (Va + Vb) / 1000;

    double pH;

    if (type == TitrationType.strongStrong) {
      if (Vb < Ve) {
        double H = max((nAcid - nBase) / total, 1e-10);
        pH = -safeLog(H) / ln10;
      } else {
        double OH = max((nBase - nAcid) / total, 1e-10);
        pH = 14 + (safeLog(OH) / ln10);
      }
    } else if (type == TitrationType.weakStrong) {
      double pKa = -safeLog(Ka) / ln10;

      if (Vb < Ve) {
        double acid = max(nAcid - nBase, 1e-10);
        double base = max(nBase, 1e-10);
        pH = pKa + (safeLog(base / acid) / ln10);
      } else {
        double OH = max((nBase - nAcid) / total, 1e-10);
        pH = 14 + (safeLog(OH) / ln10);
      }
    } else {
      pH = 7 + (Vb - Ve) * 0.15;
    }

    return pH.clamp(0, 14);
  }

  // ================= UPDATE =================
  void update(double v) {
    setState(() {
      added = v.clamp(0, Ve * 2);

      curve = List.generate(
        (added * 3).toInt(),
        (i) => FlSpot(i / 3, calculatePH(i / 3)),
      );

      reactionInfo = getReactionInfo();
    });
  }

  // ================= PARTICLES =================
  void generateParticles() {
    particles = List.generate(40, (_) {
      return Offset(
        random.nextDouble(),
        random.nextDouble(),
      );
    });
  }

  // ================= 🎨 PH COLOR SYSTEM =================
  Color getPHColor(double ph) {
    if (ph < 3) {
      return Colors.redAccent;
    } else if (ph < 6) {
      return Colors.orangeAccent;
    } else if (ph < 7.5) {
      return Colors.greenAccent;
    } else if (ph < 11) {
      return Colors.blueAccent;
    } else {
      return Colors.deepPurpleAccent;
    }
  }

  // ================= 🧪 BOTTLE COLOR =================
  Color getBottleColor() {
    double ph = calculatePH(added);

    // 🎯 نقطة التكافؤ (لون خاص)
    if ((added - Ve).abs() < 0.5) {
      return Colors.white.withOpacity(0.6);
    }

    return getPHColor(ph).withOpacity(0.45);
  }

  // ================= EQUATION =================
  String getEquation() {
    return "CH₃COOH + NaOH → CH₃COONa + H₂O";
  }

  // ================= INFO =================
  String getReactionInfo() {
    if (added < Ve * 0.5) {
      return "محلول حمضي قوي - H⁺ مرتفع";
    } else if (added < Ve) {
      return "منطقة تنظيم (Buffer)";
    } else if (added == Ve) {
      return "نقطة التكافؤ - تعادل كامل";
    } else {
      return "فائض قاعدة - OH⁻ مسيطر";
    }
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
                child: Text("ضعيف + قوي"),
              ),
              DropdownMenuItem(
                value: TitrationType.strongStrong,
                child: Text("قوي + قوي"),
              ),
              DropdownMenuItem(
                value: TitrationType.strongWeak,
                child: Text("قوي + ضعيف"),
              ),
            ],
            onChanged: (v) => setState(() {
              type = v!;
              added = 0;
              curve.clear();
            }),
          ),

          const SizedBox(height: 20),

          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: getBottleColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.science),
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

          Stack(
            alignment: Alignment.center,
            children: [

              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: getBottleColor(),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),

              ...particles.map((p) {
                return Positioned(
                  left: 75 + (p.dx * 60),
                  top: 75 + (p.dy * 60),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 10),

          Text("pH: ${calculatePH(added).toStringAsFixed(2)}"),

          const SizedBox(height: 10),

          Text(
            reactionInfo,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          Wrap(
            spacing: 10,
            children: [
              ElevatedButton(
                onPressed: () => generateParticles(),
                child: const Text("بدء"),
              ),
              ElevatedButton(
                onPressed: () => update(added + 2),
                child: const Text("قاعدة"),
              ),
              ElevatedButton(
                onPressed: () => update(added - 2),
                child: const Text("حمض"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              getEquation(),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
