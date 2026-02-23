import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:injectable/injectable.dart';

@singleton
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final FirebasePerformance _performance;
  final Map<String, Trace> _activeTraces = {};

  AnalyticsService(this._analytics, this._performance);

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> logLogStart() async {
    await logEvent('log_start');
  }

  Future<void> logLogCompleted(bool success) async {
    await logEvent('log_completed', {'success': success});
  }

  Future<void> logShareCardClicked() async {
    await logEvent('share_card_clicked');
  }

  Future<void> logOCRManualEdit(String field) async {
    await logEvent('ocr_manual_edit', {'field': field});
  }

  Future<void> startTimer(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    _activeTraces[name] = trace;
  }

  Future<void> stopTimer(String name) async {
    final trace = _activeTraces.remove(name);
    if (trace != null) {
      await trace.stop();
    }
  }
}
