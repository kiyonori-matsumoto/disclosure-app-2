import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/widgets/bottom_text_field_with_icon.dart';
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
                  child: snapshot.data.length > 0
                      ? ListView(
                          children: snapshot.data.map((fav) {
                          return Dismissible(
                            child: ListTile(
                              title: Text(fav.toString()),
                              onTap: () {
                                final company =
                                    Company(fav.code, name: fav.name);
                                return Navigator.pushNamed(
                                    context, '/company-disclosures',
                                    arguments: company);
                              },
                            ),
                            key: fav.key,
                            onDismissed: (direction) {
                              bloc.removeFavorite.add(fav.code);
                            },
                          );
                        }).toList())
                      : Container(
                          alignment: AlignmentDirectional.center,
                          child: Text('お気に入りはありません'),
                        ),
                ),
                Divider(),
                BottomTextFieldWithIcon(
                  onSubmit: (code) {
                    this._handleSubmit(bloc, code);
                  },
                  hintText: '証券コード',
                  keyboardType: TextInputType.number,
                )
              ],
            ),
          );
  }

  void _handleSubmit(AppBloc bloc, String code) {
    bloc.addFavorite.add(code);
  }
}
