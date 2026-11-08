import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/user_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoriteScreen extends ConsumerWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("お気に入り"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '会社検索',
            onPressed: () {
              Navigator.pushNamed(context, '/companies');
            },
          ),
        ],
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(userDocStreamProvider);

    return userDocAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Icon(Icons.error_outline, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text('お気に入りの読み込みに失敗しました'),
          ],
        ),
      ),
      data: (_) {
        final favorites = ref.watch(favoritesWithCompanyProvider);
        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: favorites.isNotEmpty
                    ? ListView.builder(
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final fav = favorites[index];
                          return Dismissible(
                            key: fav.key ?? ValueKey(fav.code ?? index),
                            background: Container(
                              color: Colors.red,
                            ),
                            child: FadedListTile(
                              fav: fav,
                              key: fav.key,
                            ),
                            onDismissed: (direction) {
                              final action =
                                  ref.read(favoritesActionProvider.notifier);
                              final uid = ref.read(currentUserProvider)?.uid;
                              final code = fav.code;
                              if (uid != null && code != null) {
                                action.remove(uid, code);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: const Text("削除しました"),
                                  action: SnackBarAction(
                                    label: "取り消す",
                                    onPressed: () {
                                      action.add(uid, code);
                                    },
                                  ),
                                ));
                              }
                            },
                          );
                        },
                      )
                    : Container(
                        alignment: AlignmentDirectional.center,
                        child: const Text('お気に入りはありません'),
                      ),
              ),
              const Divider(height: 8.0),
              ElevatedButton(
                child: const Text('検索して追加'),
                onPressed: () {
                  Navigator.pushNamed(context, '/companies');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class FadedListTile extends StatefulWidget {
  final Company fav;
  const FadedListTile({
    required this.fav,
    Key? key,
  }) : super(key: key);

  @override
  _FadedListTileState createState() => _FadedListTileState();
}

class _FadedListTileState extends State<FadedListTile> {
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100)).then((_) {
      if (mounted) {
        setState(() {
          opacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      child: ListTile(
        title: Text(widget.fav.toString()),
        onTap: () {
          Navigator.pushNamed(context, '/company-disclosures',
              arguments: widget.fav);
        },
      ),
      duration: const Duration(milliseconds: 500),
    );
  }
}
