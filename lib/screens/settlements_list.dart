import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/settlements_provider.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettlementsList extends ConsumerWidget {
  const SettlementsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settlementsSelectedDateProvider);
    final settlementsAsync = ref.watch(currentSettlementsListProvider);

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final end = now.add(const Duration(days: 30));

    return Scaffold(
      appBar: AppBar(
        title: Text('${toDate(current.millisecondsSinceEpoch)}の決算予定'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '会社検索',
            onPressed: () {
              Navigator.pushNamed(context, '/companies');
            },
          ),
        ],
      ),
      body: settlementsAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(error.toString()),
            ],
          ),
        ),
        data: (settlements) {
          if (settlements.isEmpty) {
            return SizedBox(
              width: double.infinity,
              height: 80.0,
              child: Card(
                shape: const RoundedRectangleBorder(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(
                        Icons.announcement,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('指定された日の決算予定はありません'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: settlements.length,
            itemBuilder: (context, idx) {
              final settlement = settlements[idx];
              final quoteText = (settlement.quote != null &&
                      settlement.quote!.isNotEmpty)
                  ? ' (${settlement.quote})'
                  : '';

              return ListTile(
                title: Text('${settlement.name ?? ''}$quoteText'),
                onTap: () {
                  final companyCodeMap = ref.read(companyCodeMapProvider);
                  final code = settlement.code ?? '';
                  final normalizedCode =
                      code.length > 4 ? code.substring(0, 4) : code;
                  final company = companyCodeMap[code] ??
                      companyCodeMap[normalizedCode] ??
                      Company(code, name: settlement.name ?? '');

                  Navigator.pushNamed(
                    context,
                    '/company-disclosures',
                    arguments: company,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.calendar_today),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: current,
            firstDate: start,
            lastDate: end,
          );
          if (picked != null) {
            ref.read(settlementsSelectedDateProvider.notifier).setDate(picked);
          }
        },
      ),
    );
  }
}
