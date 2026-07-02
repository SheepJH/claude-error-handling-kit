#!/usr/bin/env node
// PostToolUse hook: Claude가 JS/TS 파일을 수정할 때마다 에러를 삼키는 패턴을 검사한다.
// 위반 발견 시 exit code 2 + stderr 메시지 → Claude에게 피드백이 전달되어 스스로 수정한다.

const fs = require("fs");

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  let filePath;
  try {
    filePath = JSON.parse(input).tool_input?.file_path;
  } catch {
    process.exit(0);
  }
  if (!filePath || !/\.(js|jsx|ts|tsx|mjs|cjs)$/.test(filePath)) process.exit(0);

  let src;
  try {
    src = fs.readFileSync(filePath, "utf8");
  } catch {
    process.exit(0);
  }

  const problems = [];
  const catchRe = /catch\s*(\([^)]*\))?\s*\{/g;
  let match;

  while ((match = catchRe.exec(src))) {
    const openBrace = catchRe.lastIndex - 1;
    let depth = 0;
    let closeBrace = -1;
    for (let i = openBrace; i < src.length; i++) {
      if (src[i] === "{") depth++;
      else if (src[i] === "}") {
        depth--;
        if (depth === 0) {
          closeBrace = i;
          break;
        }
      }
    }
    if (closeBrace === -1) continue;

    const body = src.slice(openBrace + 1, closeBrace);
    const line = src.slice(0, match.index).split("\n").length;

    if (body.trim() === "") {
      problems.push(
        `${line}행: 빈 catch 블록. 의도적으로 무시한다면 이유를 주석으로 남기고, 아니면 로깅하거나 cause와 함께 다시 던질 것.`
      );
    } else if (/throw\s+new\s+\w*Error\s*\(/.test(body) && !/cause/.test(body)) {
      problems.push(
        `${line}행: catch 안에서 원본 에러를 버리고 새 에러를 던짐. new Error(메시지, { cause: err }) 형태로 원본을 보존할 것.`
      );
    }
  }

  if (problems.length > 0) {
    console.error(
      `[error-handling hook] ${filePath} 에서 에러 처리 규칙 위반 가능성:\n- ${problems.join(
        "\n- "
      )}\n.claude/rules/error-handling.md 규칙에 맞게 수정할 것. 오탐이라면 해당 위치에 이유를 주석으로 남길 것.`
    );
    process.exit(2);
  }
  process.exit(0);
});
