import "dotenv/config";
import * as path from "node:path";
import { TypeSafeClient } from "@typesafe-ai/sdk";
import { extractSectionsFromZip } from "./zip_extractor.js";
import { extractFinancialMetricsFromZip } from "./financial_metrics_extractor.js";
import { detectQualitativeExcuses } from "./schemas/qualitative_excuses.js";
import { detectFinancialAnomaly } from "./schemas/financial_anomaly.js";

const apiKey = process.env.TYPESAFE_API_KEY;
if (!apiKey) {
  console.error("❌ エラー: TYPESAFE_API_KEY が設定されていません。");
  process.exit(1);
}

const client = new TypeSafeClient({ apiKey });

async function main() {
  console.log("===============================================================");
  console.log("  ⚖️ 定量数値の入力有無による Jev 判定結果の比較検証 (アクセルマーク 3624)");
  console.log("===============================================================\n");

  const currentZip = path.resolve("data/downloads/S100UZAD.zip");

  // 1. 定量数値の抽出（純粋なファクト）
  const metrics = extractFinancialMetricsFromZip(currentZip);
  console.log("📊 【有報から機械抽出した純粋な客観的財務数値（ファクト）】");
  console.log({
    売上高: `${metrics.revenue?.toLocaleString()} 千円`,
    当期純利益: `${metrics.netIncome?.toLocaleString()} 千円`,
    営業キャッシュフロー: `${metrics.operatingCashFlow?.toLocaleString()} 千円`,
    総資産: `${metrics.totalAssets?.toLocaleString()} 千円`,
  });
  console.log("");

  // 2. 定性テキストの抽出
  const currentSections = extractSectionsFromZip(currentZip);
  const mdaText = currentSections.get("ManagementAnalysisOfFinancialPositionOperatingResultsAndCashFlowsTextBlock")?.text || "";
  const gcText = currentSections.get("EventsOrConditionsThatCastSignificantDoubtOnGoingConcernAssumptionTextBlock")?.text || "";
  const currentRisk = currentSections.get("BusinessRisksTextBlock")?.text || "";
  const combinedNotes = `${gcText}\n${currentRisk}`;

  // ---------------------------------------------------------------------------
  // Pattern A: 定量数値なし (定性テキストのみ)
  // ---------------------------------------------------------------------------
  console.log("---------------------------------------------------------------");
  console.log("▶ 【パターン A】定量数値なし（定性テキストのみを Jev に入力）");
  console.log("---------------------------------------------------------------");
  const [excuseA, financialA] = await Promise.all([
    detectQualitativeExcuses(client, mdaText),
    detectFinancialAnomaly(client, combinedNotes),
  ]);

  console.log("① 経営陣の業績理由:");
  console.log("   生データ:", {
    hasNegativeFactors: excuseA.hasNegativeFactors,
    blameAttribution: excuseA.blameAttribution,
    causeTags: excuseA.causeTags,
  });
  console.log("   UI表示:", excuseA.uiPresentation.headline);
  console.log("");

  console.log("② 財務・注記リスク:");
  console.log("   生データ:", {
    detectedRedFlags: financialA.detectedRedFlags,
    riskLevel: financialA.riskLevel,
  });
  console.log("   UI表示:", financialA.uiPresentation.headline, `(検出項目: ${financialA.uiPresentation.detected_items.join(", ")})`);
  console.log("");

  // ---------------------------------------------------------------------------
  // Pattern B: 定量数値あり (定性テキスト ＋ 客観的財務数値を Jev に入力)
  // ---------------------------------------------------------------------------
  console.log("---------------------------------------------------------------");
  console.log("▶ 【パターン B】定量数値あり（定性テキスト ＋ 純粋な財務数値を Jev に入力）");
  console.log("---------------------------------------------------------------");
  const [excuseB, financialB] = await Promise.all([
    detectQualitativeExcuses(client, mdaText, metrics),
    detectFinancialAnomaly(client, combinedNotes, metrics),
  ]);

  console.log("① 経営陣の業績理由:");
  console.log("   生データ:", {
    hasNegativeFactors: excuseB.hasNegativeFactors,
    blameAttribution: excuseB.blameAttribution,
    causeTags: excuseB.causeTags,
  });
  console.log("   UI表示:", excuseB.uiPresentation.headline);
  console.log("   詳細文:", excuseB.uiPresentation.description);
  console.log("");

  console.log("② 財務・注記リスク:");
  console.log("   生データ:", {
    detectedRedFlags: financialB.detectedRedFlags,
    riskLevel: financialB.riskLevel,
  });
  console.log("   UI表示:", financialB.uiPresentation.headline);
  console.log("   検出項目:", financialB.uiPresentation.detected_items.join(", "));
  console.log("   詳細文:", financialB.uiPresentation.description);
  console.log("");

  // ---------------------------------------------------------------------------
  // 比較まとめ
  // ---------------------------------------------------------------------------
  console.log("===============================================================");
  console.log("  🔍 パターンA（テキストのみ） vs パターンB（数値ファクトあり）の比較");
  console.log("===============================================================\n");
  console.log(`【財務レッドフラグの検出数】:`);
  console.log(`  パターンA (テキストのみ) : ${financialA.detectedRedFlags.join(", ")}`);
  console.log(`  パターンB (数値ファクト付): ${financialB.detectedRedFlags.join(", ")}`);
}

main().catch(console.error);
