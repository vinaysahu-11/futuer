import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/insforge_service.dart';

/// Screen displayed when user is successfully authenticated.
/// Provides database management actions (CRUD) and session info.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tableController = TextEditingController(text: 'tasks');
  List<Map<String, dynamic>> _records = [];
  bool _isLoadingRecords = false;
  String? _recordsError;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  @override
  void dispose() {
    _tableController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecords() async {
    final tableName = _tableController.text.trim();
    if (tableName.isEmpty) return;

    setState(() {
      _isLoadingRecords = true;
      _recordsError = null;
    });

    try {
      final data = await DatabaseService.instance.fetchRecords(
        tableName: tableName,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _records = data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recordsError = e.toString();
          _records = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecords = false;
        });
      }
    }
  }

  Future<void> _showAddRecordDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Insert Record into "${_tableController.text.trim()}"'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description / Content',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();

              try {
                await DatabaseService.instance.insertRecord(
                  tableName: _tableController.text.trim(),
                  data: {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'user_id': AuthService.instance.currentUser?.id,
                  },
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Record added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _fetchRecords();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Insert failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(dynamic id) async {
    try {
      await DatabaseService.instance.deleteRecord(
        tableName: _tableController.text.trim(),
        idColumn: 'id',
        idValue: id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted!')),
        );
        _fetchRecords();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;
    final activeUrl = InsforgeService.instance.activeUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('InsForge App Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRecords,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User profile & session card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? user?.email ?? 'Authenticated User',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  user?.email ?? '',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            avatar: const Icon(Icons.security, size: 16),
                            label: const Text('Authenticated'),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        'User ID: ${user?.id ?? "N/A"}',
                        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Backend: $activeUrl',
                        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Database Operations Card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.table_chart_outlined, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Database Table Explorer',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _showAddRecordDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Row'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tableController,
                              decoration: const InputDecoration(
                                labelText: 'PostgreSQL Table Name',
                                hintText: 'tasks, notes, items...',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Query Table',
                            onPressed: _isLoadingRecords ? null : _fetchRecords,
                            icon: _isLoadingRecords
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Results or Error view
              if (_recordsError != null) ...[
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                            const SizedBox(width: 8),
                            Text(
                              'Database Query Note / Error',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recordsError!,
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tip: Ensure the table "${_tableController.text.trim()}" exists in your InsForge database and that Row Level Security (RLS) policies permit operations.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_records.isEmpty && !_isLoadingRecords) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No records found in "${_tableController.text.trim()}"',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Add Row" above or query another table created in your InsForge database.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Records (${_records.length}):',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final row = _records[index];
                    final title = row['title'] ?? row['name'] ?? row['id'] ?? 'Row #$index';
                    final subtitle = row['description'] ?? row['content'] ?? row.toString();
                    final id = row['id'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(title.toString()),
                        subtitle: Text(
                          subtitle.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: id != null
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Delete Row',
                                onPressed: () => _deleteRecord(id),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
