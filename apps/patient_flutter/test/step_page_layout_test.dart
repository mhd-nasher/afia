import 'package:afia_patient/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StepPage clears the emergency fixture zone', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(402, 874),
          padding: EdgeInsets.only(top: 62),
        ),
        child: MaterialApp(
          home: const StepPage(children: [Text('PROBE')]),
        ),
      ),
    );
    await tester.pump();
    final top = tester.getTopLeft(find.text('PROBE'));
    debugPrint('PROBE top: $top');
    // The fixture occupies padding.top+10 .. padding.top+74 (62+74 = 136).
    expect(top.dy, greaterThanOrEqualTo(136));
  });
}
