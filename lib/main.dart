import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// For deployed backend:
const String apiBaseUrl = 'https://careerkit-api-production.up.railway.app/api';

void main() {
  // Ensure system UI is configured correctly
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CareerKitApp());
}

class CareerKitApp extends StatelessWidget {
  const CareerKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareerKit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF256B5F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 70, // Slightly taller for better hit testing
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56), // Standard touch target height
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const CareerKitHomePage(),
    );
  }
}

class CareerProfile {
  CareerProfile({
    this.id,
    required this.fullName,
    required this.targetRole,
    required this.skillsCount,
    required this.projectsCount,
    required this.hasContact,
    required this.hasEducation,
    required this.hasSkillsSection,
    required this.hasProjectsSection,
    this.readinessScore = 0,
    this.feedback = '',
  });

  final int? id;
  final String fullName;
  final String targetRole;
  final int skillsCount;
  final int projectsCount;
  final bool hasContact;
  final bool hasEducation;
  final bool hasSkillsSection;
  final bool hasProjectsSection;
  final int readinessScore;
  final String feedback;

  factory CareerProfile.fromJson(Map<String, dynamic> json) {
    bool asBool(dynamic value) => value == true || value == 1 || value == '1';
    int asInt(dynamic value) => int.tryParse(value.toString()) ?? 0;

    return CareerProfile(
      id: asInt(json['id']),
      fullName: json['full_name']?.toString() ?? '',
      targetRole: json['target_role']?.toString() ?? 'General',
      skillsCount: asInt(json['skills_count']),
      projectsCount: asInt(json['projects_count']),
      hasContact: asBool(json['has_contact']),
      hasEducation: asBool(json['has_education']),
      hasSkillsSection: asBool(json['has_skills_section']),
      hasProjectsSection: asBool(json['has_projects_section']),
      readinessScore: asInt(json['readiness_score']),
      feedback: json['feedback']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'target_role': targetRole,
      'skills_count': skillsCount,
      'projects_count': projectsCount,
      'has_contact': hasContact,
      'has_education': hasEducation,
      'has_skills_section': hasSkillsSection,
      'has_projects_section': hasProjectsSection,
    };
  }
}

class CareerKitApi {
  Future<List<CareerProfile>> getProfiles() async {
    final response = await http
        .get(Uri.parse('$apiBaseUrl/profiles'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => CareerProfile.fromJson(item)).toList();
  }

  Future<CareerProfile> createProfile(CareerProfile profile) async {
    final response = await http
        .post(
          Uri.parse('$apiBaseUrl/profiles'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(profile.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 201) {
      throw Exception('Server error: ${response.statusCode}');
    }
    return CareerProfile.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteProfile(int id) async {
    final response = await http
        .delete(Uri.parse('$apiBaseUrl/profiles/$id'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}

class CareerKitHomePage extends StatefulWidget {
  const CareerKitHomePage({super.key});

  @override
  State<CareerKitHomePage> createState() => _CareerKitHomePageState();
}

class _CareerKitHomePageState extends State<CareerKitHomePage> {
  int _selectedIndex = 0;
  final _api = CareerKitApi();
  final _profilesKey = GlobalKey<_ProfilesViewState>();

  void _onSaveSuccess() {
    setState(() => _selectedIndex = 1);
    _profilesKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    // PopScope handles the back button at the root of the app
    return PopScope(
      canPop: _selectedIndex == 0, // Allow pop only if on the first tab
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // If it was allowed to pop, do nothing
        // Otherwise, switch back to the first tab (Dashboard)
        setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedIndex == 0 ? 'CareerKit Dashboard' : 'Saved Profiles'),
          actions: _selectedIndex == 1
              ? [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _profilesKey.currentState?.refresh();
                    },
                    icon: const Icon(Icons.refresh),
                  )
                ]
              : null,
        ),
        body: SafeArea(
          bottom: false, // NavigationBar handles the bottom padding
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardView(api: _api, onSaveSuccess: _onSaveSuccess),
              ProfilesView(key: _profilesKey, api: _api),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Profiles',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key, required this.api, required this.onSaveSuccess});
  final CareerKitApi api;
  final VoidCallback onSaveSuccess;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skillsController = TextEditingController(text: '0');
  final _projectsController = TextEditingController(text: '0');

  String _selectedRole = 'Internship';
  bool _hasContact = false;
  bool _hasEducation = false;
  bool _hasSkillsSection = false;
  bool _hasProjectsSection = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _skillsController.dispose();
    _projectsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    setState(() => _isSaving = true);
    try {
      final profile = CareerProfile(
        fullName: _nameController.text.trim(),
        targetRole: _selectedRole,
        skillsCount: int.tryParse(_skillsController.text) ?? 0,
        projectsCount: int.tryParse(_projectsController.text) ?? 0,
        hasContact: _hasContact,
        hasEducation: _hasEducation,
        hasSkillsSection: _hasSkillsSection,
        hasProjectsSection: _hasProjectsSection,
      );
      await widget.api.createProfile(profile);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!'), behavior: SnackBarBehavior.floating),
      );
      widget.onSaveSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Text(
                'New Profile',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Target Role',
                  prefixIcon: Icon(Icons.work_outline),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Internship', child: Text('Internship')),
                  DropdownMenuItem(value: 'Junior Developer', child: Text('Junior Developer')),
                  DropdownMenuItem(value: 'General', child: Text('General')),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillsController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Skills',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _projectsController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Projects',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Contact Details'),
                value: _hasContact,
                onChanged: (v) => setState(() => _hasContact = v),
              ),
              SwitchListTile(
                title: const Text('Education Hist.'),
                value: _hasEducation,
                onChanged: (v) => setState(() => _hasEducation = v),
              ),
              SwitchListTile(
                title: const Text('Skills List'),
                value: _hasSkillsSection,
                onChanged: (v) => setState(() => _hasSkillsSection = v),
              ),
              SwitchListTile(
                title: const Text('Project List'),
                value: _hasProjectsSection,
                onChanged: (v) => setState(() => _hasProjectsSection = v),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_done_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Verify & Save'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfilesView extends StatefulWidget {
  const ProfilesView({super.key, required this.api});
  final CareerKitApi api;

  @override
  State<ProfilesView> createState() => _ProfilesViewState();
}

class _ProfilesViewState extends State<ProfilesView> {
  late Future<List<CareerProfile>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    setState(() {
      _profilesFuture = widget.api.getProfiles();
    });
  }

  Future<void> _delete(int id) async {
    HapticFeedback.heavyImpact();
    try {
      await widget.api.deleteProfile(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile deleted'), behavior: SnackBarBehavior.floating),
      );
      refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CareerProfile>>(
      future: _profilesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Connection Issue', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }
        final profiles = snapshot.data ?? [];
        if (profiles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.list_alt, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No profiles found', style: TextStyle(color: Colors.grey, fontSize: 18)),
                const SizedBox(height: 8),
                TextButton(onPressed: refresh, child: const Text('Refresh List')),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final p = profiles[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${p.targetRole} • Readiness: ${p.readinessScore}%\n${p.feedback}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _delete(p.id!),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
