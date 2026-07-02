#!/usr/bin/env bash
# Claude Code 에러 처리 킷 설치 스크립트
# 사용법 (프로젝트 루트에서):
#   curl -fsSL https://raw.githubusercontent.com/SheepJH/claude-error-handling-kit/main/install.sh | bash
set -euo pipefail

REPO="SheepJH/claude-error-handling-kit"
BRANCH="main"
BASE="${KIT_BASE_URL:-https://raw.githubusercontent.com/$REPO/$BRANCH/.claude}"

if [ "$PWD" = "$HOME" ]; then
  echo "❌ 홈 디렉토리에서 실행하면 개인 전역 설정(~/.claude)에 설치되어 모든 프로젝트에 적용됩니다."
  echo "   적용할 프로젝트 폴더로 이동한 뒤 다시 실행하세요:  cd /path/to/your-project"
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "❌ Node.js가 필요합니다 (hook 실행에 사용). 설치 후 다시 시도하세요."
  exit 1
fi

echo "📥 규칙 및 hook 파일 다운로드 중..."
mkdir -p .claude/rules .claude/hooks
curl -fsSL "$BASE/rules/error-handling.md" -o .claude/rules/error-handling.md
curl -fsSL "$BASE/hooks/check-error-handling.js" -o .claude/hooks/check-error-handling.js

if [ ! -f .claude/settings.json ]; then
  curl -fsSL "$BASE/settings.json" -o .claude/settings.json
  echo "✅ .claude/settings.json 생성 완료"
else
  echo "🔧 기존 .claude/settings.json 발견 — hook 항목을 병합합니다 (백업: settings.json.bak)"
  cp .claude/settings.json .claude/settings.json.bak
  node <<'MERGE'
const fs = require("fs");
const path = ".claude/settings.json";
const cmd = 'node "$CLAUDE_PROJECT_DIR/.claude/hooks/check-error-handling.js"';

let settings;
try {
  settings = JSON.parse(fs.readFileSync(path, "utf8"));
} catch (err) {
  console.error("❌ settings.json 파싱 실패 — 파일이 올바른 JSON인지 확인하세요:", err.message);
  process.exit(1);
}

settings.hooks = settings.hooks || {};
settings.hooks.PostToolUse = settings.hooks.PostToolUse || [];

const alreadyRegistered = settings.hooks.PostToolUse.some((entry) =>
  (entry.hooks || []).some((h) => h.command === cmd)
);

if (alreadyRegistered) {
  console.log("ℹ️  hook이 이미 등록되어 있어 병합을 건너뜁니다");
} else {
  settings.hooks.PostToolUse.push({
    matcher: "Edit|Write|MultiEdit",
    hooks: [{ type: "command", command: cmd }],
  });
  fs.writeFileSync(path, JSON.stringify(settings, null, 2) + "\n");
  console.log("✅ hook 등록 완료");
}
MERGE
fi

echo ""
echo "🎉 설치 완료! 다음 Claude Code 세션부터 자동 적용됩니다."
echo "   - 규칙: .claude/rules/error-handling.md"
echo "   - 검사 hook: JS/TS 파일 수정 시 에러 삼키는 패턴 자동 검사"
