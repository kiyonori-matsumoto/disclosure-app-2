import 'package:disclosure_app_fl/providers/saved_disclosures_provider.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

class SavedDisclosuresScreen extends ConsumerWidget {
  const SavedDisclosuresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("保存したドキュメント"),
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(savedDisclosuresStreamProvider);

    return streamAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Center(
        child: Text('エラーが発生しました: $error'),
      ),
      data: (docs) {
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              '保存されたドキュメントはありません',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final grouped = ref.watch(groupedSavedDisclosuresProvider);

        return CustomScrollView(
          slivers: grouped.entries
              .map((entry) => SliverStickyHeader(
                    header: Container(
                      height: 50.0,
                      color: Theme.of(context).scaffoldBackgroundColor,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text(
                        '追加日: ${entry.key}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final item = entry.value[i];
                          final data = item.data();
                          return Dismissible(
                            key: Key(data['document'] as String? ?? item.id),
                            child: DisclosureListItem(
                              item: item,
                              showDate: true,
                            ),
                            onDismissed: (direction) {
                              final entryBack = item.data();
                              final entryRef = item.reference;
                              final action = ref.read(
                                savedDisclosuresActionProvider.notifier,
                              );
                              action.delete(entryRef);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('削除しました'),
                                  action: SnackBarAction(
                                    onPressed: () {
                                      action.restore(entryRef, entryBack);
                                    },
                                    label: "取り消す",
                                  ),
                                ),
                              );
                            },
                            background: Container(
                              color: Colors.green,
                            ),
                          );
                        },
                        childCount: entry.value.length,
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
