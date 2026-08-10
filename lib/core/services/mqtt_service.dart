import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../config/constants.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? _client;
  bool isConnected = false;

  Function(Map<String, dynamic> data)? onVisitorArrived;
  Function(bool connected)? onConnectionChanged;

  Future<bool> initializeAndConnect() async {
    final clientId =
        'vms_operator_tablet_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(AppConstants.mqttHost, clientId);
    _client!.port = AppConstants.mqttPort;
    _client!.keepAlivePeriod = 60;
    _client!.logging(on: kDebugMode);
    _client!.autoReconnect = true;
    _client!.resubscribeOnAutoReconnect = true;

    // Real-time lifecycle callbacks
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onAutoReconnect = _onAutoReconnect;
    _client!.onAutoReconnected = _onAutoReconnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.onSubscribeFail = (topic) {
      debugPrint('MQTT: Failed to subscribe topic: $topic');
    };

    final connMessage = MqttConnectMessage()
        .authenticateAs(AppConstants.mqttUsername, AppConstants.mqttPassword)
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMessage;

    try {
      debugPrint(
          'MQTT: Connecting to TCP ${AppConstants.mqttHost}:${AppConstants.mqttPort}...');
      final status = await _client!.connect();
      if (status?.state == MqttConnectionState.connected) {
        isConnected = true;
        onConnectionChanged?.call(true);
        _subscribeToTopic();
        _listenToIncomingMessages();
        return true;
      } else {
        debugPrint('MQTT: Connection failed with status: ${status?.state}');
        _client?.disconnect();
        isConnected = false;
        onConnectionChanged?.call(false);
        return false;
      }
    } catch (e) {
      debugPrint('MQTT Connection Exception: $e');
      _client?.disconnect();
      isConnected = false;
      onConnectionChanged?.call(false);
      return false;
    }
  }

  void _subscribeToTopic() {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint(
          'MQTT: Subscribing to topic: ${AppConstants.mqttTopicArrivedVisitor}');
      _client!
          .subscribe(AppConstants.mqttTopicArrivedVisitor, MqttQos.atLeastOnce);
    }
  }

  void _listenToIncomingMessages() {
    _client?.updates
        ?.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      if (messages == null || messages.isEmpty) return;
      final recMess = messages[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      debugPrint('MQTT Incoming Payload on [${messages[0].topic}]: $payload');

      try {
        final dynamic decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          onVisitorArrived?.call(decoded);
        } else if (decoded is List &&
            decoded.isNotEmpty &&
            decoded.first is Map<String, dynamic>) {
          onVisitorArrived?.call(decoded.first as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('MQTT Payload JSON decode error: $e');
      }
    });
  }

  void _onConnected() {
    debugPrint('MQTT: Connected successfully to ${AppConstants.mqttHost}');
    isConnected = true;
    onConnectionChanged?.call(true);
  }

  void _onDisconnected() {
    debugPrint('MQTT: Disconnected from broker');
    isConnected = false;
    onConnectionChanged?.call(false);
  }

  void _onAutoReconnect() {
    debugPrint('MQTT: Auto reconnecting to broker...');
    isConnected = false;
    onConnectionChanged?.call(false);
  }

  void _onAutoReconnected() {
    debugPrint('MQTT: Auto reconnected successfully');
    isConnected = true;
    onConnectionChanged?.call(true);
    _subscribeToTopic();
  }

  void _onSubscribed(String topic) {
    debugPrint('MQTT: Subscribed successfully to topic: $topic');
  }

  void disconnect() {
    try {
      _client?.disconnect();
    } catch (e) {
      debugPrint('MQTT Disconnect error: $e');
    }
    isConnected = false;
  }
}
