import 'package:flutter_test/flutter_test.dart';

import 'package:video_selector_helper/main.dart';

void main() {
  testWidgets('App boots and shows select button', (tester) async {
    await tester.pumpWidget(const VideoSelectorApp());
    expect(find.text('Select video'), findsOneWidget);
  });
}
