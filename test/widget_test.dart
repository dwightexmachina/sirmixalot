import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirmixalot/main.dart';

void main() {
  testWidgets('boots with Program M loaded and steps', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SirMixAlotApp());
    await tester.pump();

    expect(find.text('MIXAL SOURCE'), findsOneWidget);
    expect(find.text('REGISTERS'), findsOneWidget);
    expect(find.text('MEMORY'), findsOneWidget);
    expect(find.textContaining('Program M'), findsWidgets);

    // One manual step: the driver's ENT1 executes (1u).
    await tester.tap(find.text('STEP'));
    await tester.pump();
    expect(find.text('1u'), findsAtLeastNWidgets(1));
  });
}
