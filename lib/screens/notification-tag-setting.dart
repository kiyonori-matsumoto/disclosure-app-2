import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:flutter/material.dart';

class NotificationTagSettingScreen extends StatefulWidget {
  @override
  _NotificationTagSettingScreenState createState() =>
      _NotificationTagSettingScreenState();
}

class _NotificationTagSettingScreenState
    extends State<NotificationTagSettingScreen> {
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("タグで通知")),
      body: _buildBody(context),
    );
  }

  _buildBody(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);
    return StreamBuilder<List<String>>(
      stream: bloc.tagsNotifications$,
      builder: (context, snapshot) => _builder(context, snapshot, bloc),
    );
  }

  Widget _builder(BuildContext context, AsyncSnapshot<List<String>> snapshot,
      AppBloc bloc) {
    return (!snapshot.hasData || snapshot.data == null)
        ? LinearProgressIndicator()
        : SafeArea(
            child: ListView(
              children: filterStrings.map((s) {
                final value = snapshot.data!.contains(s);
                return SwitchListTile(
                  title: Text(s),
                  value: value,
                  onChanged: (v) {
                    if (!v) {
                      bloc.removeTagsNotification.add(s);
                    } else {
                      bloc.addTagsNotification.add(s);
                    }
                  },
                );
              }).toList(),
            ),
          );
  }
}
