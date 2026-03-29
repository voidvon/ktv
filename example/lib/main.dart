import 'package:flutter/widgets.dart';

import 'src/ktv_demo_app.dart';
export 'src/ktv_demo_app.dart' show KtvDemoApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KtvDemoApp());
}
