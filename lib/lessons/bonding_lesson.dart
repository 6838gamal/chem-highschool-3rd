import 'package:flutter/material.dart';
import 'dart:math';

class BondingScreen extends StatefulWidget {
  const BondingScreen({super.key});

  @override
  State<BondingScreen> createState() => _BondingScreenState();
}

// ================= MODEL =================

class Nucleus {
  int protons;
  int neutrons;
  String symbol;

  Nucleus(this.protons, this.neutrons, this.symbol);

  int get mass => protons + neutrons;
}

enum ReactionType {
  alpha,
  betaMinus,
  betaPlus,
  electronCapture,
  neutronCapture,
  fission,
  fusion,
}

// ================= STATE =================

class _BondingScreenState extends State<BondingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  int selected = 0;

  late List<Map<String, dynamic>> reactions;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    reactions = [
      {"name": "β⁻ C → N", "type": ReactionType.betaMinus, "before": Nucleus(6, 8, "C"), "after": Nucleus(7, 7, "N")},
      {"name": "β⁺ C → B", "type": ReactionType.betaPlus, "before": Nucleus(6, 5, "C"), "after": Nucleus(5, 6, "B")},
      {"name": "Electron Capture Rb → Kr", "type": ReactionType.electronCapture, "before": Nucleus(37, 44, "Rb"), "after": Nucleus(36, 45, "Kr")},
      {"name": "Alpha Ra → Rn", "type": ReactionType.alpha, "before": Nucleus(88, 138, "Ra"), "after": Nucleus(86, 136, "Rn")},
      {"name": "Neutron Capture Au", "type": ReactionType.neutronCapture, "before": Nucleus(79, 118, "Au"), "after": Nucleus(79, 119, "Au")},
      {"name": "Fission U → Ba + Kr", "type": ReactionType.fission, "before": Nucleus(92, 143, "U"), "after": Nucleus(56, 85, "Ba")},
      {"name": "Fusion H + H → He", "type": ReactionType.fusion, "before": Nucleus(1, 1, "H"), "after": Nucleus(2, 2, "He")},
    ];
  }

  void start() => controller.forward(from: 0);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ================= EQUATION =================

  Widget buildEquation(Nucleus b, Nucleus a, ReactionType type, double t) {
    String before = "¹${b.mass}₍${b.protons}₎${b.symbol}";
    String after = "¹${a.mass}₍${a.protons}₎${a.symbol}";

    String particle = "";

    switch (type) {
      case ReactionType.betaMinus:
        particle = " + β⁻";
        break;
      case ReactionType.betaPlus:
        particle = " + β⁺";
        break;
      case ReactionType.alpha:
        particle = " + ⁴₂He";
        break;
      case ReactionType.electronCapture:
        particle = " + e⁻";
        break;
      case ReactionType.neutronCapture:
        particle = " + n";
        break;
      case ReactionType.fission:
        particle = " + Ba + Kr + 3n";
        break;
      case ReactionType.fusion:
        particle = "";
        break;
    }

    String text;

    if (t < 0.3) {
      text = before;
    } else if (t < 0.7) {
      text = "$before → ?";
    } else {
      text = "$before → $after$particle + Energy";
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final r = reactions[selected];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("المختبر النووي"),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          DropdownButton<int>(
            dropdownColor: Colors.black,
            value: selected,
            items: List.generate(
              reactions.length,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  reactions[i]["name"],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            onChanged: (v) => setState(() => selected = v!),
          ),

          Expanded(
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) => CustomPaint(
                painter: NuclearPainter(
                  controller.value,
                  r["before"],
                  r["after"],
                  r["type"],
                ),
              ),
            ),
          ),

          buildEquation(
            r["before"],
            r["after"],
            r["type"],
            controller.value,
          ),

          ElevatedButton(
            onPressed: start,
            child: const Text("ابدأ التفاعل"),
          ),
        ],
      ),
    );
  }
}

