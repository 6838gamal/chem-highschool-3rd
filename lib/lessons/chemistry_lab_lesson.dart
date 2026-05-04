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

  /// ================= REACTIONS =================
  final List<Reaction> reactions = [
    Reaction(
      inputs: [ParticleType.h2, ParticleType.cl2],
      outputs: [ParticleType.hcl, ParticleType.hcl],
      needHeat: true,
      equation: "H₂ + Cl₂ → 2HCl",
    ),
    Reaction(
      inputs: [ParticleType.h2, ParticleType.o2],
      outputs: [ParticleType.h2o, ParticleType.h2o],
      needHeat: true,
      equation: "2H₂ + O₂ → 2H₂O",
    ),
    Reaction(
      inputs: [ParticleType.caco3],
      outputs: [ParticleType.co2],
      needHeat: true,
      equation: "CaCO₃ → CO₂ + CaO",
    ),
    Reaction(
      inputs: [ParticleType.h2o2],
      outputs: [ParticleType.h2o, ParticleType.o2],
      needCatalyst: true,
      equation: "2H₂O₂ → 2H₂O + O₂",
    ),
  ];

  final List<ParticleType> materials = [
    ParticleType.h2,
    ParticleType.o2,
    ParticleType.cl2,
    ParticleType.h2o2,
  ];

  final List<ParticleType> powders = [
    ParticleType.caco3,
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

  /// ================= INJECT =================
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

  bool isGas(ParticleType t) {
    return [
      ParticleType.h2,
      ParticleType.o2,
      ParticleType.cl2,
      ParticleType.co2,
    ].contains(t);
  }

  /// ================= MOVE =================
  void _move() {
    double containerBottom = worldH / 2 + 160;
    double containerLeft = worldW / 2 - 110;
    double containerRight = worldW / 2 + 110;

    for (var p in particles) {
      if (p.reacting) {
        p.reactionProgress += 0.05;

        p.position += Offset(
          (random.nextDouble() - 0.5) * 5,
          (random.nextDouble() - 0.5) * 5,
        );

        if (p.reactionProgress >= 1) {
          p.reacting = false;
          p.reacted = true;
        }
        continue;
      }

      double heat = burnerOn ? 1.5 : 1.0;

      if (p.position.dy < 150) {
        p.velocity = const Offset(0, 3);
      } else {
        p.velocity = Offset(
          p.velocity.dx * 0.98 * heat,
          (p.velocity.dy + 0.2) * heat,
        );
      }

      /// طفو الغازات
      if (isGas(p.type)) {
        p.velocity =
            Offset(p.velocity.dx, p.velocity.dy - 0.1);
      }

      p.position += p.velocity;

      /// ارتداد من القاع
      if (p.position.dy > containerBottom - 15) {
        p.position =
            Offset(p.position.dx, containerBottom - 15);

        p.velocity = Offset(
          (random.nextDouble() - 0.5) * 3,
          -random.nextDouble() * 3,
        );
      }

      /// الجوانب
      if (p.position.dx < containerLeft + 10 ||
          p.position.dx > containerRight - 10) {
        p.velocity =
            Offset(-p.velocity.dx, p.velocity.dy);
      }
    }
  }

  /// ================= DETECT =================
  void _detectReaction() {
    currentReaction = null;

    for (var r in reactions) {
      bool ok = true;

      if (selectedMaterial == null) return;

      if (!r.inputs.contains(selectedMaterial)) ok = false;

      if (selectedPowder != null &&
          !r.inputs.contains(selectedPowder)) {
        ok = false;
      }

      if (r.needHeat && !burnerOn) ok = false;
      if (r.needCatalyst && !catalystOn) ok = false;

      if (ok) {
        currentReaction = r;
        return;
      }
    }
  }

  /// ================= COLLISIONS =================
  void _handleCollisions() {
    if (currentReaction == null) {
      reactionStatus = "لا يوجد تفاعل";
      return;
    }

    List<Particle> available = particles
        .where((p) => p.position.dy > 150 && !p.reacted && !p.reacting)
        .toList();

    if (available.isEmpty) return;

    /// تفاعل مادة واحدة
    if (currentReaction!.inputs.length == 1) {
      for (var p in available) {
        if (currentReaction!.inputs.contains(p.type)) {
          _explode(p.position);

          p.reacting = true;
          p.reactionProgress = 0;

          p.type = currentReaction!.outputs.first;

          reactionStatus = "✔ ${currentReaction!.equation}";
          return;
        }
      }
    }

    /// تفاعل بمادتين
    for (int i = 0; i < available.length; i++) {
      for (int j = i + 1; j < available.length; j++) {
        final a = available[i];
        final b = available[j];

        double dist = (a.position - b.position).distance;
        double energy = (a.velocity - b.velocity).distance;

        if (dist < 30 && energy > 0.7) {
          if (random.nextDouble() < 0.85) {
            _explode(a.position);

            a.reacting = true;
            b.reacting = true;

            a.reactionProgress = 0;
            b.reactionProgress = 0;

            a.type = currentReaction!.outputs.first;
            b.type = currentReaction!.outputs.last;

            reactionStatus =
                "✔ ${currentReaction!.equation}";
            return;
          } else {
            reactionStatus = "❌ تصادم بدون تفاعل";
          }
        }
      }
    }
  }

  /// ================= EXPLOSION =================
  void _explode(Offset pos) {
    for (int i = 0; i < 5; i++) {
      particles.add(
        Particle(
          position: pos,
          velocity: Offset(
            (random.nextDouble() - 0.5) * 6,
            (random.nextDouble() - 0.5) * 6,
          ),
          type: ParticleType.co2,
        ),
      );
    }
  }

  /// ================= COLOR =================
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
      case ParticleType.caco3:
        return Colors.grey;
      case ParticleType.cl2:
        return Colors.green;
      case ParticleType.co2:
        return Colors.pink;
      case ParticleType.h2o:
        return Colors.cyan;
      default:
        return Colors.white;
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
      child: Row(
        children: [
          const Text('🔥'),
          Switch(
            value: burnerOn,
            onChanged: (v) => setState(() => burnerOn = v),
          ),
          const Text('⚗️'),
          Switch(
            value: catalystOn,
            onChanged: (v) =>
                setState(() => catalystOn = v),
          ),
          const SizedBox(width: 10),
          DropdownButton<ParticleType>(
            hint: const Text("مادة"),
            value: selectedMaterial,
            onChanged: (v) =>
                setState(() => selectedMaterial = v),
            items: materials
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(_name(e)),
                    ))
                .toList(),
          ),
          const SizedBox(width: 10),
          DropdownButton<ParticleType?>(
            hint: const Text("مسحوق"),
            value: selectedPowder,
            onChanged: (v) =>
                setState(() => selectedPowder = v),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text("بدون")),
              ...powders.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(_name(e)),
                  ))
            ],
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _injectFromTube,
            child: const Text("إدخال"),
          ),
        ],
      ),
    );
  }

  /// ================= LAB =================
  Widget _labArea() {
    return LayoutBuilder(
      builder: (context, c) {
        worldW = c.maxWidth;
        worldH = c.maxHeight;

        return Stack(
          children: [
            /// الوعاء
            Center(
              child: Container(
                width: 220,
                height: 320,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyan),
                  borderRadius: BorderRadius.circular(20),
                ),
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
                      boxShadow: [
                        BoxShadow(
                          color:
                              _color(p.type).withOpacity(0.7),
                          blurRadius: 10,
                        )
                      ],
                    ),
                  ),
                )),

            /// النص
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    currentReaction?.equation ??
                        "لا يوجد تفاعل",
                    style: const TextStyle(
                        color: Colors.white),
                  ),
                  Text(
                    reactionStatus,
                    style: TextStyle(
                      color: reactionStatus.startsWith("✔")
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
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
