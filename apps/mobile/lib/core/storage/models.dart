import 'package:intl/intl.dart';

typedef Json = Map<String, dynamic>;
const icons = ['dumbbell', 'book', 'leaf', 'code', 'droplet', 'check'];
const iconLabels = ['运动', '阅读', '生活', '编程', '饮水', '完成'];
const maxTimestamp = 4102444799999;
String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
String number(int value) => NumberFormat.decimalPattern('zh_CN').format(value);

abstract interface class Clock {
  DateTime now();
  int offsetMinutes();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
  @override
  int offsetMinutes() => now().timeZoneOffset.inMinutes;
}

class FixedClock implements Clock {
  FixedClock(this.value, [this.offset = 480]);
  DateTime value;
  int offset;
  @override
  DateTime now() => value;
  @override
  int offsetMinutes() => offset;
}

String capturedDate(int timestamp, int offset) => dateKey(
  DateTime.fromMillisecondsSinceEpoch(
    timestamp,
    isUtc: true,
  ).add(Duration(minutes: offset)),
);

class DomainError implements Exception {
  const DomainError(this.message);
  final String message;
  @override
  String toString() => message;
}

String validText(String raw, int max, String field) {
  if (raw.runes.any(
    (r) => r < 32 || (r >= 127 && r <= 159) || r == 0x2028 || r == 0x2029,
  )) {
    throw DomainError('$field不能包含控制字符或换行');
  }
  final value = raw.trim();
  if (value.isEmpty || value.runes.length > max) {
    throw DomainError('$field须为 1–$max 个字符');
  }
  return value;
}

int validAmount(Object? value, [int max = 999999]) {
  if (value is! int || value < 1 || value > max) {
    throw DomainError('请输入 1–${number(max)} 的整数');
  }
  return value;
}

int parseAmount(String raw, [int max = 999999]) {
  if (!RegExp(r'^[0-9]+$').hasMatch(raw)) {
    throw const DomainError('请输入正整数');
  }
  return validAmount(int.tryParse(raw), max);
}

void validTime(int value) {
  if (value < 0 || value > maxTimestamp) {
    throw const DomainError('设备时间超出支持范围');
  }
}

class ProjectView {
  ProjectView(this.data);
  final Json data;
  String get id => data['id'] as String;
  String get name => data['name'] as String;
  String get unit => data['unit'] as String;
  String get icon => data['icon_key'] as String;
  int get quick => data['quick_amount'] as int;
  bool get archived => data['archived'] == 1 || data['archived'] == true;
  int get today => data['today'] as int? ?? 0;
  int get total => data['total'] as int? ?? 0;
  bool get unitLocked => (data['history_count'] as int? ?? 0) > 0;
  Json get payload => {
    for (final key in [
      'name',
      'unit',
      'icon_key',
      'quick_amount',
      'created_at_utc_ms',
      'updated_at_utc_ms',
    ])
      key: data[key],
    'archived': archived,
  };
  Json toJson() => {'id': id, ...payload};
}

class StatsData {
  StatsData(
    this.dates,
    this.values,
    this.eventCount,
    this.projectCount,
    this.activeDays,
  );
  final List<String> dates;
  final List<int> values;
  final int eventCount, projectCount, activeDays;
  int get total => values.fold(0, (a, b) => a + b);
}
