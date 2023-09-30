import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/bloc/edinet_bloc.dart';
import 'package:flutter/material.dart';

class AppProvider extends StatelessWidget {
  final Widget? child;
  AppProvider({this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.builder(
      creator: (context, _bag) => AppBloc(),
      builder: (_context, AppBloc bloc) => BlocProvider(
            creator: (context, _bag) => EdinetBloc(bloc),
            child: this.child,
          ),
    );
  }
}
