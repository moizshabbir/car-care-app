import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../injection.dart';
import '../bloc/quick_log_bloc.dart';
import '../bloc/quick_log_event.dart';
import '../bloc/quick_log_state.dart';
import '../widgets/manual_entry_form.dart';

class QuickLogPage extends StatefulWidget {
  const QuickLogPage({super.key});

  @override
  State<QuickLogPage> createState() => _QuickLogPageState();
}

class _QuickLogPageState extends State<QuickLogPage> {
  @override
  void initState() {
    super.initState();
    final analytics = getIt<AnalyticsService>();
    analytics.logLogStart();
    analytics.startTimer('time_to_log');
  }

  @override
  void dispose() {
    // Ensure timer is stopped if page is closed without saving (aborted log)
    // If saved, ManualEntryForm will have stopped it already.
    getIt<AnalyticsService>().stopTimer('time_to_log');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<QuickLogBloc>()..add(StartCamera()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Quick Log')),
        body: BlocBuilder<QuickLogBloc, QuickLogState>(
          builder: (context, state) {
            if (state.status == QuickLogStatus.review || state.status == QuickLogStatus.saving || state.status == QuickLogStatus.saved) {
               return const SingleChildScrollView(child: ManualEntryForm());
            }
            if (state.status == QuickLogStatus.cameraReady || state.status == QuickLogStatus.capturing || state.status == QuickLogStatus.processing || state.status == QuickLogStatus.imageCaptured) {
               if (state.cameraController == null || !state.cameraController!.value.isInitialized) {
                 return const Center(child: CircularProgressIndicator());
               }
               return Stack(
                 children: [
                   SizedBox(
                     height: double.infinity,
                     width: double.infinity,
                     child: CameraPreview(state.cameraController!),
                   ),
                   if (state.status == QuickLogStatus.processing || state.status == QuickLogStatus.capturing)
                     const Center(child: CircularProgressIndicator()),
                   Align(
                     alignment: Alignment.bottomCenter,
                     child: Padding(
                       padding: const EdgeInsets.all(20.0),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                         children: [
                           FloatingActionButton(
                             heroTag: 'capture',
                             onPressed: () => context.read<QuickLogBloc>().add(CaptureImage()),
                             child: const Icon(Icons.camera_alt),
                           ),
                           ElevatedButton.icon(
                             onPressed: () => context.read<QuickLogBloc>().add(SwitchToManual()),
                             icon: const Icon(Icons.edit),
                             label: const Text('Manual'),
                           ),
                         ],
                       ),
                     ),
                   ),
                 ],
               );
            }
            if (state.status == QuickLogStatus.error) {
              return Center(child: Text('Error: ${state.errorMessage}'));
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
