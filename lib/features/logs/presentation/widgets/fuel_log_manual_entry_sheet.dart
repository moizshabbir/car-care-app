import "../../domain/log_stats_service.dart";
import "../../domain/repositories/log_repository.dart";
import 'package:carlog/core/services/settings_service.dart';
import 'package:carlog/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';
import '../../../../core/services/receipt_parser_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../vehicles/presentation/bloc/vehicle_bloc.dart';
import '../bloc/quick_log_bloc.dart';
import '../bloc/quick_log_event.dart';
import '../bloc/quick_log_state.dart';

class FuelLogManualEntrySheet extends StatefulWidget {
  final VoidCallback onClose;

  const FuelLogManualEntrySheet({super.key, required this.onClose});

  @override
  State<FuelLogManualEntrySheet> createState() => _FuelLogManualEntrySheetState();
}

class _FuelLogManualEntrySheetState extends State<FuelLogManualEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _odometerController;
  late TextEditingController _litersController;
  late TextEditingController _costController;

  // Store initial values to detect manual edits to OCR data
  String? _initialOdometer;
  String? _initialLiters;
  String? _initialCost;

    @override
  void initState() {
    super.initState();
    final state = context.read<QuickLogBloc>().state;

    _initialOdometer = state.odometer?.toString() ?? '';
    _initialLiters = state.liters?.toString() ?? '';
    _initialCost = state.cost?.toString() ?? '';

    _odometerController = TextEditingController(text: _initialOdometer);
    _litersController = TextEditingController(text: _initialLiters);
    _costController = TextEditingController(text: _initialCost);

    _estimateOdometerIfNeeded();
  }

  Future<void> _estimateOdometerIfNeeded() async {
    if (_odometerController.text.isEmpty) {
        final repo = getIt<LogRepository>();
        final stats = LogStatsService();
        final logs = await repo.getRecentFuelLogs();
        if (logs.isNotEmpty) {
            final est = stats.estimateNextOdometer(logs);
            if (mounted) {
                setState(() {
                    _odometerController.text = est.toString();
                    _initialOdometer = est.toString();
                });
            }
        }
    }
  }

  Future<void> _scanOdometer() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning odometer...')),
      );

      try {
        final parser = getIt<ReceiptParserService>();
        // Using a focused prompt or specific parsing for odometer
        final result = await parser.parseFuelReceipt(image.path);
        
        if (result.odometer != null) {
          setState(() {
            _odometerController.text = result.odometer!.toInt().toString();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Odometer updated!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find odometer value in image.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + MediaQuery.of(context).padding.bottom),
      child: BlocListener<QuickLogBloc, QuickLogState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == QuickLogStatus.saved) {
             final analytics = getIt<AnalyticsService>();
             analytics.logLogCompleted(true);
             analytics.stopTimer('time_to_log');

             if (_initialOdometer!.isNotEmpty && _initialOdometer != _odometerController.text) {
               analytics.logOCRManualEdit('odometer');
             }
             if (_initialLiters!.isNotEmpty && _initialLiters != _litersController.text) {
               analytics.logOCRManualEdit('liters');
             }
             if (_initialCost!.isNotEmpty && _initialCost != _costController.text) {
               analytics.logOCRManualEdit('cost');
             }

             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Log saved successfully!')),
             );
             Navigator.of(context).pop(); // Go back to home
          } else if (state.status == QuickLogStatus.error) {
             getIt<AnalyticsService>().logLogCompleted(false);
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
             );
          }
        },
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Drag Handle
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
                margin: const EdgeInsets.only(bottom: 24),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manual Entry',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Odometer
              _buildField(
                controller: _odometerController,
                label: 'Odometer Reading',
                icon: Icons.speed,
                suffix: 'km',
                isInteger: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF135BEC)),
                  onPressed: _scanOdometer,
                ),
              ),
              const SizedBox(height: 16),

              // Row for Volume and Cost
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _litersController,
                      label: 'Volume',
                      icon: Icons.local_gas_station,
                      suffix: 'L',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BlocBuilder<QuickLogBloc, QuickLogState>(
                      builder: (context, state) {
                        return _buildField(
                          controller: _costController,
                          label: 'Total Cost',
                          icon: Icons.monetization_on,
                          prefix: state.scannedCurrency ?? getIt<SettingsService>().currency,
                        );
                      }
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Swatches spread to full width
              Row(
                children: [1, 5, 10, 20].map((val) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        double current = double.tryParse(_litersController.text) ?? 0.0;
                        _litersController.text = (current + val).toStringAsFixed(1);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF135BEC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF135BEC).withOpacity(0.4), width: 1.5),
                        ),
                        child: Text(
                          '+$val L', 
                          style: GoogleFonts.inter(
                            color: const Color(0xFF135BEC), 
                            fontSize: 14, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),

              const SizedBox(height: 24),

              // Save Button
              BlocBuilder<QuickLogBloc, QuickLogState>(
                builder: (context, state) {
                  if (state.status == QuickLogStatus.saving) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final vehicleId = context.read<VehicleBloc>().state.selectedVehicle?.id;
                          context.read<QuickLogBloc>().add(SaveLog(
                            odometer: int.parse(_odometerController.text),
                            liters: double.parse(_litersController.text),
                            cost: double.parse(_costController.text),
                            vehicleId: vehicleId,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF135BEC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF135BEC).withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Save Entry',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
      ),
    ),
    ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    String? prefix,
    bool isInteger = false,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
          style: GoogleFonts.robotoMono(fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            prefixText: prefix != null ? '$prefix ' : null,
            prefixStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            suffixText: suffix,
            suffixIcon: suffixIcon,
            suffixStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            filled: true,
            fillColor: isDark ? const Color(0xFF0B0E14) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF135BEC), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (isInteger) {
              if (int.tryParse(value) == null) return 'Integer required';
            } else {
              if (double.tryParse(value) == null) return 'Number required';
            }
            return null;
          },
        ),
      ],
    );
  }
}
