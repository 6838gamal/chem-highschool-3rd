import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../constants.dart';

/// ================= TYPES =================
enum ParticleType {
  h2,
  o2,
  hcl,
  h2o2,
  butane,
  octane,
  caco3,
  cl2,
  f2,
  co2,
  h2o,
}

/// ================= PARTICLE =================
class Particle {
  Offset position;
  Offset velocity;
  ParticleType type;

  bool reacted;
  bool reacting;
  double reactionProgress;

  Particle({
    required this.position,
    required this.velocity,
    required this.type,
    this.reacted = false,
    this.reacting = false,
    this.reactionProgress = 0,
  });
}

/// ================= REACTION =================
class Reaction {
  final List<ParticleType> inputs;
  final List<ParticleType> outputs;
  final bool needHeat;
  final bool needCatalyst;
  final String equation;

  Reaction({
    required this.inputs,
    required this.outputs,
    required this.equation,
    this.needHeat = false,
    this.needCatalyst = false,
  });
}

/// ================= MAIN SCREEN =================
class ChemistryLabScreen extends StatefulWidget {
  const ChemistryLabScreen({super.key});

  @override
  State<ChemistryLabScreen> createState() =>
      _ChemistryLabScreenState();
}

/// ================= STATE =================
class _ChemistryLabScreenState extends State<ChemistryLabScreen> {
  final List<Particle> particles = [];
  final Random random = Random();
  Timer? timer;

  double worldW = 300;
  double worldH = 500;

  bool burnerOn = false;
  bool catalystOn = false;

  ParticleType? selectedMaterial;
  ParticleType? selectedPowder;

  Reaction? currentReaction;

  String reactionStatus = "";

