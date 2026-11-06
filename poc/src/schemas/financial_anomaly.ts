import { choice, noul, TypeSafeClient } from "@typesafe-ai/sdk";

export type RedFlagType =
  | "going_concern" // 継続企業の前提に関する注記・疑義
  | "covenant_breach" // 財務制限条項への抵触
  | "negative_operating_cf" // 営業CFのマイナス・本業での現金流出
  | "inventory_receivable_surge" // 売れ残り在庫や未回収金の急増
  | "impairment_loss" // 減損損失の計上・兆候
  | "interest_debt_pressure" // 利払い負担増・変動金利リスク・借入急増
  | "unsustainable_payout" // 純利益を超える配当・内部留保の取り崩し
  | "subsequent_events"; // 重要な後発事象（訴訟・事故・大口解約等）

export type FinancialRiskLevel = "low" | "medium" | "critical";

export interface FinancialUiPresentation {
  status: "safe" | "caution" | "warning";
  headline: string;
  detected_items: string[];
  description: string;
}

export class FinancialAnomalySchema {
  constructor(
    public detectedRedFlags: RedFlagType[],
    public riskLevel: FinancialRiskLevel
  ) {}

  get uiPresentation(): FinancialUiPresentation {
    if (this.detectedRedFlags.length === 0) {
      return {
        status: "safe",
        headline: "健全：危険な財務サインなし",
        detected_items: [],
        description: "資金繰りや資産価値に関する特段の危険サインは見当たりません。",
      };
    }

    const flagDetails: Record<RedFlagType, [string, string]> = {
      going_concern: [
        "倒産危機サイン",
        "事業を続けられるかどうかの重大な懸念（継続企業の前提の疑義）が出ています",
      ],
      covenant_breach: [
        "銀行ルール違反",
        "銀行との約束（財務制限条項）に違反し、借金の一括返済を求められるリスクがあります",
      ],
      negative_operating_cf: [
        "本業の現金減少",
        "本業の営業活動で現金がマイナス（流出状態）になっています",
      ],
      inventory_receivable_surge: [
        "在庫・未回収金の膨張",
        "商品の売れ残り（在庫）や未回収の代金が急増し、資金繰りを圧迫しています",
      ],
      impairment_loss: [
        "資産価値の暴落",
        "過去の投資や買収した事業の価値が下がり、特別損失（減損）が発生しています",
      ],
      interest_debt_pressure: [
        "借金・利払い負担の増加",
        "借入金の増加や金利上昇により、利払いの負担が重くなっています",
      ],
      unsustainable_payout: [
        "無理な配当維持",
        "稼いだ利益以上の配当を出すため、会社の貯金（内部留保）を切り崩しています",
      ],
      subsequent_events: [
        "決算後の重大トラブル",
        "決算期日後に訴訟や事故、大口契約の終了など重要なトラブルが報告されています",
      ],
    };

    const badges = this.detectedRedFlags.map((f) => flagDetails[f][0]);
    const explanations = this.detectedRedFlags.map((f) => flagDetails[f][1]);

    const status = this.riskLevel === "critical" ? "warning" : "caution";
    const headline =
      status === "warning"
        ? "危険：経営を揺るがす重大な資金・会計リスク"
        : "注意：資金繰りや資産価値に懸念サイン";

    return {
      status,
      headline,
      detected_items: badges,
      description: explanations.join("。また、") + "。",
    };
  }
}

/**
 * Jev による「財務・資金繰り・注記リスク」の検知実行
 * @param client TypeSafeClient
 * @param footnotesText 有報から抜き出した注記・リスク原文テキスト
 * @param metrics 有報から抜き出した客観的財務数値（オプション）
 */
