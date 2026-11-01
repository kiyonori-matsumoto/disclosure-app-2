import AdmZip from "adm-zip";
import * as cheerio from "cheerio";
import { RedFlagType } from "./schemas/financial_anomaly.js";

export interface KeyFinancialMetrics {
  revenue?: number; // 金額 (千円)
  netIncome?: number; // 金額 (千円)
  operatingCashFlow?: number; // 金額 (千円)
  payoutRatio?: number; // %
  totalAssets?: number; // 金額 (千円)
  unit: "千円";
  rawItems: Record<string, number[]>;
}

export interface QuantitativeRiskAssessment {
  metrics: KeyFinancialMetrics;
  detectedRedFlags: RedFlagType[];
  quantitativeWarnings: string[];
}

/**
 * 有報ZIPから主要財務数値（サマリーテーブル + キャッシュフロー計算書）を自動パース
 */
export function extractFinancialMetricsFromZip(zipPathOrBuffer: string | Buffer): KeyFinancialMetrics {
  const zip = typeof zipPathOrBuffer === "string" ? new AdmZip(zipPathOrBuffer) : new AdmZip(zipPathOrBuffer);
  const entries = zip.getEntries();

  const rawItems: Record<string, number[]> = {};

  // 全ての PublicDoc/*.htm から数値タグを走査
  for (const entry of entries) {
    if (!entry.entryName.includes("PublicDoc") || !entry.entryName.endsWith(".htm")) continue;

    const content = entry.getData().toString("utf-8");
    if (!content.includes("nonFraction")) continue;

    const $ = cheerio.load(content);
    $("ix\\:nonfraction, nonfraction").each((_, el) => {
      const name = $(el).attr("name") || "";
      const text = $(el).text().replace(/[\n\r\s,]/g, "");
      const sign = $(el).attr("sign");
      const scaleStr = $(el).attr("scale");
      let num = parseFloat(text);

      if (!isNaN(num)) {
        if (sign === "-") {
          num = -Math.abs(num);
        }
        // scale: "6" (百万円) の場合は千円単位 (*1000) に正規化、"3" (千円) はそのまま
        if (scaleStr === "6") {
          num = num * 1000;
        }

        if (!rawItems[name]) {
          rawItems[name] = [];
        }
        rawItems[name].push(num);
      }
    });
  }

  // 最新値の探索ヘルパー
  const findLatest = (patterns: string[]): number | undefined => {
    for (const pattern of patterns) {
      for (const key of Object.keys(rawItems)) {
        if (key.includes(pattern)) {
          const values = rawItems[key];
          if (values && values.length > 0) {
            return values[values.length - 1];
          }
        }
      }
    }
    return undefined;
  };

  const revenue = findLatest(["OperatingRevenues", "NetSalesSummaryOfBusinessResults", "NetSales"]);
  const netIncome = findLatest(["NetIncomeLossSummaryOfBusinessResults", "ProfitLossAttributableToOwnersOfParent", "NetIncomeLoss"]);
  const operatingCashFlow = findLatest([
    "NetCashProvidedByUsedInOperatingActivities",
    "CashFlowsFromUsedInOperatingActivities",
  ]);
  const payoutRatio = findLatest(["PayoutRatio"]);
  const totalAssets = findLatest(["TotalAssetsSummaryOfBusinessResults", "TotalAssets"]);

  return {
    revenue,
    netIncome,
    operatingCashFlow,
    payoutRatio,
    totalAssets,
    unit: "千円",
    rawItems,
  };
}

/**
 * 財務数値から「営業CF赤字」「無理な配当維持」などの定量的リスクを自動判定
 */
export function assessQuantitativeRisk(metrics: KeyFinancialMetrics): QuantitativeRiskAssessment {
  const detectedRedFlags: RedFlagType[] = [];
  const quantitativeWarnings: string[] = [];

  // 1. 営業活動によるキャッシュフローの赤字判定 (negative_operating_cf)
  if (metrics.operatingCashFlow !== undefined) {
    if (metrics.operatingCashFlow < 0) {
      detectedRedFlags.push("negative_operating_cf");
      quantitativeWarnings.push(
        `営業活動によるキャッシュ・フローがマイナス（${metrics.operatingCashFlow.toLocaleString()}千円）`
      );
    }
  }

  // 2. 配当性向 100% 超え（タコ足配当・unsustainable_payout）
  if (metrics.payoutRatio !== undefined && metrics.payoutRatio > 100.0) {
    detectedRedFlags.push("unsustainable_payout");
    quantitativeWarnings.push(
      `配当性向が ${metrics.payoutRatio.toFixed(1)}%`
    );
  }

  return {
    metrics,
    detectedRedFlags,
    quantitativeWarnings,
  };
}
