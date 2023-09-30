import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:disclosure_app_fl/widgets/bottom_text_field_with_icon.dart';
import 'package:flutter/material.dart';

class CustomTagScreen extends StatefulWidget {
  @override
  _CustomTagScreenState createState() => _CustomTagScreenState();
}

class _CustomTagScreenState extends State<CustomTagScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("カスタムタグ設定")), body: _buildBody(context));
  }

  _buildBody(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);
    return StreamBuilder<List<Filter>>(
      stream: bloc.customFilters$,
      builder: (context, snapshot) => _builder(context, snapshot, bloc),
    );
  }

  Widget _builder(BuildContext context, AsyncSnapshot<List<Filter>> snapshot,
      AppBloc bloc) {
    return (!snapshot.hasData || snapshot.data == null)
        ? LinearProgressIndicator()
        : SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: snapshot.data!.length > 0
                      ? ListView(
                          children: snapshot.data!.map((filter) {
                          return Dismissible(
                            child: ListTile(
                              title: Text(filter.title),
                            ),
                            key: filter.key,
                            onDismissed: (dir) {
                              bloc.removeCustomFilter.add(filter);
                            },
                          );
                        }).toList())
                      : Container(
                          alignment: AlignmentDirectional.center,
                          child: Text("カスタムタグはありません"),
                        ),
                ),
                Divider(),
                BottomTextFieldWithIcon(
                  onSubmit: (code) {
                    this._handleSubmit(bloc, code);
                  },
                  hintText: 'タグ名',
                )
              ],
            ),
          );
  }

  void _handleSubmit(AppBloc bloc, String code) {
    bloc.addCustomFilter.add(code);
  }
}
