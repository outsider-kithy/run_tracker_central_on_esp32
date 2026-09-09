import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Database.dart';
import 'LatestLogPage.dart';
import 'PastLogPage.dart';
import 'AnalyticsPage.dart';
import 'BleManager.dart';

final bleManager = BleManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初回起動時にBluetoothの可否を問う
  await requestBlePermissions();
  // 初回起動時にDB作成
  await DatabaseHelper().database;
  // ペリフェラルデバイスとの通信をバックグラウンドで開始
  WidgetsBinding.instance.addPostFrameCallback((_) async{
    // 時計を同期
    bleManager.rtcSync();
    // JSONを同期
    await bleManager.getJson();
  });

  runApp(MyApp());
}

Future<void> requestBlePermissions() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Run Tracker',
      home: MainTabPage(),
    );
  }
}

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  _MainTabPageState createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    LatestLogPage(),
    PastLogPage(),
    AnalyticsPage(),
  ];

  void _onTabTapped(int index){
    setState(() {
      _currentIndex  = index;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LatestLogPage(),
          PastLogPage(),
          AnalyticsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, 
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: const[
            BottomNavigationBarItem(
                icon: Icon(Icons.directions_run),
                label: '最新ログ'
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: '過去ログ'
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.dataset),
                label: '分析'
            ),
          ]),
    );
  }
}

