import 'package:disclosure_app_fl/utils/admob.dart';
import 'package:flutter/material.dart';

class WhatsNewScreen extends StatefulWidget {
  @override
  _WhatsNewScreenState createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> with SingleTickerProviderStateMixin {

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    this._tabController = TabController(length: 2, vsync: this)
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Scaffold(
      body: Container(
        child: TabBarView(
          children: <Widget>[
            Container(color: Colors.green),
            Container(color: Colors.red),
          ],
        ),
      ),
      persistentFooterButtons: <Widget>[
        SizedBox(height: getSmartBannerHeight(mediaQuery) - 16.0),
      ],
    );
  }
}
