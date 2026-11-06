import "dotenv/config";
import * as path from "node:path";
import { EdinetClient } from "./edinet_client.js";
import { extractSectionsFromZip } from "./zip_extractor.js";
import { computeDiff } from "./differ.js";
import { TypeSafeClient } from "@typesafe-ai/sdk";
import { detectQualitativeExcuses } from "./schemas/qualitative_excuses.js";
import { detectFinancialAnomaly } from "./schemas/financial_anomaly.js";
import { extractFinancialMetricsFromZip, assessQuantitativeRisk } from "./financial_metrics_extractor.js";

async function main() {
  console.log("===============================================================");
  console.log("  🏢 アクセルマーク株式会社 (3624) フォレンジック完全評価");
  console.log("===============================================================\n");

  const typesafeKey = process.env.TYPESAFE_API_KEY;
  if (!typesafeKey) {
    console.error("❌ エラー: TYPESAFE_API_KEY が設定されていません。");
    process.exit(1);
  }

  const priorDocId = "S100SIWP"; // 2023年有報 (第31期)
  const currentDocId = "S100UZAD"; // 2024年有報 (第32期)

  const edinetClient = new EdinetClient();
  const client = new TypeSafeClient({ apiKey: typesafeKey });

  // 1. 書類のダウンロード
  console.log("📥 EDINET から有報ZIPをダウンロード中...");
  const priorPath = path.resolve(`data/downloads/${priorDocId}.zip`);
  const currentPath = path.resolve(`data/downloads/${currentDocId}.zip`);

  const [priorBuf, currentBuf] = await Promise.all([
    edinetClient.downloadDocumentZip(priorDocId, priorPath),
    edinetClient.downloadDocumentZip(currentDocId, currentPath),
  ]);
  console.log("   └ ダウンロード完了！\n");

  // 2. 定量財務数値のパース & ルール判定
  console.log("📊 1. 定量財務データの抽出 & 数理判定...");
  const metrics = extractFinancialMetricsFromZip(currentBuf);
  const quantAssessment = assessQuantitativeRisk(metrics);

  console.log(`  ・売上高・収益          : ${metrics.revenue?.toLocaleString() || "---"} 百万円`);
  console.log(`  ・当期純損益            : ${metrics.netIncome?.toLocaleString() || "---"} 百万円`);
  console.log(`  ・営業活動による現金(CF): ${metrics.operatingCashFlow?.toLocaleString() || "---"} 百万円`);
  console.log(`  ・総資産                : ${metrics.totalAssets?.toLocaleString() || "---"} 百万円`);
  if (quantAssessment.quantitativeWarnings.length > 0) {
    quantAssessment.quantitativeWarnings.forEach((w) => console.log(`  🚨 【定量アラート】${w}`));
  } else {
    console.log("  ✅ 定量キャッシュフローは基準内");
  }
  console.log("");

  // 3. 定性セクションの抽出
  console.log("⚙️  2. 定性セクション（MD&A、事業等のリスク、注記）の抽出...");
  const priorSections = extractSectionsFromZip(priorBuf);
  const currentSections = extractSectionsFromZip(currentBuf);

  const priorRisk = priorSections.get("BusinessRisksTextBlock")?.text || "";
  const currentRisk = currentSections.get("BusinessRisksTextBlock")?.text || "";
  const riskDiff = computeDiff("BusinessRisksTextBlock", "事業等のリスク", priorRisk, currentRisk);

  const mdaText = currentSections.get("ManagementAnalysisOfFinancialPositionOperatingResultsAndCashFlowsTextBlock")?.text || "";
  const gcText = currentSections.get("EventsOrConditionsThatCastSignificantDoubtOnGoingConcernAssumptionTextBlock")?.text || "";
  const accountingPolicyText = currentSections.get("ChangesInAccountingPoliciesTextBlock")?.text || "";

  console.log(`   ・事業等のリスク差分: 追加 ${riskDiff.addedLines.length}行 / 削除 ${riskDiff.removedLines.length}行`);
  console.log(`   ・継続企業の前提(GC)注記の有無: ${gcText ? "🚨 GC注記セクションあり！" : "なし"}\n`);

  // 4. Jev による定性判定（言い訳・注記リスク）
  console.log("🤖 3. Jev (TypeSafe AI) による定性フォレンジック判定を実行中...");
  const startTime = Date.now();

  const [excuseResult, financialResult] = await Promise.all([
    detectQualitativeExcuses(client, mdaText),
    detectFinancialAnomaly(client, `${gcText}\n${currentRisk}\n${accountingPolicyText}`),
  ]);

  // 定量判定のフラグもマージ
  quantAssessment.detectedRedFlags.forEach((flag) => {
    if (!financialResult.detectedRedFlags.includes(flag)) {
      financialResult.detectedRedFlags.push(flag);
    }
  });

  const duration = Date.now() - startTime;
  console.log(`   └ 判定完了 (${duration}ms)\n`);

  // 5. 結果表示
  console.log("===============================================================");
  console.log("  📱 【アクセルマーク (3624) のフォレンジック診断結果】");
  console.log("===============================================================\n");

  console.log("■ 【1. 経営陣の業績言い訳・責任転嫁】");
  console.log(JSON.stringify(excuseResult.uiPresentation, null, 2));
  console.log("");

  console.log("■ 【2. 財務・資金繰り・注記リスク】");
  console.log(JSON.stringify(financialResult.uiPresentation, null, 2));
  console.log("");

  if (gcText) {
    console.log("■ 【🚨 継続企業の前提に関する注記（抜粋）】");
    console.log(gcText.slice(0, 300) + "...\n");
  }
}

main().catch((err) => {
  console.error("❌ エラー:", err);
  process.exit(1);
});
