# Nirvana Studio Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 將網站資料夾與 GitHub 儲存庫改名為 `Nirvana_Studio`，保留全部網站內容並維持 GitHub Pages 部署。

**Architecture:** 先同步遠端最新提交，再以 Git 重新命名網站資料夾並更新 Pages 工作流程。推送後改名 GitHub 儲存庫、更新本機遠端，最後驗證新網址與清除舊路徑。

**Tech Stack:** Git、GitHub CLI、GitHub Actions、GitHub Pages、靜態 HTML

---

### Task 1: 同步與保護現況

**Files:**
- Preserve: 現有未提交檔案
- Inspect: `.github/workflows/pages.yml`

- [ ] 執行 `git fetch origin`，確認本機與遠端提交關係
- [ ] 將目前規格提交安全整合到遠端最新 `main`
- [ ] 確認未提交檔案狀態未被更動

### Task 2: 重新命名部署資料夾

**Files:**
- Rename: `網路資料/` → `Nirvana_Studio/`
- Modify: `.github/workflows/pages.yml`

- [ ] 使用 `git mv` 重新命名完整網站資料夾
- [ ] 將 `actions/upload-pages-artifact` 的 `path` 改為 `Nirvana_Studio`
- [ ] 搜尋儲存庫，確認無舊部署路徑或其他平台設定
- [ ] 提交資料夾與工作流程改名

### Task 3: 發布並改名儲存庫

**Files:**
- Remote repository: `ray541221/codex-backup` → `ray541221/Nirvana_Studio`

- [ ] 推送最新 `main`
- [ ] 使用 GitHub CLI 改名儲存庫
- [ ] 更新本機 `origin` 為新儲存庫網址
- [ ] 確認 GitHub Pages 工作流程開始執行

### Task 4: 最終驗證與清理

**Files:**
- Verify: `Nirvana_Studio/`
- Verify: `.github/workflows/pages.yml`

- [ ] 等待最新 GitHub Pages 工作流程成功
- [ ] 驗證新首頁、商品頁、`commercial-33.jpg`、`commercial-34.jpg` 回傳 HTTP 200
- [ ] 確認 GitHub 儲存庫內不存在 `網路資料/`
- [ ] 確認部署平台、工作流程、遠端唯一指向 GitHub
- [ ] 確認原網站檔案數量與內容完整保留
