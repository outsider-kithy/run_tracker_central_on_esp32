import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fl_chart/fl_chart.dart';
import 'Database.dart';
import 'DailyStats.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

enum AnalyticsRange { week, month, year }

class _AnalyticsPageState extends State<AnalyticsPage> {

  late Database _db;
  AnalyticsRange selectedRange = AnalyticsRange.week;
  List<DailyStats> stats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDbAndLoad();
  }

  Future<void> _initDbAndLoad() async {
    _db = await DatabaseHelper().database;
    final data = await _loadWeeklyStats();
    setState(() {
      stats = data;
      isLoading = false;
    });
  }

  //セグメントによって週・月・年を切り替え
  Future<void> _loadDataByRange() async {
    List<DailyStats> data = [];

    switch (selectedRange) {
      case AnalyticsRange.week:
        data = await _loadWeeklyStats();
        break;

      case AnalyticsRange.month:
        data = await _loadMonthlyStats();
        break;

      case AnalyticsRange.year:
        data = await _loadYearlyStats();
        break;
    }

    setState(() {
      stats = data;
      isLoading = false;
    });
  }


  /// 過去1週間のデータを取得して日別集計
  Future<List<DailyStats>> _loadWeeklyStats() async {

      /// 今日を基準に7日配列を作成
      final now = DateTime.now();

      /// yyyy-MM-dd 形式キー
      final formatter = DateFormat('yyyy-MM-dd');

      /// 日付 → index マップ
      Map<String, int> dayIndexMap = {};

      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: 6 - i));
        dayIndexMap[formatter.format(day)] = i;
      }

      /// SQLite 集計クエリ
      final result = await _db.rawQuery('''
        SELECT 
          DATE(startDate) as day,
          SUM(distance) as totalDistance,
          SUM(steps) as totalSteps,
          SUM(elapsedSeconds) as totalElapsedSeconds
        FROM runningData
        WHERE startDate >= date('now','-6 days')
        GROUP BY day
        ORDER BY day
      ''');

      /// 0埋め stats
      List<DailyStats> stats = List.generate(7, (i) {
        return DailyStats(day: i, distance: 0.0, steps: 0, elapsedSeconds: 0, pace: 0.0);
      });

      for (final row in result) {
        final dayStr = row['day'] as String;
      
      if (dayIndexMap.containsKey(dayStr)) {
        final index = dayIndexMap[dayStr]!;

        final distance = (row['totalDistance'] as num).toDouble();

        final elapsed =(row['totalElapsedSeconds'] as num).toInt();

        /// pace計算（sec / km 想定）
        double pace = 0.0;

        if (distance > 0) {
          pace = elapsed / distance;
        }

        stats[index] = DailyStats(
          day: index,
          distance: distance,
          steps: (row['totalSteps'] as num).toInt(),
          elapsedSeconds: elapsed,
          pace: pace,
        );
      }
      }
      return stats;
    }

    //月のデータを取得
    Future<List<DailyStats>> _loadMonthlyStats() async {
      final db = await DatabaseHelper().database;

      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      /// 0埋め生成
      List<DailyStats> stats = List.generate(daysInMonth, (i) {
        return DailyStats(
          day: i + 1,
          distance: 0.0,
          steps: 0,
          elapsedSeconds: 0,
          pace: 0.0,
        );
      });

      final result = await db.rawQuery('''
        SELECT
          strftime('%d', startDate) as day,
          SUM(distance) as totalDistance,
          SUM(steps) as totalSteps,
          SUM(elapsedSeconds) as totalElapsedSeconds
        FROM runningData
        WHERE startDate >= date('now','start of month')
        GROUP BY day
        ORDER BY day
      ''');

      for (final row in result) {
        final day = int.parse(row['day'] as String);

        final distance =
            (row['totalDistance'] as num).toDouble();

        final elapsedSeconds =
            (row['totalElapsedSeconds'] as num).toInt();

        double pace = 0.0;

        if (distance > 0) {
          pace = elapsedSeconds / distance;
        }
  
        stats[day - 1] = DailyStats(
          day: day,
          distance: distance,
          steps: (row['totalSteps'] as num).toInt(),
          elapsedSeconds: elapsedSeconds,
          pace: pace,
        );
      }
      return stats;
  }

  //年のデータを取得
  Future<List<DailyStats>> _loadYearlyStats() async {

    final result = await _db.rawQuery('''
        SELECT 
          strftime('%m', startDate) as month,
          SUM(distance) as totalDistance,
          SUM(steps) as totalSteps,
          SUM(elapsedSeconds) as totalElapsedSeconds
        FROM runningData
        WHERE startDate >= date('now','start of year')
        GROUP BY month
        ORDER BY month
      ''');

      List<double> distances = List.filled(12, 0);
      List<int> elapsed = List.filled(12, 0);
      double pace = 0.0;

      for (final row in result) {
        final month = int.parse(row['month'] as String) - 1;
        distances[month] = (row['totalDistance'] as num).toDouble();
        elapsed[month] = (row['totalElapsedSeconds'] as num).toInt();

        if (distances[month] > 0) {
          pace = elapsed[month] / distances[month];
        }
      }

    return result.map((row) {
      return DailyStats(
        day: int.parse(row['month'] as String),
        distance: (row['totalDistance'] as num).toDouble(),
        steps: (row['totalSteps'] as num).toInt(),
        elapsedSeconds: (row['totalElapsedSeconds'] as num).toInt(),
        pace: pace,
      );
    }).toList();
  }



  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  //セグメントコントロール風UI
  Widget _buildSegmentedControl() {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: SegmentedButton<AnalyticsRange>(
      segments: const [
        ButtonSegment(
          value: AnalyticsRange.week,
          label: Text('週'),
        ),
        ButtonSegment(
          value: AnalyticsRange.month,
          label: Text('月'),
        ),
        ButtonSegment(
          value: AnalyticsRange.year,
          label: Text('年'),
        ),
      ],
      selected: {selectedRange},
      onSelectionChanged: (newSelection) {
        setState(() {
          selectedRange = newSelection.first;
          isLoading = true;
        });
        _loadDataByRange();
      },
    ),
  );
}


  // 走行距離の棒グラフ用データ生成
  List<BarChartGroupData> _buildDistanceBars(List<DailyStats> stats) {
    return stats.map((s) {
      return BarChartGroupData(
        x: s.day,
        barRods: [
          BarChartRodData(toY: s.distance),
        ],
      );
    }).toList();
  }

  //歩数の棒グラフ用データ
  List<BarChartGroupData> _buildStepsBars(List<DailyStats> stats) {
    return stats.map((s) {
      return BarChartGroupData(
        x: s.day,
        barRods: [
          BarChartRodData(toY: s.steps.toDouble()),
        ],
      );
    }).toList();
  }

  //走行時間の折れ線グラフ用データ
  List<FlSpot> _buildElapsedSecondsSpots(List<DailyStats> stats) {
    return stats.map((s) {
      return FlSpot(
        s.day.toDouble(),
        s.elapsedSeconds.toDouble()
      );
    }).toList();
  }

  //ペースの折れ線グラフ用データ
  List<FlSpot> _buildPaceSpots(List<DailyStats> stats) {
    return stats.map((s) {
      return FlSpot(
        s.day.toDouble(),
        s.pace.toDouble()
      );
    }).toList();
  }

