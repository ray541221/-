# Nirvana Studio 改名規格

## 目標

- GitHub 儲存庫：`codex-backup` 改為 `Nirvana_Studio`
- 部署資料夾：`網路資料` 改為 `Nirvana_Studio`
- GitHub Pages 網址改為 `https://ray541221.github.io/Nirvana_Studio/`
- 新網站驗證成功後，不保留舊資料夾

## 執行

1. 將本機 `網路資料` 重新命名為 `Nirvana_Studio`
2. 更新 GitHub Pages 工作流程發布路徑
3. 提交並推送至 GitHub
4. 將 GitHub 儲存庫改名為 `Nirvana_Studio`
5. 更新本機 `origin`
6. 等待 GitHub Pages 部署完成
7. 驗證首頁、商品頁、兩張商品圖片
8. 確認舊資料夾與舊部署設定已移除

## 保護範圍

- 不修改現有未提交的其他檔案
- 不使用 Netlify
- 唯一部署平台為 GitHub Pages

## 驗證

- GitHub 儲存庫名稱為 `ray541221/Nirvana_Studio`
- Git 遠端指向新儲存庫
- GitHub Pages 工作流程成功
- 新網址與商品圖片回傳 HTTP 200
- 儲存庫內不存在舊的 `網路資料` 資料夾
