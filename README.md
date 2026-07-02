# Claude Code 에러 처리 킷

바이브 코딩을 하다 보면 AI가 모든 에러를 "Failed to fetch"나 "생성 실패(400)" 같은
일반 메시지로 뭉개버려서 실제 원인을 찾기 어려워지는 경우가 많습니다.
이 킷은 그걸 두 겹으로 막습니다:

1. **규칙** (`.claude/rules/error-handling.md`) — 세션 시작 시 자동 로드되어
   Claude가 코드를 짤 때 항상 참고하는 에러 처리 규칙
2. **검사 hook** (`.claude/hooks/` + `settings.json`) — Claude가 JS/TS 파일을
   수정할 때마다 자동 실행되어, 에러를 삼키는 패턴(빈 catch, cause 없는 재던지기)을
   발견하면 Claude에게 즉시 피드백 → Claude가 스스로 고침

규칙은 "권고", hook은 "강제"라서 컨텍스트가 길어져 규칙이 희석돼도 hook이 잡아줍니다.

## 설치 (한 줄)

> ⚠️ **반드시 적용할 프로젝트 폴더 안에서 실행하세요.** 이 명령은 "현재 위치한 폴더"에
> `.claude` 폴더를 만듭니다. 홈 디렉토리(`~`)에서 실행하면 개인 전역 설정 위치에
> 설치되어 모든 프로젝트에 적용되니 주의하세요. 프로젝트가 여러 개라면 각 프로젝트에서
> 한 번씩 실행하면 됩니다.

```bash
curl -fsSL https://raw.githubusercontent.com/SheepJH/claude-error-handling-kit/main/install.sh | bash
```

다음 Claude Code 세션부터 자동 적용됩니다. 이미 `.claude/settings.json`이 있는
프로젝트에서도 안전합니다 — 기존 파일을 백업(`settings.json.bak`)한 뒤 hook 항목만
병합하고, 재실행해도 중복 등록되지 않습니다.

## 수동 설치

스크립트 실행이 꺼려진다면 이 레포의 `.claude` 폴더를 프로젝트 루트에 복사하면 됩니다.

```bash
cp -r .claude /path/to/your-project/
```

이미 `settings.json`이 있다면 이 킷의 `hooks` 항목을 기존 파일에 직접 병합하세요.

## 요구 사항 / 참고

- hook 실행에 Node.js가 필요합니다 (웹 프로젝트라면 이미 있을 것)
- hook 검사 대상은 `.js .jsx .ts .tsx .mjs .cjs` 파일입니다
- hook은 정규식 기반 휴리스틱이라 오탐이 있을 수 있습니다. 의도된 코드라면
  해당 위치에 이유를 주석으로 남기라고 Claude에게 안내됩니다
- 팀 레포라면 `.claude` 폴더를 커밋해두세요. 클론받는 사람 전원에게 자동 적용됩니다
