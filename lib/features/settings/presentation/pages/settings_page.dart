import 'package:carlog/core/services/settings_service.dart';
import 'package:carlog/injection.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'help_support_page.dart';
import 'notifications_page.dart';
import 'privacy_security_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Profile', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.white),
            title: const Text('Notifications', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage())),
          ),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.white),
            title: const Text('Privacy & Security', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacySecurityPage())),
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.white),
            title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportPage())),
          ),
          const Divider(color: Colors.grey, height: 32),
          const Text('LOCALIZATION', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildLocalizationTile(
            context,
            icon: Icons.monetization_on,
            title: 'Currency',
            value: getIt<SettingsService>().currency,
            options: [r'$', '₹', '€', '£', '¥', 'Rs.'],
            onChanged: (val) => getIt<SettingsService>().setCurrency(val),
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.blueAccent),
            title: const Text('Auto-detect Currency', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Based on your current location', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () async {
              await getIt<SettingsService>().detectAndSetCurrency();
              // The UI should rebuild via the stream or just a manual setState if we want
              // Since SettingsPage is a StatelessWidget, we might need a rebuild trigger
              // But SettingsService.detectAndSetCurrency calls setCurrency which updates the box.
              // We can use a StreamBuilder or just navigate back/forth.
              // To keep it simple, I'll update _buildLocalizationTile to use a StreamBuilder or a StatefulWidget.
            },
          ),
          _buildLocalizationTile(
            context,
            icon: Icons.calendar_month,
            title: 'Date Format',
            value: getIt<SettingsService>().dateFormat,
            options: ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd', 'dd MMM yyyy'],
            onChanged: (val) => getIt<SettingsService>().setDateFormat(val),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalizationTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          trailing: DropdownButton<String>(
            value: options.contains(value) ? value : options.first,
            dropdownColor: AppTheme.cardDark,
            underline: const SizedBox(),
            items: options.map((String opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(opt, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (newVal) {
              if (newVal != null) {
                onChanged(newVal);
                setState(() {});
              }
            },
          ),
        );
      },
    );
  }
}
