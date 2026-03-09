import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Help & Support', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary.withValues(alpha: 0.15), AppTheme.primary.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_car, color: AppTheme.primary, size: 32),
                ),
                const SizedBox(height: 12),
                Text('CarCareApp', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('v1.0.0', style: GoogleFonts.inter(color: Colors.grey[400])),
                const SizedBox(height: 8),
                Text(
                  'Track fuel, maintenance & parts for your vehicles',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Frequently Asked Questions'),
          _faqTile('How do I log a fuel fill-up?',
            'Tap the + button on the dashboard and choose "Magic Scan" to scan your fuel receipt, or "Add Expense" for manual entry. The app will automatically extract the petrol pump name, amount, liters, and more.'),
          _faqTile('Can I scan handwritten bills?',
            'Yes! Choose "Scan Mechanic Bill" from the + menu. The OCR will read the handwritten text and extract service descriptions and costs. You can edit any incorrectly recognized text before saving.'),
          _faqTile('How does the POS receipt scanner work?',
            'Select "Scan Store Receipt" from the + menu. Take a photo of your auto parts receipt and the app will extract individual items, quantities, and prices. Each selected item is saved as a separate transaction.'),
          _faqTile('Is my data stored securely?',
            'Yes, your data is stored locally on your device using encrypted storage and synced to Firebase Firestore with user-level authentication. Only you can access your data.'),
          _faqTile('Can I use the app offline?',
            'Absolutely! CarCareApp works offline-first. All your data is saved locally and automatically syncs when you reconnect to the internet.'),
          _faqTile('How do I share my cost-per-KM?',
            'From the dashboard, tap the share icon in the top-right corner. You\'ll get a shareable card with your vehicle\'s cost-per-KM metric.'),

          const SizedBox(height: 24),
          _sectionTitle('Contact & Support'),
          _actionTile(
            title: 'Send Feedback',
            subtitle: 'Help us improve the app',
            icon: Icons.feedback_outlined,
            iconColor: AppTheme.primary,
            onTap: () {
              final uri = Uri(scheme: 'mailto', path: 'support@carcareapp.com', queryParameters: {'subject': 'CarCareApp Feedback'});
              launchUrl(uri);
            },
          ),
          _actionTile(
            title: 'Contact Us',
            subtitle: 'support@carcareapp.com',
            icon: Icons.email_outlined,
            iconColor: Colors.green,
            onTap: () {
              final uri = Uri(scheme: 'mailto', path: 'support@carcareapp.com');
              launchUrl(uri);
            },
          ),
          _actionTile(
            title: 'Rate the App',
            subtitle: 'Leave a review on the app store',
            icon: Icons.star_outline,
            iconColor: Colors.amber,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App store link coming soon!')),
              );
            },
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Made with ❤️ for car enthusiasts',
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
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

  Widget _faqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: AppTheme.primary,
        collapsedIconColor: Colors.grey[500],
        title: Text(question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
        children: [
          Text(answer, style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        tileColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
      ),
    );
  }
}
