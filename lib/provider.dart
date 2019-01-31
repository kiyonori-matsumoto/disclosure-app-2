import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:flutter/material.dart';

class AppProvider extends StatelessWidget {
  final Widget child;
  AppProvider({this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      creator: (context, _bag) => AppBloc(),
      child: this.child,
    );
  }
}
