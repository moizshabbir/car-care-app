import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _fuelReminders = true;
  bool _serviceReminders = true;
  bool _weeklySummary = false;
  bool _priceAlerts = false;
  bool _odometerReminders = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final box = await Hive.openBox('notification_prefs');
    setState(() {
      _fuelReminders = box.get('fuelReminders', defaultValue: true);
      _serviceReminders = box.get('serviceReminders', defaultValue: true);
      _weeklySummary = box.get('weeklySummary', defaultValue: false);
      _priceAlerts = box.get('priceAlerts', defaultValue: false);
      _odometerReminders = box.get('odometerReminders', defaultValue: true);
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final box = await Hive.openBox('notification_prefs');
    await box.put(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Notifications', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Manage how you receive notifications and reminders.',
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),

          _sectionTitle('Reminders'),
          _toggleTile(
            title: 'Fuel Reminders',
            subtitle: 'Remind me to log fuel fill-ups',
            icon: Icons.local_gas_station,
            iconColor: Colors.blue,
            value: _fuelReminders,
            onChanged: (val) {
              setState(() => _fuelReminders = val);
              _savePref('fuelReminders', val);
            },
          ),
          _toggleTile(
            title: 'Service Reminders',
            subtitle: 'Notify about upcoming maintenance',
            icon: Icons.build,
            iconColor: Colors.orange,
            value: _serviceReminders,
            onChanged: (val) {
              setState(() => _serviceReminders = val);
              _savePref('serviceReminders', val);
            },
          ),
          _toggleTile(
            title: 'Odometer Check',
            subtitle: 'Remind to update odometer regularly',
            icon: Icons.speed,
            iconColor: Colors.green,
            value: _odometerReminders,
            onChanged: (val) {
              setState(() => _odometerReminders = val);
              _savePref('odometerReminders', val);
            },
          ),

          const SizedBox(height: 16),
          _sectionTitle('Reports'),
          _toggleTile(
            title: 'Weekly Summary',
            subtitle: 'Get a weekly report of expenses',
            icon: Icons.bar_chart,
            iconColor: Colors.purple,
            value: _weeklySummary,
            onChanged: (val) {
              setState(() => _weeklySummary = val);
              _savePref('weeklySummary', val);
            },
          ),
          _toggleTile(
            title: 'Price Alerts',
            subtitle: 'Alert when fuel prices change',
            icon: Icons.trending_up,
            iconColor: Colors.redAccent,
            value: _priceAlerts,
            onChanged: (val) {
              setState(() => _priceAlerts = val);
              _savePref('priceAlerts', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: Colors.grey[500]),
      ),
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
