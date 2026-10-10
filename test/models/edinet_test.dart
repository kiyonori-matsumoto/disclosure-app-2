import 'package:flutter_test/flutter_test.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/edinet.dart';

void main() {
  group('Edinet', () {
    test('docTypes returns document type list', () {
      final types = Edinet.docTypes();
      expect(types, isNotEmpty);
      expect(types, contains('大量保有報告書'));
      expect(types, contains('四半期報告書'));
      expect(types, contains('有価証券報告書'));
    });

    test('docType maps code to correct label', () {
      expect(Edinet(docTypeCode: '010').docType, '有価証券通知書');
      expect(Edinet(docTypeCode: '120').docType, '有価証券報告書');
      expect(Edinet(docTypeCode: '140').docType, '四半期報告書');
      expect(Edinet(docTypeCode: '350').docType, '大量保有報告書');
      expect(Edinet(docTypeCode: '999').docType, '');
      expect(Edinet(docTypeCode: null).docType, '');
    });

    test('fillCompanyName resolves companies from company map', () {
      final edinet = Edinet(
        edinetCode: 'E00001',
        issuerEdinetCode: 'E00002',
        subjectEdinetCode: 'E00003',
        subsidiaryEdinetCode: 'E00004',
      );

      final companies = {
        'E00001': Company('1111', name: '会社A', edinetCode: 'E00001'),
        'E00002': Company('2222', name: '会社B', edinetCode: 'E00002'),
      };

      edinet.fillCompanyName(companies);

      expect(edinet.filer?.name, '会社A');
      expect(edinet.issuer?.name, '会社B');
      expect(edinet.subject?.name, '');
      expect(edinet.subject?.code, isNull);
      expect(edinet.subsidiary?.name, '');
      expect(edinet.subsidiary?.code, isNull);
    });

    test('relatedCompaniesName concatenates valid names', () {
      final edinet = Edinet(
        filerName: '提出者',
        issuer: Company('1111', name: '発行者'),
        subject: Company('2222', name: ''),
        subsidiary: Company('3333', name: '子会社'),
      );

      expect(edinet.relatedCompaniesName, '提出者,発行者,子会社');
    });

    test('companies returns only companies with valid code', () {
      final edinet = Edinet(
        filer: Company('1111', name: '会社A'),
        issuer: Company(null, name: '未定'),
        subject: Company('2222', name: '会社B'),
        subsidiary: null,
      );

      final validCompanies = edinet.companies;
      expect(validCompanies.length, 2);
      expect(validCompanies.map((c) => c?.code), containsAll(['1111', '2222']));
    });
  });
}
