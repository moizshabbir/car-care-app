import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

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
  late Future<double> _costPerKmFuture;

  @override
  void initState() {
    super.initState();
    _costPerKmFuture = _calculateStats();
  }

  Future<double> _calculateStats() async {
    // getIt<LogRepository>() returns the repository instance.
    // We assume the repository is registered in injection.dart
    final logs = await getIt<LogRepository>().getRecentFuelLogs();
    return _statsService.calculateAverageCostPerKm(logs);
  }

  Future<void> _shareCard(double costPerKm) async {
    try {
      // Capture only the widget. We wrap in Material and Directionality for theme/text direction.
      final Uint8List image = await _screenshotController.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            type: MaterialType.transparency,
            child: ViralShareCard(costPerKm: costPerKm),
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
      body: Center(
        child: FutureBuilder<double>(
          future: _costPerKmFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData) {
              return const Text('No data available');
            }

            // If we have data but it's 0, it might mean not enough logs.
            // We still show the card, maybe with 0.00.
            final costPerKm = snapshot.data!;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ViralShareCard(costPerKm: costPerKm),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _shareCard(costPerKm),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
