import 'package:disclosure_app_fl/providers/tag_disclosures_provider.dart';
import 'package:disclosure_app_fl/widgets/banner_ad.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:disclosure_app_fl/widgets/no_disclosures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisclosureTagsScreen extends ConsumerWidget {
  final String? tag;

  const DisclosureTagsScreen({super.key, this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTag = tag ?? '';
    final disclosuresAsync = ref.watch(tagDisclosuresProvider(currentTag));

    return Scaffold(
      appBar: AppBar(
        title: Text("$currentTagの通知履歴"),
      ),
      body: disclosuresAsync.when(
        loading: () => const Column(
          children: <Widget>[
            LinearProgressIndicator(),
          ],
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.event_busy, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(error.toString()),
            ],
          ),
        ),
        data: (paginated) {
          final docs = paginated.docs;
          if (docs.isEmpty) {
            return const NoDisclosures();
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(tagDisclosuresProvider(currentTag).notifier).refresh(),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = docs[index];
                      final docKey = doc.id;
                      return DisclosureListItem(
                        item: doc,
                        showDate: true,
                        key: Key(docKey),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
                if (paginated.hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 24.0),
                      child: ElevatedButton(
                        onPressed: paginated.isLoadingMore
                            ? null
                            : () => ref
                                .read(tagDisclosuresProvider(currentTag).notifier)
                                .loadMore(),
                        child: paginated.isLoadingMore
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('更に読み込む'),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
