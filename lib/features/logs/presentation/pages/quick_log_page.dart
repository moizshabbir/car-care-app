import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../injection.dart';
import '../bloc/quick_log_bloc.dart';
import '../bloc/quick_log_event.dart';
import '../bloc/quick_log_state.dart';
import '../widgets/fuel_log_manual_entry_sheet.dart';

class QuickLogPage extends StatefulWidget {
  const QuickLogPage({super.key});

  @override
  State<QuickLogPage> createState() => _QuickLogPageState();
}

class _QuickLogPageState extends State<QuickLogPage> with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    final analytics = getIt<AnalyticsService>();
    analytics.logLogStart();
    analytics.startTimer('time_to_log');

    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    getIt<AnalyticsService>().stopTimer('time_to_log');
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<QuickLogBloc>()..add(StartCamera()),
      child: Scaffold(
        backgroundColor: const Color(0xFF111318), // AppTheme.backgroundDark
        appBar: AppBar(
          title: const Text('Refuel', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: BlocBuilder<QuickLogBloc, QuickLogState>(
          builder: (context, state) {
            final bool showSheet = state.status == QuickLogStatus.review ||
                                   state.status == QuickLogStatus.saving ||
                                   state.status == QuickLogStatus.saved;

            final bool isProcessing = state.status == QuickLogStatus.processing || 
                                      state.status == QuickLogStatus.capturing;

            return Stack(
              children: [
                // Main Content
                if (state.status == QuickLogStatus.error)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.errorMessage ?? "Unknown"}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<QuickLogBloc>().add(RetakeImage()),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                else if (isProcessing)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF135BEC)), // AppTheme.primary
                        SizedBox(height: 16),
                        Text('Analyzing receipt...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )
                else if (!showSheet)
                  _buildScanPrompt(context),

                // Manual Entry Sheet (Sliding Up)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: 0,
                  right: 0,
                  bottom: showSheet ? 0 : -MediaQuery.of(context).size.height,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    child: FuelLogManualEntrySheet(
                      onClose: () {
                         context.read<QuickLogBloc>().add(RetakeImage());
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScanPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF135BEC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.local_gas_station, color: Color(0xFF135BEC), size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Scan Fuel Receipt',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo of your fuel receipt or dashboard odometer to automatically extract data',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => context.read<QuickLogBloc>().add(CaptureImage()),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: Text('Take Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => context.read<QuickLogBloc>().add(PickImageFromGallery()),
                icon: Icon(Icons.image, color: Colors.grey[300]),
                label: Text('Pick from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[300])),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[700]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.read<QuickLogBloc>().add(SwitchToManual()),
              child: const Text('Enter Manually', style: TextStyle(color: Color(0xFF135BEC), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}