import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company.dart';

class Edinet {
  String? docDescription;
  String? docId;
  String? docTypeCode;
  String? edinetCode;
  String? filerName;
  Company? filer;
  String? formCode;
  String? issuerEdinetCode;
  Company? issuer;
  String? ordinanceCode;
  String? pdfFlag;
  int? seqNumber;
  String? subjectEdinetCode;
  Company? subject;
  String? subsidiaryEdinetCode;
  Company? subsidiary;
  int? time;
  int? lastEvaluate;
  int? view_count;

  Edinet.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final item = snapshot.data() as Map<String, dynamic>;
    docDescription = item['docDescription'];
    docId = item['docID'];
    docTypeCode = item['docTypeCode'];
    edinetCode = item['edinetCode'];
    filerName = item['filerName'];
    formCode = item['formCode'];
    issuerEdinetCode = item['issuerEdinetCode'];
    ordinanceCode = item['ordinanceCode'];
    pdfFlag = item['pdfFlag'];
    subjectEdinetCode = item['subjectEdinetCode'];
    subsidiaryEdinetCode = item['subsidiaryEdinetCode'];
    time = (item['time'] - 9 * 60 * 60) * 1000;
    lastEvaluate = item['time'];
    view_count = item['view_count'];
  }

  void fillCompanyName(Map<String, Company> companies) {
    this.filer = companies[this.edinetCode] ?? Company(null);
    this.issuer = companies[this.issuerEdinetCode] ?? Company(null);
    this.subject = companies[this.subjectEdinetCode] ?? Company(null);
    this.subsidiary = companies[this.subsidiaryEdinetCode] ?? Company(null);
  }

  String get relatedCompaniesName {
    return [filerName, issuer?.name, subject?.name, subsidiary?.name]
        .where((e) => e != null && e != '')
        .join(',');
  }

  List<Company?> get companies {
    return [filer, issuer, subject, subsidiary]
        .where((c) => c?.code != null)
        .toList();
  }

  static List<String> docTypes() {
    return [
      '大量保有報告書',
      '四半期報告書',
      '訂正四半期報告書',
      '公開買付届出書',
      '有価証券通知書',
      '変更通知書(有価証券通知書)',
      '有価証券届出書',
      '訂正有価証券届出書',
      '届出の取下げ願い',
      '発行登録通知書',
      '変更通知書(発行登録通知書)',
      '発行登録書',
      '訂正発行登録書',
      '発行登録追補書類',
      '発行登録取下届出書',
      '有価証券報告書',
      '訂正有価証券報告書',
      '確認書',
      '訂正確認書',
      '半期報告書',
      '訂正半期報告書',
      '臨時報告書',
      '訂正臨時報告書',
      '親会社等状況報告書',
      '訂正親会社等状況報告書',
      '自己株券買付状況報告書',
      '訂正自己株券買付状況報告書',
      '内部統制報告書',
      '訂正内部統制報告書',
      '訂正公開買付届出書',
      '公開買付撤回届出書',
      '公開買付報告書',
      '訂正公開買付報告書',
      '意見表明報告書',
      '訂正意見表明報告書',
      '対質問回答報告書',
      '訂正対質問回答報告書',
      '別途買付け禁止の特例を受けるための申出書',
      '訂正別途買付け禁止の特例を受けるための申出書',
      '訂正大量保有報告書',
      '基準日の届出書',
      '変更の届出書',
    ];
  }

  String get docType {
    switch (this.docTypeCode) {
      case '010':
        return '有価証券通知書';
      case '020':
        return '変更通知書(有価証券通知書)';
      case '030':
        return '有価証券届出書';
      case '040':
        return '訂正有価証券届出書';
      case '050':
        return '届出の取下げ願い';
      case '060':
        return '発行登録通知書';
      case '070':
        return '変更通知書(発行登録通知書)';
      case '080':
        return '発行登録書';
      case '090':
        return '訂正発行登録書';
      case '100':
        return '発行登録追補書類';
      case '110':
        return '発行登録取下届出書';
      case '120':
        return '有価証券報告書';
      case '130':
        return '訂正有価証券報告書';
      case '135':
        return '確認書';
      case '136':
        return '訂正確認書';
      case '140':
        return '四半期報告書';
      case '150':
        return '訂正四半期報告書';
      case '160':
        return '半期報告書';
      case '170':
        return '訂正半期報告書';
      case '180':
        return '臨時報告書';
      case '190':
        return '訂正臨時報告書';
      case '200':
        return '親会社等状況報告書';
      case '210':
        return '訂正親会社等状況報告書';
      case '220':
        return '自己株券買付状況報告書';
      case '230':
        return '訂正自己株券買付状況報告書';
      case '235':
        return '内部統制報告書';
      case '236':
        return '訂正内部統制報告書';
      case '240':
        return '公開買付届出書';
      case '250':
        return '訂正公開買付届出書';
      case '260':
        return '公開買付撤回届出書';
      case '270':
        return '公開買付報告書';
      case '280':
        return '訂正公開買付報告書';
      case '290':
        return '意見表明報告書';
      case '300':
        return '訂正意見表明報告書';
      case '310':
        return '対質問回答報告書';
      case '320':
        return '訂正対質問回答報告書';
      case '330':
        return '別途買付け禁止の特例を受けるための申出書';
      case '340':
        return '訂正別途買付け禁止の特例を受けるための申出書';
      case '350':
        return '大量保有報告書';
      case '360':
        return '訂正大量保有報告書';
      case '370':
        return '基準日の届出書';
      case '380':
        return '変更の届出書';
      default:
        return '';
    }
  }
}
