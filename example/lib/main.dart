import 'package:flutter/material.dart';
import 'dart:async';
import 'package:native2js/native2js.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  JsEngine engine1 = JsEngine();
  JsEngine engine2 = JsEngine();
  int a = 0;
  int b = 0;

  @override
  void initState() {
    super.initState();
    engine1.evaluate('let x = $a;');
    engine2.evaluate('let x = $b;');
  }

  add1() async {
    a = int.parse(await engine1.evaluate('++x'));
    setState(() {});
  }

  add2() async {
    b = int.parse(await engine2.evaluate('++x'));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlatButton(
                onPressed: () => add1(),
                child: Text('engine1: $a'),
              ),
              FlatButton(
                onPressed: () => add2(),
                child: Text('engine2: $b'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
