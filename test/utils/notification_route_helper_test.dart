import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/utils/notification_route_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationRouteHelper.resolveDestination', () {
    test('null または空データの場合は NoneDestination を返す', () async {
      expect(
        await NotificationRouteHelper.resolveDestination(null),
        equals(const NoneDestination()),
      );
      expect(
        await NotificationRouteHelper.resolveDestination({}),
        equals(const NoneDestination()),
      );
    });

    test('type == tag の場合、tag が存在すれば TagDestination を返す', () async {
      final result = await NotificationRouteHelper.resolveDestination({
        'type': 'tag',
        'tag': '株主優待',
      });
      expect(result, isA<TagDestination>());
      expect((result as TagDestination).tag, '株主優待');
    });

    test('type == tag で tag が空文字や空白の場合は NoneDestination を返す', () async {
      final res1 = await NotificationRouteHelper.resolveDestination({
        'type': 'tag',
        'tag': '',
      });
      expect(res1, equals(const NoneDestination()));

      final res2 = await NotificationRouteHelper.resolveDestination({
        'type': 'tag',
        'tag': '   ',
      });
      expect(res2, equals(const NoneDestination()));

      final res3 = await NotificationRouteHelper.resolveDestination({
        'type': 'tag',
      });
      expect(res3, equals(const NoneDestination()));
    });

    test('code が存在する場合、CompanyDestination を返す', () async {
      final result = await NotificationRouteHelper.resolveDestination({
        'code': '7203',
        'name': 'トヨタ自動車',
      });
      expect(result, isA<CompanyDestination>());
      final company = (result as CompanyDestination).company;
      expect(company.code, '7203');
      expect(company.name, 'トヨタ自動車');
    });

    test('companyCodeMap が提供されている場合、マップ内の会社情報を優先利用する', () async {
      final mockMap = {
        '7203': Company('7203', name: 'トヨタ自動車 (フル名称)', edinetCode: 'E02144'),
      };
      final result = await NotificationRouteHelper.resolveDestination(
        {'code': '7203', 'name': 'トヨタ'},
        companyCodeMap: mockMap,
      );
      expect(result, isA<CompanyDestination>());
      final company = (result as CompanyDestination).company;
      expect(company.name, 'トヨタ自動車 (フル名称)');
      expect(company.edinetCode, 'E02144');
    });

    test('companyResolver が提供されている場合、リゾルバで解決された会社情報を返す', () async {
      final result = await NotificationRouteHelper.resolveDestination(
        {'code': '6758', 'name': 'ソニーG'},
        companyResolver: (code, name) async {
          return Company(code, name: '$name (解決済み)');
        },
      );
      expect(result, isA<CompanyDestination>());
      final company = (result as CompanyDestination).company;
      expect(company.name, 'ソニーG (解決済み)');
    });

    test('code も edinetCode も無い場合は NoneDestination を返す', () async {
      final result = await NotificationRouteHelper.resolveDestination({
        'name': 'どこかの会社',
        'code': '',
      });
      expect(result, equals(const NoneDestination()));
    });

    test('edinetCode のみがある場合は CompanyDestination を返す', () async {
      final result = await NotificationRouteHelper.resolveDestination({
        'edinetCode': 'E02144',
        'name': 'トヨタ自動車',
      });
      expect(result, isA<CompanyDestination>());
      final company = (result as CompanyDestination).company;
      expect(company.edinetCode, 'E02144');
      expect(company.name, 'トヨタ自動車');
    });
  });

  group('NotificationRouteHelper.navigateToDestination', () {
    testWidgets('TagDestination の場合、/tag-disclosures に遷移する',
        (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      String? routedPath;
      Object? routedArguments;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Home')),
          onGenerateRoute: (settings) {
            routedPath = settings.name;
            routedArguments = settings.arguments;
            return MaterialPageRoute<dynamic>(
              settings: settings,
              builder: (_) => Scaffold(body: Text(settings.name ?? '')),
            );
          },
        ),
      );

      final navigated = NotificationRouteHelper.navigateToDestination(
        navigatorKey.currentState!,
        const TagDestination('決算短信'),
      );

      await tester.pumpAndSettle();

      expect(navigated, isTrue);
      expect(routedPath, '/tag-disclosures');
      expect(routedArguments, '決算短信');
    });

    testWidgets('CompanyDestination の場合、/company-disclosures に遷移する',
        (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      String? routedPath;
      Object? routedArguments;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Home')),
          onGenerateRoute: (settings) {
            routedPath = settings.name;
            routedArguments = settings.arguments;
            return MaterialPageRoute<dynamic>(
              settings: settings,
              builder: (_) => Scaffold(body: Text(settings.name ?? '')),
            );
          },
        ),
      );

      final testCompany = Company('7203', name: 'トヨタ自動車');
      final navigated = NotificationRouteHelper.navigateToDestination(
        navigatorKey.currentState!,
        CompanyDestination(testCompany),
      );

      await tester.pumpAndSettle();

      expect(navigated, isTrue);
      expect(routedPath, '/company-disclosures');
      expect(routedArguments, testCompany);
    });

    testWidgets('NoneDestination の場合、遷移せず false を返す',
        (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      String? routedPath;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Home')),
          onGenerateRoute: (settings) {
            routedPath = settings.name;
            return MaterialPageRoute<dynamic>(
              settings: settings,
              builder: (_) => Scaffold(body: Text(settings.name ?? '')),
            );
          },
        ),
      );

      final navigated = NotificationRouteHelper.navigateToDestination(
        navigatorKey.currentState!,
        const NoneDestination(),
      );

      await tester.pumpAndSettle();

      expect(navigated, isFalse);
      expect(routedPath, isNull);
    });
  });
}