  /// ================= REACTIONS DATABASE =================
  final List<Reaction> reactions = [
    Reaction(
      inputs: [ParticleType.h2, ParticleType.cl2],
      outputs: [ParticleType.hcl, ParticleType.hcl],
      needHeat: true,
      equation: "H₂ + Cl₂ → 2HCl",
    ),
    Reaction(
      inputs: [ParticleType.h2, ParticleType.f2],
      outputs: [ParticleType.h2o],
      needHeat: true,
      equation: "H₂ + F₂ → H₂O",
    ),
    Reaction(
      inputs: [ParticleType.caco3],
      outputs: [ParticleType.co2],
      needHeat: true,
      equation: "CaCO₃ → CO₂ + CaO",
    ),
    Reaction(
      inputs: [ParticleType.h2o2],
      outputs: [ParticleType.h2o],
      needCatalyst: true,
      equation: "2H₂O₂ → 2H₂O + O₂",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startLoop();
  }

  /// ================= LOOP =================
  void _startLoop() {
    timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(() {
        _move();
        _detectReaction();
        _handleCollisions();
      });
    });
  }

  /// ================= INJECT FROM TUBE =================
  void _injectFromTube() {
    if (selectedMaterial == null) return;

    particles.add(
      Particle(
        position: Offset(worldW / 2, 0),
        velocity: const Offset(0, 3),
        type: selectedMaterial!,
      ),
    );

    if (selectedPowder != null) {
      particles.add(
        Particle(
          position: Offset(worldW / 2 + 10, 0),
          velocity: const Offset(0, 3),
          type: selectedPowder!,
        ),
      );
    }
  }

  /// ================= MOVEMENT =================
  void _move() {
    for (var p in particles) {
      if (p.reacting) {
        p.reactionProgress += 0.05;

        p.position += Offset(
          random.nextDouble() * 2 - 1,
          random.nextDouble() * 2 - 1,
        );

        if (p.reactionProgress >= 1) {
          p.reacting = false;
          p.reacted = true;
          p.velocity = Offset.zero;
        }
        continue;
      }

      /// نزول داخل الأنبوب
      if (p.position.dy < 150) {
        p.velocity = const Offset(0, 3);
      }

      p.position += p.velocity;
    }
  }

  /// ================= DETECT REACTION =================
  void _detectReaction() {
    reactionStatus = "";

    if (selectedMaterial == null) return;

    for (var r in reactions) {
      bool matchMaterial = r.inputs.contains(selectedMaterial);
      bool matchPowder = selectedPowder == null ||
          r.inputs.contains(selectedPowder);

      if (matchMaterial && matchPowder) {
        if (r.needHeat && !burnerOn) continue;
        if (r.needCatalyst && !catalystOn) continue;

        currentReaction = r;
        return;
      }
    }

    currentReaction = null;
  }

  /// ================= COLLISIONS =================
  void _handleCollisions() {
    bool anyReaction = false;

    if (selectedMaterial == null) {
      reactionStatus = "⚠ اختر مادة أولاً";
      return;
    }

    // Check if particles are in reaction zone (inside the container)
    List<Particle> inZone = particles
        .where((p) => p.position.dy > 150 && !p.reacted && !p.reacting)
        .toList();

    if (inZone.length < 2) {
      return;
    }

    for (int i = 0; i < inZone.length; i++) {
      for (int j = i + 1; j < inZone.length; j++) {
        final a = inZone[i];
        final b = inZone[j];

        if ((a.position - b.position).distanceSquared < 600) {
          if (currentReaction != null &&
              _matches(a, b, currentReaction!)) {
            anyReaction = true;
            _executeReaction(a, b, currentReaction!);
            reactionStatus =
                "✔ تفاعل صحيح: ${currentReaction!.equation}";
            return;
          }
        }
      }
    }

    if (!anyReaction && inZone.length >= 2) {
      reactionStatus = "❌ لا يوجد تفاعل بين هذه المواد";
    }
  }

  bool _matches(Particle a, Particle b, Reaction r) {
    return r.inputs.contains(a.type) &&
        r.inputs.contains(b.type);
  }

  /// ================= EXECUTE REACTION =================
  void _executeReaction(
      Particle a, Particle b, Reaction r) {
    a.reacting = true;
    b.reacting = true;

    a.reactionProgress = 0;
    b.reactionProgress = 0;

    a.velocity = Offset.zero;
    b.velocity = Offset.zero;

    if (r.outputs.isNotEmpty) {
      a.type = r.outputs.first;
      b.type = r.outputs.length > 1
          ? r.outputs[1]
          : r.outputs.first;
    }
  }

  /// ================= COLORS =================
  Color _color(ParticleType t) {
    switch (t) {
      case ParticleType.h2:
        return Colors.lightBlue;
      case ParticleType.o2:
        return Colors.blue;
      case ParticleType.hcl:
        return Colors.red;
      case ParticleType.h2o2:
        return Colors.purple;
      case ParticleType.butane:
        return Colors.orange;
      case ParticleType.octane:
        return Colors.deepOrange;
      case ParticleType.caco3:
        return Colors.grey;
      case ParticleType.cl2:
        return Colors.green;
      case ParticleType.f2:
        return Colors.yellow;
      case ParticleType.co2:
        return Colors.pink;
      case ParticleType.h2o:
        return Colors.cyan;
    }
  }

  String _name(ParticleType t) =>
      t.toString().split('.').last;

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("مختبر التفاعلات الكيميائية"),
      ),
      body: Column(
        children: [
          _topPanel(),
          Expanded(child: _labArea()),
        ],
      ),
    );
  }

  /// ================= TOP PANEL =================
  Widget _topPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black26,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Tooltip(
              message: 'الحرارة',
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  Switch(
                    value: burnerOn,
                    onChanged: (v) =>
                        setState(() => burnerOn = v),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'العامل المساعد',
              child: Row(
                children: [
                  const Text('⚗️', style: TextStyle(fontSize: 20)),
                  Switch(
                    value: catalystOn,
                    onChanged: (v) =>
                        setState(() => catalystOn = v),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<ParticleType>(
              hint: const Text("مادة", style: TextStyle(color: Colors.white)),
              dropdownColor: Colors.grey[800],
              value: selectedMaterial,
              onChanged: (v) =>
                  setState(() => selectedMaterial = v),
              items: ParticleType.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(_name(e), style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
            ),
            const SizedBox(width: 8),
            DropdownButton<ParticleType>(
              hint: const Text("مسحوق", style: TextStyle(color: Colors.white)),
              dropdownColor: Colors.grey[800],
              value: selectedPowder,
              onChanged: (v) =>
                  setState(() => selectedPowder = v),
              items: ParticleType.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(_name(e), style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _injectFromTube,
              icon: const Icon(Icons.arrow_downward),
              label: const Text("إدخال"),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= LAB AREA =================
  Widget _labArea() {
    return LayoutBuilder(
      builder: (context, c) {
        worldW = c.maxWidth;
        worldH = c.maxHeight;

        return Stack(
          children: [
            /// الأنبوب
            Positioned(
              top: 0,
              left: worldW / 2 - 10,
              child: Container(
                width: 20,
                height: 150,
                color: Colors.white24,
              ),
            ),

            /// الوعاء
            Center(
              child: Container(
                width: 220,
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent),
                  color: Colors.black38,
                ),
              ),
            ),

            /// النص
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    currentReaction?.equation ??
                        "لا يوجد تفاعل",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reactionStatus,
                    style: TextStyle(
                      color: reactionStatus.startsWith("✔")
                          ? Colors.green
                          : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// النار
            Positioned(
              bottom: 10,
              left: worldW / 2 - 20,
              child: Icon(
                Icons.local_fire_department,
                color: burnerOn
                    ? Colors.red
                    : Colors.grey,
                size: 40,
              ),
            ),

            /// الجسيمات
            ...particles.map((p) => Positioned(
                  left: p.position.dx,
                  top: p.position.dy,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _color(p.type),
                      shape: BoxShape.circle,
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
