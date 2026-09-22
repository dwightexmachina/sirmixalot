import 'package:flutter/material.dart';

import 'src/controller/machine_controller.dart';
import 'src/theme.dart';
import 'src/ui/decode_panel.dart';
import 'src/ui/device_panel.dart';
import 'src/ui/memory_panel.dart';
import 'src/ui/register_panel.dart';
import 'src/ui/source_panel.dart';
import 'src/ui/toolbar.dart';

void main() {
  runApp(const SirMixAlotApp());
}

class SirMixAlotApp extends StatelessWidget {
  const SirMixAlotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sirMIXalot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MixColors.ground,
        colorScheme: const ColorScheme.dark(
          primary: MixColors.amber,
          surface: MixColors.panel,
        ),
        useMaterial3: true,
      ),
      home: const MachineScreen(),
    );
  }
}

class MachineScreen extends StatefulWidget {
  const MachineScreen({super.key});

  @override
  State<MachineScreen> createState() => _MachineScreenState();
}

class _MachineScreenState extends State<MachineScreen> {
  late final MachineController controller;

  @override
  void initState() {
    super.initState();
    controller = MachineController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  static const double _minWidth = 1240;
  static const double _minHeight = 780;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final width =
              box.maxWidth < _minWidth ? _minWidth : box.maxWidth;
          final height =
              box.maxHeight < _minHeight ? _minHeight : box.maxHeight;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: SizedBox(
                width: width,
                height: height,
                child: _console(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _console() {
    return ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 12),
              ConsoleToolbar(controller: controller),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                        width: 305,
                        child: SourcePanel(controller: controller)),
                    const SizedBox(width: 12),
                    Expanded(child: MemoryPanel(controller: controller)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 355,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                              height: 268,
                              child:
                                  RegisterPanel(controller: controller)),
                          const SizedBox(height: 12),
                          Expanded(
                              child: DecodePanel(controller: controller)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                  height: 170, child: DeviceStrip(controller: controller)),
            ],
          ),
        ));
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: monoFamily,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: MixColors.data,
              letterSpacing: 0.8,
            ),
            children: [
              TextSpan(text: 'sir'),
              TextSpan(text: 'MIX', style: TextStyle(color: MixColors.amber)),
              TextSpan(text: 'alot'),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Text("Knuth's MIX 1009, visualized",
            style: TextStyle(fontSize: 12.5, color: MixColors.labelDim)),
        const Spacer(),
        const Text('6-BIT BYTES · 4000 WORDS · TAOCP',
            style: MixText.caption),
      ],
    );
  }
}
