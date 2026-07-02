import 'package:intl/intl.dart';
import 'dart:math';

//startDateをフォーマット
String runDate(String date){
  return date.split(' ')[0];
}
//距離をフォーマット
final distanceFormatter = NumberFormat("0.0");

//ペースをフォーマット
String formattedPace(double distance, int elapsedSeconds){
  final paceFormatter = NumberFormat("0.0");
  String paceText = "--";
  if (distance > 0) {
    final pace = (elapsedSeconds / 60 /distance);
    paceText = "${paceFormatter.format(pace)} 分/km";
  }
  return paceText;
}

// タイムをフォーマット
String formattedTime(int elapsedSeconds){
  final duration = Duration(seconds: elapsedSeconds);
  final formattedTime =
      "${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes %
      60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60)
      .toString()
      .padLeft(2, '0')}";
  return formattedTime;
}

//小数点の任意の桁で切り下げ
double truncateToDecimelPlaces(double value, int fractionDigits){
  num mod = pow(10, fractionDigits);
  return (value * mod).truncate() / mod;
}