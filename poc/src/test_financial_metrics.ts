import * as path from "node:path";
import { extractFinancialMetricsFromZip, assessQuantitativeRisk } from "./financial_metrics_extractor.js";
import { FinancialAnomalySchema } from "./schemas/financial_anomaly.js";

async function main() {
  console.log("===============================================================");
  console.log("  📊 有報iXBRLからの財務数値パース＆定量的リスク判定");
  console.log("===============================================================\n");

  const toyotaZip = path.resolve("data/downloads/S100TR7I.zip");
  console.log(`📂 対象ファイル: ${toyotaZip}\n`);

  // 1. 財務数値のパース
  console.log("⚙️  有報から主要財務数値を抽出中...");
  const metrics = extractFinancialMetricsFromZip(toyotaZip);

  console.log("📈 【抽出された財務数値（トヨタ自動車 2024年3月期）】");
  console.log(`  ・売上高・収益          : ${metrics.revenue ? (metrics.revenue / 1000000).toFixed(1) + " 兆円" : "取得できず"} (${metrics.revenue?.toLocaleString()} 百万円)`);
  console.log(`  ・当期純利益            : ${metrics.netIncome ? (metrics.netIncome / 1000000).toFixed(1) + " 兆円" : "取得できず"} (${metrics.netIncome?.toLocaleString()} 百万円)`);
  console.log(`  ・営業活動による現金(CF): ${metrics.operatingCashFlow ? (metrics.operatingCashFlow / 1000000).toFixed(1) + " 兆円" : "取得できず"} (${metrics.operatingCashFlow?.toLocaleString()} 百万円)`);
  console.log(`  ・配当性向              : ${metrics.payoutRatio !== undefined ? metrics.payoutRatio.toFixed(1) + " %" : "取得できず"}`);
  console.log(`  ・総資産                : ${metrics.totalAssets ? (metrics.totalAssets / 1000000).toFixed(1) + " 兆円" : "取得できず"} (${metrics.totalAssets?.toLocaleString()} 百万円)`);
  console.log("");

  // 2. 数値ベースの定量的リスク判定
  console.log("⚖️  財務リスク判定（営業CF赤字・タコ足配当チェック）を実行...");
  const assessment = assessQuantitativeRisk(metrics);

  console.log(`  検知されたレッドフラグ: ${assessment.detectedRedFlags.length > 0 ? assessment.detectedRedFlags.join(", ") : "なし（極めて健全）"}`);
  if (assessment.quantitativeWarnings.length > 0) {
    assessment.quantitativeWarnings.forEach((w) => console.log(`  ⚠️ ${w}`));
  } else {
    console.log("  ✅ 営業CF・利益・配当バランスともに健全です。");
  }
  console.log("");

  // 3. FinancialAnomalySchema との結合
  const schema = new FinancialAnomalySchema(
    assessment.detectedRedFlags,
    assessment.detectedRedFlags.length > 0 ? "medium" : "low"
  );

  console.log("📱 【UI Presentation（プログラム自動判定結果）】");
  console.log(JSON.stringify(schema.uiPresentation, null, 2));
}

main().catch(console.error);
