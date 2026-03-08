import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:payparse/features/company_profile/domain/company_model.dart';
import 'package:payparse/features/company_profile/presentation/company_providers.dart';
import 'package:payparse/features/sms/presentation/sms_list_screen.dart';

class CompanySetupScreen extends ConsumerStatefulWidget {
  final bool isEditing;

  const CompanySetupScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends ConsumerState<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();
  final _bankDetailsController = TextEditingController();
  final _upiController = TextEditingController();

  String? _logoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    final profile = ref.read(companyProfileProvider);
    if (profile != null) {
      _nameController.text = profile.companyName;
      _addressController.text = profile.address;
      _phoneController.text = profile.phone;
      _gstController.text = profile.gstNumber ?? '';
      _bankDetailsController.text = profile.bankDetails ?? '';
      _upiController.text = profile.upiId ?? '';
      _logoPath = profile.logoPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _bankDetailsController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      final notifier = ref.read(companyProfileProvider.notifier);
      final savedPath = await notifier.saveLogo(File(image.path));
      setState(() {
        _logoPath = savedPath;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final profile = CompanyProfile(
      companyName: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      gstNumber:
          _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
      logoPath: _logoPath,
      bankDetails: _bankDetailsController.text.trim().isEmpty
          ? null
          : _bankDetailsController.text.trim(),
      upiId:
          _upiController.text.trim().isEmpty ? null : _upiController.text.trim(),
    );

    await ref.read(companyProfileProvider.notifier).saveProfile(profile);

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (widget.isEditing) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SmsListScreen()),
      );
    }
  }

 @override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return Scaffold(
    appBar: AppBar(
      title: Text(widget.isEditing ? 'Edit Company Profile' : 'Company Setup'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.isEditing) ...[
              Icon(Icons.business_rounded,
                  size: 48, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                'Set up your company profile',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'This information will appear on your invoices',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
            ],

            // Logo picker
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: _logoPath != null && File(_logoPath!).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_logoPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 32, color: colorScheme.primary),
                            const SizedBox(height: 4),
                            Text('Upload Logo',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Company name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address *',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone *',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // GST
            TextFormField(
              controller: _gstController,
              decoration: const InputDecoration(
                labelText: 'GST Number (Optional)',
                prefixIcon: Icon(Icons.receipt),
              ),
            ),
            const SizedBox(height: 16),

            // Bank details
            TextFormField(
              controller: _bankDetailsController,
              decoration: const InputDecoration(
                labelText: 'Bank Details (Optional)',
                prefixIcon: Icon(Icons.account_balance),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // UPI ID
            TextFormField(
              controller: _upiController,
              decoration: const InputDecoration(
                labelText: 'UPI ID (Optional)',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isSaving ? null : _saveProfile,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(
              _isSaving ? 'Saving...' : (widget.isEditing ? 'Update' : 'Continue')),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ),
  );
}
}