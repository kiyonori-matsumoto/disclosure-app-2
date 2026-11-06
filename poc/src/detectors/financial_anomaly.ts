import { choice, noul, TypeSafeClient } from "@typesafe-ai/sdk";

export interface FinancialAnomalyResult {
  interestRateStructureAlert: boolean;
  payoutManipulationAlert: boolean;
  accountingRedFlagType: "going_concern" | "impairment_loss" | "subsequent_events" | "covenant_breach" | "none";
  riskLevel: "critical" | "medium" | "low";
  triggerSystem2: boolean;
}

/**
 * 3. 財務・注記リスクの高速フラグ立て（REIT・金利・注記特化）
 * 金利構造の変異、減損・引当金リスク、タコ足分配などの異常シグナルをミリ秒で判定する。
 */
export async function detectFinancialAnomaly(
  client: TypeSafeClient,
  notesText: string
): Promise<FinancialAnomalyResult> {
  const promptSnippet = notesText.slice(0, 3000);

  const response = await client.systemOne({
    state: {
      role: "Forensic Financial Risk Screener",
      task: "Scan footnote excerpts and balance sheet commentary for high-risk anomalies.",
      extracted_footnotes_and_financial_notes: promptSnippet,
      rules: [
        "If text mentions switching debt to floating rates ('変動金利') during rate hike phases or states floating ratio > 50%, set 'interest_rate_structure_alert' = True.",
        "If distribution exceeds net income ('当期純利益') or mentions utilizing retained earnings ('内部留保取崩し', '繰越利益剰余金充当') to maintain DPU, set 'payout_manipulation_alert' = True.",
        "If any going concern or covenant issues are mentioned, set 'risk_level' = 'critical' immediately.",
      ].join("\n"),
    },
    questions: {
      interest_rate_structure_alert: noul(
        "変動金利比率の急増（50%超など）、固定金利化の遅れ、または借入金利急騰に対する警戒の記載がありますか？"
      ),
      payout_manipulation_alert: noul(
        "当期純利益を超える分配（利益超過分配・タコ足分配）、または内部留保・剰余金の大幅取り崩しによる配当維持の記述がありますか？"
      ),
      accounting_red_flag_type: choice(
        "注記等に見られる重大な会計フォレンジック・シグナルを分類してください。",
        {
          going_concern: "継続企業の前提に関する注記・重要事象（GC注記）",
          impairment_loss: "固定資産・のれんの減損損失、または減損の兆候",
          subsequent_events: "重要な後発事象（重大訴訟、火災、大口取引停止、不正発覚等）",
          covenant_breach: "財務制限条項（コベナンツ）への抵触、または抵触懸念",
          none: "特段の危険シグナルなし",
        }
      ),
      risk_level: choice(
        "財務・注記リスクの総合深刻度レベルを判定してください。",
        {
          critical: "GC注記、コベナンツ抵触、破綻懸念など即時警戒レベル",
          medium: "タコ足分配、金利上昇による利益圧迫、減損兆候など警戒レベル",
          low: "通常範囲の注記、軽微なリスク",
        }
      ),
    },
  });

  const interestRateStructureAlert = response.answers.interest_rate_structure_alert.noul >= 0.6;
  const payoutManipulationAlert = response.answers.payout_manipulation_alert.noul >= 0.6;
  const accountingRedFlagType = response.answers.accounting_red_flag_type.choice as FinancialAnomalyResult["accountingRedFlagType"];
  const riskLevel = response.answers.risk_level.choice as FinancialAnomalyResult["riskLevel"];

  // ルール: いずれかのアラートが立つか、リスクが medium / critical であれば System 2 トリガー
  const triggerSystem2 =
    interestRateStructureAlert ||
    payoutManipulationAlert ||
    riskLevel === "critical" ||
    riskLevel === "medium" ||
    accountingRedFlagType !== "none";

  return {
    interestRateStructureAlert,
    payoutManipulationAlert,
    accountingRedFlagType,
    riskLevel,
    triggerSystem2,
  };
}
