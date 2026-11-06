import "dotenv/config";
import { EdinetClient } from "./edinet_client.js";

async function main() {
  const args = process.argv.slice(2);
  const targetDate = args[0] || new Date().toISOString().split("T")[0]; // デフォルトは今日
  const keyword = args[1] || ""; // 銘柄コードまたは会社名（部分一致）

  console.log(`🔍 EDINET書類検索: 日付=${targetDate}, 絞り込み=${keyword || "全件"}\n`);

  const client = new EdinetClient();
  const docs = await client.getDocumentList(targetDate);

  console.log(`総提出件数: ${docs.length} 件`);

  const filtered = docs.filter((d) => {
    // 有報(120), 半期報告書(150), 四半期報告書(140) 等
    const isReport = ["120", "130", "140", "150"].includes(d.docTypeCode);
    if (!isReport) return false;

    if (!keyword) return true;
    const matchName = d.filerName?.includes(keyword);
    const matchCode = d.secCode?.includes(keyword);
    return matchName || matchCode;
  });

  console.log(`該当報告書: ${filtered.length} 件\n`);

  for (const doc of filtered) {
    console.log(`📄 [${doc.docID}] ${doc.secCode || "----"} ${doc.filerName}`);
    console.log(`   種別: ${doc.docDescription} (${doc.submitDateTime})`);
    console.log(`   解析コマンド例: npx tsx src/analyze_by_docid.ts <前期docID> ${doc.docID}\n`);
  }
}

main().catch((err) => {
  console.error("❌ エラー:", err);
  process.exit(1);
});
