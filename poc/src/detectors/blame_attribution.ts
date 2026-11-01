import { choice, noul, TypeSafeClient } from "@typesafe-ai/sdk";

export interface QualitativeExcusesResult {
  hasNegativeFactors: boolean;
  blameAttribution: "external_macro" | "temporary_one_off" | "internal_structural" | "none";
  confidenceScore: number;
  unusualModifierDetected: boolean;
  triggerSystem2: boolean;
}

/**
 * 1. 定性言い訳・責任転嫁の検知（MD&A・短信業績理由用）
 * 業績悪化の原因を「外部要因」に転嫁しているか、構造的悪化を隠蔽しているかを瞬時にトリアージする。
 */
export async function detectBlameAttribution(
  client: TypeSafeClient,
  mdaText: string
): Promise<QualitativeExcusesResult> {
  const promptSnippet = mdaText.slice(0, 3000);

  const response = await client.systemOne({
    state: {
      role: "Forensic Accounting Screener",
      task: "Analyze the management discussion snippet and detect blame attribution patterns.",
      extracted_mda_text: promptSnippet,
      rules: [
        "'blame_attribution' MUST be 'external_macro' if decline is blamed exclusively on foreign exchange, soaring raw materials, or weather without admitting loss of pricing power.",
        "If both structural loss and macro headwinds exist but management emphasizes macro headwinds, classify as 'external_macro'.",
      ].join("\n"),
    },
    questions: {
      has_negative_factors: noul(
        "減収減益、利益圧迫要因、事業環境の悪化についての言及が存在しますか？"
      ),
      blame_attribution: choice(
        "経営陣が主張する不振・減益の主因を分類してください。",
        {
          external_macro: "為替、原材料高、資源高、天候、地政学等に全責任転嫁している",
          temporary_one_off: "「一過性の先行投資」「システム切替」「移転費用」等の一時的要因と主張",
          internal_structural: "自社の価格競争力低下、シェア低下、需要減退、解約増などの自社要因を認めている",
          none: "減益・不振要因の言及なし（または好調・増益の開示）",
        }
      ),
      unusual_modifier_detected: noul(
        "「足元では底打ち傾向」「中長期的には堅調」「下半期には回復を見込む」等の根拠なき楽観形容詞や先送り表現が含まれますか？"
      ),
    },
  });

  const hasNegativeFactors = response.answers.has_negative_factors.noul >= 0.5;
  const blameAttribution = response.answers.blame_attribution.choice as QualitativeExcusesResult["blameAttribution"];
  const unusualModifierDetected = response.answers.unusual_modifier_detected.noul >= 0.6;

  // ルール: 不振要因があり、外部転嫁または一過性主張、もしくは怪しい楽観形容詞があれば System 2（推論LLM）トリガー
  const isSuspiciousAttribution = blameAttribution === "external_macro" || blameAttribution === "temporary_one_off";
  const triggerSystem2 = hasNegativeFactors && (isSuspiciousAttribution || unusualModifierDetected);

  return {
    hasNegativeFactors,
    blameAttribution,
    confidenceScore: Math.round(response.answers.has_negative_factors.noul * 100) / 100,
    unusualModifierDetected,
    triggerSystem2,
  };
}
