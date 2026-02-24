import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../injection.dart';
import '../bloc/expense_log_bloc.dart';
import '../bloc/expense_log_event.dart';
import '../bloc/expense_log_state.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'Maintenance';
  DateTime _selectedDate = DateTime.now();
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _costController.addListener(_validateForm);
    _odometerController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _costController.removeListener(_validateForm);
    _odometerController.removeListener(_validateForm);
    _costController.dispose();
    _odometerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final cost = double.tryParse(_costController.text);
    final isCostValid = cost != null && cost > 0;

    final odometerText = _odometerController.text;
    final isOdometerValid =
        odometerText.isEmpty || int.tryParse(odometerText) != null;

    final isValid = isCostValid && isOdometerValid;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _saveExpense(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (!_isFormValid) return;

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

      context.read<ExpenseLogBloc>().add(SaveExpenseLog(
        cost: cost,
        category: _selectedCategory,
        note: _notesController.text,
        date: _selectedDate,
        odometer: odometer,
        photoPath: null, // Image picking not implemented yet
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inject Bloc manually since getIt factory is registered
    return BlocProvider(
      create: (context) => getIt<ExpenseLogBloc>(),
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
                        'Add Expense',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer
                    ],
                  ),
                ),

                Expanded(
                  child: Form(
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
                                    color: Theme.of(context).colorScheme.onBackground,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                    ),
                                    prefixText: '\$ ',
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
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCategoryChip('Repair', Icons.build),
                              const SizedBox(width: 12),
                              _buildCategoryChip('Maintenance', Icons.car_repair),
                              const SizedBox(width: 12),
                              _buildCategoryChip('Insurance', Icons.security),
                              const SizedBox(width: 12),
                              _buildCategoryChip('Misc', Icons.more_horiz),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Receipt Attachment (Placeholder)
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              style: BorderStyle.solid, // Dashed not directly supported by Border.all easily without CustomPaint or package, sticking to solid/light for now or DottedBorder if I had package
                            ),
                          ),
                          child: Center(
                            child: Column(
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
                                  DateFormat.yMMMd().format(_selectedDate),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onBackground,
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
                            suffixText: 'km', // or mi
                            hintText: 'e.g., 45,200',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

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
          bottomSheet: Container(
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
                      onPressed: _isFormValid ? () => _saveExpense(context) : null,
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
}
