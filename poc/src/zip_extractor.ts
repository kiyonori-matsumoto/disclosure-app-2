import AdmZip from "adm-zip";
import * as path from "node:path";
import { extractQualitativeSections, QualitativeSection } from "./extractor.js";

/**
 * 有報のZIPファイル（またはバッファ）から、PublicDoc/*.htm を探して
 * 定性セクション（事業等のリスクなど）を一括抽出する
 */
export function extractSectionsFromZip(zipPathOrBuffer: string | Buffer): Map<string, QualitativeSection> {
  const zip = typeof zipPathOrBuffer === "string" ? new AdmZip(zipPathOrBuffer) : new AdmZip(zipPathOrBuffer);
  const zipEntries = zip.getEntries();

  const allSections = new Map<string, QualitativeSection>();

  // PublicDoc/ 配下の .htm / .html ファイルを探索
  const htmEntries = zipEntries.filter((entry) => {
    const entryName = entry.entryName.toLowerCase();
    const isPublicDoc = entryName.includes("publicdoc/") || entryName.includes("auditdoc/");
    const isHtm = entryName.endsWith(".htm") || entryName.endsWith(".html");
    return isPublicDoc && isHtm;
  });

  // もし PublicDoc が見つからない場合は、すべての .htm を対象にする
  const targetEntries = htmEntries.length > 0
    ? htmEntries
    : zipEntries.filter((e) => e.entryName.endsWith(".htm") || e.entryName.endsWith(".html"));

  for (const entry of targetEntries) {
    const content = entry.getData().toString("utf-8");
    const sections = extractQualitativeSections(content);

    for (const [key, sec] of sections.entries()) {
      // まだ見つかっていないか、より長い本文が見つかった場合に更新
      const existing = allSections.get(key);
      if (!existing || sec.text.length > existing.text.length) {
        allSections.set(key, sec);
      }
    }
  }

  return allSections;
}
