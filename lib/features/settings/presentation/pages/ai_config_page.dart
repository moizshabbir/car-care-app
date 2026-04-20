import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../injection.dart';

class AiConfigPage extends StatefulWidget {
  const AiConfigPage({super.key});

  @override
  State<AiConfigPage> createState() => _AiConfigPageState();
}

class _AiConfigPageState extends State<AiConfigPage> {
  final _settingsService = getIt<SettingsService>();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _baseUrlController.text = _settingsService.aiBaseUrl;
    _apiKeyController.text = _settingsService.aiApiKey;
    _modelController.text = _settingsService.aiModel;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    await _settingsService.setAiBaseUrl(_baseUrlController.text.trim());
    await _settingsService.setAiApiKey(_apiKeyController.text.trim());
    await _settingsService.setAiModel(_modelController.text.trim());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Configuration saved')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('AI Configuration', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom AI Model (OpenAI Compatible)',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'If configured, this will overwrite the default Gemini model used for OCR. Leave blank to use default.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Base URL',
              controller: _baseUrlController,
              hint: 'https://api.openai.com/v1',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'API Key',
              controller: _apiKeyController,
              hint: 'sk-...',
              obscure: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Model Name',
              controller: _modelController,
              hint: 'gpt-4o',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Configuration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _baseUrlController.clear();
                _apiKeyController.clear();
                _modelController.clear();
              },
              child: const Center(child: Text('Reset to Default', style: TextStyle(color: Colors.redAccent))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: AppTheme.cardDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
