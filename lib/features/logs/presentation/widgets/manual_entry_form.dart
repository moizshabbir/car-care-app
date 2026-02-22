import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/quick_log_bloc.dart';
import '../bloc/quick_log_event.dart';
import '../bloc/quick_log_state.dart';

class ManualEntryForm extends StatefulWidget {
  const ManualEntryForm({super.key});

  @override
  State<ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<ManualEntryForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _odometerController;
  late TextEditingController _litersController;
  late TextEditingController _costController;

  @override
  void initState() {
    super.initState();
    final state = context.read<QuickLogBloc>().state;
    _odometerController = TextEditingController(text: state.odometer?.toString() ?? '');
    _litersController = TextEditingController(text: state.liters?.toString() ?? '');
    _costController = TextEditingController(text: state.cost?.toString() ?? '');
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _litersController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuickLogBloc, QuickLogState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == QuickLogStatus.saved) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Log saved successfully!')),
           );
           Navigator.of(context).pop();
        } else if (state.status == QuickLogStatus.error) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
           );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _odometerController,
                decoration: const InputDecoration(labelText: 'Odometer (km)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Must be an integer';
                  return null;
                },
              ),
              TextFormField(
                controller: _litersController,
                decoration: const InputDecoration(labelText: 'Liters (L)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Must be a number';
                  return null;
                },
              ),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Total Cost'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              BlocBuilder<QuickLogBloc, QuickLogState>(
                builder: (context, state) {
                  if (state.status == QuickLogStatus.saving) {
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<QuickLogBloc>().add(SaveLog(
                          odometer: int.parse(_odometerController.text),
                          liters: double.parse(_litersController.text),
                          cost: double.parse(_costController.text),
                        ));
                      }
                    },
                    child: const Text('Save Log'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
