import { choice, TypeSafeClient } from "@typesafe-ai/sdk";

export type TrackedItemStatus =
  | "fully_disclosed"
  | "partially_obscured"
  | "completely_omitted"
  | "metric_redefined";

export type Severity = "low" | "medium" | "high";

export interface KpiUiPresentation {
  status: "safe" | "caution" | "warning";
  headline: string;
  description: string;
}

export class KpiOmissionSchema {
  constructor(
    public trackedItemStatus: TrackedItemStatus,
    public severity: Severity
  ) {}

  toUiPresentation(targetKpiName: string): KpiUiPresentation {
    const templates: Record<
      TrackedItemStatus,
      [KpiUiPresentation["status"], string, string]
    > = {
      fully_disclosed: [
        "safe",
        "透明：過去の重点目標を継続公開",
        `前回アピールしていた「${targetKpiName}」について、今回も具体的な数値や進捗がしっかり公開されています。`,
      ],
      partially_obscured: [
        "caution",
        "警戒：具体的な数字が曖昧な表現に後退",
        `前回は具体的な数値でアピールしていた「${targetKpiName}」が、今回は『順調』などの曖昧な言葉にごまかされています。`,
      ],
      completely_omitted: [
        "warning",
        "危険：過去の重点アピール項目が消滅",
        `前回強調していた「${targetKpiName}」に関する記載が、今回の資料から完全に消えています。計画が頓挫した可能性があります。`,
      ],
      metric_redefined: [
        "caution",
        "注意：目標の計算ルールを途中で変更",
        `「${targetKpiName}」の集計ルールや計算基準が前回から変更されています。数字を良く見せるための変更でないか注意が必要です。`,
      ],
    };

    const [status, headline, description] = templates[this.trackedItemStatus];
    return { status, headline, description };
  }
}

/**
 * Jev による「前期比較における重点KPI言及消滅・定義変更」の検知実行
 */
export async function detectKpiOmission(
  client: TypeSafeClient,
  targetKpiName: string,
  prevPeriodExcerpt: string,
  currPeriodFullText: string
): Promise<KpiOmissionSchema> {
  const response = await client.systemOne({
    state: {
      role: "Disclosure Consistency Auditor",
      task: "Determine whether the target metric/project emphasized in the previous period is obscured or omitted in the current period text.",
      target_kpi_name: targetKpiName,
      previous_period_statement: prevPeriodExcerpt.slice(0, 1500),
      current_period_text: currPeriodFullText.slice(0, 3500),
      rules: [
        "If the target metric had exact quantitative numbers in the previous period but only qualitative claims (e.g., '順調に推移') in the current period, classify as 'partially_obscured'.",
        "If the topic is entirely missing from the current text, classify as 'completely_omitted' and set severity 'high'.",
        "If calculation criteria or definition changed, classify as 'metric_redefined'.",
      ].join("\n"),
    },
    questions: {
      tracked_item_status: choice(
        `前回アピールしていた「${targetKpiName}」について、今回の開示状況を判定してください。`,
        {
          fully_disclosed: "前回同様に具体的な数値や進捗がしっかり公開されている",
          partially_obscured: "数値が開示されず、「順調」等の定性的な表現にごまかされた",
          completely_omitted: "該当項目についての言及が完全に消滅した",
          metric_redefined: "計算基準、対象範囲、定義が変更された",
        }
      ),
      severity: choice("開示後退・隠蔽の深刻度レベルを判定してください。", {
        high: "重大な不都合隠蔽、重要KPIの完全消滅",
        medium: "数値の定性化、計算ルールの変更",
        low: "問題なし、十分な開示維持",
      }),
    },
  });

  const status = response.answers.tracked_item_status.choice as TrackedItemStatus;
  const severity = response.answers.severity.choice as Severity;

  return new KpiOmissionSchema(status, severity);
}
