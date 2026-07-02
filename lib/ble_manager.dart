import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'RunningData.dart';
import 'Database.dart';
import 'functions.dart';

class BleManager {

  bool connecting = false;

  String textBuffer = "";
  List<RunningData> jsonsList = [];

  StreamSubscription? scanSubscription;
  StreamSubscription?  connectionSubscription;
  StreamSubscription<List<int>>? notifySubscription;


  void dispose(){
    scanSubscription?.cancel();
    connectionSubscription?.cancel();
    notifySubscription?.cancel();
  }

  final FlutterReactiveBle ble = FlutterReactiveBle();
  
  final Uuid serviceUuid = Uuid.parse("930788e7-5e3d-7c7d-65ff-2461a6023d44");
  final Uuid rtcUuid = Uuid.parse("9cd2702a-656d-539a-d060-c341a485a861");
  final Uuid jsonUuid = Uuid.parse("930788e7-5e3d-7c7d-65ff-2461a6023d44");


  Future<void> startBleProcess() async {
    await Future.delayed(
      Duration(seconds:1)
    );
    await startGetJson();
  }

  // =============================================
  // RTC同期
  // =============================================

  void startScan() {
    scanSubscription = ble.scanForDevices(
        withServices:[serviceUuid],
        scanMode: ScanMode.lowLatency,
      ).listen(
        (device){
          connectAndSync(device);
        }, onError:(e){
          print(e);
        }
      );
  }

  Future<void> connectAndSync(DiscoveredDevice device) async {
    scanSubscription = ble.connectToDevice(id: device.id,)
      .listen((state){
          print(state.connectionState);
          if(state.connectionState == DeviceConnectionState.connected){
            //  discoverCharacteristics(device.id);
             sendRtcSync(device.id);
          }
        }
      );
  }

  // RTC同期のコマンドと現在時刻をペリフェラルに送信
  Future<void> sendRtcSync(String deviceId) async {
    final epoch = DateTime.now().millisecondsSinceEpoch ~/1000;
    final bytes=[
      epoch & 0xff,
      (epoch >> 8) & 0xff,
      (epoch >> 16) & 0xff,
      (epoch >> 24) & 0xff,
    ];

    final characteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: rtcUuid,
      deviceId: deviceId,
    );

    await ble.writeCharacteristicWithResponse(
        characteristic,
        value: bytes,
    );
    print("RTC_SYNCコマンド送信完了 : $epoch");
  }

  
// =============================================
// JSON同期
// =============================================
  Future<void> startGetJson() async{
  connecting = false;
  connectionSubscription = ble.scanForDevices(
      withServices:[serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen(
      (device){
        if (connecting) return;
        connecting = true;
        scanSubscription?.cancel();
        connectAndGetJson(device);
      }, onError:(e){
        print(e);
      }
    );
}

Future<void> connectAndGetJson(DiscoveredDevice device) async {
  print("connect start ${device.id}");
  connectionSubscription = ble.connectToDevice(id: device.id,)
    .listen((state){
        if(state.connectionState == DeviceConnectionState.connected){
            requestJson(device.id);
        }
      }
    );
}

Future<void> requestJson(String deviceId) async {

    // JSONを受信
    final jsonCharacteristic =
      QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: jsonUuid ,
        deviceId: deviceId,
    );

    notifySubscription = ble.subscribeToCharacteristic(jsonCharacteristic).listen((data) async{
        connectionSubscription?.cancel();

        final chunk = utf8.decode(data, allowMalformed: true);
     
        // ① 到着順に連結
        textBuffer += chunk;
        print(textBuffer);
        print(textBuffer.length);

        // ② JSON抽出処理
        extractJsonsFromBuffer(textBuffer);

      },
      onError: (Object e) {
        print('通知受信エラー: $e');
      },
    );

    //GET_JSONコマンドをペリフェラルに送信
    try {
      await ble.writeCharacteristicWithResponse(
        jsonCharacteristic,
        value: utf8.encode('GET_JSON'),
      );
      print('GET_JSONコマンド送信完了');
      return;
    } catch (e) {
      print('GET_JSON送信失敗 $e');
    }

  }

  // キャラクタリステックスUUIDを確認
  Future<void> discoverCharacteristics(String deviceId) async {
    final services = await ble.getDiscoveredServices(deviceId);
    for(final service in services){
      print("Service:");
      print(service.id);
      for(final characteristic in service.characteristics){
        print("Characteristic:");
        print(characteristic.id);
      }
    }
  }

  //JSON抽出関数
  void extractJsonsFromBuffer(textBuffer) async{
  int braceCount = 0;
  int jsonStart = -1;

  for (int i = 0; i < textBuffer.length; i++) {

    if (textBuffer[i] == '{') {
      if (braceCount == 0) {
        jsonStart = i; // JSON開始位置
      }
      braceCount++;
    } 
    else if (textBuffer[i] == '}') {
      braceCount--;

      // JSON完成
      if (braceCount == 0 && jsonStart != -1) {
        final jsonString = textBuffer.substring(jsonStart, i + 1);

        try {
          final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;

          // 🔥 Map → RunningData に変換
          final runningData = RunningData.fromJson(jsonMap);
          print(jsonMap);
          jsonsList.add(runningData);

          // データベースに登録
          final pointsJson = jsonEncode(runningData.points.map((p) => p.toJson()).toList());
          //ペースを計算
          final pace = (runningData.distance > 0)
              ? truncateToDecimelPlaces(runningData.elapsedSeconds / 60 / runningData.distance, 2) * 10.0
              : 0.0;
          //距離を計算
          final double kmDistance = runningData.distance * 0.001;

          await DatabaseHelper().insertRunningData(
            pointsJson,
            kmDistance,
            runningData.steps,
            runningData.elapsedSeconds,
            pace,
            runningData.startDate,
            runningData.endDate,
            runningData.temp,
            runningData.avgBpm
          );
          print("データベースに登録完了");
      
        } catch (e) {
          print("JSON解析エラー: $e");
        }

        // 取り出した部分をバッファから削除
        textBuffer = textBuffer.substring(i + 1);

        return;
      }
    }
    print("Recieved JSON:");
    print(textBuffer);
  }
}
}