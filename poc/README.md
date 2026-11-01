# 有報・短信 定性リスク フォレンジック比較エンジン (PoC)

適時開示・有価証券報告書の非財務・定性リスク（経営陣の言い訳、重点KPIのサイレント消滅、継続企業の前提・注記爆弾）を炙り出し、**TypeSafe AI (Jev / System One)** と数理モデルで高速判定する PoC です。

---

## 🎯 コア・コンセプト

1. **仕様の9割を無視した iXBRL ピンポイント抽出**
   - 複雑なXBRLタクソノミ解決をバイパスし、HTMLパーサー（cheerio）で `ix:nonNumeric`（事業等のリスク、MD&A、注記）および `ix:nonFraction`（売上、純利益、営業CF）のみを直接抽出。
2. **完全フリーテキスト廃止設計（Literal / bool のみ）**
   - Jev に文章を書かせず、厳格な `Literal`（Enum / Choice）と `bool`（Noul）だけを判定。
   - LLMによるテキスト生成を排除し、**ハルシネーション（嘘）0%・待ち時間 0ms・コスト 0円** で確実なUI解説文（`ui_presentation`）をプログラム側でテンプレート合成。
3. **客観的ファクト（財務数値）と文章（定性言い訳）のクロス検証**
   - プロンプトに主観的な定性形容詞を入れず、機械抽出した純粋なファクト数値（売上・純損失・営業CF）と原文テキストをJevに突き合わせて、数値と文章の矛盾を見抜く。

---

## 📂 モジュール構成

```text
poc/
├── .env.example               # APIキー設定例 (TYPESAFE_API_KEY, EDINET_API_KEY)
├── package.json
├── tsconfig.json
├── data/
│   ├── sample_prior.htm       # テスト用iXBRL (前期)
│   └── sample_current.htm     # テスト用iXBRL (当期)
└── src/
    ├── schemas/               # 💎 完全フリーテキスト廃止スキーマ
    │   ├── qualitative_excuses.ts  # ① 経営陣の定性言い訳・責任転嫁検知
    │   ├── kpi_omission.ts         # ② 前期比較での重点KPI言及消滅検知
    │   └── financial_anomaly.ts    # ③ 財務・資金繰り・注記リスク検知
    ├── extractor.ts           # iXBRL定性タグピンポイント抽出
    ├── zip_extractor.ts       # 有報ZIP自動走査・抽出
    ├── differ.ts              # 前期 vs 当期の行単位テキストDiff
    ├── financial_metrics_extractor.ts # 主要財務数値 (BS/PL/CF) の自動パース＆数理判定
    ├── tag_engine.ts          # リスクタグ自動付与エンジン
    ├── edinet_client.ts       # EDINET API v2 直結クライアント
    ├── search_edinet.ts       # EDINET 書類検索
    ├── evaluate_axelmark.ts   # アクセルマーク(3624) 完全評価
    ├── compare_with_numbers.ts# 定量数値有無の判定精度比較
    └── test_literal_schemas.ts# スキーマ単体検証
```

---

## 🔬 実在企業の検証結果

### 1. トヨタ自動車 (7203) — 巨大企業の好業績とリスク顕在化
- **売上**: 45.1 兆円 / **営業CF**: +4.2 兆円（**極めて健全**）
- **判定結果**:
  - MD&A: `【誠実】`（為替や海外市況悪化を客観的に認識）
  - 事業等のリスク: `【⚠️ リスク顕在化】`（中国不動産停滞、認証問題、気候変動コストの追加を的確に捕捉）
  - 注記・財務: `【健全】`（GC注記やタコ足分配等の致命的爆弾はゼロ）

### 2. アクセルマーク (3624) — 小型株の資本危機・GC注記検知
- **売上**: 約15.8億円 / **当期純損益**: ▲3.8億円 / **営業CF**: ▲2.8億円（**2期連続の現金流出**）
- **判定結果**:
  - MD&A: `【誠実】`（原材料・コスト高を認めている）
  - 財務・注記リスク: `【🚨 危険：経営を揺るがす重大な資金・会計リスク】`
  - 検出バッジ: `[🏷️ 倒産危機サイン]` `[🏷️ 本業の現金減少]`
  - UI生成文:
    > *「事業を続けられるかどうかの重大な懸念（継続企業の前提の疑義）が出ています。また、本業の営業活動で現金がマイナス（流出状態）になっています。」*
  - **有報本文の「継続企業の前提に関する重要な疑義」と「営業CFマイナス数値」を Jev が100%正確に捕捉！**

---

## 🚀 実行コマンド一覧

### 準備
```bash
cd poc
cp .env.example .env
# .env に TYPESAFE_API_KEY と (任意) EDINET_API_KEY を設定
npm install
```

### 検証コマンド
```bash
# 1. 完全フリーテキスト廃止スキーマの検証 (3つのテストケース + トヨタ実データ)
npm run test:literal

# 2. 定量財務数値パース & 定量リスク判定
npm run test:metrics

# 3. アクセルマーク(3624) のフォレンジック完全評価
npx tsx src/evaluate_axelmark.ts

# 4. 定量数値入力の有無による Jev 判定の精度比較
npx tsx src/compare_with_numbers.ts

# 5. EDINET書類検索
npm run search 2024-06-25 トヨタ
```
