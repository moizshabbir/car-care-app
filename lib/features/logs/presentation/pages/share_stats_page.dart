import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../injection.dart';
import '../../domain/log_stats_service.dart';
import '../../domain/repositories/log_repository.dart';
import '../widgets/viral_share_card.dart';

class ShareStatsPage extends StatefulWidget {
  const ShareStatsPage({super.key});

  @override
  State<ShareStatsPage> createState() => _ShareStatsPageState();
}

class _ShareStatsPageState extends State<ShareStatsPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final LogStatsService _statsService = LogStatsService();
  late Future<Map<String, double>> _statsFuture;

  bool _includeTotalSpent = false;
  bool _includeTotalDistance = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _calculateStats();
  }

  Future<Map<String, double>> _calculateStats() async {
    // getIt<LogRepository>() returns the repository instance.
    // We assume the repository is registered in injection.dart
    final logs = await getIt<LogRepository>().getRecentFuelLogs();
    return {
      'costPerKm': _statsService.calculateAverageCostPerKm(logs),
      'totalSpent': _statsService.calculateTotalSpent(logs),
      'totalDistance': _statsService.calculateTotalDistance(logs),
    };
  }

  Future<void> _shareCard(double costPerKm, double? totalSpent, double? totalDistance) async {
    try {
      getIt<AnalyticsService>().logShareCardClicked();

      // Capture only the widget. We wrap in Material and Directionality for theme/text direction.
      final Uint8List image = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            type: MaterialType.transparency,
            child: ViralShareCard(
              costPerKm: costPerKm,
              totalSpent: totalSpent,
              totalDistance: totalDistance,
            ),
          ),
        ),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      final directory = await getTemporaryDirectory();
      final file = await File('${directory.path}/share_card.png').create();
      await file.writeAsBytes(image);

      // Use Share.shareXFiles for sharing files
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my car cost stats! #CarCareApp',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Stats')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, double>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data available'));
            }

            final data = snapshot.data!;
            final costPerKm = data['costPerKm'] ?? 0.0;
            final totalSpent = data['totalSpent'] ?? 0.0;
            final totalDistance = data['totalDistance'] ?? 0.0;

            final displayTotalSpent = _includeTotalSpent ? totalSpent : null;
            final displayTotalDistance = _includeTotalDistance ? totalDistance : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Show off your efficiency! Customize your card below and share it with your friends.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),
                Center(
                  child: ViralShareCard(
                    costPerKm: costPerKm,
                    totalSpent: displayTotalSpent,
                    totalDistance: displayTotalDistance,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Customize Card',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: SwitchListTile(
                    title: const Text('Include Total Spent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Show amount spent on vehicle', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _includeTotalSpent,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF135BEC),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.payments, color: Colors.blue),
                    ),
                    onChanged: (val) => setState(() => _includeTotalSpent = val),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: SwitchListTile(
                    title: const Text('Include Total Distance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Show kilometers tracked', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _includeTotalDistance,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF135BEC),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.route, color: Colors.purple),
                    ),
                    onChanged: (val) => setState(() => _includeTotalDistance = val),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _shareCard(costPerKm, displayTotalSpent, displayTotalDistance),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share with Friends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
}
