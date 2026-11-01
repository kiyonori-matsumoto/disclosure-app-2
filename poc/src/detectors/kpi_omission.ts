import { choice, score, TypeSafeClient } from "@typesafe-ai/sdk";

export interface KpiOmissionResult {
  targetTopic: string;
  trackedItemStatus: "fully_disclosed" | "partially_obscured" | "completely_omitted" | "metric_redefined";
  omissionSeverity: number; // 0.0 〜 1.0
  triggerSystem2: boolean;
}

/**
 * 2. 前期比較における「言及消滅・定義変更」検知
 * 前期の開示資料でアピールしていた重点KPIやプロジェクトが、当期で意図的にトーンダウン・消滅したかを判定する。
 */
export async function detectKpiOmission(
  client: TypeSafeClient,
  targetTopic: string,
  prevPeriodExcerpt: string,
  currPeriodText: string
): Promise<KpiOmissionResult> {
  const response = await client.systemOne({
    state: {
      role: "Disclosure Consistency Auditor",
      task: "Determine whether the target metric/project emphasized in the previous period is obscured or omitted in the current period text.",
      target_kpi_name: targetTopic,
      previous_period_statement: prevPeriodExcerpt.slice(0, 1500),
      current_period_text: currPeriodText.slice(0, 3000),
      rules: [
        "If the target metric had exact quantitative numbers in the previous period but only qualitative claims (e.g., '順調に推移') in the current period, classify as 'partially_obscured'.",
        "If the topic is entirely missing from the current text, classify as 'completely_omitted' and set 'omission_severity' high.",
        "If calculation criteria or definitions changed, classify as 'metric_redefined'.",
      ].join("\n"),
    },
    questions: {
      tracked_item_status: choice(
        `前期で強調されていた「${targetTopic}」の開示状態を当期テキストと照合して判定してください。`,
        {
          fully_disclosed: "前期同様に具体的な数値・進捗・成果が明確に開示されている",
          partially_obscured: "数値が開示されず、「順調に推移」「注力した」等の定性的な表現にぼかされた",
          completely_omitted: "該当項目やKPIについての言及が完全に消滅・削除された",
          metric_redefined: "計算基準、対象範囲、集計期間、定義などが変更された",
        }
      ),
      omission_severity: score(
        "この開示変更・言及後退の深刻度（不都合な情報の隠蔽度合い）を評価してください。",
        [
          "問題なし / 十分に開示維持",
          "軽度の定性表現への移行 / 補足あり",
          "重要なKPIの非開示化 / 警戒すべきトーンダウン",
          "致命的な意図的隠蔽 / 不都合なプロジェクトの完全消滅",
        ]
      ),
    },
  });

  const trackedItemStatus = response.answers.tracked_item_status.choice as KpiOmissionResult["trackedItemStatus"];
  // 4要素 criteria (0〜3) のインデックスを 0.0〜1.0 に正規化
  const omissionSeverity = Math.min(Math.max(response.answers.omission_severity.score / 3.0, 0.0), 1.0);

  const triggerSystem2 = trackedItemStatus !== "fully_disclosed" || omissionSeverity >= 0.5;

  return {
    targetTopic,
    trackedItemStatus,
    omissionSeverity: Math.round(omissionSeverity * 100) / 100,
    triggerSystem2,
  };
}
