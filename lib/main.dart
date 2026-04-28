import 'package:flutter/material.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF256B5F)),
        useMaterial3: true,
      ),
      home: const CareerKitDashboardPage(),
    );
  }
}

enum CareerRole {
  internship('Internship'),
  juniorDeveloper('Junior Developer'),
  general('General');

  const CareerRole(this.label);

  final String label;
}

class CvCheckResult {
  const CvCheckResult({
    required this.score,
    required this.message,
  });

  final int score;
  final String message;
}

class CareerKitDashboardPage extends StatefulWidget {
  const CareerKitDashboardPage({super.key});

  @override
  State<CareerKitDashboardPage> createState() => _CareerKitDashboardPageState();
}

class _CareerKitDashboardPageState extends State<CareerKitDashboardPage> {
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController projectsController = TextEditingController();

  CareerRole selectedRole = CareerRole.internship;

  bool hasContactInfo = false;
  bool hasEducation = false;
  bool hasSkillsSection = false;
  bool hasProjectsSection = false;

  CvCheckResult result = const CvCheckResult(score: 0, message: '');

  @override
  void dispose() {
    skillsController.dispose();
    projectsController.dispose();
    super.dispose();
  }

  void checkCv() {
    final skills = int.tryParse(skillsController.text) ?? 0;
    final projects = int.tryParse(projectsController.text) ?? 0;

    int newScore = 0;
    if (hasContactInfo) newScore += 20;
    if (hasEducation) newScore += 20;
    if (hasSkillsSection) newScore += 20;
    if (hasProjectsSection) newScore += 20;
    if (skills >= 3) newScore += 10;
    if (projects >= 1) newScore += 10;

    final message = switch (newScore) {
      >= 80 => 'Your CV looks ready.',
      >= 50 => 'Your CV is okay but needs some improvement.',
      _ => 'Your CV needs improvement.',
    };

    setState(() {
      result = CvCheckResult(score: newScore, message: message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareerKit Mobile Dashboard'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 720 ? 720.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _SectionTitle('Target Role'),
                  _RoleDropdown(
                    selectedRole: selectedRole,
                    onSelected: (role) {
                      setState(() {
                        selectedRole = role;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _NumberInput(
                    key: const ValueKey('skillsField'),
                    controller: skillsController,
                    label: 'Number of skills',
                  ),
                  const SizedBox(height: 12),
                  _NumberInput(
                    key: const ValueKey('projectsField'),
                    controller: projectsController,
                    label: 'Number of projects',
                  ),
                  const SizedBox(height: 16),
                  _ChecklistTile(
                    key: const ValueKey('contactCheckbox'),
                    title: 'Contact information included',
                    value: hasContactInfo,
                    onChanged: (value) {
                      setState(() {
                        hasContactInfo = value;
                      });
                    },
                  ),
                  _ChecklistTile(
                    key: const ValueKey('educationCheckbox'),
                    title: 'Education section included',
                    value: hasEducation,
                    onChanged: (value) {
                      setState(() {
                        hasEducation = value;
                      });
                    },
                  ),
                  _ChecklistTile(
                    key: const ValueKey('skillsCheckbox'),
                    title: 'Skills section included',
                    value: hasSkillsSection,
                    onChanged: (value) {
                      setState(() {
                        hasSkillsSection = value;
                      });
                    },
                  ),
                  _ChecklistTile(
                    key: const ValueKey('projectsCheckbox'),
                    title: 'Projects section included',
                    value: hasProjectsSection,
                    onChanged: (value) {
                      setState(() {
                        hasProjectsSection = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('checkCvButton'),
                    onPressed: checkCv,
                    child: const Text('Check CV'),
                  ),
                  const SizedBox(height: 20),
                  _ResultCard(
                    key: const ValueKey('resultCard'),
                    role: selectedRole.label,
                    result: result,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.selectedRole,
    required this.onSelected,
  });

  final CareerRole selectedRole;
  final ValueChanged<CareerRole> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<CareerRole>(
          initialSelection: selectedRole,
          width: constraints.maxWidth,
          onSelected: (role) {
            if (role != null) {
              onSelected(role);
            }
          },
          dropdownMenuEntries: [
            for (final role in CareerRole.values)
              DropdownMenuEntry(value: role, label: role.label),
          ],
        );
      },
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: (value) {
        onChanged(value ?? false);
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    super.key,
    required this.role,
    required this.result,
  });

  final String role;
  final CvCheckResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role: $role',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${result.score} / 100',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (result.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(result.message),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
