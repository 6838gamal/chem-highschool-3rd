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
                size: Size.infinite,
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

    // Linear smooth movement - no vibration
    final c = Offset.lerp(start, end, t)!;

    final current = _interpolateNucleus(before, after, t);

    // Draw path/trajectory line - thin and subtle
    final pathPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.15)
      ..strokeWidth = 1;
    canvas.drawLine(start, end, pathPaint);

    // Subtle glow only during reaction
    if (t > 0.3 && t < 0.7) {
      double glowIntensity = sin((t - 0.3) * pi / 0.4) * 0.4;
      final glowPaint = Paint()
        ..color = Colors.orange.withOpacity(glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawCircle(c, 75, glowPaint);
    }

    _drawAtom(canvas, c, current);
    _drawParticles(canvas, c);

    if (t > 0.6) {
      _drawExplosion(canvas, c);
    }
  }

  void _drawProgressTrail(Canvas canvas, Offset start, Offset current) {
    final trailPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..strokeWidth = 3;
    canvas.drawLine(start, current, trailPaint);
  }

  Nucleus _interpolateNucleus(Nucleus a, Nucleus b, double t) {
    int p = (a.protons + (b.protons - a.protons) * t).round();
    int n = (a.neutrons + (b.neutrons - a.neutrons) * t).round();

    return Nucleus(p, n, t < 0.5 ? a.symbol : b.symbol);
  }

  void _drawAtom(Canvas canvas, Offset center, Nucleus n) {
    // Draw nucleus core with size proportional to mass
    double coreRadius = 25 + (n.mass / 50) * 15;
    canvas.drawCircle(center, coreRadius, Paint()..color = Colors.blueAccent);
    
    // Draw nucleus border
    canvas.drawCircle(center, coreRadius, Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Draw protons (red) - show count clearly
    for (int i = 0; i < n.protons; i++) {
      final angle = i * 2 * pi / max(1, n.protons);
      final radius = coreRadius + 20;
      final pos = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawCircle(pos, 6, Paint()..color = Colors.red);
    }

    // Draw neutrons (grey) - show count clearly
    for (int i = 0; i < n.neutrons; i++) {
      final angle = i * 2 * pi / max(1, n.neutrons);
      final radius = coreRadius + 10;
      final pos = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawCircle(pos, 5, Paint()..color = Colors.grey);
    }
    
    // Draw text with proton and neutron count
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'P:${n.protons} N:${n.neutrons}',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, -coreRadius - 30));
  }

  void _drawParticles(Canvas canvas, Offset center) {
    void draw(Offset p, Color c, double r) {
      canvas.drawCircle(p, r, Paint()..color = c);
      // Add glow to particles
      canvas.drawCircle(p, r + 2, Paint()
        ..color = c.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    // Beta minus emission - electron/antineutrino
    if (type == ReactionType.betaMinus) {
      if (t > 0.25 && t < 1.0) {
        double particleT = min(1.0, (t - 0.25) / 0.75);
        final p = Offset.lerp(center, center + const Offset(200, -100), particleT)!;
        draw(p, Colors.yellow, 8);
      }
    }

    // Beta plus emission - positron
    if (type == ReactionType.betaPlus) {
      if (t > 0.25 && t < 1.0) {
        double particleT = min(1.0, (t - 0.25) / 0.75);
        final p = Offset.lerp(center, center + const Offset(-200, 100), particleT)!;
        draw(p, Colors.pink, 8);
      }
    }

    // Alpha particle emission
    if (type == ReactionType.alpha) {
      if (t > 0.25 && t < 1.0) {
        double particleT = min(1.0, (t - 0.25) / 0.75);
        final p = Offset.lerp(center, center + const Offset(0, -220), particleT)!;
        draw(p, Colors.deepOrange, 14);
      }
    }

    // Electron capture
    if (type == ReactionType.electronCapture) {
      if (t > 0.2 && t < 1.0) {
        double particleT = min(1.0, (t - 0.2) / 0.8);
        final p = Offset.lerp(center + const Offset(-150, -150), center, particleT)!;
        draw(p, Colors.lightBlue, 7);
      }
    }

    // Neutron capture
    if (type == ReactionType.neutronCapture) {
      if (t > 0.2 && t < 1.0) {
        double particleT = min(1.0, (t - 0.2) / 0.8);
        final p = Offset.lerp(center + const Offset(150, 0), center, particleT)!;
        draw(p, Colors.grey, 10);
      }
    }

    // Fission - two products moving outward
    if (type == ReactionType.fission) {
      if (t > 0.25 && t < 1.0) {
        double particleT = min(1.0, (t - 0.25) / 0.75);
        final p1 = Offset.lerp(center, center + const Offset(-250, -120), particleT)!;
        final p2 = Offset.lerp(center, center + const Offset(250, 120), particleT)!;
        draw(p1, Colors.amber, 12);
        draw(p2, Colors.amber, 12);
      }
    }

    // Fusion - combining nuclei
    if (type == ReactionType.fusion) {
      final l = Offset.lerp(center + const Offset(-120, 0), center, t)!;
      final r = Offset.lerp(center + const Offset(120, 0), center, t)!;

      if (t < 0.7) {
        draw(l, Colors.lightBlue, 15);
        draw(r, Colors.lightBlue, 15);
      }

      if (t > 0.7) {
        double mergeT = min(1.0, (t - 0.7) / 0.3);
        double size = 20 + mergeT * 10;
        draw(center, Color.lerp(Colors.purple, Colors.yellow, mergeT)!, size);
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
