import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/groups_provider.dart';
import 'create_group_screen.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(groupsProvider.notifier).fetchGroups(),
          ),
        ],
      ),
      body: groupsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupsState.errorMessage != null
              ? Center(child: Text('Error: ${groupsState.errorMessage}'))
              : groupsState.groups.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      itemCount: groupsState.groups.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final group = groupsState.groups[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(group.name[0].toUpperCase()),
                            ),
                            title: Text(group.name),
                            subtitle: const Text('Tap to view expenses'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // TODO: Navigate to Group Detail Screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Opening ${group.name}...')),
                              );
                            },
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
        },
        child: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_off_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Groups Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Create a group to start sharing expenses.'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Group'),
          ),
        ],
      ),
    );
  }
}