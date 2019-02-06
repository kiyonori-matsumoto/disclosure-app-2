import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/favorite.dart';
import 'package:disclosure_app_fl/screens/disclosure-company.dart';
import 'package:disclosure_app_fl/widgets/bottom_text_field_with_icon.dart';
import 'package:disclosure_app_fl/widgets/drawer.dart';
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
        drawer: AppDrawer(),
        body: _buildBody(context));
  }

  _buildBody(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);
    return StreamBuilder<List<Favorite>>(
      stream: bloc.favoritesWithName$,
      builder: (context, snapshot) => _builder(context, snapshot, bloc),
    );
  }

  Widget _builder(BuildContext context, AsyncSnapshot<List<Favorite>> snapshot,
      AppBloc bloc) {
    return (!snapshot.hasData || snapshot.data == null)
        ? LinearProgressIndicator()
        : SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                      children: snapshot.data.map((fav) {
                    return Dismissible(
                      child: ListTile(
                        title: Text(fav.toString()),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DisclosureCompanyScreen(
                                    company: Company(fav.code, name: fav.name),
                                  ),
                            ),
                          );
                        },
                      ),
                      key: fav.key,
                      onDismissed: (direction) {
                        bloc.removeFavorite.add(fav.code);
                      },
                    );
                  }).toList()),
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
