지금까지 한 작업
1. CLAUDE.md 수정.
2. PreToolUse 타이밍에 block-main-commit 가드 구현.
3. PR Create skill 구현.

## TODO:
1. PR Create skill을 hook 자동화를 통해서 호출  
   - PR 생성 (Stop:write|Edit?)
   - 기능 브랜치 이동 (PreToolUse:Write|Edit) 중요한 점은 매번 호출되지 않도록 브랜치 체크.(이미 기능 브랜치라면 return.)
