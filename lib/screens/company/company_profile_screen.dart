import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../theme/app_theme.dart';
import '../../models/company_profile.dart';
import '../../services/company_service.dart';
import '../../widgets/top_notification.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  late CompanyProfile _profile;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _industryController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _aboutController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await CompanyService.getProfile();
    setState(() {
      _profile = profile;
      _nameController = TextEditingController(text: profile.name);
      _industryController = TextEditingController(text: profile.industry);
      _locationController = TextEditingController(text: profile.location);
      _websiteController = TextEditingController(text: profile.website);
      _aboutController = TextEditingController(text: profile.about);
      _emailController = TextEditingController(text: profile.email);
      _phoneController = TextEditingController(text: profile.phone);
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedProfile = _profile.copyWith(
      name: _nameController.text,
      industry: _industryController.text,
      location: _locationController.text,
      website: _websiteController.text,
      about: _aboutController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );

    await CompanyService.saveProfile(updatedProfile);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
        _profile = updatedProfile;
      });
      TopNotification.show(
        context,
        message: 'Profile updated successfully!',
        icon: Icons.check_circle,
        color: AppTheme.success,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _aboutController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Company Profile'),
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && !_isEditing)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: SpinKitCubeGrid(color: AppTheme.primary))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section (Simplified)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppTheme.cardDark,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.business,
                              size: 32,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text
                                      : 'Company Name',
                                  style: AppTheme.heading2,
                                ),
                                if (!_isEditing &&
                                    _industryController.text.isNotEmpty)
                                  Text(
                                    _industryController.text,
                                    style: AppTheme.bodyMedium,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      if (_isEditing) ...[
                        // EDIT MODE
                        _buildSectionTitle('General Information'),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Company Name',
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _industryController,
                          label: 'Industry',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _locationController,
                          label: 'Location',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _websiteController,
                          label: 'Website',
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle('About Us'),
                        _buildTextField(
                          controller: _aboutController,
                          label: 'Description',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle('Contact'),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _loadProfile(); // Reset fields
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
                                child:
                                    _isSaving
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Text('Save Changes'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // VIEW MODE (Clean, Data-driven)
                        _buildViewItem(
                          Icons.location_on,
                          'Location',
                          _locationController.text,
                        ),
                        _buildViewItem(
                          Icons.category,
                          'Industry',
                          _industryController.text,
                        ),
                        _buildViewItem(
                          Icons.language,
                          'Website',
                          _websiteController.text,
                        ),
                        const Divider(height: 48, color: AppTheme.surfaceDark),

                        const Text('About', style: AppTheme.heading3),
                        const SizedBox(height: 12),
                        Text(
                          _aboutController.text.isNotEmpty
                              ? _aboutController.text
                              : 'No description provided.',
                          style: AppTheme.bodyLarge.copyWith(
                            height: 1.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),

                        const Divider(height: 48, color: AppTheme.surfaceDark),
                        const Text('Contact', style: AppTheme.heading3),
                        const SizedBox(height: 16),
                        _buildContactCard(
                          _emailController.text,
                          Icons.email,
                          'Email',
                        ),
                        const SizedBox(height: 12),
                        _buildContactCard(
                          _phoneController.text,
                          Icons.phone,
                          'Phone',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: AppTheme.heading3),
    );
  }

  Widget _buildViewItem(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(value, style: AppTheme.bodyLarge),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(String value, IconData icon, String label) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: AppTheme.textMuted) : null,
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            icon == null
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
                : null,
      ),
    );
  }
}
