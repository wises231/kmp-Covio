# ADR-0005：本机用固定证书签名

- Status：accepted
- Kind：architecture
- Date：2026-10-15
- Supersedes：none
- Implements：#116

## 背景

TCC 用代码签名识别应用。工程原来在四处构建配置里写 `CODE_SIGN_IDENTITY = "-"`，即 ad-hoc 签名。

ad-hoc 签名没有 Team ID。识别依据退化成 cdhash：

```text
$ codesign -d -r- build/xcode-dd/Build/Products/Debug/Covio.app
# designated => cdhash H"c994eba9091859a67982e890baef6e97d782b088"
```

每次构建都产生新 cdhash。系统把新构建当成新应用。于是系统重新要辅助功能权限，并重发「已添加设备控制和数据访问」通知。授权在两次构建之间不保留。

三个约束：

1. CI 跑在 GitHub 运行器上。那里没有本机证书。默认配置必须能构建。
2. `scripts/package-macos-swift.sh` 有意用 ad-hoc 签名对外分发。分发签名要 Developer ID 证书与公证，不在本决策范围内。
3. 本机没有可用的签名身份。`security find-identity -v -p codesigning` 返回 0 个。

## 决策

1. 工程默认保持 ad-hoc 签名。任何机器都能构建，CI 也走这条。
2. 新增 `macosApp/Signing.xcconfig`，作为工程的 base configuration。
3. 该文件用 `#include?` 可选引入同目录的 `Signing.local.xcconfig`。
4. `Signing.local.xcconfig` 不进仓库。本机在那里放签名身份。
5. 签名身份用本机自建的代码签名证书，不用 Apple 开发者证书。

建证书的步骤：

```bash
cat > openssl.cnf <<'EOF'
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = Covio Dev
O = Covio
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
  -config openssl.cnf -keyout covio.key -out covio.crt
openssl pkcs12 -export -out covio.p12 -inkey covio.key -in covio.crt -passout pass:covio
security import covio.p12 -k "$HOME/Library/Keychains/login.keychain-db" -P covio \
  -T /usr/bin/codesign -T /usr/bin/xcodebuild
security find-identity -v -p codesigning
```

最后一条命令应列出 `"Covio Dev"`。然后在 `macosApp/Signing.local.xcconfig` 写：

```text
CODE_SIGN_IDENTITY = Covio Dev
CODE_SIGN_STYLE = Manual
```

## 后果

### 正面

- 本机授权一次之后，重新构建不再弹窗。
- CI 与别人的克隆不受影响。
- 签名身份不进仓库，也不绑 Apple 账号。

### 负面

- 每台开发机要建一次证书。
- 换机器或删掉证书后，识别依据改变，要重新授权一次。

### 风险

- 证书进登录钥匙串后，其他进程可以用它签名。缓解：该证书只用于本机开发，不用于分发。
- 自签名证书过不了 Gatekeeper。缓解：分发仍走 `package-macos-swift.sh` 的 ad-hoc 路径，将来换 Developer ID。

## 备选方案

### 备选 1：Apple Development 证书

用 Xcode 的 Apple ID 账号建 Apple Development 证书，把 `DEVELOPMENT_TEAM` 写进工程。识别依据会锚定团队 ID，跨证书续期稳定。

未采纳的原因：本机 Xcode 没有登录的账号，构建报 `error: No Accounts`。建证书要在图形界面登录。而且它只解决本机开发，分发仍要另买 Developer ID。

### 备选 2：把签名身份写进工程

直接把四处 `CODE_SIGN_IDENTITY` 改成证书名。

未采纳的原因：CI 与本机之外的克隆会构建失败。

### 备选 3：只在构建脚本里传签名参数

`scripts/build-macos-swift.sh` 与 `scripts/test-macos-swift.sh` 加命令行参数。

未采纳的原因：Xcode 图形界面里构建仍走 ad-hoc。而那正是调试弹窗的场景之一。

## 未决事项

| 项目 | 状态 | 确认方法 |
| --- | --- | --- |
| 连续两次构建的 designated requirement 是否相同 | pending | 建好证书后连续构建两次，比对 `codesign -d -r-` 的输出 |
| 分发签名与公证 | pending | 另开 issue |

## 参考

- `macosApp/Signing.xcconfig`
- `scripts/package-macos-swift.sh`
