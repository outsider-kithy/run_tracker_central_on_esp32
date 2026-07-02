import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'RunningData.dart';
import 'RunningMap.dart';
import 'InfoCard.dart';
import 'Database.dart';
import 'functions.dart';


class LatestLogPage extends StatefulWidget {

  const LatestLogPage({super.key});

  @override
  State<LatestLogPage> createState() => _LatestLogPageState();
}

class _LatestLogPageState extends State<LatestLogPage>{

  RunningData? runningData;
  bool isLoadingFromDb = true;


  @override
  void initState() {
    _initAndLoad();
    super.initState();
    _loadLatestFromDatabase();
  }
  
  Future<void> _initAndLoad() async {
    await DatabaseHelper().database;
  }

  //データベースから最新のレコードを読み込む
  Future<void> _loadLatestFromDatabase() async {
  final latest = await DatabaseHelper().getLatestRunningData();
  if (latest != null) {
    setState(() {
      runningData = latest;
      isLoadingFromDb = false;
    });
  }
}

  @override
  void dispose() {
    super.dispose();
  }

  // UI部分
  @override
  Widget build(BuildContext context) {
    if (runningData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("最新のランニング")),
        body: Center(
          child: isLoadingFromDb
              ? const CircularProgressIndicator()
              : Text( "データ読み込み中...", style: const TextStyle(fontSize: 18),),
        ),
      );
    } else {
        return Scaffold(
        appBar: AppBar(title: const Text("最新のランニング")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text("${runningData!.startDate.split(' ')[0].toString()}のランニング",
                  style: const TextStyle(fontSize: 16)),

              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  InfoCard(
                    title: "距離",
                    value: "${distanceFormatter.format(
                        runningData!.distance)} km",
                    icon: Icons.route,
                    color: Colors.orange,
                  ),
                  InfoCard(
                    title: "タイム",
                    value: formattedTime(runningData!.elapsedSeconds),
                    icon: Icons.timer,
                    color: Colors.green,
                  ),
                  InfoCard(
                    title: "歩数",
                    value: "${NumberFormat("#,###").format(
                        runningData!.steps)} 歩",
                    icon: Icons.speed,
                    color: Colors.blue,
                  ),
                  InfoCard(
                    title: "ペース",
                    value: formattedPace(runningData!.distance, runningData!.elapsedSeconds),
                    icon: Icons.local_fire_department,
                    color: Colors.red,
                  ),
                  InfoCard(
                    title: "気温",
                    value: "${NumberFormat("##").format(
                        runningData!.temp)} ℃",
                    icon: Icons.thermostat,
                    color: Colors.purple,
                  ),
                  InfoCard(
                    title: "平均BPM",
                    value: "${NumberFormat("##").format(runningData!.avgBpm)} bpm",
                    icon: Icons.monitor_heart,
                    color: Colors.pink,
                  ),
                ],
              ),

              // ---- Google Map ----
              const SizedBox(height: 16),
              Expanded(child: RunningMap(points: runningData!.points)),
            ],
          ),
        ),
      );
    }
  }
}

