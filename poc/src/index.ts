import "dotenv/config";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import { extractQualitativeSections, QualitativeSection } from "./extractor.js";
import { extractSectionsFromZip } from "./zip_extractor.js";
import { computeDiff } from "./differ.js";
import { ForensicAnalyzer, RiskAnalysisReport } from "./analyzer.js";

async function loadSections(filePath: string): Promise<Map<string, QualitativeSection>> {
  if (filePath.toLowerCase().endsWith(".zip")) {
    return extractSectionsFromZip(filePath);
  } else {
    const html = await fs.readFile(filePath, "utf-8");
    return extractQualitativeSections(html);
  }
}

async function main() {
  console.log("===============================================================");
  console.log("  🔍 有報・短信 定性リスク フォレンジック差分エンジン (PoC) ");
  console.log("===============================================================\n");

  const apiKey = process.env.TYPESAFE_API_KEY;
  if (!apiKey) {
    console.error("❌ エラー: TYPESAFE_API_KEY が設定されていません。");
    console.error("poc/.env に TYPESAFE_API_KEY=your_key を設定してください。\n");
    process.exit(1);
  }

  // ファイルパス（CLI引数があればそれを使用、なければサンプルデータ）
  const args = process.argv.slice(2);
  const priorPath = args[0] || path.resolve("data/sample_prior.htm");
  const currentPath = args[1] || path.resolve("data/sample_current.htm");

  console.log(`📂 前期ファイル: ${priorPath}`);
  console.log(`📂 当期ファイル: ${currentPath}\n`);

  // 1. 定性セクションをピンポイント抽出 (ZIPまたはHTMから自動判別)
  console.log("⚙️  1. 定性セクションを抽出中 (ZIP / iXBRL 自動判別)...");
  const priorSections = await loadSections(priorPath);
  const currentSections = await loadSections(currentPath);

  console.log(`   前期セクション数: ${priorSections.size} 件`);
  console.log(`   当期セクション数: ${currentSections.size} 件\n`);

  // 2. セクションごとのテキストDiffを計算
  console.log("⚙️  2. 前年同期テキスト差分 (Diff) を計算中...");
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
  console.log("");

  // 3. Jev によるフォレンジック・リスク評価
  console.log("🤖 3. Jev (TypeSafe AI) によるリスク＆トーン分析を実行中...");
  const analyzer = new ForensicAnalyzer(apiKey);
  const reports: RiskAnalysisReport[] = [];

  for (const diff of diffs) {
    console.log(`   📡 Jev 判定中: [${diff.sectionLabel}]...`);
    const startTime = Date.now();
    const report = await analyzer.analyzeSectionDiff(diff);
    const latency = Date.now() - startTime;
    console.log(`      └ 判定完了 (${latency}ms) => ${report.badge} (Score: ${report.riskScore})`);
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
      .slice(0, 8)
      .map((l) => `     ${l}`)
      .join("\n");
    console.log(previewLines);
    if (r.diffSummary.split("\n").length > 8) {
      console.log("     ... (他省略)");
    }
    console.log("");
  }

  // 4. アプリ（Flutter / Firestore）用のペイロード構造
  const firestorePayload = {
    docId: "SAMPLE_2026_Q4",
    companyCode: "9999",
    companyName: "サンプルクラウド株式会社",
    filingDate: new Date().toISOString(),
    overallRiskBadge: reports.some((r) => r.badge === "🚨 CRITICAL")
      ? "🚨 CRITICAL"
      : reports.some((r) => r.badge === "⚠️ WARNING")
      ? "⚠️ WARNING"
      : "✅ NORMAL",
    maxRiskScore: Math.max(...reports.map((r) => r.riskScore), 0),
    reports: reports.map((r) => ({
      sectionKey: r.sectionKey,
      sectionLabel: r.sectionLabel,
      badge: r.badge,
      riskScore: r.riskScore,
      toneRetreatProb: r.toneRetreatProb,
      materializedRiskProb: r.materializedRiskProb,
    })),
  };

  console.log("📱 【Flutter アプリ (Firestore) 連携用データ】");
  console.log(JSON.stringify(firestorePayload, null, 2));
  console.log("\n✅ PoCの実行が正常に完了しました！");
}

main().catch((err) => {
  console.error("❌ エラーが発生しました:", err);
  process.exit(1);
});
