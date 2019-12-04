import 'dart:async';

import 'package:aws_iot/aws_iot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cognito_plugin/flutter_cognito_plugin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  var dotenv = DotEnv();
  await dotenv.load('assets/.env');
  print(dotenv.env);

  print(await Cognito.initialize());
  if (!await Cognito.isSignedIn()) {
    print(await Cognito.signIn(dotenv.env['USERNAME'], dotenv.env['PASSWORD']));
  }
  print(await Cognito.getIdentityId());

  var device = AWSIotDevice(
    endpoint: dotenv.env['ENDPOINT'],
    clientId: dotenv.env['CLIENT_ID'],
  );

  await device.attachPolicy(
    identityId: await Cognito.getIdentityId(),
    policyName: dotenv.env['POLICY_NAME'],
  );

  await device.connect();

  runApp(MyApp(device: device));
}

class MyApp extends StatefulWidget {
  final AWSIotDevice device;

  const MyApp({Key key, @required this.device}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView(
            children: <Widget>[
              TextField(
                controller: topicControl,
                decoration: InputDecoration(labelText: "Topic"),
              ),
              TextField(
                controller: msgControl,
                decoration: InputDecoration(labelText: "Message"),
              ),
              RaisedButton(
                child: Text("PUBLISH"),
                onPressed: () {
                  device.publishStr(msgControl.text, topic: topicControl.text);
                },
              ),
              RaisedButton(
                child: Text("SUSCRIBE"),
                onPressed: onSubscribe,
              ),
              for (var msg in history)
                Text(
                  "<${msg.runtimeType} topic='${msg.topic}' asStr='${msg.asStr}'>",
                ),
            ],
          ),
        ),
      ),
    );
  }

  var phoneControl = TextEditingController();
  var passwordControl = TextEditingController();
  var topicControl = TextEditingController(text: 'demoTopic');
  var msgControl = TextEditingController(text: 'Hello World!');
  var history = <AWSIotMsg>[];

  AWSIotDevice get device => widget.device;

  @override
  void initState() {
    super.initState();
    initAsyncState();
  }

  Future<void> initAsyncState() async {
    await for (var msg in device.messages) {
      setState(() {
        history.add(msg);
      });
    }
  }

  Future<void> onSubscribe() async {
    device.subscribe(topicControl.text);
  }
}
