import 'package:flutter/material.dart';

class MedicalRecordSearchDelegate extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> allMHEntry;
  final BuildContext outercontext;
  Function(BuildContext outercontext, Map<String, dynamic>) onSelected;
  Function(BuildContext outercontext, Map<String, dynamic>) onEdit;
  MedicalRecordSearchDelegate(
    this.allMHEntry,
    this.outercontext,
    this.onSelected,
    this.onEdit,
  );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, {});
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final List<Map<String, dynamic>> results = allMHEntry.where((entry) {
      final name = entry['name']?.toString() ?? '';
      final age = entry['age']?.toString() ?? '';
      final uuid = entry['uuid']?.toString() ?? '';

      return name.toLowerCase().contains(query.toLowerCase()) ||
          age.toLowerCase().contains(query.toLowerCase()) ||
          uuid.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final entry = results[index];
        return InkWell(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                title: Text(entry['name'] == '' ? '未命名' : entry['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry['age'].toString().isNotEmpty)
                      Text('年龄: ${entry['age']}'),
                    Text(
                      'UUID: ${entry['uuid']?.toString().substring(0, 8)}...',
                    ),
                    Text('创建时间: ${_formatDate(entry['created_at'])}'),
                  ],
                ),
                trailing: IconButton(
                  onPressed: () {
                    onEdit(outercontext, entry);
                  },
                  icon: Icon(Icons.info),
                ),
              ),
            ),
          ),
          onTap: () {
            onSelected(outercontext, entry);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<Map<String, dynamic>> suggestions = query.isEmpty
        ? allMHEntry
        : allMHEntry.where((entry) {
            final name = entry['name']?.toString() ?? '';
            final age = entry['age']?.toString() ?? '';
            final uuid = entry['uuid']?.toString() ?? '';

            return name.toLowerCase().contains(query.toLowerCase()) ||
                age.toLowerCase().contains(query.toLowerCase()) ||
                uuid.toLowerCase().contains(query.toLowerCase());
          }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final entry = suggestions[index];
        return ListTile(
          title: Text(entry['name'] == '' ? '未命名' : entry['name']),
          subtitle: Text(
            '年龄: ${entry['age']?.toString()}UUID: ${entry['uuid']?.toString().substring(0, 8)}...',
          ),
          onTap: () {
            query =
                entry['name']?.toString() ?? entry['uuid']?.toString() ?? '';
            showResults(context);
          },
        );
      },
    );
  }

  // 辅助方法：格式化时间戳为可读日期
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '未知时间';
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp is String ? int.tryParse(timestamp) ?? 0 : timestamp as int,
    );
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
