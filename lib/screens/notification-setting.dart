import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/widgets/bottom_text_field_with_icon.dart';
import 'package:flutter/material.dart';

class NotificationSettingScreen extends StatefulWidget {
  @override
  _NotificationSettingScreenState createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("証券コードで通知")),
      body: _buildBody(context),
    );
  }

  _buildBody(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);
    return StreamBuilder<List<Company>>(
      stream: bloc.notifications$,
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
                          children: snapshot.data.map((notification) {
                          return Dismissible(
                            child:
                                ListTile(title: Text(notification.toString())),
                            key: notification.key,
                            onDismissed: (direction) {
                              bloc.removeNotification.add(notification.code);
                            },
                          );
                        }).toList())
                      : Container(
                          alignment: AlignmentDirectional.center,
                          child: Text("通知はありません"),
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
    bloc.addNotification.add(code);
    _controller.clear();
  }
}
