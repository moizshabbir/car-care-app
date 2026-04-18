import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../injection.dart';
import '../../domain/repositories/log_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../../data/models/fuel_log_model.dart';
import '../../data/models/maintenance_log_model.dart';

class TransactionDetailPage extends StatelessWidget {
  final DashboardLogItem logItem;

  const TransactionDetailPage({Key? key, required this.logItem}) : super(key: key);

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Transaction', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this transaction?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = getIt<LogRepository>();
      if (logItem.type == LogType.fuel) {
        await repo.deleteFuelLog(logItem.id);
      } else {
        await repo.deleteMaintenanceLog(logItem.id);
      }
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _openMap(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = getIt<SettingsService>().currency;
    final isFuel = logItem.type == LogType.fuel;

    String? photoPath;
    double? lat, lng;
    int? odometer;

    if (isFuel && logItem.originalLog is FuelLogModel) {
      final fuelLog = logItem.originalLog as FuelLogModel;
      photoPath = fuelLog.odometerPhotoPath;
      odometer = fuelLog.odometer;
      if (fuelLog.location != null) {
        lat = fuelLog.location!.latitude;
        lng = fuelLog.location!.longitude;
      }
    } else if (!isFuel && logItem.originalLog is MaintenanceLogModel) {
      final maintLog = logItem.originalLog as MaintenanceLogModel;
      photoPath = maintLog.photoPath;
      odometer = maintLog.odometer;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text('Transaction Details', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            Center(
              child: Text(
                NumberFormat.currency(symbol: currency).format(logItem.amount),
                style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                logItem.title,
                style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 32),

            // Details
            _buildDetailRow('Date', DateFormat('MMM dd, yyyy - hh:mm a').format(logItem.date)),
            _buildDetailRow('Details', logItem.subtitle),
            if (odometer != null)
              _buildDetailRow('Odometer', '${NumberFormat('#,###').format(odometer)} km'),

            const SizedBox(height: 24),

            if (lat != null && lng != null) ...[
              const Text('Location', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openMap(lat!, lng!),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('View on Map', style: TextStyle(color: Colors.white))),
                      const Icon(Icons.open_in_new, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (photoPath != null && File(photoPath).existsSync()) ...[
              const Text('Receipt / Odometer Photo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(photoPath),
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14)),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
