import * as cheerio from "cheerio";

export interface QualitativeSection {
  tag: string;
  label: string;
  text: string;
}

// 監視・比較対象とする主要定性タグ
export const TARGET_SECTIONS: Record<string, string> = {
  "BusinessRisksTextBlock": "事業等のリスク",
  "PolicyEnvironmentIssuesToAddressEtcTextBlock": "対処すべき課題等",
  "ManagementAnalysisOfFinancialPositionOperatingResultsAndCashFlowsTextBlock": "経営成績等の状況の分析",
  "EventsOrConditionsThatCastSignificantDoubtOnGoingConcernAssumptionTextBlock": "継続企業の前提に関する重要事象等",
  "ChangesInAccountingPoliciesTextBlock": "会計方針の変更",
  "SignificantSubsequentEventsTextBlock": "重要な後発事象",
  "OpinionTextBlock": "監査意見",
};

/**
 * iXBRL (.htm) のHTML文字列から指定された定性セクションのテキストを抽出する
 */
export function extractQualitativeSections(htmlContent: string): Map<string, QualitativeSection> {
  const $ = cheerio.load(htmlContent);
  const results = new Map<string, QualitativeSection>();

  // ix:nonNumeric または nonNumeric 要素を探索
  $("ix\\:nonnumeric, nonnumeric").each((_, elem) => {
    const $elem = $(elem);
    const nameAttr = $elem.attr("name") || "";

    for (const [key, label] of Object.entries(TARGET_SECTIONS)) {
      if (nameAttr.includes(key)) {
        // テキストを抽出して空白・改行を正規化
        // HTMLテーブルや段落の構造をある程度維持するため、pやtrの後に改行を補正
        $elem.find("br").replaceWith("\n");
        $elem.find("p, div, tr").each((_, block) => {
          $(block).append("\n");
        });

        const rawText = $elem.text();
        const cleanedText = cleanText(rawText);

        if (cleanedText.length > 0) {
          results.set(key, {
            tag: nameAttr,
            label,
            text: cleanedText,
          });
        }
      }
    }
  });

  return results;
}

/**
 * テキストの正規化（連続する空白や空行の除去、全角半角の軽微な調整）
 */
export function cleanText(text: string): string {
  return text
    .replace(/\r\n/g, "\n")
    .replace(/\r/g, "\n")
    .replace(/[ \t]+/g, " ") // 連続するスペース・タブを1つに
    .replace(/\n\s*\n\s*\n+/g, "\n\n") // 3つ以上の連続改行を2つに
    .trim();
}
