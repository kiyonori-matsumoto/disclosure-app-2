import "dotenv/config";
import * as path from "node:path";
import { EdinetClient } from "./edinet_client.js";
import { extractSectionsFromZip } from "./zip_extractor.js";
import { computeDiff } from "./differ.js";
import { ForensicAnalyzer, RiskAnalysisReport } from "./analyzer.js";

async function main() {
  const args = process.argv.slice(2);
  const priorDocId = args[0];
  const currentDocId = args[1];

  if (!priorDocId || !currentDocId) {
    console.error("使用方法: npx tsx src/analyze_by_docid.ts <前期docId> <当期docId>");
    console.error("例: npx tsx src/analyze_by_docid.ts S100XXXX S100YYYY\n");
    process.exit(1);
  }

  const typesafeKey = process.env.TYPESAFE_API_KEY;
  if (!typesafeKey) {
    console.error("❌ エラー: TYPESAFE_API_KEY が設定されていません。");
    process.exit(1);
  }

  const edinetClient = new EdinetClient();

  console.log("===============================================================");
  console.log("  📥 EDINET API 直結 有報定性フォレンジック解析");
  console.log("===============================================================\n");

  console.log(`📡 前期書類 (${priorDocId}) をダウンロード中...`);
  const priorZipPath = path.resolve(`data/downloads/${priorDocId}.zip`);
  const priorBuffer = await edinetClient.downloadDocumentZip(priorDocId, priorZipPath);
  console.log(`   └ 保存完了: ${priorZipPath}`);

  console.log(`📡 当期書類 (${currentDocId}) をダウンロード中...`);
  const currentZipPath = path.resolve(`data/downloads/${currentDocId}.zip`);
  const currentBuffer = await edinetClient.downloadDocumentZip(currentDocId, currentZipPath);
  console.log(`   └ 保存完了: ${currentZipPath}\n`);

  console.log("⚙️  ZIP内から定性セクション (BusinessRisksTextBlock等) を抽出中...");
  const priorSections = extractSectionsFromZip(priorBuffer);
  const currentSections = extractSectionsFromZip(currentBuffer);

  console.log(`   前期セクション数: ${priorSections.size} 件`);
  console.log(`   当期セクション数: ${currentSections.size} 件\n`);

  const diffs = [];
  for (const [key, currentSec] of currentSections.entries()) {
    const priorSec = priorSections.get(key);
    const priorText = priorSec ? priorSec.text : "";
    const diff = computeDiff(key, currentSec.label, priorText, currentSec.text);
    if (diff.hasChanges) {
      diffs.push(diff);
      console.log(`   ⚡ [差分あり] ${diff.sectionLabel}: 追加 ${diff.addedLines.length}行 / 削除 ${diff.removedLines.length}行`);
    } else {
      console.log(`   ⚪ [変更なし] ${diff.sectionLabel}`);
    }
  }

  if (diffs.length === 0) {
    console.log("\n⚠️ 抽出されたセクションに変更は見つかりませんでした。");
    return;
  }

  console.log("\n🤖 Jev (TypeSafe AI) によるフォレンジック判定を実行中...");
  const analyzer = new ForensicAnalyzer(typesafeKey);
  const reports: RiskAnalysisReport[] = [];

  for (const diff of diffs) {
    console.log(`   📡 Jev 判定中: [${diff.sectionLabel}]...`);
    const startTime = Date.now();
    const report = await analyzer.analyzeSectionDiff(diff);
    const latency = Date.now() - startTime;
    console.log(`      └ 判定完了 (${latency}ms) => ${report.badge} (Score: ${(report.riskScore * 100).toFixed(0)}%)`);
    reports.push(report);
  }

  console.log("\n===============================================================");
  console.log("  📊 リスク判定レポート サマリー");
  console.log("===============================================================\n");

  for (const r of reports) {
    console.log(`【${r.badge}】${r.sectionLabel}`);
    console.log(`  ・リスク深刻度スコア: ${(r.riskScore * 100).toFixed(0)}%`);
    console.log(`  ・表現トーン後退確率: ${(r.toneRetreatProb * 100).toFixed(0)}%`);
    console.log(`  ・リスク顕在化確率  : ${(r.materializedRiskProb * 100).toFixed(0)}%`);
    console.log(`  ・変更行数          : +${r.addedCount}行 / -${r.removedCount}行`);
    console.log("  ・差分プレビュー:");
    const previewLines = r.diffSummary
      .split("\n")
      .slice(0, 10)
      .map((l) => `     ${l}`)
      .join("\n");
    console.log(previewLines);
    if (r.diffSummary.split("\n").length > 10) {
      console.log("     ... (他省略)");
    }
    console.log("");
  }
}

main().catch((err) => {
  console.error("❌ エラーが発生しました:", err);
  process.exit(1);
});