//複合チャート
Widget _buildCombinedChart(List<DailyStats> stats) {

  final distance = _buildDistanceBars(stats);
  final steps = _buildStepsBars(stats);
  final elapsedSeconds = _buildElapsedSecondsSpots(stats);
  final pace = _buildPaceSpots(stats);

  return SingleChildScrollView(
    child:Column(
    children: [
      // 距離のグラフ
      Text("走行距離（km）"),
      SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            barGroups: distance,
            titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: _bottomTitles,
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
          ),
        ),
      ),

      const SizedBox(height: 16),

      //歩数のグラフ
      Text('歩数（歩）'),
      SizedBox(
        height: 200,
        child: BarChart(
            BarChartData(
              barGroups: steps,
              titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: _bottomTitles,
                  ),
                ),
              ),
              borderData: FlBorderData(show: true),
            )
          ),
      ),

      const SizedBox(height: 16),

      //走行時間の折れ線グラフ
      Text('タイム（秒）'),
      SizedBox(
        height: 200,
        child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: elapsedSeconds,
              isCurved: true,
              dotData: FlDotData(show: true),
            ),
          ],
          titlesData: FlTitlesData(
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
              bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: _bottomTitles,
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          gridData: FlGridData(show: true),
        ),
      ),
      ),

      const SizedBox(height: 16),

      //ペースの折れ線グラフ
      Text('ペース（km/秒）'),
      SizedBox(
        height: 200,
        child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: pace,
              isCurved: true,
              dotData: FlDotData(show: true),
            ),
          ],
          titlesData: FlTitlesData(
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
              bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: _bottomTitles,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
        ),
      ),
      ),
    ],
    ),
  );
}



  /// 🔹 X軸ラベル（日付）
  Widget _bottomTitles(double value, TitleMeta meta) {

  switch (selectedRange) {

    case AnalyticsRange.week:
      final day = DateTime.now()
          .subtract(Duration(days: 6 - value.toInt()));
      return Text(DateFormat('E').format(day));

    case AnalyticsRange.month:
      final day = value.toInt() + 1;

      final now = DateTime.now();
      final lastDay =
          DateTime(now.year, now.month + 1, 0).day;

      if (day % 10 == 0 || day == lastDay) {
        return Text('${day.toInt()}日');
      }

      return const SizedBox.shrink();

    case AnalyticsRange.year:
      return Text('${value.toInt() + 1}月');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分析')),
      body: Column(
        children: [
          /// Segmented Control
          _buildSegmentedControl(),

          /// グラフ
          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                    child: _buildCombinedChart(stats),
                ),
            ),
          ],
        ),
      );
    }

}
