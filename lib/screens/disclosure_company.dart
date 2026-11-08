import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/company_disclosures_provider.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/widgets/banner_ad.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:disclosure_app_fl/widgets/edinet_streaming.dart';
import 'package:disclosure_app_fl/widgets/no_disclosures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisclosureCompanyScreen extends ConsumerWidget {
  final Company? company;

  const DisclosureCompanyScreen({super.key, this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialCode = company?.code?.trim() ?? '';
    final normalizedCode =
        initialCode.length > 4 ? initialCode.substring(0, 4) : initialCode;

    // 企業マスタ（companyCodeMapProvider）から企業情報を補完・解決
    final codeMap = ref.watch(companyCodeMapProvider);
    final matchedCompany = codeMap[initialCode] ??
        (normalizedCode.isNotEmpty ? codeMap[normalizedCode] : null) ??
        company;

    final companyName = (company?.name ?? '').isNotEmpty
        ? company!.name!
        : (matchedCompany?.name ?? '');
    final companyCode = initialCode.isNotEmpty
        ? initialCode
        : (matchedCompany?.code ?? '');
    final edinetCode = (company?.edinetCode ?? '').isNotEmpty
        ? company!.edinetCode!
        : (matchedCompany?.edinetCode ?? '');
    final hasEdinet = edinetCode.isNotEmpty;
    final tabLength = hasEdinet ? 2 : 1;

    final title = companyName.isNotEmpty
        ? (companyCode.isNotEmpty ? "$companyName ($companyCode)" : companyName)
        : (companyCode.isNotEmpty ? companyCode : '会社詳細');

    return DefaultTabController(
      length: tabLength,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            if (companyCode.isNotEmpty)
              IconButton(
                icon: Icon(
                  ref.watch(isFavoriteProvider(companyCode))
                      ? Icons.star
                      : Icons.star_border,
                ),
                tooltip: 'お気に入り',
                onPressed: () {
                  final uid = ref.read(currentUserProvider)?.uid;
                  final isFavorite = ref.read(isFavoriteProvider(companyCode));
                  if (uid != null) {
                    ref
                        .read(favoritesActionProvider.notifier)
                        .toggle(uid, companyCode, isFavorite: isFavorite);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isFavorite
                          ? 'お気に入りを解除しました'
                          : 'お気に入りに追加しました'),
                    ));
                  }
                },
              ),
          ],
          bottom: TabBar(tabs: <Widget>[
            const Tab(text: 'TDNET'),
            if (hasEdinet) const Tab(text: 'EDINET'),
          ]),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildTdnetBody(context, ref, companyCode),
            if (hasEdinet) _buildEdinetBody(context, ref, edinetCode),
          ],
        ),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }

  Widget _buildTdnetBody(BuildContext context, WidgetRef ref, String code) {
    if (code.isEmpty) {
      return const NoDisclosures();
    }

    final disclosuresAsync = ref.watch(companyDisclosuresProvider(code));
    final settlementAsync = ref.watch(companySettlementProvider(code));

    return disclosuresAsync.when(
      loading: () => const Column(
        children: <Widget>[
          LinearProgressIndicator(),
        ],
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Icon(Icons.error_outline, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text('開示情報の取得に失敗しました'),
          ],
        ),
      ),
      data: (state) {
        final docs = state.docs;
        if (docs.isEmpty) {
          return const NoDisclosures();
        }

        final settlement = settlementAsync.value;
        final hasValidSettlement = settlement != null &&
            settlement.schedule != null &&
            !settlement.schedule!
                .add(const Duration(days: 1))
                .isBefore(DateTime.now());

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(companyDisclosuresProvider(code).notifier).refresh(),
          child: CustomScrollView(
            slivers: <Widget>[
              if (hasValidSettlement)
                SliverToBoxAdapter(
                  child: Card(
                    shape: const RoundedRectangleBorder(),
                    child: ListTile(
                      leading: Icon(
                        Icons.announcement,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(settlement.toMessage()),
                    ),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final docKey = data?['document']?.toString() ?? doc.id;
                    return DisclosureListItem(
                      item: doc,
                      showDate: true,
                      key: Key(docKey),
                    );
                  },
                  childCount: docs.length,
                ),
              ),
              if (state.hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 24.0),
                    child: ElevatedButton(
                      onPressed: state.isLoadingMore
                          ? null
                          : () => ref
                              .read(companyDisclosuresProvider(code).notifier)
                              .loadMore(),
                      child: state.isLoadingMore
                          ? const SizedBox(
                              width: 20,
                              height: 20,
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
    );
  }

  Widget _buildEdinetBody(
      BuildContext context, WidgetRef ref, String edinetCode) {
    if (edinetCode.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: const Text("選択した条件の適時開示は0件です"),
      );
    }

    final edinetAsync = ref.watch(companyEdinetsProvider(edinetCode));

    return edinetAsync.when(
      loading: () => const Column(
        children: <Widget>[
          LinearProgressIndicator(),
        ],
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Icon(Icons.error_outline, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text('EDINET開示の取得に失敗しました'),
          ],
        ),
      ),
      data: (state) {
        final items = state.items;
        if (items.isEmpty) {
          return Container(
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.event_busy),
                SizedBox(height: 8),
                Text("選択した条件の適時開示は0件です"),
              ],
            ),
          );
        }

        final itemCount = items.length + (state.hasMore ? 1 : 0);

        return RefreshIndicator(
          onRefresh: () => ref
              .read(companyEdinetsProvider(edinetCode).notifier)
              .refresh(),
          child: ListView.builder(
            itemCount: itemCount,
            itemBuilder: (context, idx) {
              if (idx == items.length) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 24.0),
                  child: ElevatedButton(
                    onPressed: state.isLoadingMore
                        ? null
                        : () => ref
                            .read(companyEdinetsProvider(edinetCode).notifier)
                            .loadMore(),
                    child: state.isLoadingMore
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('更に読み込む'),
                  ),
                );
              }
              return EdinetListItem(
                edinet: items[idx],
                showDate: true,
              );
            },
          ),
        );
      },
    );
  }
}
