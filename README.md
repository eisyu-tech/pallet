# PalletStudio

Roblox 用の板 (PalletLightBrown) カスタマイズ UI。

## 使い方

1. `hello.lua` を **LocalScript** として `StarterPlayer > StarterPlayerScripts` に入れる (これ1個だけで動く)。
2. 起動時にサーバー用コードを `ReplicatedStorage.RunServerCode` (CodeLoader / ServerScriptService) へ送る。
   サーバー側が無い場合は、自分の画面だけに直接反映される。
3. 左下の 🎨 ボタンでウィンドウを開閉。

## 機能

- 色 (パレット / HSV / RGB / 16進数)
- 素材、プリセット
- 質感 (反射・透明度・色ムラ・テクスチャ)
- 光 (発光・縁取り)
- 効果 (レインボー・キラキラ)
- FOV 調整
- 保存 / 永久保存 (これから出す板に自動で反映)
