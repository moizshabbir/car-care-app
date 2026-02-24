import 'package:camera/camera.dart';
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
        backgroundColor: Colors.black, // Camera background
        body: BlocBuilder<QuickLogBloc, QuickLogState>(
          builder: (context, state) {
            // Determine if sheet should be shown
            final bool showSheet = state.status == QuickLogStatus.review ||
                                   state.status == QuickLogStatus.saving ||
                                   state.status == QuickLogStatus.saved;

            return Stack(
              children: [
                // 1. Camera Layer
                if (state.status == QuickLogStatus.error)
                  Center(
                    child: Text(
                      'Error: ${state.errorMessage ?? "Unknown"}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                else if (state.cameraController != null && state.cameraController!.value.isInitialized)
                  SizedBox.expand(
                    child: CameraPreview(state.cameraController!),
                  )
                else
                  const Center(child: CircularProgressIndicator()),

                // 2. Overlay Layer (Gradient & UI)
                // Top Bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCircleButton(
                          icon: Icons.close,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(
                            'MAGIC SCAN',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        _buildCircleButton(
                          icon: Icons.flash_on,
                          onPressed: () {
                            // Toggle Flash logic if needed (not implemented in Bloc yet)
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Scanning Area (Middle)
                if (!showSheet)
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 300,
                            height: 225, // 4:3 aspect ratio
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                // Corners
                                _buildCorner(top: 0, left: 0),
                                _buildCorner(top: 0, right: 0),
                                _buildCorner(bottom: 0, left: 0),
                                _buildCorner(bottom: 0, right: 0),

                                // Scan Line
                                AnimatedBuilder(
                                  animation: _scanAnimation,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: 225 * _scanAnimation.value,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF135BEC).withOpacity(0.8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF135BEC).withOpacity(0.8),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.center_focus_strong, color: Color(0xFF135BEC), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Align receipt or dashboard',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom Controls
                if (!showSheet)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 40, top: 24, left: 24, right: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.8), Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Shutter Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(Icons.image),
                              const SizedBox(width: 40),
                              GestureDetector(
                                onTap: () => context.read<QuickLogBloc>().add(CaptureImage()),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                              _buildActionButton(Icons.receipt_long),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Manual Entry Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111318),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Trouble scanning?',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Lighting or glare issues?',
                                      style: GoogleFonts.inter(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () => context.read<QuickLogBloc>().add(SwitchToManual()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF135BEC),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  child: const Text('Enter Manually'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Manual Entry Sheet (Sliding Up)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: 0,
                  right: 0,
                  bottom: showSheet ? 0 : -MediaQuery.of(context).size.height, // Slide in/out
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    child: FuelLogManualEntrySheet(
                      onClose: () {
                         // To close sheet, we need to reset state to camera ready or pop if saved.
                         // But current Bloc SwitchToManual sets state to Review.
                         // To go back, we need an event like RetakeImage or just reset.
                         context.read<QuickLogBloc>().add(RetakeImage());
                      },
                    ),
                  ),
                ),

                // Loading Indicator for Processing
                if (state.status == QuickLogStatus.processing || state.status == QuickLogStatus.capturing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildActionButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildCorner({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? const BorderSide(color: Color(0xFF135BEC), width: 4) : BorderSide.none,
            bottom: bottom != null ? const BorderSide(color: Color(0xFF135BEC), width: 4) : BorderSide.none,
            left: left != null ? const BorderSide(color: Color(0xFF135BEC), width: 4) : BorderSide.none,
            right: right != null ? const BorderSide(color: Color(0xFF135BEC), width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top != null && left != null ? const Radius.circular(12) : Radius.zero,
            topRight: top != null && right != null ? const Radius.circular(12) : Radius.zero,
            bottomLeft: bottom != null && left != null ? const Radius.circular(12) : Radius.zero,
            bottomRight: bottom != null && right != null ? const Radius.circular(12) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
