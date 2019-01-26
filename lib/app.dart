import 'package:disclosure_app_fl/screens/search-company.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/disclosure-stream.dart';

class AppRootWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppRootWidgetState();
  }
}

class AppRootWidgetState extends State<AppRootWidget> {
  @override
  void initState() {
    FirebaseAuth.instance.signInAnonymously().then(print);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '適時開示(TDNet) Notifier',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.teal,
      ),
      // home: DisclosureStream(),
      routes: {
        '/': (context) => DisclosureStreamScreen(),
        '/companies': (context) => SearchCompanyScreen(),
      },
    );
  }
}
