import { choice, noul, TypeSafeClient } from "@typesafe-ai/sdk";

export type CauseTag =
  | "fx_fluctuation" // 為替変動
  | "raw_material_energy" // 原材料・エネルギー価格高騰
  | "weather_or_disaster" // 天候不順・自然災害
  | "market_or_geopolitics" // 市況悪化・地政学リスク
  | "upfront_investment" // 先行投資・一時的システム費用等
  | "weak_sales_or_churn" // 販売数量減少・客離れ・解約増
  | "delayed_price_pass"; // 価格転嫁（値上げ）の遅れ

export type BlameAttribution =
  | "external_macro_dominant"
  | "temporary_one_off"
  | "internal_acknowledged"
  | "none";

export interface UiPresentation {
  status: "safe" | "caution" | "warning";
  headline: string;
  description: string;
  causeTagsJa?: string[];
}

export class QualitativeExcusesSchema {
  constructor(
    public hasNegativeFactors: boolean,
    public causeTags: CauseTag[],
    public blameAttribution: BlameAttribution,
    public unfoundedOptimismDetected: boolean
  ) {}

  get uiPresentation(): UiPresentation {
    if (!this.hasNegativeFactors) {
      return {
        status: "safe",
        headline: "順調",
        description: "業績を圧迫する特段の悪化要因は報告されていません。",
      };
    }

    const tagJa: Record<CauseTag, string> = {
      fx_fluctuation: "為替変動",
      raw_material_energy: "原材料や光熱費の高騰",
      weather_or_disaster: "天候不順・災害",
      market_or_geopolitics: "市場環境や海外情勢の悪化",
      upfront_investment: "将来に向けた一時的な投資費用",
      weak_sales_or_churn: "売れ行き不振・顧客離れ",
      delayed_price_pass: "値上げの遅れ",
    };

    const causesStr = this.causeTags.map((t) => tagJa[t]).join("・") || "複数のコスト要因";
    const optimismNote = this.unfoundedOptimismDetected
      ? "なお、数値根拠のない楽観的な回復見通しが記載されています。"
      : "";

    if (this.blameAttribution === "external_macro_dominant") {
      return {
        status: "warning",
        headline: "要注意：外部環境のせいにする他責傾向",
        description: `不振の理由を「${causesStr}」といった外部環境ばかりに求めており、自社の課題への言及が乏しい状態です。${optimismNote}`,
        causeTagsJa: this.causeTags.map((t) => tagJa[t]),
      };
    }

    if (this.blameAttribution === "temporary_one_off") {
      return {
        status: "caution",
        headline: "注意：「一時的な悪化」と主張",
        description: `「${causesStr}」による一時的な減益と説明しています。次回以降の決算で本当に回復するか確認が必要です。${optimismNote}`,
        causeTagsJa: this.causeTags.map((t) => tagJa[t]),
      };
    }

    return {
      status: "safe",
      headline: "誠実：自社の課題・苦戦を正面から認識",
      description: `「${causesStr}」などの課題を隠さず認めており、経営陣の状況認識は誠実です。`,
      causeTagsJa: this.causeTags.map((t) => tagJa[t]),
    };
  }
}

/**
 * Jev による「定性言い訳・責任転嫁」の検知実行
 * @param client TypeSafeClient
 * @param mdaText 有報から抜き出したMD&A原文テキスト
 * @param metrics 有報から抜き出した客観的財務数値（オプション）
 */
export async function detectQualitativeExcuses(
  client: TypeSafeClient,
  mdaText: string,
  metrics?: { revenue?: number; netIncome?: number; operatingCashFlow?: number; unit?: string }
): Promise<QualitativeExcusesSchema> {
  const statePayload: Record<string, any> = {
    role: "Forensic Accounting Screener",
    task: "Analyze the management discussion snippet and detect blame attribution patterns.",
    extracted_mda_text: mdaText.slice(0, 3500),
  };

  // 客観的な財務数値が存在する場合は純粋な数値として state に追加（定性的な形容詞は一切付与しない）
  if (metrics) {
    statePayload.financial_data = {
      revenue: metrics.revenue !== undefined ? `${metrics.revenue} ${metrics.unit || ""}` : undefined,
      net_income: metrics.netIncome !== undefined ? `${metrics.netIncome} ${metrics.unit || ""}` : undefined,
      operating_cash_flow: metrics.operatingCashFlow !== undefined ? `${metrics.operatingCashFlow} ${metrics.unit || ""}` : undefined,
    };
  }

  const response = await client.systemOne({
    state: statePayload,
    questions: {
      has_negative_factors: noul("減収減益や利益圧迫要因についての言及が存在しますか？"),
      blame_attribution: choice("経営陣が主張する不振の主因を分類してください。", {
        external_macro_dominant: "為替、原材料高、資源高、天候、地政学等に全責任転嫁している",
        temporary_one_off: "「一過性の先行投資・システム切替」等の一時的要因と主張している",
        internal_acknowledged: "自社の価格競争力低下、需要減退、解約増など自社課題を認めている",
        none: "そもそも減益要因の言及なし、または業績好調",
      }),
      unfounded_optimism: noul(
        "「足元では底打ち」「中長期的には堅調」「下期回復を見込む」等の根拠なき楽観形容詞が含まれますか？"
      ),
      // 原因タグのマルチラベル判定 (Noul)
      cause_fx: noul("為替変動（円安・円高の影響）に関する言及がありますか？"),
      cause_raw_material: noul("原材料・エネルギー・資材価格の高騰に関する言及がありますか？"),
      cause_weather: noul("天候不順、台風、豪雪、猛暑、自然災害に関する言及がありますか？"),
      cause_geopolitics: noul("市況悪化、海外景気減速、地政学リスク、紛争に関する言及がありますか？"),
      cause_upfront: noul("先行投資、システム切替、拠点新設、研究開発費など一時的費用に関する言及がありますか？"),
      cause_weak_sales: noul("販売数量の減少、来店客数の減少、顧客離れ、解約増に関する言及がありますか？"),
      cause_price_pass: noul("価格転嫁（値上げ）の遅れや浸透不足に関する言及がありますか？"),
    },
  });

  const answers = response.answers;
  const hasNegativeFactors = answers.has_negative_factors.noul >= 0.55;
  const blameAttribution = answers.blame_attribution.choice as BlameAttribution;
  const unfoundedOptimismDetected = answers.unfounded_optimism.noul >= 0.65;

  const causeTags: CauseTag[] = [];
  if (answers.cause_fx.noul >= 0.65) causeTags.push("fx_fluctuation");
  if (answers.cause_raw_material.noul >= 0.65) causeTags.push("raw_material_energy");
  if (answers.cause_weather.noul >= 0.65) causeTags.push("weather_or_disaster");
  if (answers.cause_geopolitics.noul >= 0.65) causeTags.push("market_or_geopolitics");
  if (answers.cause_upfront.noul >= 0.65) causeTags.push("upfront_investment");
  if (answers.cause_weak_sales.noul >= 0.65) causeTags.push("weak_sales_or_churn");
  if (answers.cause_price_pass.noul >= 0.65) causeTags.push("delayed_price_pass");

  return new QualitativeExcusesSchema(
    hasNegativeFactors,
    causeTags,
    blameAttribution,
    unfoundedOptimismDetected
  );
}
