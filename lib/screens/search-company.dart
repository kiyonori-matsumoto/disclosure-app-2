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
  String text = "";

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
          onChanged: (text) {
            setState(() {
              this.text = text;
            });
            _bloc.changeFilter.add(text);
          },
          onSubmitted: (code) {
            _controller.clear();
            final company = Company(code);
            Navigator.pushNamed(context, '/company-disclosures',
                arguments: company);
          },
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() {
                  this.text = "";
                });
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
    return this.text.length >= 2
        ? StreamBuilder<List<Company>>(
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
          )
        : StreamBuilder<List<Company>>(
            stream: _bloc.companyHistory$,
            builder: (context, snapshot) => CompanyListView(
                  snapshot?.data ?? [],
                  history: true,
                ),
          );
  }
}

class CompanyListView extends StatelessWidget {
  final List<Company>? companies;
  final bool history;

  const CompanyListView(
    this.companies, {
    Key? key,
    this.history = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppBloc bloc = BlocProvider.of<AppBloc>(context);

    return ListView.builder(
      itemBuilder: (context, index) {
        final company = companies![index];
        return ListTile(
          title: Text(company.name!),
          leading: history ? Icon(Icons.history) : null,
          onTap: () {
            bloc.addHistory.add(company);
            Navigator.pushNamed(
              context,
              '/company-disclosures',
              arguments: company,
            );
          },
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text('お気に入りに追加'),
                    value: 'add_favorite',
                  )
                ],
            onSelected: (dynamic value) {
              switch (value) {
                case "add_favorite":
                  bloc.addFavorite.add(company.code);
                  Scaffold.of(context).showSnackBar((SnackBar(
                    content: Text('${company.name}をお気に入りに追加しました'),
                  )));
                  break;
                default:
              }
            },
          ),
        );
      },
      itemCount: companies!.length,
    );
  }
}
