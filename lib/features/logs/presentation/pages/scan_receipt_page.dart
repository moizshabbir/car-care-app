import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/receipt_parser_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection.dart';
import '../../../../core/services/settings_service.dart';
import '../../../vehicles/presentation/bloc/vehicle_bloc.dart';
import '../../data/models/maintenance_log_model.dart';
import '../../domain/repositories/log_repository.dart';

/// Page to scan a store POS receipt and create per-item transactions
class ScanReceiptPage extends StatefulWidget {
  const ScanReceiptPage({super.key});

  @override
  State<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends State<ScanReceiptPage> {
  final _parserService = getIt<ReceiptParserService>();
  final _logRepository = getIt<LogRepository>();

  bool _isProcessing = false;
  bool _isSaving = false;
  String? _storeName;
  List<POSItem> _items = [];
  List<bool> _selectedItems = [];

  List<TextEditingController> _nameControllers = [];
  List<TextEditingController> _qtyControllers = [];
  List<TextEditingController> _priceControllers = [];

  @override
  void dispose() {
    for (var c in _nameControllers) { c.dispose(); }
    for (var c in _qtyControllers) { c.dispose(); }
    for (var c in _priceControllers) { c.dispose(); }
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

    try {
      await _processImage(pickedFile.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning receipt: $e')),
        );
      }
    }
  }

  Future<void> _processImage(String path) async {
    setState(() => _isProcessing = true);

    try {
      final parsedReceipt = await _parserService.parsePOSReceipt(path);
      final items = parsedReceipt.items;
      final storeName = parsedReceipt.storeName;

      if (items.isEmpty) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read any items from the receipt. Please try another clearer image.')),
          );
        }
        return;
      }

      for (var c in _nameControllers) { c.dispose(); }
      for (var c in _qtyControllers) { c.dispose(); }
      for (var c in _priceControllers) { c.dispose(); }

      setState(() {
        _items = items;
        _selectedItems = List.filled(items.length, true);
        _storeName = storeName;
        _nameControllers = items.map((i) => TextEditingController(text: i.name)).toList();
        _qtyControllers = items.map((i) => TextEditingController(text: i.quantity.toString())).toList();
        _priceControllers = items.map((i) => TextEditingController(text: i.price.toStringAsFixed(2))).toList();
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning receipt: $e')),
        );
      }
    }
  }

  Future<void> _saveSelectedItems() async {
    final vehicleId = context.read<VehicleBloc>().state.selectedVehicle?.id;
    setState(() => _isSaving = true);

    try {
      for (int i = 0; i < _items.length; i++) {
        if (_selectedItems[i]) {
          final item = _items[i];
          final name = _nameControllers[i].text.trim().isNotEmpty ? _nameControllers[i].text.trim() : item.name;
          final qty = int.tryParse(_qtyControllers[i].text) ?? item.quantity;
          final price = double.tryParse(_priceControllers[i].text) ?? item.price;
          
          final log = MaintenanceLogModel(
            id: const Uuid().v4(),
            date: DateTime.now(),
            category: 'Parts',
            cost: price * qty,
            note: '$name (Qty: $qty)${_storeName != null ? ' from $_storeName' : ''}',
            userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            vehicleId: vehicleId,
          );
          await _logRepository.addMaintenanceLog(log);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parts transactions saved successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transactions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Scan Store Receipt', style: TextStyle(color: Colors.white)),
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
                  Text('Scanning receipt...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : _items.isEmpty
              ? _buildScanPrompt()
              : _buildItemsList(),
      bottomSheet: _items.isNotEmpty
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
                        : _selectedItems.contains(true)
                            ? _saveSelectedItems
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save ${_selectedItems.where((s) => s).length} Items',
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
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.receipt_long, color: AppTheme.primary, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Scan Store Receipt',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo of your auto parts or accessories receipt to automatically create transaction entries',
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

  Widget _buildItemsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_storeName != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.store, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_storeName!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          '${_items.length} items found',
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...List.generate(_items.length, (index) {
          return Card(
            color: AppTheme.cardDark,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedItems[index],
                    onChanged: (val) {
                      setState(() => _selectedItems[index] = val ?? false);
                    },
                    activeColor: AppTheme.primary,
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameControllers[index],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
                            labelText: 'Item Name',
                            labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _qtyControllers[index],
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
                                  labelText: 'Qty',
                                  labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _priceControllers[index],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixText: getIt<SettingsService>().currency,
                                  prefixStyle: TextStyle(color: Colors.grey[400]),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
                                  labelText: 'Unit Price',
                                  labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
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
