import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/screens/disclosure-company.dart';
import 'package:disclosure_app_fl/widgets/bottom_text_field_with_icon.dart';
import 'package:flutter/material.dart';
import '../widgets/drawer.dart';

class SearchCompanyScreen extends StatefulWidget {
  @override
  _SearchCompanyScreenState createState() => _SearchCompanyScreenState();
}

class _SearchCompanyScreenState extends State<SearchCompanyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('会社検索')),
      drawer: AppDrawer(),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final _bloc = BlocProvider.of<AppBloc>(context);
    return StreamBuilder<List<Company>>(
      stream: _bloc.filteredCompany$,
      builder: (context, snapshot) => Column(
            children: <Widget>[
              (!snapshot.hasData || snapshot.data == null)
                  ? LinearProgressIndicator()
                  : Expanded(child: CompanyListView(snapshot.data)),
              Divider(),
              BottomTextFieldWithIcon(
                onChanged: (text) => _bloc.changeFilter.add(text),
                onSubmit: (code) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              DisclosureCompanyScreen(company: Company(code))));
                },
                hintText: '証券コード or 会社名',
                keyboardType: TextInputType.text,
                iconData: Icons.search,
              )
            ],
          ),
    );
  }
}

class CompanyListView extends StatelessWidget {
  final List<Company> companies;

  const CompanyListView(
    this.companies, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) => ListTile(
            title: Text(companies[index].name),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        DisclosureCompanyScreen(company: companies[index]))),
          ),
      itemCount: companies.length,
    );
  }
}
