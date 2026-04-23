import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../injection.dart';
import '../../../vehicles/presentation/bloc/vehicle_bloc.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';
import '../bloc/expense_log_bloc.dart';
import '../bloc/expense_log_event.dart';
import '../bloc/expense_log_state.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/receipt_parser_service.dart';
import '../../../../core/services/settings_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../data/models/fuel_log_model.dart';
import '../../data/models/maintenance_log_model.dart';

import '../bloc/dashboard_bloc.dart';

class AddExpensePage extends StatefulWidget {
  final DashboardLogItem? existingLog;

  const AddExpensePage({super.key, this.existingLog});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _litersController = TextEditingController();

  String _selectedCategory = 'General';
  DateTime _selectedDate = DateTime.now();
  String? _photoPath;
  bool _isProcessing = false;
  bool _isManualEntry = false;

  final _ocrService = getIt<OCRService>();
  final _parserService = getIt<ReceiptParserService>();

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
    setState(() {
      _isProcessing = true;
      _photoPath = path;
    });

    try {
      final fuelData = await _parserService.parseFuelReceipt(path);
      setState(() {
        if (fuelData.totalAmount != null) {
          _costController.text = fuelData.totalAmount!.toStringAsFixed(2);
        }
        if (fuelData.liters != null) {
          _litersController.text = fuelData.liters!.toString();
        }
        if (fuelData.stationName != null) {
          _notesController.text = 'From ${fuelData.stationName}';
        }
        _isManualEntry = true;
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

  Future<void> _scanOdometer() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final recognizedText = await _ocrService.processImage(inputImage);
      
      // Look for numbers in OCR that could be odometer
      final odoPattern = RegExp(r'(\d{4,6})');
      final match = odoPattern.firstMatch(recognizedText.text);
      
      if (match != null) {
        setState(() {
          _odometerController.text = match.group(1)!;
          _isProcessing = false;
        });
      } else {
        setState(() => _isProcessing = false);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Could not find odometer reading in image')),
           );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      _isManualEntry = true;
      _costController.text = widget.existingLog!.amount.toStringAsFixed(2);
      _notesController.text = widget.existingLog!.subtitle;
      _selectedDate = widget.existingLog!.date;
      
      final log = widget.existingLog!.originalLog;
      if (log is FuelLogModel) {
        _selectedCategory = 'Fuel';
        _odometerController.text = log.odometer.toString();
        _litersController.text = log.liters.toString();
        _photoPath = log.odometerPhotoPath;
      } else if (log is MaintenanceLogModel) {
        _selectedCategory = log.category;
        if (log.odometer != null) {
          _odometerController.text = log.odometer.toString();
        }
        _photoPath = log.photoPath;
      }
    }
  }

  @override
  void dispose() {
    _costController.dispose();
    _odometerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveExpense(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (_costController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a cost')),
        );
        return;
      }

      final cost = double.tryParse(_costController.text);
      if (cost == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid cost')),
        );
        return;
      }

      final odometer = _odometerController.text.isNotEmpty
          ? int.tryParse(_odometerController.text)
          : null;
      
      final liters = _litersController.text.isNotEmpty
          ? double.tryParse(_litersController.text)
          : null;

      final vehicleId = context.read<VehicleBloc>().state.selectedVehicle?.id;

      if (widget.existingLog != null) {
        context.read<ExpenseLogBloc>().add(UpdateExpenseLog(
          id: widget.existingLog!.id,
          cost: cost,
          category: _selectedCategory,
          note: _notesController.text,
          date: _selectedDate,
          odometer: odometer,
          liters: liters,
          photoPath: _photoPath,
          vehicleId: vehicleId,
        ));
      } else {
        context.read<ExpenseLogBloc>().add(SaveExpenseLog(
          cost: cost,
          category: _selectedCategory,
          note: _notesController.text,
          date: _selectedDate,
          odometer: odometer,
          liters: liters,
          photoPath: _photoPath,
          vehicleId: vehicleId,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<ExpenseLogBloc>()),
        BlocProvider(create: (context) => getIt<CategoryBloc>()..add(LoadCategories())),
      ],
      child: BlocListener<ExpenseLogBloc, ExpenseLogState>(
        listener: (context, state) {
          if (state.status == ExpenseLogStatus.saved) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Expense saved successfully!')),
             );
             Navigator.of(context).pop();
          } else if (state.status == ExpenseLogStatus.error) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
             );
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Text(
                        widget.existingLog != null ? 'Edit Expense' : 'Add Expense',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer
                    ],
                  ),
                ),

                Expanded(
                  child: _isProcessing
                      ? const Center(child: CircularProgressIndicator())
                      : !_isManualEntry
                          ? _buildScanPrompt()
                          : Form(
                              key: _formKey,
                              child: ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                        // Cost Input
                        Center(
                          child: Column(
                            children: [
                              SizedBox(
                                width: 200,
                                child: TextFormField(
                                  controller: _costController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                    ),
                                    prefixText: '${getIt<SettingsService>().currency} ',
                                    prefixStyle: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                'Enter amount',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Category Selector
                        Text(
                          'Category',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        BlocBuilder<CategoryBloc, CategoryState>(
                          builder: (context, state) {
                            if (state.status == CategoryStatus.loading && state.categories.isEmpty) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            bool selectedCatExists = state.categories.any((cat) => cat.name == _selectedCategory);

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ...state.categories.map((cat) => Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: _buildCategoryChip(cat.name, IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons')),
                                  )),
                                  if (!selectedCatExists && _selectedCategory.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: _buildCategoryChip(_selectedCategory, Icons.label),
                                    ),
                                  _buildAddCategoryChip(context),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Receipt Attachment
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setState(() {
                                _photoPath = pickedFile.path;
                              });
                            }
                          },
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Center(
                              child: _photoPath != null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 32),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Receipt Attached',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to change',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Attach Receipt / Bill',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.center_focus_strong, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Auto-scan enabled',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Details Form
                        _buildLabel('Date'),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                              });
                            }
                          },
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).inputDecorationTheme.fillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: Theme.of(context).hintColor),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat(getIt<SettingsService>().dateFormat).format(_selectedDate),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Odometer (Optional)'),
                        TextFormField(
                          controller: _odometerController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.speed),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: _scanOdometer,
                            ),
                            suffixText: 'km', // or mi
                            hintText: 'e.g., 45,200',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_selectedCategory.toLowerCase() == 'fuel' || _selectedCategory.toLowerCase() == 'petrol') ...[
                          _buildLabel('Liters'),
                          TextFormField(
                            controller: _litersController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.gas_meter),
                              suffixText: 'L',
                              hintText: 'e.g., 15.5',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        _buildLabel('Notes'),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Describe the service details...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 100), // Bottom spacer
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomSheet: !_isManualEntry ? null : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: SafeArea(
              child: Builder(
                builder: (context) {
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _saveExpense(context),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: BlocBuilder<ExpenseLogBloc, ExpenseLogState>(
                        builder: (context, state) {
                          if (state.status == ExpenseLogStatus.saving) {
                            return const CircularProgressIndicator(color: Colors.white);
                          }
                          return Text(
                            'Save Expense',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'General': return Icons.category;
      case 'Maintenance': return Icons.car_repair;
      case 'Repair': return Icons.build;
      case 'Insurance': return Icons.security;
      case 'Fuel': return Icons.local_gas_station;
      case 'Misc': return Icons.more_horiz;
      default: return Icons.label_important;
    }
  }

  Widget _buildAddCategoryChip(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddCategoryDialog(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(
          Icons.add,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newCatName = controller.text.trim();
                context.read<CategoryBloc>().add(AddUserCategory(
                  name: newCatName,
                  iconCodePoint: Icons.label.codePoint,
                ));
                setState(() {
                  _selectedCategory = newCatName;
                });
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.transparent : theme.dividerColor,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Expense',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'How would you like to add your expense?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _scanImage,
                icon: const Icon(Icons.camera_alt),
                label: Text('Take Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.image),
                label: Text('Pick from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _isManualEntry = true),
              child: Text('Enter Manually', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
