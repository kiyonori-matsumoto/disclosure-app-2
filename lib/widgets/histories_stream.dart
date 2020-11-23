import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:flutter/material.dart';

class DisclosureHistoriesStreamWidget extends StatelessWidget {
  final Widget Function(List<String>) builder;

  const DisclosureHistoriesStreamWidget({Key key, @required this.builder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);
    return StreamBuilder<List<String>>(
      stream: bloc.disclosureHistory$,
      builder: (context, snapshot) {
        return this.builder(snapshot.hasData ? snapshot.data : []);
      },
    );
  }
}

class EdinetHistoriesStreamWidget extends StatelessWidget {
  final Widget Function(List<String>) builder;

  const EdinetHistoriesStreamWidget({Key key, @required this.builder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<AppBloc>(context);
    return StreamBuilder<List<String>>(
      stream: bloc.edinetHistory$,
      builder: (context, snapshot) {
        return this.builder(snapshot.hasData ? snapshot.data : []);
      },
    );
  }
}
