import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/company_history_provider.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchCompanyScreen extends ConsumerStatefulWidget {
  const SearchCompanyScreen({super.key});

  @override
  ConsumerState<SearchCompanyScreen> createState() =>
      _SearchCompanyScreenState();
}

class _SearchCompanyScreenState extends ConsumerState<SearchCompanyScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = "";

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        iconTheme: Theme.of(context).iconTheme.copyWith(color: Colors.black),
        title: TextField(
          autofocus: true,
          style: Theme.of(context).textTheme.titleLarge,
          decoration: const InputDecoration.collapsed(hintText: '証券コード or 会社名'),
          controller: _controller,
          onChanged: (text) {
            setState(() {
              _query = text;
            });
          },
          onSubmitted: (code) {
            final trimmed = code.trim().toUpperCase();
            if (trimmed.isEmpty) return;

            final uid = ref.read(currentUserProvider)?.uid;
            if (uid != null) {
              ref.read(companyHistoryActionProvider.notifier).add(uid, trimmed);
            }

            _controller.clear();
            final codeMap = ref.read(companyCodeMapProvider);
            final normalized =
                trimmed.length > 4 ? trimmed.substring(0, 4) : trimmed;
            final company =
                codeMap[trimmed] ?? codeMap[normalized] ?? Company(trimmed);
            Navigator.pushNamed(context, '/company-disclosures',
                arguments: company);
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              setState(() {
                _query = "";
              });
            },
          )
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final companiesAsync = ref.watch(companiesStreamProvider);

    return companiesAsync.when(
      loading: () => Container(
        alignment: AlignmentDirectional.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('会社情報をダウンロード中です…'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Icon(Icons.error_outline, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text('会社情報の取得に失敗しました'),
          ],
        ),
      ),
      data: (_) {
        if (_query.trim().length >= 2) {
          final searchResults = ref.watch(searchCompaniesProvider(_query));
          return CompanyListView(
            searchResults,
            history: false,
          );
        } else {
          final history = ref.watch(companyHistoryProvider);
          return CompanyListView(
            history,
            history: true,
          );
        }
      },
    );
  }
}

class CompanyListView extends ConsumerWidget {
  final List<Company> companies;
  final bool history;

  const CompanyListView(
    this.companies, {
    super.key,
    this.history = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final company = companies[index];
        return ListTile(
          title: Text(company.name ?? ''),
          leading: history ? const Icon(Icons.history) : null,
          onTap: () {
            final uid = ref.read(currentUserProvider)?.uid;
            final code = company.code;
            if (uid != null && code != null) {
              ref.read(companyHistoryActionProvider.notifier).add(uid, code);
            }
            Navigator.pushNamed(
              context,
              '/company-disclosures',
              arguments: company,
            );
          },
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Text('お気に入りに追加'),
                value: 'add_favorite',
              )
            ],
            onSelected: (dynamic value) {
              switch (value) {
                case "add_favorite":
                  final uid = ref.read(currentUserProvider)?.uid;
                  final code = company.code;
                  if (uid != null && code != null) {
                    ref.read(favoritesActionProvider.notifier).add(uid, code);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${company.name}をお気に入りに追加しました'),
                  ));
                  break;
                default:
              }
            },
          ),
        );
      },
      itemCount: companies.length,
    );
  }
}