// ================= PAINTER =================

class NuclearPainter extends CustomPainter {
  final double t;
  final Nucleus before;
  final Nucleus after;
  final ReactionType type;

  NuclearPainter(this.t, this.before, this.after, this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.1, size.height / 2);
    final end = Offset(size.width * 0.9, size.height / 2);

    // Smooth easing for more natural movement
    double easeT = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
    final pos = Offset.lerp(start, end, easeT)!;

    double shake = (t > 0.25 && t < 0.65) ? sin(t * 50) * 8 : 0;
    final c = pos + Offset(shake, 0);

    final current = _interpolateNucleus(before, after, t);

    // Enhanced glow effect
    double glowIntensity = 0.0;
    if (t > 0.2 && t < 0.7) {
      glowIntensity = sin((t - 0.2) * pi / 0.5) * 0.8;
    }
    final glowPaint = Paint()
      ..color = Colors.orange.withOpacity(glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);

    canvas.drawCircle(c, 65, glowPaint);

    _drawAtom(canvas, c, current);
    _drawParticles(canvas, c);

    if (t > 0.6) {
      _drawExplosion(canvas, c);
    }
  }

  Nucleus _interpolateNucleus(Nucleus a, Nucleus b, double t) {
    int p = (a.protons + (b.protons - a.protons) * t).round();
    int n = (a.neutrons + (b.neutrons - a.neutrons) * t).round();

    return Nucleus(p, n, t < 0.5 ? a.symbol : b.symbol);
  }

  void _drawAtom(Canvas canvas, Offset center, Nucleus n) {
    // Draw nucleus core
    canvas.drawCircle(center, 35, Paint()..color = Colors.blueAccent);
    
    // Draw nucleus border
    canvas.drawCircle(center, 35, Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Draw protons (red) in outer ring
    for (int i = 0; i < n.protons; i++) {
      final angle = i * 2 * pi / max(1, n.protons);
      final pos = center + Offset(cos(angle), sin(angle)) * 25;
      canvas.drawCircle(pos, 5, Paint()..color = Colors.red);
      // Add proton label
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '+',
          style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Draw neutrons (grey) in inner ring
    for (int i = 0; i < n.neutrons; i++) {
      final angle = i * 2 * pi / max(1, n.neutrons);
      final pos = center + Offset(cos(angle), sin(angle)) * 16;
      canvas.drawCircle(pos, 4, Paint()..color = Colors.grey);
    }
  }

  void _drawParticles(Canvas canvas, Offset center) {
    void draw(Offset p, Color c, double r) {
      canvas.drawCircle(p, r, Paint()..color = c);
      // Add glow to particles
      canvas.drawCircle(p, r + 2, Paint()
        ..color = c.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    if (type == ReactionType.betaMinus && t > 0.25) {
      double particleT = min(1.0, (t - 0.25) / 0.5);
      final p = Offset.lerp(center, center + const Offset(150, -80), particleT)!;
      draw(p, Colors.yellow, 6);
    }

    if (type == ReactionType.alpha && t > 0.25) {
      double particleT = min(1.0, (t - 0.25) / 0.5);
      final p = Offset.lerp(center, center + const Offset(0, -180), particleT)!;
      draw(p, Colors.orange, 11);
    }

    if (type == ReactionType.fusion) {
      final l = Offset.lerp(center + const Offset(-100, 0), center, t)!;
      final r = Offset.lerp(center + const Offset(100, 0), center, t)!;

      if (t < 0.6) {
        draw(l, Colors.blue, 13);
        draw(r, Colors.blue, 13);
      }

      if (t > 0.6) {
        draw(center, Colors.purple, 22);
      }
    }
  }

  void _drawExplosion(Canvas canvas, Offset center) {
    double p = (t - 0.7) / 0.3;
    if (p < 0 || p > 1) return;

    final radius = p * 150;

    final paint = Paint()
      ..color = Colors.orange.withOpacity(1 - p)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
