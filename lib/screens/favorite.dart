import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:flutter/material.dart';

class FavoriteScreen extends StatefulWidget {
  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("お気に入り")),
        // drawer: AppDrawer(),
        body: _buildBody(context));
  }

  _buildBody(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);
    return StreamBuilder<List<Company>>(
      stream: bloc.favoritesWithName$,
      builder: (context, snapshot) => _builder(context, snapshot, bloc),
    );
  }

  Widget _builder(BuildContext context, AsyncSnapshot<List<Company>> snapshot,
      AppBloc bloc) {
    return (!snapshot.hasData || snapshot.data == null)
        ? LinearProgressIndicator()
        : SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: snapshot.data!.length > 0
                      ? ListView(
                          children: snapshot.data!.map((fav) {
                          return Dismissible(
                            background: Container(
                              color: Colors.red,
                            ),
                            child: new FadedListTile(
                              fav: fav,
                              key: fav.key,
                            ),
                            key: fav.key!,
                            onDismissed: (direction) {
                              final revert = () {
                                bloc.addFavorite.add(fav.code);
                              };
                              bloc.removeFavorite.add(fav.code);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text("削除しました"),
                                action: SnackBarAction(
                                  label: "取り消す",
                                  onPressed: revert,
                                ),
                              ));
                            },
                          );
                        }).toList())
                      : Container(
                          alignment: AlignmentDirectional.center,
                          child: Text('お気に入りはありません'),
                        ),
                ),
                Divider(
                  height: 8.0,
                ),
                ElevatedButton(
                  child: Text('検索して追加'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/companies');
                  },
                )
              ],
            ),
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
      this.setState(() {
        opacity = 1.0;
      });
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
