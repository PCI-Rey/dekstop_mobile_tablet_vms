import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_operator_tablet/core/shared/widgets/gold_standard_scaler.dart';

void main() {
  testWidgets(
    'GoldStandardScaler scales small screen sizes to phone gold standard',
    (WidgetTester tester) async {
      // Simulate a narrow device screen (e.g., width 320)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: GoldStandardScaler(
            child: Builder(
              builder: (context) {
                final mediaQuery = MediaQuery.of(context);
                // Expected width is the Gold Standard phone width (360.0)
                expect(mediaQuery.size.width, 360.0);
                // Expected height is scaled proportionally (568 / (320/360)) = 639.0
                expect(mediaQuery.size.height, closeTo(639.0, 0.1));
                return const Scaffold(body: Center(child: Text('Scaled UI')));
              },
            ),
          ),
        ),
      );

      expect(find.text('Scaled UI'), findsOneWidget);

      // Reset physical size and ratio to defaults
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
