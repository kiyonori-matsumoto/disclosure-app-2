import "dotenv/config";
import * as path from "node:path";
import { extractSectionsFromZip } from "./zip_extractor.js";
import { computeDiff } from "./differ.js";
import { TagEngine } from "./tag_engine.js";

async function main() {
  console.log("===============================================================");
  console.log("  🏷️ トヨタ自動車 (7203) 有報リスクタグ検知 検証");
  console.log("===============================================================\n");

  const apiKey = process.env.TYPESAFE_API_KEY;
  if (!apiKey) {
    console.error("❌ エラー: TYPESAFE_API_KEY が設定されていません。");
    process.exit(1);
  }

  const priorZip = path.resolve("data/downloads/S100QZHY.zip");
  const currentZip = path.resolve("data/downloads/S100TR7I.zip");

  console.log(`📂 前期 (第119期): ${priorZip}`);
  console.log(`📂 当期 (第120期): ${currentZip}\n`);

  console.log("⚙️  有報ZIPからセクションを抽出中...");
  const priorSections = extractSectionsFromZip(priorZip);
  const currentSections = extractSectionsFromZip(currentZip);

  // 1. 事業等のリスクの差分
  const priorRisk = priorSections.get("BusinessRisksTextBlock")?.text || "";
  const currentRisk = currentSections.get("BusinessRisksTextBlock")?.text || "";
  const riskDiff = computeDiff("BusinessRisksTextBlock", "事業等のリスク", priorRisk, currentRisk);

  // 2. MD&A (経営成績等の状況の分析)
  const mdaText = currentSections.get("ManagementAnalysisOfFinancialPositionOperatingResultsAndCashFlowsTextBlock")?.text || "";

  // 3. 会計方針の変更
  const accountingPolicyText = currentSections.get("ChangesInAccountingPoliciesTextBlock")?.text || "";

  console.log("🤖 Jev によるタグ検知を実行中...\n");
  const engine = new TagEngine(apiKey);

  const start = Date.now();

  // 3つのセクションを並列に Jev に投げてタグを判定
  const [riskTags, mdaTags, footnoteTags] = await Promise.all([
    engine.detectRiskSectionTags(riskDiff.diffSummaryText),
    engine.detectMdaTags(mdaText),
    engine.detectFootnoteTags("", accountingPolicyText),
  ]);

  const duration = Date.now() - start;
  const allTags = [...new Set([...riskTags, ...mdaTags, ...footnoteTags])];
  const overallRisk = engine.computeOverallRisk(allTags);

  console.log("===============================================================");
  console.log(`  ⏱️ 解析所要時間: ${duration}ms (並列Jev判定)`);
  console.log(`  🚨 総合リスク判定: 【${overallRisk}】`);
  console.log("===============================================================\n");

  console.log("🏷️  【検知されたタグ一覧】");
  if (allTags.length === 0) {
    console.log("   ✅ [正常開示] リスクタグは検知されませんでした。");
  } else {
    allTags.forEach((tag) => console.log(`   ・${tag}`));
  }
  console.log("");

  console.log("--- セクション別の詳細内訳 ---");
  console.log(`  ・事業等のリスク差分 : ${riskTags.join(", ") || "タグなし"}`);
  console.log(`  ・MD&A（経営陣トーン）: ${mdaTags.join(", ") || "タグなし"}`);
  console.log(`  ・注記・会計方針     : ${footnoteTags.join(", ") || "タグなし"}\n`);

  // Firestore 保存用スキーマ
  const firestoreRecord = {
    docId: "S100TR7I",
    companyCode: "7203",
    companyName: "トヨタ自動車株式会社",
    filingDate: "2024-06-25",
    overallRisk,
    tags: allTags,
  };

  console.log("📱 【Firestore 保存用ペイロード】");
  console.log(JSON.stringify(firestoreRecord, null, 2));
}

main().catch((err) => {
  console.error("❌ エラー:", err);
  process.exit(1);
});
