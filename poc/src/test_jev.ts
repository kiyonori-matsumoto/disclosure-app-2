import "dotenv/config";
import { choice, score, noul, TypeSafeClient } from "@typesafe-ai/sdk";

// APIキーの確認
const apiKey = process.env.TYPESAFE_API_KEY;
if (!apiKey) {
  console.error("❌ エラー: TYPESAFE_API_KEY が設定されていません。");
  console.error("poc/.env ファイルを作成して TYPESAFE_API_KEY=your_key を記述してください。");
  process.exit(1);
}

const client = new TypeSafeClient({ apiKey });

async function main() {
  console.log("🚀 TypeSafe AI (Jev) の疎通テストを開始します...\n");

  // 有報の定性テキスト差分サンプル（架空の事例: 事業等のリスクに不穏な文言が追加されたケース）
  const sampleDiff = `
【有価証券報告書「事業等のリスク」前期からの変更差分】

--- 前期 (抜粋)
当社グループの主要事業であるクラウドソリューションは市場拡大を背景に順調に成長を維持しており、
主要顧客との関係も極めて安定的であります。為替変動の影響についてもヘッジ取引により極小化されております。

+++ 当期 (抜粋)
当社グループの主要事業であるクラウドソリューションにおいて、主要取引先（売上高の38%を占める）からの
発注規模が縮小傾向に転じており、今後の収益性に重大な悪影響を及ぼす可能性があります。
また、一部の進行中プロジェクトにおいて納期遅延および想定外の追加原価が発生しており、
顧客との間で損害賠償請求に関する係争のリスクが顕在化しつつあります。
なお、前述の「順調に成長を維持」の記載は削除されました。
`.trim();

  console.log("=== 入力テキスト (有報リスク差分) ===");
  console.log(sampleDiff);
  console.log("=====================================\n");

  const startTime = Date.now();

  const response = await client.systemOne({
    state: {
      diff_text: sampleDiff,
      context: "上場企業の有価証券報告書「事業等のリスク」セクションの前年同期比較テキスト差分",
    },
    questions: {
      // 1. リスクレベルの多肢選択 (Choice)
      severity: choice(
        "前期からの差分を考慮し、投資家にとっての定性リスク重大度を判定してください。",
        {
          CRITICAL: "業績悪化、訴訟、大口顧客離反など重大なネガティブ事象の発生・顕在化",
          WARN: "表現の軟化、不確実性の高まり、注記の軽微な悪化",
          INFO: "通常のリスク更新、文言の微調整、好転・平常運転",
        }
      ),

      // 2. リスクスコア (Score: 0.0 〜 1.0)
      risk_score: score(
        "この変更による企業価値・業績へのネガティブインパクトの深刻度を評価してください。",
        [
          "リスクなし / 影響極小",
          "軽度の懸念あり",
          "重大な業績下振れ・損失リスクあり",
          "事業継続に影響を及ぼしうる極めて深刻な危機",
        ]
      ),

      // 3. 後退・軟化表現の有無 (Noul: Yes/No 確率)
      is_tone_retreat: noul(
        "「順調」「注力」などの前向きな文言の削除や、表現の後退・軟化が見られますか？"
      ),

      // 4. 新規リスク顕在化の有無 (Noul: Yes/No 確率)
      is_risk_materialized: noul(
        "「〜のリスクがある」という想定から「〜が発生している」「係争中」などリスクが既に顕在化した記述がありますか？"
      ),
    },
  });

  const durationMs = Date.now() - startTime;

  console.log(`⏱️ Jev API 応答時間: ${durationMs}ms\n`);
  console.log("=== Jev リスク判定結果 ===");
  console.log("🚨 重大度 (severity):", response.answers.severity.choice);
  console.log("📊 リスクスコア (risk_score):", response.answers.risk_score.score);
  console.log("📉 トーン後退確率 (is_tone_retreat):", response.answers.is_tone_retreat.noul);
  console.log("⚠️ リスク顕在化確率 (is_risk_materialized):", response.answers.is_risk_materialized.noul);
  console.log("===========================\n");

  // 4要素 criteria (0〜3) のインデックスを 0.0〜1.0 に正規化
  const normalizedRiskScore = Math.min(Math.max(response.answers.risk_score.score / 3.0, 0.0), 1.0);

  // 将来 Firestore / アプリに渡すバッジデータの形式イメージ
  const appBadgeData = {
    badge:
      response.answers.severity.choice === "CRITICAL"
        ? "🚨 CRITICAL RISK"
        : response.answers.severity.choice === "WARN"
        ? "⚠️ WARNING"
        : "✅ NORMAL",
    riskScorePercent: Math.round(normalizedRiskScore * 100),
    hasToneRetreat: response.answers.is_tone_retreat.noul > 0.7,
    hasMaterializedRisk: response.answers.is_risk_materialized.noul > 0.7,
  };

  console.log("📱 アプリ（Flutter UI）連携用データ:");
  console.log(JSON.stringify(appBadgeData, null, 2));
}

main().catch((err) => {
  console.error("❌ エラーが発生しました:", err);
  process.exit(1);
});
