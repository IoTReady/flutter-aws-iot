import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:aws_iot/src/consts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cognito_plugin/flutter_cognito_plugin.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:sigv4/sigv4.dart';
import 'package:typed_data/typed_data.dart';

class AWSIotDevice {
  final String endpoint;
  final String clientId;
  final bool enableLogging;

  StreamController<AWSIotMsg> _msgControl;
  Stream<AWSIotMsg> messages;

  MqttClient _client;

  MqttClient get client {
    if (_client == null) {
      throw AWSIotNotConnected();
    }
    return _client;
  }

  set client(MqttClient client) {
    _client = client;
  }

  AWSIotDevice({
    @required this.endpoint,
    @required this.clientId,
    this.enableLogging: false,
  }) {
    _msgControl = StreamController();
    messages = _msgControl.stream.asBroadcastStream();
  }

  Stream<AWSIotMsg> filterMessages(String topicFilter) async* {
    var topic = SubscriptionTopic(topicFilter);
    await for (var msg in messages) {
      if (topic.matches(PublicationTopic(msg.topic))) {
        yield msg;
      }
    }
  }

  Future<void> connect() async {
    var url = await getWebSocketURL();
    client = MqttClient(url, clientId);
    client.logging(on: enableLogging);
    client.useWebSocket = true;
    client.port = 443;
    client.connectionMessage =
        MqttConnectMessage().withClientIdentifier(clientId).keepAliveFor(300);
    client.keepAlivePeriod = 300;

    try {
      await client.connect();
    } on Exception catch (e) {
      client.disconnect();
      throw e;
    }

    client.updates.listen((messages) {
      for (var msg in messages) {
        MqttPublishMessage pubMsg = msg.payload;
        _msgControl.add(
          AWSIotMsg(
            msg.topic,
            Uint8List.fromList(pubMsg.payload.message.toList()),
          ),
        );
      }
    });
  }

  Future<String> getWebSocketURL() async {
    var now = _generateDatetime();
    var region = getRegion();
    var credentials = await Cognito.getCredentials();

    var creds = [
      credentials.accessKey,
      _getDate(now),
      region,
      serviceName,
      awsS4Request,
    ];
    var queryParams = {
      'X-Amz-Algorithm': aws4HmacSha256,
      'X-Amz-Credential': creds.join('/'),
      'X-Amz-Date': now,
      'X-Amz-SignedHeaders': 'host',
    };

    var canonicalQueryString = Sigv4.buildCanonicalQueryString(queryParams);
    var request = Sigv4.buildCanonicalRequest(
      'GET',
      urlPath,
      queryParams,
      {'host': endpoint},
      '',
    );

    var hashedCanonicalRequest = Sigv4.hashCanonicalRequest(request);
    var stringToSign = Sigv4.buildStringToSign(
      now,
      Sigv4.buildCredentialScope(now, region, serviceName),
      hashedCanonicalRequest,
    );

    var signingKey = Sigv4.calculateSigningKey(
      credentials.secretKey,
      now,
      region,
      serviceName,
    );

    var signature = Sigv4.calculateSignature(signingKey, stringToSign);

    var finalParams =
        '$canonicalQueryString&X-Amz-Signature=$signature&X-Amz-Security-Token=${Uri.encodeComponent(credentials.sessionToken)}';

    return '$scheme$endpoint$urlPath?$finalParams';
  }

  String _generateDatetime() {
    return new DateTime.now()
        .toUtc()
        .toString()
        .replaceAll(new RegExp(r'\.\d*Z$'), 'Z')
        .replaceAll(new RegExp(r'[:-]|\.\d{3}'), '')
        .split(' ')
        .join('T');
  }

  String _getDate(String dateTime) {
    return dateTime.substring(0, 8);
  }

  void disconnect() {
    return client.disconnect();
  }

  void publishBytes(Uint8List data, {@required String topic}) {
    client.publishMessage(
      topic,
      MqttQos.atMostOnce,
      Uint8Buffer()..addAll(data),
    );
  }

  void publishStr(String str, {@required String topic}) {
    publishBytes(utf8.encode(str), topic: topic);
  }

  void publishJson(dynamic json, {@required String topic}) {
    publishStr(jsonEncode(json), topic: topic);
  }

  Subscription subscribe(
    String topic, {
    MqttQos qos = MqttQos.atMostOnce,
  }) {
    return client.subscribe(topic, qos);
  }

  void unsubscribe(String topic) {
    client.unsubscribe(topic);
  }

  static const channel = const MethodChannel('com.scientifichackers.aws_iot');

  Future<void> attachPolicy({
    @required String identityId,
    @required String policyName,
  }) async {
    assert(identityId != null && policyName != null);
    await channel.invokeMethod('attachPolicy', {
      'identityId': identityId ?? '',
      'policyName': policyName ?? '',
      'region': getRegion(),
    });
  }

  String getRegion() {
    var endpointWithoutPort = endpoint.split(':')[0];
    var splits = endpointWithoutPort.split('.');
    var offset = splits.length == 7 ? 3 : 2;
    try {
      return splits[offset];
    } on IndexError {
      throw InvalidAWSIotEndpoint("Cannot parse region from endpoint.");
    }
  }
}

class AWSIotMsg {
  final String topic;
  final Uint8List asBytes;

  AWSIotMsg(this.topic, this.asBytes);

  String get asStr => utf8.decode(asBytes);

  dynamic get asJson => jsonDecode(asStr);

  @override
  String toString() {
    return "<$runtimeType topic: '$topic' asStr: '$asStr'>";
  }
}

class InvalidAWSIotEndpoint implements Exception {
  final String msg;

  InvalidAWSIotEndpoint(this.msg);

  @override
  String toString() {
    return '<$runtimeType: $msg>';
  }
}

class AWSIotNotConnected implements Exception {
  @override
  String toString() {
    return '<$runtimeType: You must call connect() before using the device>';
  }
}
