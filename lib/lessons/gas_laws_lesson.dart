import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../constants.dart';

class GasLawsScreen extends StatefulWidget {
  const GasLawsScreen({super.key});

  @override
  State<GasLawsScreen> createState() => _GasLawsScreenState();
}

class _GasLawsScreenState extends State<GasLawsScreen>
    with SingleTickerProviderStateMixin, TickerProviderStateMixin {

  late Ticker _ticker;
  final int particleCount = 60;
  final Random random = Random();

  List<Offset> positions = [];
  List<Offset> velocities = [];

  double temperature = 1.0;
  double volumeFactor = 1.0;

  List<double> pressureHistory = [];

  final double baseBoxSize = 260;

  int gasIndex = 0;

  final List<Map<String, dynamic>> gases = [
    {"name": "H₂", "mass": 2, "color": Colors.blue},
    {"name": "N₂", "mass": 28, "color": Colors.green},
    {"name": "O₂", "mass": 32, "color": Colors.orange},
    {"name": "UF₆", "mass": 352, "color": Colors.purple},
  ];

  double get boxSize => baseBoxSize * volumeFactor;

  double get pressure => (temperature * particleCount) / volumeFactor;

  @override
  void initState() {
    super.initState();
    _initParticles();
    _ticker = Ticker(_update)..start();
  }

  void _initParticles() {
    positions = List.generate(
      particleCount,
      (_) => Offset(
        random.nextDouble() * baseBoxSize,
        random.nextDouble() * baseBoxSize,
      ),
    );

    velocities = List.generate(
      particleCount,
      (_) => Offset(
        (random.nextDouble() - 0.5) * 3,
        (random.nextDouble() - 0.5) * 3,
      ),
    );
  }

  double _speedFactor() {
    // كلما زادت الكتلة قلّت السرعة
    final mass = gases[gasIndex]["mass"];
    return temperature / (mass / 10);
  }

  void _update(Duration _) {
    if (!mounted) return;

    setState(() {
      final speed = _speedFactor();

      for (int i = 0; i < particleCount; i++) {
        final p = positions[i];
        final v = velocities[i] * speed;

        double dx = p.dx + v.dx;
        double dy = p.dy + v.dy;

        // 🔴 منع الخروج النهائي (تصحيح قوي)
        if (dx <= 0) {
          dx = 0;
          velocities[i] = Offset(-velocities[i].dx, velocities[i].dy);
        }
        if (dx >= boxSize) {
          dx = boxSize;
          velocities[i] = Offset(-velocities[i].dx, velocities[i].dy);
        }

        if (dy <= 0) {
          dy = 0;
          velocities[i] = Offset(velocities[i].dx, -velocities[i].dy);
        }
        if (dy >= boxSize) {
          dy = boxSize;
          velocities[i] = Offset(velocities[i].dx, -velocities[i].dy);
        }

        positions[i] = Offset(dx, dy);
      }

      pressureHistory.add(pressure);
      if (pressureHistory.length > 80) {
        pressureHistory.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gas = gases[gasIndex];

    return DefaultTabController(
      length: gases.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("قوانين الغازات"),
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            onTap: (i) {
              setState(() => gasIndex = i);
            },
            tabs: gases.map((g) => Tab(text: g["name"])).toList(),
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [

              /// 📊 لوحة المعلومات مع الوحدات
              _infoPanel(gas),

              const SizedBox(height: 15),

              /// 🔬 المحاكاة
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: gas["color"], width: 2),
                    color: Colors.black26,
                  ),
                  child: CustomPaint(
                    painter: GasPainter(positions, gas["color"]),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              /// 📈 الرسم البياني
              SizedBox(
                height: 120,
                child: CustomPaint(
                  painter: GraphPainter(pressureHistory),
                ),
              ),

              const SizedBox(height: 10),

              /// 🎛 التحكم
              _controls(gas),

            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPanel(Map gas) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "الغاز: ${gas["name"]}",
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            "الضغط: ${pressure.toStringAsFixed(2)} atm",
            style: const TextStyle(color: Colors.cyan),
          ),
          Text(
            "الحرارة (T): ${temperature.toStringAsFixed(2)} K",
            style: const TextStyle(color: Colors.orange),
          ),
          Text(
            "الحجم (V): ${volumeFactor.toStringAsFixed(2)} L",
            style: const TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _controls(Map gas) {
    return Column(
      children: [
        Slider(
          value: temperature,
          min: 0.5,
          max: 3.0,
          activeColor: Colors.orange,
          onChanged: (v) => setState(() => temperature = v),
        ),
        Slider(
          value: volumeFactor,
          min: 0.5,
          max: 1.5,
          activeColor: Colors.blue,
          onChanged: (v) => setState(() => volumeFactor = v),
        ),
      ],
    );
  }
}

class GasPainter extends CustomPainter {
  final List<Offset> positions;
  final Color color;

  GasPainter(this.positions, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (final p in positions) {
      canvas.drawCircle(p, 3.5, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class GraphPainter extends CustomPainter {
  final List<double> data;

  GraphPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    final maxVal = data.reduce(max).clamp(1, double.infinity);

    for (int i = 0; i < data.length; i++) {
      final x = (i / data.length) * size.width;
      final y = size.height - (data[i] / maxVal) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
