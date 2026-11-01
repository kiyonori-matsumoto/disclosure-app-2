import { choice, noul, TypeSafeClient } from "@typesafe-ai/sdk";

export interface TagDetectionResult {
  tags: string[];
  overallRisk: "CRITICAL" | "WARNING" | "NORMAL";
  details: Record<string, any>;
}

export class TagEngine {
  private client: TypeSafeClient;

  constructor(apiKey?: string) {
    this.client = new TypeSafeClient(apiKey ? { apiKey } : undefined);
  }

  /**
   * 1. 「事業等のリスク」差分からリスク顕在化・新規追加・表現後退タグを判定
   */
  async detectRiskSectionTags(diffText: string): Promise<string[]> {
    if (!diffText || diffText.trim().length === 0) return [];

    const tags: string[] = [];
    const response = await this.client.systemOne({
      state: {
        role: "Forensic Risk Screener",
        task: "Detect risk escalation tags from business risk diff text.",
        diff_text: diffText.slice(0, 3500),
      },
      questions: {
        is_materialized: noul(
          "「損害賠償」「訴訟」「納期遅延」「不正」「取引停止」「損失計上」など、リスクが実際に顕在化・発生した記述が追加されていますか？"
        ),
        is_new_major_risk: noul(
          "前期には記載がなかった、新たな重大リスク項目や大幅な規制・市場リスクが追加されていますか？"
        ),
        has_tone_retreat: noul(
          "「順調」「強固」「安定的」などの強気文言が削除され、慎重・不透明・懸念する表現へ後退していますか？"
        ),
      },
    });

    if (response.answers.is_materialized.noul >= 0.7) {
      tags.push("⚠️ リスク顕在化");
    }
    if (response.answers.is_new_major_risk.noul >= 0.7) {
      tags.push("⚠️ 新規リスク追加");
    }
    if (response.answers.has_tone_retreat.noul >= 0.7) {
      tags.push("⚠️ 表現トーン後退");
    }

    return tags;
  }

  /**
   * 2. 「MD&A（経営成績の概況）」から外部責任転嫁・一過性強弁・根拠なき楽観タグを判定
   */
  async detectMdaTags(mdaText: string): Promise<string[]> {
    if (!mdaText || mdaText.trim().length === 0) return [];

    const tags: string[] = [];
    const response = await this.client.systemOne({
      state: {
        role: "Management Tone Auditor",
        task: "Detect excuse and attribution tags from management discussion text.",
        mda_text: mdaText.slice(0, 3500),
      },
      questions: {
        blame_attribution: choice(
          "経営陣が説明する業績不振・減益・利益圧迫の主因を分類してください。",
          {
            external_macro: "為替、原材料高、資源高、天候、地政学等に全責任転嫁している",
            temporary_one_off: "「一過性の先行投資」「システム切替」「移転費用」等の一時的要因と強弁している",
            internal_structural: "自社の価格競争力低下、シェア低下、需要減退などの自社要因を認めている",
            none: "不振・減益の要因説明なし、または業績好調",
          }
        ),
        has_unusual_optimism: noul(
          "「足元底打ち傾向」「中長期的には堅調」「下期回復を見込む」など、根拠薄弱な楽観的形容詞や先送り主張が含まれますか？"
        ),
      },
    });

    const blame = response.answers.blame_attribution.choice;
    if (blame === "external_macro") {
      tags.push("⚠️ 外部責任転嫁");
    } else if (blame === "temporary_one_off") {
      tags.push("⚠️ 一過性強弁");
    }

    if (response.answers.has_unusual_optimism.noul >= 0.65) {
      tags.push("⚠️ 根拠なき楽観");
    }

    return tags;
  }

  /**
   * 3. 「注記・会計方針」からGC注記・タコ足分配・会計方針変更タグを判定
   */
  async detectFootnoteTags(notesText: string, accountingPolicyText?: string): Promise<string[]> {
    const combined = `${notesText}\n${accountingPolicyText || ""}`.trim();
    if (!combined) return [];

    const tags: string[] = [];
    const response = await this.client.systemOne({
      state: {
        role: "Financial Footnote Screener",
        task: "Detect critical financial and accounting red flags.",
        notes_text: combined.slice(0, 3500),
      },
      questions: {
        is_going_concern: noul(
          "継続企業の前提に関する注記（GC注記）や、重大な不確実性に関する言及がありますか？"
        ),
        is_payout_manipulation: noul(
          "当期純利益を超える分配（利益超過分配・タコ足分配）、または内部留保・剰余金の大幅取り崩しによる配当維持の言及がありますか？"
        ),
        has_accounting_policy_change: noul(
          "減価償却方法の変更など、会計方針や見積もりの変更に関する記述がありますか？"
        ),
      },
    });

    if (response.answers.is_going_concern.noul >= 0.6) {
      tags.push("🚨 GC注記");
    }
    if (response.answers.is_payout_manipulation.noul >= 0.7) {
      tags.push("🚨 タコ足分配");
    }
    if (response.answers.has_accounting_policy_change.noul >= 0.7) {
      tags.push("⚠️ 会計方針変更");
    }

    return tags;
  }

  /**
   * 総合判定：収集したタグ群から全体の危険度（CRITICAL / WARNING / NORMAL）を決定
   */
  computeOverallRisk(tags: string[]): "CRITICAL" | "WARNING" | "NORMAL" {
    if (tags.some((t) => t.startsWith("🚨"))) {
      return "CRITICAL";
    }
    if (tags.some((t) => t.startsWith("⚠️"))) {
      return "WARNING";
    }
    return "NORMAL";
  }
}
