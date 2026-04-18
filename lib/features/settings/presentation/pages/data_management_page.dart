import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection.dart';
import '../../../logs/domain/repositories/log_repository.dart';

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({Key? key}) : super(key: key);

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  bool _isLoading = false;

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      final repo = getIt<LogRepository>();
      final fuelLogs = await repo.getRecentFuelLogs();

      List<List<dynamic>> rows = [
        ['Type', 'ID', 'Date', 'Amount', 'Odometer', 'Liters', 'Title/Note']
      ];

      for (var log in fuelLogs) {
        rows.add([
          'Fuel',
          log.id,
          log.timestamp.toIso8601String(),
          log.cost,
          log.odometer,
          log.liters,
          log.stationName ?? ''
        ]);
      }

      StringBuffer sb = StringBuffer();
      for (var row in rows) {
        sb.writeln(row.map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
      }
      String csv = sb.toString();


      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/carlog_export.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'Carlog Data Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        // Just acknowledging import for now
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import functionality coming soon!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Data Management'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.white),
                  title: const Text('Export to CSV', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Download all your logs', style: TextStyle(color: Colors.grey)),
                  onTap: _exportData,
                ),
                ListTile(
                  leading: const Icon(Icons.upload, color: Colors.white),
                  title: const Text('Import from CSV', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Restore data from a backup', style: TextStyle(color: Colors.grey)),
                  onTap: _importData,
                ),
              ],
            ),
    );
  }
}