export async function detectFinancialAnomaly(
  client: TypeSafeClient,
  footnotesText: string,
  metrics?: { revenue?: number; netIncome?: number; operatingCashFlow?: number; payoutRatio?: number; totalAssets?: number; unit?: string }
): Promise<FinancialAnomalySchema> {
  const statePayload: Record<string, any> = {
    role: "Forensic Financial Risk Screener",
    task: "Scan footnote excerpts and financial notes for high-risk anomalies.",
    extracted_footnotes_and_financial_notes: footnotesText.slice(0, 3500),
    rules: [
      "If text or financial data indicates going concern (継続企業の前提) or covenant breach, set risk_level = 'critical'.",
      "If financial data shows negative operating cash flow, flag negative_operating_cf.",
      "If distribution exceeds net income or utilizes retained earnings, flag unsustainable_payout.",
      "If debt pressure, impairment, or negative operating CF is noted, flag respectively.",
    ].join("\n"),
  };

  // 客観的な財務数値が存在する場合は純粋な数値として state に追加（定性的な形容詞は一切付与しない）
  if (metrics) {
    statePayload.financial_data = {
      revenue: metrics.revenue !== undefined ? `${metrics.revenue} ${metrics.unit || ""}` : undefined,
      net_income: metrics.netIncome !== undefined ? `${metrics.netIncome} ${metrics.unit || ""}` : undefined,
      operating_cash_flow: metrics.operatingCashFlow !== undefined ? `${metrics.operatingCashFlow} ${metrics.unit || ""}` : undefined,
      payout_ratio: metrics.payoutRatio !== undefined ? `${metrics.payoutRatio} %` : undefined,
      total_assets: metrics.totalAssets !== undefined ? `${metrics.totalAssets} ${metrics.unit || ""}` : undefined,
    };
  }

  const response = await client.systemOne({
    state: statePayload,
    questions: {
      risk_level: choice("財務・注記リスクの総合深刻度レベルを判定してください。", {
        critical: "GC注記、コベナンツ抵触など経営を揺るがす重大リスク",
        medium: "利払い負担増、減損兆候、タコ足配当、在庫急増など懸念サイン",
        low: "資金繰り・資産価値に特段の危険サインなし",
      }),
      flag_going_concern: noul("継続企業の前提に関する注記・疑義（GC注記）の記載がありますか？"),
      flag_covenant: noul("財務制限条項（コベナンツ）への抵触、または抵触懸念の記載がありますか？"),
      flag_negative_cf: noul("営業キャッシュ・フローのマイナスや本業での現金流出に関する言及がありますか？"),
      flag_inventory_receivable: noul(
        "棚卸資産（売れ残り在庫）や売上債権（未回収代金）の急増に関する記載がありますか？"
      ),
      flag_impairment: noul("固定資産やのれんの減損損失、または減損の兆候に関する記載がありますか？"),
      flag_debt_pressure: noul(
        "借入金の急増、利払い負担増、変動金利比率の急増（50%超）に関する記載がありますか？"
      ),
      flag_payout: noul(
        "当期純利益を超える配当・分配（利益超過分配）、または内部留保・剰余金の大幅取崩しに関する記載がありますか？"
      ),
      flag_subsequent: noul(
        "重要な後発事象（重大訴訟、事故、大口取引終了、不正発覚等）に関する記載がありますか？"
      ),
    },
  });

  const answers = response.answers;
  const riskLevel = answers.risk_level.choice as FinancialRiskLevel;

  const detectedFlags: RedFlagType[] = [];
  if (answers.flag_going_concern.noul >= 0.65) detectedFlags.push("going_concern");
  if (answers.flag_covenant.noul >= 0.65) detectedFlags.push("covenant_breach");
  if (answers.flag_negative_cf.noul >= 0.65) detectedFlags.push("negative_operating_cf");
  if (answers.flag_inventory_receivable.noul >= 0.65) detectedFlags.push("inventory_receivable_surge");
  if (answers.flag_impairment.noul >= 0.65) detectedFlags.push("impairment_loss");
  if (answers.flag_debt_pressure.noul >= 0.65) detectedFlags.push("interest_debt_pressure");
  if (answers.flag_payout.noul >= 0.65) detectedFlags.push("unsustainable_payout");
  if (answers.flag_subsequent.noul >= 0.65) detectedFlags.push("subsequent_events");

  return new FinancialAnomalySchema(detectedFlags, riskLevel);
}
