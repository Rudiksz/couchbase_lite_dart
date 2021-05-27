import 'package:flutter/material.dart';
import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Cbl.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Text('hello world'),
    );
  }
}
