import * as fs from "node:fs/promises";
import * as path from "node:path";

export interface EdinetDocumentItem {
  seqNumber: number;
  docID: string;
  edinetCode: string;
  secCode?: string;
  filerName: string;
  fundCode?: string;
  ordinanceCode: string;
  formCode: string;
  docTypeCode: string;
  periodStart?: string;
  periodEnd?: string;
  submitDateTime: string;
  docDescription: string;
}

export class EdinetClient {
  private apiKey?: string;
  private baseUrl = "https://api.edinet-fsa.go.jp/api/v2";

  constructor(apiKey?: string) {
    this.apiKey = apiKey || process.env.EDINET_API_KEY;
  }

  private buildUrl(path: string, params: Record<string, string | number>): string {
    const url = new URL(`${this.baseUrl}${path}`);
    for (const [key, val] of Object.entries(params)) {
      url.searchParams.set(key, String(val));
    }
    if (this.apiKey) {
      url.searchParams.set("Subscription-Key", this.apiKey);
    }
    return url.toString();
  }

  /**
   * 指定日付の提出書類一覧を取得
   * @param date YYYY-MM-DD
   */
  async getDocumentList(date: string): Promise<EdinetDocumentItem[]> {
    if (!this.apiKey) {
      throw new Error(
        "EDINET API キーが未設定です。poc/.env に EDINET_API_KEY=your_key を設定するか、WebサイトからダウンロードしたZIPファイルを直接ご利用ください。"
      );
    }

    const url = this.buildUrl("/documents.json", { date, type: 2 });
    const res = await fetch(url);

    if (!res.ok) {
      throw new Error(`EDINET API error: ${res.status} ${res.statusText}`);
    }

    const text = await res.text();
    try {
      const data = JSON.parse(text) as { results?: EdinetDocumentItem[]; status?: string; message?: string };
      return data.results || [];
    } catch {
      throw new Error(
        `EDINET API からJSON以外の応答が返されました (APIキーが無効、またはメンテナンスの可能性があります):\n${text.slice(0, 300)}`
      );
    }
  }

  /**
   * 書類のZIP（提出本文書・監査報告書）をダウンロード
   * @param docId 書類管理番号 (例: S100XXXX)
   * @param savePath 保存先パス (指定があればファイル保存)
   */
  async downloadDocumentZip(docId: string, savePath?: string): Promise<Buffer> {
    if (!this.apiKey) {
      throw new Error(
        "EDINET API キーが未設定です。poc/.env に EDINET_API_KEY=your_key を設定してください。"
      );
    }

    const url = this.buildUrl(`/documents/${docId}`, { type: 1 });
    const res = await fetch(url);

    if (!res.ok) {
      throw new Error(`Failed to download document ${docId}: ${res.status} ${res.statusText}`);
    }

    const arrayBuffer = await res.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    if (savePath) {
      await fs.mkdir(path.dirname(savePath), { recursive: true });
      await fs.writeFile(savePath, buffer);
    }

    return buffer;
  }
}
