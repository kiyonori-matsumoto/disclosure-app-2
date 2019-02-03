import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/filter.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/drawer.dart';

final Filters = ["株主優待", "決算", "配当", "業績予想", "新株", "自己株式", "日々の開示事項"];

class DisclosureStreamScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return DisclosureStreamScreenState();
  }
}

class DisclosureStreamScreenState extends State<DisclosureStreamScreen> {
  DateTime date = DateTime.now();

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView.builder(
      itemBuilder: (context, index) =>
          new DisclosureListItem(item: snapshot[index]),
      itemCount: snapshot.length,
    );
  }

  Widget _buildBody(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);

    return StreamBuilder<List<DocumentSnapshot>>(
      stream: bloc.disclosure$,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null)
          return LinearProgressIndicator();
        else if (snapshot.data.length == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.event_busy),
                Text("この日の適時開示は0件です"),
              ],
            ),
          );
        }
        return _buildList(context, snapshot.data);
      },
    );
  }

  Widget _dialog(BuildContext context, AppBloc bloc) =>
      StreamBuilder<List<Filter>>(
        builder: (context, snapshot) => SimpleDialog(
              title: Text('filter'),
              children: (snapshot.data ?? [])
                  .map(
                    (filter) => SimpleDialogOption(
                          child: CheckboxListTile(
                            title: Text(filter.title),
                            value: filter.isSelected,
                            onChanged: (value) {
                              bloc.addFilter.add(filter.title);
                            },
                          ),
                        ),
                  )
                  .toList(),
            ),
        stream: bloc.filter$,
      );

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);
    final formatter = DateFormat.yMd();
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("${formatter.format(date)}"),
        actions: <Widget>[
          IconButton(
            icon: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(Icons.calendar_today),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            onPressed: () async {
              final _date = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2017, 1, 1),
                lastDate: DateTime.now(),
              );
              if (_date == null) return;
              setState(() {
                this.date = _date;
              });
              bloc.date.add(date);
            },
          ),
          StreamBuilder(
            builder: (context, snapshot) => IconButton(
                  icon: Stack(
                    children: [
                      Icon(Icons.filter_list),
                      snapshot.data != null && snapshot.data > 0
                          ? Container(
                              decoration: ShapeDecoration(
                                  color: Colors.red, shape: CircleBorder()),
                              child: Text(
                                snapshot.data.toString(),
                                style: TextStyle(fontSize: 10.0),
                              ),
                              padding: EdgeInsets.all(4.0),
                            )
                          : null,
                    ].where((w) => w != null).toList(),
                    alignment: Alignment.bottomRight,
                  ),
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (context) => _dialog(context, bloc),
                    );
                    print(result);
                  },
                ),
            stream: bloc.filterCount$,
          ),
        ],
      ),
      body: _buildBody(context),
      drawer: AppDrawer(),
    );
  }
}
