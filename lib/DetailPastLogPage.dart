import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'RunningData.dart';
import 'RunningMap.dart';
import 'InfoCard.dart';
import 'package:intl/intl.dart';
import 'functions.dart';

class DetailPastLogPage extends StatefulWidget {
  final Database db;
  final int pk;
  final String points;
  final double distance;
  final int steps;
  final int elapsedSeconds;
  final double pace;
  final String startDate;
  final String endDate;
  final double temp;
  final double avgBpm;

  const DetailPastLogPage({
    super.key,
    required this.db,
    required this.pk,
    required this.points,
    required this.distance,
    required this.steps,
    required this.elapsedSeconds,
    required this.pace,
    required this.startDate,
    required this.endDate,
    required this.temp,
    required this.avgBpm
  });

  @override
  _DetailPastLogPageState createState() => _DetailPastLogPageState();
}

class _DetailPastLogPageState extends State<DetailPastLogPage> {

  RunningData? runningData;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context){

    // 🔹 JSON文字列 → List<Point> に変換
    List<Point> decodedPoints = [];
    try {
      if (widget.points.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(widget.points);
        decodedPoints = jsonList.map((p) => Point.fromJson(p)).toList();

      } else {
        print('points is empty');
      }
    } catch (e) {
      print('Failed to decode points JSON: $e');
    }

    return Scaffold(
      appBar: AppBar(title:  Text('過去ログ詳細')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child:Column(
            children: [

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
                    value: "${distanceFormatter.format(widget.distance)} km",
                    icon: Icons.route,
                    color: Colors.orange,
                  ),
                  InfoCard(
                    title: "タイム",
                    value: formattedTime(widget.elapsedSeconds),
                    icon: Icons.timer,
                    color: Colors.green,
                  ),
                  InfoCard(
                    title: "歩数",
                    value: "${NumberFormat("#,###").format(widget.steps)} 歩",
                    icon: Icons.speed,
                    color: Colors.blue,
                  ),
                  InfoCard(
                    title: "ペース",
                    value: "${(widget.pace * 100.0).toStringAsFixed(2)} 分/km",
                    icon: Icons.local_fire_department,
                    color: Colors.red,
                  ),
                  InfoCard(
                    title: "気温",
                    value: "${NumberFormat("##").format(
                        widget.temp)} ℃",
                    icon: Icons.thermostat,
                    color: Colors.purple,
                  ),
                  InfoCard(
                    title: "平均BPM",
                    value: "${NumberFormat("##").format(widget.avgBpm)} bpm",
                    icon: Icons.monitor_heart,
                    color: Colors.pink,
                  ),
                ],
              ),

              // ---- Google Map ----
              const SizedBox(height: 16),
              Expanded(child: RunningMap(points: decodedPoints)),
            ]
        ),
      ),
    );
  }
}