import 'package:bloc_provider/bloc_provider.dart';
import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:flutter/material.dart';

class SearchCompanyScreen extends StatefulWidget {
  @override
  _SearchCompanyScreenState createState() => _SearchCompanyScreenState();
}

class _SearchCompanyScreenState extends State<SearchCompanyScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final _bloc = BlocProvider.of<AppBloc>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        iconTheme: Theme.of(context).iconTheme.copyWith(color: Colors.black),
        title: TextField(
          autofocus: true,
          style: Theme.of(context).textTheme.title,
          decoration: InputDecoration.collapsed(hintText: '証券コード or 会社名'),
          controller: _controller,
          onChanged: (text) => _bloc.changeFilter.add(text),
          onSubmitted: (code) {
            _controller.clear();
            final company = Company(code);
            return Navigator.pushNamed(context, '/company-disclosures',
                arguments: company);
          },
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                _bloc.changeFilter.add('');
              })
        ],
      ),
      // drawer: AppDrawer(),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final _bloc = BlocProvider.of<AppBloc>(context);
    return StreamBuilder<List<Company>>(
      stream: _bloc.filteredCompany$,
      builder: (context, snapshot) =>
          (!snapshot.hasData || snapshot.data == null)
              ? Container(
                  alignment: AlignmentDirectional.center,
                  child: Column(
                    children: <Widget>[
                      CircularProgressIndicator(),
                      Text('会社情報をダウンロード中です…')
                    ],
                  ),
                )
              : CompanyListView(snapshot.data),
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
          onTap: () {
            return Navigator.pushNamed(
              context,
              '/company-disclosures',
              arguments: companies[index],
            );
          }),
      itemCount: companies.length,
    );
  }
}
