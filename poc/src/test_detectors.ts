import "dotenv/config";
import { TypeSafeClient } from "@typesafe-ai/sdk";
import { detectBlameAttribution } from "./detectors/blame_attribution.js";
import { detectKpiOmission } from "./detectors/kpi_omission.js";
import { detectFinancialAnomaly } from "./detectors/financial_anomaly.js";

const apiKey = process.env.TYPESAFE_API_KEY;
if (!apiKey) {
  console.error("❌ エラー: TYPESAFE_API_KEY が設定されていません。");
  process.exit(1);
}

const client = new TypeSafeClient({ apiKey });

async function runTests() {
  console.log("===============================================================");
  console.log("  🔬 高度フォレンジック判定ディテクター 3選 テスト実行");
  console.log("===============================================================\n");

  // ---------------------------------------------------------------------------
  // 1. 定性言い訳・責任転嫁の検知 (Blame Attribution)
  // ---------------------------------------------------------------------------
  console.log("▶ 【テスト 1】定性言い訳・責任転嫁の検知（MD&A・業績理由）");
  const mdaExcuseSample = `
当第３四半期連結累計期間における当社グループの営業利益は、前年同期比32.4%の減益となりました。
この主たる要因といたしましては、夏季における記録的な猛暑および台風の上陸による一時的な来店客数の減少、
ならびにウクライナ情勢の長期化に伴う輸入原材料価格および電力エネルギーコストの歴史的な高騰によるものであります。
なお、これらの一過性の外部要因による影響を除けば、当社のブランド力は依然として極めて高く、
足元におきましては客足も底打ち傾向が見られており、中長期的には堅調な業績回復を果たすものと確信しております。
`.trim();

  console.log("--- 入力テキスト (MD&A抜粋) ---");
  console.log(mdaExcuseSample);
  console.log("---------------------------------");

  const start1 = Date.now();
  const res1 = await detectBlameAttribution(client, mdaExcuseSample);
  const lat1 = Date.now() - start1;

  console.log(`⏱️ 判定速度: ${lat1}ms`);
  console.log("🔍 結果:");
  console.log(`  ・減益要因の言及あり  : ${res1.hasNegativeFactors ? "YES" : "NO"}`);
  console.log(`  ・主張する不振の主因  : 【${res1.blameAttribution}】`);
  console.log(`  ・根拠なき楽観形容詞  : ${res1.unusualModifierDetected ? "🚨 検知 (底打ち/中長期堅調など)" : "なし"}`);
  console.log(`  ・System 2 推論トリガー: ${res1.triggerSystem2 ? "⚡ TRUE (要・深層調査)" : "FALSE"}\n`);

  // ---------------------------------------------------------------------------
  // 2. 前期比較における「言及消滅・定義変更」検知 (KPI Omission)
  // ---------------------------------------------------------------------------
  console.log("▶ 【テスト 2】前期比較における重点KPIの言及消滅・ぼかし検知");
  const targetKpi = "SaaS ARR（年間経常収益）および解約率(Churn Rate)";
  const prevKpiExcerpt = `
当社は最重要経営指標としてARRを位置づけており、当事業年度末のARRは前年比48.5%増の32.4億円に急拡大いたしました。
また、ネットレベニューリテンション(NRR)は124%、月次解約率(Churn Rate)は0.45%と極めて健全なユニットエコノミクスを維持しております。
`.trim();

  const currKpiText = `
当事業年度におけるクラウドプラットフォーム事業におきましては、既存顧客へのアップセル提案および
パートナー企業との連携強化に注力いたしました。市場のデジタル変革需要を背景に、事業は順調に推移しております。
今後はエンタープライズ領域への展開を加速し、サービス品質の向上に努めてまいります。
`.trim();

  console.log(`--- 対象KPI: ${targetKpi} ---`);
  console.log(`前期: "${prevKpiExcerpt}"`);
  console.log(`当期: "${currKpiText}"`);
  console.log("---------------------------------");

  const start2 = Date.now();
  const res2 = await detectKpiOmission(client, targetKpi, prevKpiExcerpt, currKpiText);
  const lat2 = Date.now() - start2;

  console.log(`⏱️ 判定速度: ${lat2}ms`);
  console.log("🔍 結果:");
  console.log(`  ・開示ステータス      : 【${res2.trackedItemStatus}】`);
  console.log(`  ・開示後退の深刻度    : ${(res2.omissionSeverity * 100).toFixed(0)}%`);
  console.log(`  ・System 2 推論トリガー: ${res2.triggerSystem2 ? "⚡ TRUE (KPI隠蔽疑惑)" : "FALSE"}\n`);

  // ---------------------------------------------------------------------------
  // 3. 財務・注記リスクの高速フラグ立て (Financial Anomaly)
  // ---------------------------------------------------------------------------
  console.log("▶ 【テスト 3】財務・注記リスクの高速フラグ立て（金利・タコ足分配・注記）");
  const notesSample = `
当期（第24期）の1口当たり分配金につきましては、前期水準（3,400円）を維持するため、
当期純利益（12.5億円）に加えて、利益超過分配金として一時差額調整引当額および繰越利益剰余金より
計2.8億円を取り崩して充当いたしました。
なお、有利子負債残高のうち変動金利による借入金比率は64.5%となっており、
国内金利の先高観を考慮し、今後の金利更改に伴う金融費用の増加リスクを注視してまいります。
また、保有物件「Aビル」につきましては主要テナントの退去に伴い減損の兆候が認められます。
`.trim();

  console.log("--- 入力注記テキスト ---");
  console.log(notesSample);
  console.log("------------------------");

  const start3 = Date.now();
  const res3 = await detectFinancialAnomaly(client, notesSample);
  const lat3 = Date.now() - start3;

  console.log(`⏱️ 判定速度: ${lat3}ms`);
  console.log("🔍 結果:");
  console.log(`  ・変動金利・調達急騰アラート: ${res3.interestRateStructureAlert ? "🚨 警戒 (変動比率60%超など)" : "なし"}`);
  console.log(`  ・利益超過・タコ足分配アラート: ${res3.payoutManipulationAlert ? "🚨 警戒 (利益超過・剰余金取崩し)" : "なし"}`);
  console.log(`  ・会計フォレンジック種別      : 【${res3.accountingRedFlagType}】`);
  console.log(`  ・総合リスクレベル            : 【${res3.riskLevel.toUpperCase()}】`);
  console.log(`  ・System 2 推論トリガー        : ${res3.triggerSystem2 ? "⚡ TRUE (財務爆弾検知)" : "FALSE"}\n`);

  console.log("===============================================================");
  console.log("✅ 全ディテクターのテストが正常に完了しました！");
}

runTests().catch((err) => {
  console.error("❌ エラー:", err);
  process.exit(1);
});
