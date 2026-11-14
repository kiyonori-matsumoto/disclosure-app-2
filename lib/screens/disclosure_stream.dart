import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/providers/disclosures_provider.dart';
import 'package:disclosure_app_fl/providers/edinet_disclosures_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/utils/routeobserver.dart';
import 'package:disclosure_app_fl/utils/sliver_appbar_delegate.dart';
import 'package:disclosure_app_fl/widgets/banner_ad.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:disclosure_app_fl/widgets/edinet_streaming.dart';
import 'package:disclosure_app_fl/widgets/no_disclosures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../widgets/drawer.dart';

class DisclosureStreamScreen extends ConsumerStatefulWidget {
  const DisclosureStreamScreen({super.key});

  @override
  ConsumerState<DisclosureStreamScreen> createState() {
    return DisclosureStreamScreenState();
  }
}

class DisclosureStreamScreenState extends ConsumerState<DisclosureStreamScreen>
    with RouteAware, SingleTickerProviderStateMixin {
  final MyRouteObserver routeObserver = MyRouteObserver();
  String displayTarget = 'tdnet';
  final ScrollController sliverScrollController = ScrollController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    sliverScrollController.addListener(_onScroll);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final newTarget = _tabController.index == 0 ? 'tdnet' : 'edinet';
    if (displayTarget != newTarget) {
      setState(() {
        displayTarget = newTarget;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    sliverScrollController.removeListener(_onScroll);
    sliverScrollController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!sliverScrollController.hasClients) return;
    // 上端から10px以内を「最上部」と判定
    final isAtTop = sliverScrollController.offset <= 10.0;
    ref.read(disclosuresFeedProvider.notifier).updateScrollPosition(
          isAtTop: isAtTop,
        );
    ref.read(edinetFeedProvider.notifier).updateScrollPosition(
          isAtTop: isAtTop,
        );
  }

  @override
  Widget build(BuildContext context) {
    final newCount = displayTarget == 'tdnet'
        ? ref.watch(pendingNewDisclosureCountProvider)
        : ref.watch(edinetFeedProvider).newCount;

    return Scaffold(
      body: buildSliverBody(context),
      drawer: AppDrawer(),
      floatingActionButton: newCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                sliverScrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
                if (displayTarget == 'tdnet') {
                  ref.read(disclosuresFeedProvider.notifier).refreshToLatest();
                } else {
                  ref.read(edinetFeedProvider.notifier).refreshToLatest();
                }
              },
              label: Text('$newCount NEW MESSAGE'),
              icon: const Icon(Icons.refresh),
            )
          : const SizedBox.shrink(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget buildSliverBody(BuildContext context) {
    final formatter = DateFormat.yMd('ja');
    final appbar = SliverAppBar(
      title: const Text('開示情報速報'),
      pinned: false,
      floating: true,
      snap: true,
      bottom: TabBar(
        controller: _tabController,
        indicatorWeight: 3.0,
        tabs: const [
          Tab(text: 'TDNET'),
          Tab(text: 'EDINET'),
        ],
      ),
      actions: <Widget>[
        /* スクリーンショット撮影およびクリーンなUI表示のためデバッグボタンは非表示
        if (kDebugMode)
          IconButton(
            icon: const Icon(Icons.add_alert, color: Colors.amber),
            tooltip: '【Debug】新着開示を注入',
            onPressed: () {
              if (displayTarget == 'tdnet') {
                ref
                    .read(disclosuresFeedProvider.notifier)
                    .injectDebugNewDisclosure();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('【Debug】ダミーTDNET開示を受信しました'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } else {
                ref
                    .read(edinetFeedProvider.notifier)
                    .injectDebugNewEdinet();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('【Debug】ダミーEDINET開示を受信しました'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        */
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '会社検索',
          onPressed: () {
            Navigator.of(context).pushNamed('/companies');
          },
        ),
      ],
    );

    return SafeArea(
      child: NestedScrollView(
        controller: sliverScrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            appbar,
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            CustomScrollView(
              slivers: <Widget>[
                filterToolbar(formatter),
                tdnetList(),
              ],
            ),
            CustomScrollView(
              slivers: <Widget>[
                edinetFilterToolbar(formatter),
                const EdinetStreamingWidget(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// TDNET 用フィルタツールバー
  SliverPersistentHeader filterToolbar(DateFormat formatter) {
    final selectedDate = ref.watch(selectedDateProvider);
    final filterCount = ref.watch(selectedFilterCountProvider);
    final order = ref.watch(disclosureOrderProvider);
    final showOnlyFavs = ref.watch(showOnlyFavoritesProvider);

    return SliverPersistentHeader(
      pinned: true,
      delegate: SliverAppBarDelegate(
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            // 日付選択 Chip
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ActionChip(
                avatar: const Icon(Icons.calendar_today),
                label: Text(formatter.format(selectedDate)),
                onPressed: () => _changeDate(selectedDate),
              ),
            ),
            // フィルタ件数 Chip
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ChoiceChip(
                label: Text('$filterCount'),
                avatar: const Icon(Icons.filter_list),
                selected: filterCount > 0,
                onSelected: (_) => _showFilterDialog(context),
              ),
            ),
            // ソート順切り替え Chip
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ActionChip(
                label: Text(order),
                avatar: const Icon(Icons.sort),
                onPressed: () {
                  ref.read(disclosureOrderProvider.notifier).toggle();
                },
              ),
            ),
            // お気に入りのみ表示 Chip
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ChoiceChip(
                avatar: const Icon(Icons.favorite),
                label: const Text('お気に入りのみ表示する'),
                selected: showOnlyFavs,
                onSelected: (val) {
                  ref.read(showOnlyFavoritesProvider.notifier).set(val);
                  if (val && ref.read(favoritesProvider).isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('お気に入りに登録されている銘柄がありません'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// EDINET 用フィルタツールバー
  SliverPersistentHeader edinetFilterToolbar(DateFormat formatter) {
    final selectedDate = ref.watch(edinetSelectedDateProvider);
    final filter = ref.watch(edinetDocTypeFilterProvider);
    final showOnlyFavs = ref.watch(edinetShowOnlyFavoritesProvider);

    return SliverPersistentHeader(
      pinned: true,
      delegate: SliverAppBarDelegate(
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            // 日付選択 Chip
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ActionChip(
                avatar: const Icon(Icons.calendar_today),
                label: Text(formatter.format(selectedDate)),
                onPressed: () => _changeEdinetDate(selectedDate),
              ),
            ),
            // 書類種別フィルタ Chip
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ChoiceChip(
                label: Text(filter.isEmpty ? 'なし' : filter),
                avatar: const Icon(Icons.filter_list),
                selected: filter.isNotEmpty,
                onSelected: (_) => _showEdinetFilterDialog(context),
              ),
            ),
            // お気に入りのみ表示 Chip
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ChoiceChip(
                avatar: const Icon(Icons.favorite),
                label: const Text('お気に入りのみ表示する'),
                selected: showOnlyFavs,
                onSelected: (val) {
                  ref.read(edinetShowOnlyFavoritesProvider.notifier).set(val);
                  if (val && ref.read(favoritesProvider).isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('お気に入りに登録されている銘柄がありません'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TDNET 開示情報一覧スリバー
  Widget tdnetList() {
    final disclosuresAsync = ref.watch(filteredDisclosuresProvider);

    return disclosuresAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: LinearProgressIndicator(),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.event_busy),
              const SizedBox(height: 8),
              Text(error.toString()),
            ],
          ),
        ),
      ),
      data: (docs) {
        if (docs.isEmpty) {
          return const SliverFillRemaining(
            child: NoDisclosures(),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, idx) => DisclosureListItem(
              key: Key(docs[idx].id),
              item: docs[idx],
            ),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Future<void> _changeDate(DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2017, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).setDate(picked);
    }
  }

  Future<void> _changeEdinetDate(DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2019, 3, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(edinetSelectedDateProvider.notifier).setDate(picked);
    }
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final filters = ref.watch(availableFiltersProvider);

          return SimpleDialog(
            title: const Text('filter'),
            contentPadding: EdgeInsets.zero,
            children: filters
                .map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: CheckboxListTile(
                      title: Text(filter.title),
                      value: filter.isSelected,
                      onChanged: (_) {
                        ref
                            .read(selectedFiltersProvider.notifier)
                            .toggle(filter.title);
                      },
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Future<void> _showEdinetFilterDialog(BuildContext context) async {
    final selectedFilter = ref.read(edinetDocTypeFilterProvider);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('filter'),
        contentPadding: EdgeInsets.zero,
        children: Edinet.docTypes()
            .map(
              (type) => Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: CheckboxListTile(
                  title: Text(type),
                  value: type == selectedFilter,
                  onChanged: (value) {
                    Navigator.of(dialogContext).pop(value! ? type : '');
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
    if (result != null) {
      ref.read(edinetDocTypeFilterProvider.notifier).setFilter(result);
    }
  }
}
