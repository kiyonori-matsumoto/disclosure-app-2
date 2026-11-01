import { choice, score, noul, TypeSafeClient } from "@typesafe-ai/sdk";
import { DiffResult } from "./differ.js";

export interface RiskAnalysisReport {
  sectionKey: string;
  sectionLabel: string;
  badge: "🚨 CRITICAL" | "⚠️ WARNING" | "ℹ️ NOTICE" | "✅ NO_RISK";
  severity: "CRITICAL" | "WARN" | "INFO";
  riskScore: number; // 0.0 〜 1.0
  toneRetreatProb: number; // 0.0 〜 1.0
  materializedRiskProb: number; // 0.0 〜 1.0
  diffSummary: string;
  addedCount: number;
  removedCount: number;
}

export class ForensicAnalyzer {
  private client: TypeSafeClient;

  constructor(apiKey?: string) {
    this.client = new TypeSafeClient(apiKey ? { apiKey } : undefined);
  }

  /**
   * 差分テキストを Jev に渡し、フォレンジック・リスク評価を実行
   */
  async analyzeSectionDiff(diff: DiffResult): Promise<RiskAnalysisReport> {
    if (!diff.hasChanges) {
      return {
        sectionKey: diff.sectionKey,
        sectionLabel: diff.sectionLabel,
        badge: "✅ NO_RISK",
        severity: "INFO",
        riskScore: 0.0,
        toneRetreatProb: 0.0,
        materializedRiskProb: 0.0,
        diffSummary: "変更なし",
        addedCount: 0,
        removedCount: 0,
      };
    }

    // Jev に渡す入力ステートの作成
    const state = {
      section: diff.sectionLabel,
      added_lines: diff.addedLines.slice(0, 50), // 上限を設けて要約
      removed_lines: diff.removedLines.slice(0, 50),
      raw_diff: diff.diffSummaryText.slice(0, 4000),
    };

    const response = await this.client.systemOne({
      state,
      questions: {
        severity: choice(
          `開示書類の「${diff.sectionLabel}」セクションの前年差分を分析し、投資リスクの重大度を評価してください。`,
          {
            CRITICAL: "重大な業績下方リスク、不祥事・訴訟・大口離反の顕在化、または重大な会計方針変更",
            WARN: "表現の軟化、先行き不透明感の追加、注意を要するリスク項目の微増",
            INFO: "法令・定型表現の更新、事業拡大に伴う通常のリスク追記、好転",
          }
        ),
        risk_score: score(
          "この定性開示の変更が企業価値・業績に与えるネガティブ影響の深刻度（0.0: 無影響 〜 1.0: 破滅的）を評価してください。",
          [
            "軽微またはポジティブな変更",
            "注視が必要な中程度のリスク",
            "業績に明確な打撃を与えうる深刻なリスク",
            "継続企業の前提を脅かす致命的リスク",
          ]
        ),
        tone_retreat: noul(
          "「順調」「強固」などの強気文言の削除、あるいは「懸念」「厳しい」などへのトーン後退が見られますか？"
        ),
        risk_materialized: noul(
          "これまで単なる「可能性」とされていたリスクが、現実に「発生した」「顕在化した」という記述が含まれていますか？"
        ),
      },
    });

    // score は criteria 配列（4要素 = 最大インデックス3）のスケールで返るため 0.0〜1.0 に正規化
    const rawScore = response.answers.risk_score.score;
    const normalizedScore = Math.min(Math.max(rawScore / 3.0, 0.0), 1.0);

    const severity = response.answers.severity.choice as "CRITICAL" | "WARN" | "INFO";
    const riskScore = normalizedScore;
    const toneRetreatProb = response.answers.tone_retreat.noul;
    const materializedRiskProb = response.answers.risk_materialized.noul;

    let badge: RiskAnalysisReport["badge"] = "ℹ️ NOTICE";
    if (severity === "CRITICAL" || riskScore >= 0.6 || materializedRiskProb >= 0.75) {
      badge = "🚨 CRITICAL";
    } else if (severity === "WARN" || riskScore >= 0.35 || toneRetreatProb >= 0.6) {
      badge = "⚠️ WARNING";
    }

    return {
      sectionKey: diff.sectionKey,
      sectionLabel: diff.sectionLabel,
      badge,
      severity,
      riskScore: Math.round(riskScore * 100) / 100,
      toneRetreatProb: Math.round(toneRetreatProb * 100) / 100,
      materializedRiskProb: Math.round(materializedRiskProb * 100) / 100,
      diffSummary: diff.diffSummaryText,
      addedCount: diff.addedLines.length,
      removedCount: diff.removedLines.length,
    };
  }
}
