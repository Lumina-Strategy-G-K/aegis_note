# Aegis Note 🛡️

**Advanced Privacy. Practical Sovereignty. Zero-Trust Architecture.**

[English](#english) | [日本語](#japanese)

---

<a name="english"></a>
## English

**Aegis Note** is a standalone, encrypted note-taking utility designed for users who prioritize robust privacy and long-term data survivability. By operating entirely offline and eliminating databases, it provides a "Zero-Trust" environment where you maintain high sovereignty over your information.

### 🛡️ Design Philosophy: Local-First & Zero-Trust
In an era of cloud dependency, **Aegis Note** returns control to the user. 
- **No Internet**: Designed to minimize the risk of data leakage by removing network vectors.
- **No Database**: Every note is an independent encrypted file, reducing the risk of mass data corruption.
- **Survivability**: Your password is the primary key. No complex hidden metadata files are required for recovery.

### 🌟 Technical Specifications
- **Cryptography**: **XChaCha20-Poly1305** (AEAD) for high-performance, modern authenticated encryption. Its **constant-time implementation** minimizes the risk of software-based timing attacks.
- **Key Derivation**: **PBKDF2-HMAC-SHA256** with **600,000 iterations** (OWASP compliant) to significantly strengthen resistance against hardware-accelerated brute-force attacks.
- **Memory Safety**: Secure erasure policy for sensitive keys upon session termination.
- **Interoperability**: High data compatibility across **Windows, Linux, and Android**, allowing you to move encrypted files between devices freely.

### 🚀 How to Use
1. **Initial Setup**: On first launch, set a Master Password (min. 3 characters). This cannot be recovered if lost.
2. **Organization**: Create a directory tree in the left pane (Desktop) or via the folder view (Mobile).
3. **Writing**: Use the Editor to write in Plain Text (`.ext`) or Markdown (`.mde`). 
4. **Auto-Lock**: The app automatically logs out after 5 minutes of inactivity to help protect your data.
5. **Portability**: Simply copy your `user_data` folder to any device to access your notes.

### 💖 Support the Development
Aegis Note is an open-source project. Your support helps us maintain and ensure sustainable development.
- **Support Link**: [https://www.paypal.com/ncp/payment/4MLF4MTN4BSUG]
- *Note: Please understand that all contributions are non-refundable. We appreciate your support for the project's sustainability.*

### ⚖️ License
Licensed under the **Apache License, Version 2.0**.
Copyright 2026 Lumina Strategy G.K.

---

<a name="japanese"></a>
## 日本語

**Aegis Note** は、強固なプライバシー保護と長期的なデータの生存性に主眼を置いた、スタンドアロン型の高度暗号化ノートツールです。「ゼロトラスト（何も過信しない）」の設計思想に基づき、ネットワーク利用とデータベースを排除することで、ユーザーのデータに高度な主権を提供します。

### 🛡️ 設計哲学：ローカル・ファースト＆ゼロトラスト
クラウドへの依存が一般的となった現代において、**Aegis Note** は制御権をユーザーの手に取り戻します。
- **完全オフライン**: インターネット権限を持たず、ネットワーク経由の流出リスクを構造的に抑制します。
- **データベースレス**: 各ノートを独立した暗号化ファイルとして管理し、一括データ破損のリスクを低減します。
- **高い生存性**: パスワードがあれば、将来にわたってデバイスを問わず復元しやすい、シンプルで堅牢な構造を採用しています。

### 🌟 技術仕様
- **暗号化アルゴリズム**: **XChaCha20-Poly1305** を採用。高速かつ、**定数時間（Constant-time）動作**により、ソフトウェア的なタイミング攻撃（サイドチャネル攻撃の一種）に対する高い耐性を備えています。
- **鍵生成（KDF）**: **PBKDF2-HMAC-SHA256 (600,000回反復)** を実装。セキュリティ基準（OWASP）に準拠し、総当たり攻撃に対する耐性を大幅に高めています。
- **メモリ保護**: ログアウトまたは終了時にメモリ上の暗号鍵を速やかに破棄する管理ポリシー。
- **互換性**: **Windows, Linux, Android** の間で、暗号化ファイルの高いデータ互換性を確保。デバイスを跨いだ自由なファイル移動が可能です。

### 🚀 使い方
1. **初期設定**: 初回起動時にマスターパスワードを設定してください（3文字以上）。パスワードの復元は不可能です。
2. **整理**: 左ペイン（PC）またはフォルダ画面（スマホ）でディレクトリツリーを作成し、情報を整理します。
3. **記録**: テキスト形式（`.ext`）またはマークダウン形式（`.mde`）で記録できます。
4. **自動ロック**: 5分間の無操作で自動ログアウトし、離席時の覗き見リスクからデータを守ります。
5. **持ち運び**: `user_data` フォルダをコピーするだけで、異なるデバイス間でデータを共有できます。

### 💖 開発支援
Aegis Note はオープンソースプロジェクトとして公開されています。皆様からの継続的なご支援は、持続的な開発を続けていくための大きな力となります。
- **支援用リンク**: [https://www.paypal.com/ncp/payment/4MLF4MTN4BSUG]
- ※恐れ入りますが、お送りいただいた支援の返金には応じかねます。プロジェクトの継続的な運営へのご協力として、あらかじめご了承いただけますと幸いです。

### ⚖️ ライセンス
本プロジェクトは **Apache License, Version 2.0** のもとで公開されています。
Copyright 2026 合同会社ルミナス