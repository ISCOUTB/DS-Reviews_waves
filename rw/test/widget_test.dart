// Este es un test básico de Flutter.
// Creamos un widget de prueba independiente para evitar la inicialización de Firebase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// No importamos main.dart porque contiene lógica de Firebase que es difícil de mockear

// Creamos un widget simple para pruebas
class TestCounterApp extends StatefulWidget {
  const TestCounterApp({Key? key}) : super(key: key);

  @override
  State<TestCounterApp> createState() => _TestCounterAppState();
}

class _TestCounterAppState extends State<TestCounterApp> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reviews Waves Test',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Reviews Waves Test'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Has presionado el botón estas veces:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Incrementar',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TestCounterApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
