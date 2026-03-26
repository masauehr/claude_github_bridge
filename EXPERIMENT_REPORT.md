# Remote Trigger 外部API接続実験レポート

**実験日**: 2026-03-26
**目的**: Claude Code Remote Trigger 環境から外部APIへアクセスできるか検証する

---

## 背景

`claude_github_bridge` プロジェクトは、Claude のクラウド実行環境（Remote Trigger）で何ができるかを試す実験的プロジェクト。
週次レポートの Trigger を起点に、外部データ取得の可否を検証した。

---

## 実験内容と結果

### 試行1: Yahoo Finance API（日経平均データ）

**目的**: 日経平均の現在値・52週高値を取得して暴落判定を行う

**エンドポイント**:
```
https://query1.finance.yahoo.com/v8/finance/chart/%5EN225?interval=1d&range=1y
```

**結果**: ❌ タイムアウト（接続応答なし）

**考察**: Yahoo Finance はレート制限・IP制限が厳しく、クラウドDCからの接続をブロックしていると推定。

---

### 試行2: stooq.com（日経平均データ・代替）

**目的**: Yahoo Finance の代替として stooq.com を使用

**エンドポイント**:
```
https://stooq.com/q/l/?s=^nkx&f=sd2t2ohlcv&h&e=csv  （現在値）
https://stooq.com/q/d/l/?s=^nkx&i=d                 （1年分の日次データ）
```

**結果**: ❌ ネットワークエラー（curl exit code 56: Failure with receiving network data）

**考察**: 接続は確立されるがデータ転送に失敗。stooq.com がクラウドDCからの接続を途中で切断していると推定。

---

### 試行3: Yahoo Finance API（ヘッダー付き・別サブドメイン）

**目的**: User-Agent ヘッダーを付与し、query2 サブドメインを使用

**エンドポイント**:
```
https://query2.finance.yahoo.com/v8/finance/chart/%5EN225?interval=1d&range=1y
```

**追加ヘッダー**:
```
User-Agent: curl/7.84.0
Accept: application/json
--max-time 30
```

**結果**: ❌ タイムアウト（改善なし）

**考察**: サブドメイン変更・ヘッダー付与では突破できず。IP レベルでのブロックと判断。

---

### 試行4: 気象庁API（沖縄本島地方の天気予報）

**目的**: 金融データを諦め、気象庁の公開APIを試す

**エンドポイント**:
```
https://www.jma.go.jp/bosai/forecast/data/forecast/471000.json
```

**試行A（ヘッダーなし）**:
結果: ❌ 403 Forbidden

**試行B（ブラウザ偽装ヘッダー付き）**:
```
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ...
Referer: https://www.jma.go.jp/bosai/forecast/
Accept: application/json, text/plain, */*
Accept-Language: ja,en;q=0.9
```
結果: ❌ 403 Forbidden（改善なし）

**ローカルからの検証**:
```bash
# 同一コマンドをローカル（日本国内）から実行
→ ✅ HTTP 200 OK（正常取得）
```

取得できたデータ例:
```
発表: 沖縄気象台
日時: 2026-03-26T11:00:00+09:00
エリア: 本島中南部
  2026-03-26: 晴れ 時々 くもり
  2026-03-27: くもり
  2026-03-28: くもり
```

**考察**: 気象庁は **日本国内IP からのアクセスのみ許可** している。
Remote Trigger が動作する Anthropic のクラウド環境（米国DCと推定）からは IP ジオブロッキングにより 403 が返る。
User-Agent や Referer の偽装では突破できない。

---

## 総合結果

| サービス | URL | 結果 | 原因推定 |
|----------|-----|------|----------|
| GitHub API | api.github.com | ✅ 成功 | 制限なし |
| Yahoo Finance | query1/query2.finance.yahoo.com | ❌ タイムアウト | IP制限 |
| stooq.com | stooq.com | ❌ exit code 56 | 接続切断 |
| 気象庁 | www.jma.go.jp | ❌ 403 Forbidden | IPジオブロッキング（日本国内のみ許可） |

---

## 結論

**Remote Trigger 環境から安定してアクセスできるのは `api.github.com` のみ**。

日本の金融・気象データを提供するサービスの多くは、クラウドDC（海外IP）からのアクセスを制限している。
これは利用規約・セキュリティ・インフラコスト等の観点から意図的な制限と考えられる。

---

## 今後の方向性

### Remote Trigger でできること（GitHub API 活用）
- Issue / PR の自動要約・レビュー（当初の設計通り）
- コミット統計・リポジトリ状況のレポート生成
- GitHub API 経由でのファイル作成・更新

### 日本データを使う場合の代替手段
| 手段 | 概要 |
|------|------|
| **macOS launchd でローカル実行** | 日本国内IPから直接実行。既存の `setup_launchd.sh` を活用 |
| **GitHub Actions（self-hosted runner）** | ローカルマシンをランナーとして登録 |
| **Open-Meteo API** | 無料・認証不要・グローバルアクセス可。気象庁データではないが気温・降水確率は取得可能 |

---

## 参考: Remote Trigger の設定

```json
{
  "name": "claude_github_bridge 週次レポート",
  "cron_expression": "30 6 * * 4",
  "session_context": {
    "allowed_tools": ["Bash", "Read", "Glob", "Grep"],
    "model": "claude-sonnet-4-6"
  }
}
```

実行タイミング: 毎週木曜 15:30 JST
