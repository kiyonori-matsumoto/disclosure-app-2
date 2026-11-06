import "dotenv/config";
import * as path from "node:path";
import { TypeSafeClient } from "@typesafe-ai/sdk";
import { detectQualitativeExcuses } from "./schemas/qualitative_excuses.js";
import { detectKpiOmission } from "./schemas/kpi_omission.js";
import { detectFinancialAnomaly } from "./schemas/financial_anomaly.js";
import { extractSectionsFromZip } from "./zip_extractor.js";

const apiKey = process.env.TYPESAFE_API_KEY;
if (!apiKey) {
  console.error("❌ エラー: TYPESAFE_API_KEY が設定されていません。");
  process.exit(1);
}

const client = new TypeSafeClient({ apiKey });

async function main() {
  console.log("===============================================================");
  console.log("  💎 完全フリーテキスト廃止版（Literal / bool のみ）検証");
  console.log("===============================================================\n");

  // ---------------------------------------------------------------------------
  // 1. 定性言い訳・責任転嫁の検知
  // ---------------------------------------------------------------------------
  console.log("▶ 【1. 定性言い訳・責任転嫁の検知】");
  const mdaSample = `
当第３四半期連結累計期間における当社グループの営業利益は、前年同期比32.4%の減益となりました。
この主たる要因といたしましては、夏季における記録的な猛暑および台風の上陸による一時的な来店客数の減少、
ならびにウクライナ情勢の長期化に伴う輸入原材料価格および電力エネルギーコストの歴史的な高騰によるものであります。
なお、これらの一過性の外部要因による影響を除けば、当社のブランド力は依然として極めて高く、
足元におきましては客足も底打ち傾向が見られており、中長期的には堅調な業績回復を果たすものと確信しております。
`.trim();

  const res1 = await detectQualitativeExcuses(client, mdaSample);
  console.log("Jev からの生データ (Literal/boolのみ):", {
    hasNegativeFactors: res1.hasNegativeFactors,
    causeTags: res1.causeTags,
    blameAttribution: res1.blameAttribution,
    unfoundedOptimismDetected: res1.unfoundedOptimismDetected,
  });
  console.log("📱 UI Presentation (自動合成された表示用データ):");
  console.log(JSON.stringify(res1.uiPresentation, null, 2));
  console.log("");

  // ---------------------------------------------------------------------------
  // 2. 前期比較における重点KPIの言及消滅・定義変更検知
  // ---------------------------------------------------------------------------
  console.log("▶ 【2. 前期比較における重点KPIの言及消滅検知】");
  const targetKpi = "SaaS ARR成長率および解約率";
  const prevKpi = `当社は最重要経営指標としてARRを位置づけており、当事業年度末のARRは前年比48.5%増の32.4億円に急拡大いたしました。`;
  const currKpi = `当事業年度におけるクラウドプラットフォーム事業におきましては、パートナー連携を強化し、事業は順調に推移しております。`;

  const res2 = await detectKpiOmission(client, targetKpi, prevKpi, currKpi);
  console.log("Jev からの生データ (Literalのみ):", {
    trackedItemStatus: res2.trackedItemStatus,
    severity: res2.severity,
  });
  console.log("📱 UI Presentation (自動合成された表示用データ):");
  console.log(JSON.stringify(res2.toUiPresentation(targetKpi), null, 2));
  console.log("");

  // ---------------------------------------------------------------------------
  // 3. 財務・注記リスクの検知
  // ---------------------------------------------------------------------------
  console.log("▶ 【3. 財務・注記リスクの検知】");
  const notesSample = `
当期（第24期）の1口当たり分配金につきましては、前期水準（3,400円）を維持するため、
当期純利益（12.5億円）に加えて、利益超過分配金として一時差額調整引当額および繰越利益剰余金より
計2.8億円を取り崩して充当いたしました。
なお、有利子負債残高のうち変動金利による借入金比率は64.5%となっており、
今後の金利更改に伴う金融費用の増加リスクを注視してまいります。
また、保有物件「Aビル」につきましては主要テナントの退去に伴い減損の兆候が認められます。
`.trim();

  const res3 = await detectFinancialAnomaly(client, notesSample);
  console.log("Jev からの生データ (Literalのみ):", {
    detectedRedFlags: res3.detectedRedFlags,
    riskLevel: res3.riskLevel,
  });
  console.log("📱 UI Presentation (自動合成された表示用データ):");
  console.log(JSON.stringify(res3.uiPresentation, null, 2));
  console.log("");

  // ---------------------------------------------------------------------------
  // 4. トヨタ自動車の実有報データへの適用
  // ---------------------------------------------------------------------------
  console.log("===============================================================");
  console.log("▶ 【4. トヨタ自動車 (7203) の実データへの適用】");
  console.log("===============================================================");
  const currentZip = path.resolve("data/downloads/S100TR7I.zip");
  const currentSections = extractSectionsFromZip(currentZip);

  const toyotaMda = currentSections.get("ManagementAnalysisOfFinancialPositionOperatingResultsAndCashFlowsTextBlock")?.text || "";
  const toyotaNotes = currentSections.get("BusinessRisksTextBlock")?.text || "";

  console.log("📡 トヨタのMD&A（業績理由）を解析中...");
  const toyotaExcuse = await detectQualitativeExcuses(client, toyotaMda);

  console.log("📡 トヨタの事業リスク・注記を解析中...");
  const toyotaFinancial = await detectFinancialAnomaly(client, toyotaNotes);

  console.log("\n📱 トヨタ自動車の UI Presentation 診断結果:");
  console.log("【定性言い訳・経営陣トーン】");
  console.log(JSON.stringify(toyotaExcuse.uiPresentation, null, 2));
  console.log("\n【財務・注記リスク】");
  console.log(JSON.stringify(toyotaFinancial.uiPresentation, null, 2));
}

main().catch((err) => {
  console.error("❌ エラー:", err);
  process.exit(1);
});
