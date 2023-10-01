import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/bloc/tags_disclosure_bloc.dart';
import 'package:disclosure_app_fl/widgets/banner_ad.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DisclosureTagsScreen extends StatefulWidget {
  final String? tag;

  DisclosureTagsScreen({this.tag});

  @override
  _DisclosureTagsScreenState createState() =>
      _DisclosureTagsScreenState(tag: this.tag);
}

class _DisclosureTagsScreenState extends State<DisclosureTagsScreen> {
  final String? tag;
  TagsDisclosureBloc? bloc2;

  @override
  initState() {
    super.initState();
    final appBloc = BlocProvider.of<AppBloc>(context);
    this.bloc2 = TagsDisclosureBloc(
      tag: this.tag,
      user$: appBloc.user$,
    );
    this.bloc2!.disclosure.reload.add(null);
  }

  _DisclosureTagsScreenState({this.tag});

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return RefreshIndicator(
      child: CustomScrollView(slivers: <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => DisclosureListItem(
              item: snapshot[index],
              showDate: true,
              key: Key(snapshot[index]['document']),
            ),
            childCount: snapshot.length,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              child: StreamBuilder<bool>(
                  stream: bloc2!.disclosure.isLoading$,
                  builder: (context, snapshot) {
                    return snapshot.data == false
                        ? Text('更に読み込む')
                        : CircularProgressIndicator();
                  }),
              onPressed: () {
                this.bloc2!.disclosure.loadNext.add(snapshot.last);
              },
            ),
          ),
        )
      ]),
      onRefresh: () {
        bloc2!.disclosure.reload.add(this.tag);
        return bloc2!.disclosure.isLoading$.where((e) => e).first;
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<List<DocumentSnapshot>?>(
      stream: bloc2!.disclosure.data$,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Column(
            children: <Widget>[
              LinearProgressIndicator(),
            ],
          );
        }
        return _buildList(context, snapshot.data!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${this.tag}の通知履歴"),
      ),
      body: WithBannerAdWidget(child: _buildBody(context)),
    );
  }

  @override
  void dispose() {
    bloc2?.dispose();
    super.dispose();
  }
}
