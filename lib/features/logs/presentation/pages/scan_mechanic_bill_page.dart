import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/receipt_parser_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection.dart';
import '../../../vehicles/presentation/bloc/vehicle_bloc.dart';
import '../../data/models/maintenance_log_model.dart';
import '../../domain/repositories/log_repository.dart';

/// Page to scan a handwritten mechanic bill and create maintenance entries
class ScanMechanicBillPage extends StatefulWidget {
  const ScanMechanicBillPage({super.key});

  @override
  State<ScanMechanicBillPage> createState() => _ScanMechanicBillPageState();
}

class _ScanMechanicBillPageState extends State<ScanMechanicBillPage> {
  final _ocrService = getIt<OCRService>();
  final _parserService = getIt<ReceiptParserService>();
  final _logRepository = getIt<LogRepository>();

  bool _isProcessing = false;
  bool _isSaving = false;
  String? _mechanicName;
  List<ServiceItem> _services = [];
  List<bool> _selectedServices = [];

  // Editable controllers for each service
  List<TextEditingController> _descControllers = [];
  List<TextEditingController> _costControllers = [];

  @override
  void dispose() {
    for (var c in _descControllers) { c.dispose(); }
    for (var c in _costControllers) { c.dispose(); }
    super.dispose();
  }

  Future<void> _scanImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    await _processImage(pickedFile.path);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    await _processImage(pickedFile.path);
  }

  Future<void> _processImage(String path) async {
    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognizedText = await _ocrService.processImage(inputImage);
      final text = recognizedText.text;

      final services = _parserService.parseMechanicBill(text);
      final mechanicName = _parserService.extractBusinessName(text);

      // Dispose old controllers
      for (var c in _descControllers) { c.dispose(); }
      for (var c in _costControllers) { c.dispose(); }

      setState(() {
        _services = services;
        _selectedServices = List.filled(services.length, true);
        _mechanicName = mechanicName;
        _descControllers = services.map((s) => TextEditingController(text: s.description)).toList();
        _costControllers = services.map((s) => TextEditingController(text: s.cost.toStringAsFixed(2))).toList();
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning bill: $e')),
        );
      }
    }
  }

  Future<void> _saveSelectedServices() async {
    final vehicleId = context.read<VehicleBloc>().state.selectedVehicle?.id;
    setState(() => _isSaving = true);

    try {
      for (int i = 0; i < _services.length; i++) {
        if (_selectedServices[i]) {
          final desc = _descControllers[i].text.trim();
          final cost = double.tryParse(_costControllers[i].text) ?? _services[i].cost;

          final log = MaintenanceLogModel(
            id: const Uuid().v4(),
            date: DateTime.now(),
            category: 'Repair',
            cost: cost,
            note: '$desc${_mechanicName != null ? ' (by $_mechanicName)' : ''}',
            userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            vehicleId: vehicleId,
          );
          await _logRepository.addMaintenanceLog(log);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance records saved successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving records: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Scan Mechanic Bill', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text('Reading mechanic bill...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : _services.isEmpty
              ? _buildScanPrompt()
              : _buildServicesList(),
      bottomSheet: _services.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.cardDark,
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : _selectedServices.contains(true)
                            ? _saveSelectedServices
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save ${_selectedServices.where((s) => s).length} Services',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildScanPrompt() {
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.handyman, color: Colors.orange, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Scan Mechanic Bill',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo of your handwritten or printed mechanic bill to auto-record maintenance work',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _scanImage,
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: Text('Take Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: Icon(Icons.image, color: Colors.grey[300]),
                label: Text('Pick from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[300])),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[700]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_mechanicName != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_mechanicName!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_services.length} services found',
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
            ),
            Text(
              'Edit fields if needed',
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_services.length, (index) {
          return Card(
            color: AppTheme.cardDark,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedServices[index],
                    onChanged: (val) {
                      setState(() => _selectedServices[index] = val ?? false);
                    },
                    activeColor: AppTheme.primary,
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _descControllers[index],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
                        labelText: 'Service',
                        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _costControllers[index],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: '₹',
                        prefixStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 80), // Space for bottom button
      ],
    );
  }
}
