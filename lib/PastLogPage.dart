import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database.dart';
import 'DetailPastLogPage.dart';
import 'functions.dart';

class PastLogPage extends StatefulWidget {
  const PastLogPage({super.key});

  @override
  _PastLogPageState createState() => _PastLogPageState();
}

class _PastLogPageState extends State<PastLogPage> {

  late Database _db;
  Future<List<Map<String, dynamic>>>? _runningLogListFuture;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    _db = await DatabaseHelper().database;
    setState(() {
      _runningLogListFuture =  DatabaseHelper().fetchAllRunningData();
    });
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title:  Text('過去ログ')),
      body:
      FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().fetchAllRunningData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("エラー: ${snapshot.error}"));
          }

          final runningLogs = snapshot.data ?? [];
          return ListView.builder(
            itemCount: runningLogs.length,
            itemBuilder: (context, index) {
              final runningLog = runningLogs[index];
              //スワイプして削除
              return Dismissible(
                key: Key(runningLog['id'].toString()),
                direction: DismissDirection.endToStart, // 右から左にスワイプ
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await DatabaseHelper().deleteRunningData(runningLog['id']);
                  setState(() {
                    _runningLogListFuture = DatabaseHelper().fetchAllRunningData();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${runDate(runningLog["startDate"])}のログを削除')),
                  );
                },
                child:  Card(
                  child: ListTile(
                    leading: Icon(Icons.directions_run),
                    title: Text('${(runningLog['distance']).toStringAsFixed(1)} km'),
                    subtitle: Text('${runningLog['startDate'].split(' ')[0]}　のランニング'),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailPastLogPage(
                                db: _db,
                                pk: runningLog['id'] ?? '',
                                points: runningLog['points'] ?? '',
                                distance: runningLog['distance'] ?? '',
                                steps: runningLog['steps'] ?? '',
                                elapsedSeconds: runningLog['elapsedSeconds'] ?? '',
                                pace: runningLog['pace'] ?? '',
                                startDate: runningLog['startDate'] ?? '',
                                endDate: runningLog['endDate'] ?? '',
                                temp: runningLog['temp'] ?? '',
                                avgBpm: runningLog['avgBpm'] ?? '',
                              ),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          _runningLogListFuture = DatabaseHelper().fetchAllRunningData();
                        });
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}