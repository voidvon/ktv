import 'package:flutter/widgets.dart';

import 'app/app.dart';
export 'app/app.dart' show KtvApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KtvApp());
}
