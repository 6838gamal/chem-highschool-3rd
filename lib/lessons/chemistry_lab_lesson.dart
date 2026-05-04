import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../constants.dart';

/// ================= ELECTRON =================
class Electron {
  double angle;
  double radius;
  double speed;

  Electron({
    required this.angle,
    required this.radius,
    required this.speed,
  });
}

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
  double size;

  List<Electron> electrons;

  Particle({
    required this.position,
    required this.velocity,
    required this.type,
    required this.electrons,
    this.reacted = false,
    this.reacting = false,
    this.reactionProgress = 0,
    this.size = 20,
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

/// ================= SCREEN =================
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

  /// ================= ELECTRONS =================
  List<Electron> _generateElectrons(ParticleType type) {
    int count;

    switch (type) {
      case ParticleType.h2:
        count = 1;
        break;
      case ParticleType.o2:
        count = 2;
        break;
      case ParticleType.cl2:
        count = 3;
        break;
      default:
        count = 2;
    }

    return List.generate(count, (i) {
      return Electron(
        angle: (2 * pi / count) * i,
        radius: 10 + i * 4,
        speed: 0.02 + random.nextDouble() * 0.02,
      );
    });
  }

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
        electrons: _generateElectrons(selectedMaterial!),
      ),
    );

    if (selectedPowder != null) {
      particles.add(
        Particle(
          position: Offset(worldW / 2 + 10, 0),
          velocity: const Offset(0, 3),
          type: selectedPowder!,
          electrons: _generateElectrons(selectedPowder!),
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
    double bottom = worldH / 2 + 160;
    double left = worldW / 2 - 110;
    double right = worldW / 2 + 110;

    for (var p in particles) {
      for (var e in p.electrons) {
        e.angle += e.speed;
      }

      if (p.reacting) {
        p.reactionProgress += 0.08;
        p.size = 20 + sin(p.reactionProgress * pi) * 8;

        p.position += Offset(
          (random.nextDouble() - 0.5) * 6,
          (random.nextDouble() - 0.5) * 6,
        );

        if (p.reactionProgress >= 1) {
          p.reacting = false;
          p.reacted = true;
          p.size = 20;
        }
        continue;
      }

      double heatFactor = burnerOn ? 1.8 : 1.0;

      if (p.position.dy < 150) {
        p.velocity = const Offset(0, 3);
      } else {
        p.velocity = Offset(
          p.velocity.dx * 0.98 * heatFactor,
          (p.velocity.dy + 0.2) * heatFactor,
        );
      }

      if (isGas(p.type)) {
        p.velocity =
            Offset(p.velocity.dx, p.velocity.dy - 0.15);
      }

      p.position += p.velocity;

      if (p.position.dy > bottom - 15) {
        p.position = Offset(p.position.dx, bottom - 15);
        p.velocity = Offset(
          (random.nextDouble() - 0.5) * 3,
          -random.nextDouble() * 3,
        );
      }

      if (p.position.dx < left + 10 ||
          p.position.dx > right - 10) {
        p.velocity =
            Offset(-p.velocity.dx, p.velocity.dy);
      }
    }
  }

  /// ================= DETECT =================
  void _detectReaction() {
    currentReaction = null;

    if (selectedMaterial == null) return;

    for (var r in reactions) {
      bool ok = r.inputs.contains(selectedMaterial);

      if (selectedPowder != null) {
        ok &= r.inputs.contains(selectedPowder);
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
      reactionStatus = "⚠️ لا يوجد تفاعل";
      return;
    }

    List<Particle> available = particles
        .where((p) => p.position.dy > 150 && !p.reacting)
        .toList();

    if (available.isEmpty) return;

    for (int i = 0; i < available.length; i++) {
      for (int j = i + 1; j < available.length; j++) {
        final a = available[i];
        final b = available[j];

        double dist = (a.position - b.position).distance;

        if (dist < 28) {
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
        }
      }
    }
  }

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
          electrons: _generateElectrons(ParticleType.co2),
        ),
      );
    }
  }

  Color _color(ParticleType t) {
    switch (t) {
      case ParticleType.h2:
        return Colors.cyanAccent;
      case ParticleType.o2:
        return Colors.blueAccent;
      case ParticleType.hcl:
        return Colors.redAccent;
      case ParticleType.h2o2:
        return Colors.purpleAccent;
      case ParticleType.caco3:
        return Colors.brown;
      case ParticleType.cl2:
        return Colors.greenAccent;
      case ParticleType.co2:
        return Colors.pinkAccent;
      case ParticleType.h2o:
        return Colors.lightBlueAccent;
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
      appBar: AppBar(title: const Text("مختبر الذرات المتقدم")),
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
          Column(
            children: [
              const Text("🔥 حرارة", style: TextStyle(color: Colors.white)),
              Switch(
                value: burnerOn,
                onChanged: (v) => setState(() => burnerOn = v),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              const Text("⚗️ وسيط", style: TextStyle(color: Colors.white)),
              Switch(
                value: catalystOn,
                onChanged: (v) => setState(() => catalystOn = v),
              ),
            ],
          ),
          const SizedBox(width: 10),
          DropdownButton<ParticleType>(
            hint: const Text("مادة"),
            value: selectedMaterial,
            onChanged: (v) {
              setState(() {
                selectedMaterial = v;
                _detectReaction();
              });
            },
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
            onChanged: (v) {
              setState(() {
                selectedPowder = v;
                _detectReaction();
              });
            },
            items: [
              const DropdownMenuItem(value: null, child: Text("بدون")),
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

  /// ================= LAB AREA =================
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
                  border: Border.all(color: Colors.cyanAccent),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black38,
                ),
              ),
            ),

            /// 🔥 النار
            if (burnerOn)
              Positioned(
                bottom: 0,
                left: worldW / 2 - 40,
                child: Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.6),
                        Colors.orange.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),

            /// 🧂 المسحوق
            if (selectedPowder != null)
              Positioned(
                bottom: 80,
                left: worldW / 2 - 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _color(selectedPowder!),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            /// الجزيئات
            ...particles.map((p) => Positioned(
                  left: p.position.dx,
                  top: p.position.dy,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _color(p.type),
                          boxShadow: [
                            BoxShadow(
                              color: _color(p.type)
                                  .withOpacity(0.7),
                              blurRadius: 12,
                            )
                          ],
                        ),
                      ),

                      /// الإلكترونات
                      ...p.electrons.map((e) {
                        return Transform.translate(
                          offset: Offset(
                            cos(e.angle) * e.radius,
                            sin(e.angle) * e.radius,
                          ),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),

                      /// 🏷️ اسم الجزيء
                      Positioned(
                        top: -20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _color(p.type)
                                  .withOpacity(0.6),
                            ),
                          ),
                          child: Text(
                            _name(p.type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            /// النص
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    currentReaction?.equation ??
                        "⚠️ لا يوجد تفاعل",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
