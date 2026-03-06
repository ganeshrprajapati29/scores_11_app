import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  String _selectedSport = 'Cricket';
  String _selectedCategory = 'Amateur';
  bool _isPublic = true;
  bool _isLoading = false;
  
  final List<String> _sports = ['Cricket', 'Football', 'Basketball', 'Volleyball'];
  final List<String> _categories = ['Professional', 'Amateur', 'Recreational', 'School'];

  @override
  void dispose() {
    _teamNameController.dispose();
    _shortNameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Team'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Icon(
                        Icons.group,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 24),
              
              // Team Name
              const Text('Team Name *', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _teamNameController,
                hintText: 'Enter team name',
                prefixIcon: Icons.group,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter team name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Short Name
              const Text('Short Name *', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _shortNameController,
                hintText: 'e.g., MI, CSK',
                prefixIcon: Icons.label,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter short name';
                  }
                  if (value.length > 5) {
                    return 'Short name should be max 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              const Text('Description', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Tell us about your team',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Sport & Category
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sport', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedSport,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: _sports.map((sport) => DropdownMenuItem(
                              value: sport,
                              child: Text(sport),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedSport = value!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: _categories.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedCategory = value!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // City
              const Text('City', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _cityController,
                hintText: 'Enter city',
                prefixIcon: Icons.location_city,
              ),
              const SizedBox(height: 16),
              
              // Team Visibility
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Public Team', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          _isPublic ? 'Anyone can find and join' : 'Only invited players can join',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
              
              // Create Button
              CustomButton(
                text: 'Create Team',
                onPressed: _createTeam,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

