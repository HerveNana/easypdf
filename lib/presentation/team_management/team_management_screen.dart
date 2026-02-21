import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/collaboration_service.dart';
import '../../widgets/custom_icon_widget.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final CollaborationService _collaborationService =
      CollaborationService.instance;
  final TextEditingController _teamNameController = TextEditingController();

  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);

    try {
      final teams = await _collaborationService.getTeams();
      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load teams: $e')));
      }
    }
  }

  Future<void> _createTeam() async {
    if (_teamNameController.text.trim().isEmpty) return;

    try {
      await _collaborationService.createTeam(_teamNameController.text.trim());
      _teamNameController.clear();
      await _loadTeams();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create team: $e')));
      }
    }
  }

  void _showCreateTeamDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        return AlertDialog(
          title: Text('Create Team'),
          content: TextField(
            controller: _teamNameController,
            decoration: InputDecoration(
              hintText: 'Team name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _createTeam,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Teams',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'add',
              color: theme.colorScheme.primary,
            ),
            onPressed: _showCreateTeamDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _teams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'groups_outlined',
                    size: 48.sp,
                    color: theme.colorScheme.onSurface.withAlpha(77),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No teams yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  TextButton.icon(
                    onPressed: _showCreateTeamDialog,
                    icon: Icon(Icons.add),
                    label: Text('Create Team'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                final team = _teams[index];
                final memberCount =
                    (team['team_members'] as List?)?.length ?? 0;

                return Card(
                  margin: EdgeInsets.only(bottom: 2.h),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: CustomIconWidget(
                        iconName: 'group',
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20.sp,
                      ),
                    ),
                    title: Text(
                      team['name'] as String,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '$memberCount members',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: CustomIconWidget(
                      iconName: 'arrow_forward_ios',
                      size: 16.sp,
                      color: theme.colorScheme.onSurface.withAlpha(128),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Team Details'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Team: ${team['name']}'),
                              SizedBox(height: 1.h),
                              Text('Members: $memberCount'),
                              SizedBox(height: 1.h),
                              Text(
                                'Created: ${team['created_at'] ?? 'Unknown'}',
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
