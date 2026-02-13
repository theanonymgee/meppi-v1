## 1. Development Philosophy

### Kent Beck TDD Methodology
**Core TDD Cycle: Red → Green → Refactor**

1. **Red (Failing Test)**
   - Write the simplest failing test first
   - Use meaningful test names describing behavior (e.g., `shouldSumTwoPositiveNumbers`)
   - Make test failures clear and informative
   - Write one test at a time - focus on small increment of functionality

2. **Green (Minimum Implementation)**
   - Write just enough code to make the test pass - no more
   - Use the simplest solution that could possibly work
   - Avoid premature optimization or over-engineering

3. **Refactor (Improve Structure)**
   - Refactor only when all tests are passing
   - Eliminate duplication ruthlessly
   - Express intent clearly through naming and structure
   - Keep methods small and focused on single responsibility
   - Run tests after each refactoring step

### Tidy First Approach
**Separate Structural from Behavioral Changes**

- **Structural Changes (Tidy First)**:
  - Rearranging code without changing behavior
  - Renaming variables, functions, files
  - Extracting methods or moving code
  - Validate with tests before and after
  - Commit separately with "chore:" or "refactor:" prefix

- **Behavioral Changes (Feature Second)**:
  - Adding or modifying actual functionality
  - Always comes AFTER structural changes
  - Commit separately with "feat:" or "fix:" prefix
  - Never mix with structural changes in same commit

### Vibe Coding 6 Principles
**바이브코딩 6대 원칙 (6 Core Standards)**

1. **Consistent Pattern (일관된 패턴)**
   - All code follows the same CRUD patterns across the project
   - Analyze existing patterns before writing new code
   - File structure, naming, and organization must be uniform

2. **One Source of Truth (단일 진실 공급원)**
   - No duplicated logic or data
   - Single authoritative source for each piece of information
   - DRY (Don't Repeat Yourself) principle strictly enforced

3. **No Hardcoding (하드코딩 금지)**
   - Magic Numbers/Strings must be named constants
   - Status values ("취소", "완료") extracted to `constants/` directory
   - Configuration values in environment variables
   - Example: `constants/` for app-wide values, `types/` for type definitions

4. **Error & Exception Handling (에러/예외 처리)**
   - Not just happy path - handle all error cases
   - try-catch for all async operations
   - User-friendly error messages
   - Graceful degradation when services fail

5. **Single Responsibility (단일 책임)**
   - Each function/module performs ONE task only
   - Clear separation of concerns
   - Easy to test and maintain
   - If a function does multiple things, split it

6. **Shared Code Management (재사용성 관리)**
   - Reusable components in `components/ui/`
   - Shared hooks in `hooks/`
   - Common utilities in `lib/` or `utils/`
   - Ensures code extensibility and reusability

---

## 2. Documentation

### Document Structure (`/docs`)
```
docs/
├── ondev/               # Detailed plans and analysis documents
│   └── YYYYMMDD_NN_description.md  # Date + sequence + description
└── ref/                 # Reference materials
```

**Documentation Organization Rules:**
- **`/docs/` (root)**: High-level strategic documents only (plan.md, current_state.md, decisions.md, PRD.md, LLD.md)
- **`/docs/ondev/`**: Detailed phase plans, implementation plans, fix plans, analysis documents
- **`/docs/ref/`**: Reference materials and development principles

**File Naming Convention (`/docs/ondev/`):**
```
Format: YYYYMMDD_NN_description.md

- YYYYMMDD: 생성 날짜 (예: 20251209)
- NN: 해당일 생성 순서 (01, 02, 03...)
- description: 문서 설명 (snake_case)

Examples:
- 20251209_01_webhook_analysis.md
- 20251209_02_blueprint_option_a_implementation_plan.md
- 20251209_03_phase_68_phase2_task4_5_plan.md
```

### Insight Documentation Rule

**오류 발견 및 수정 시 인사이트 문서 저장 필수**

오류가 발견되고, 시도된 오류 수정, 수정하는 과정, 수정 완료된 것에 대한 인사이트는 문서 저장 규칙에 따라 항상 `.md` 파일로 저장해야 합니다.

**저장 위치**: `docs/ondev/YYYYMMDD_NN_description_insight.md`

**인사이트 문서 포함 내용**:
1. **Issue Summary**: 발견된 문제 요약
2. **Initial Hypothesis**: 초기 가설 (맞았든 틀렸든)
3. **Root Cause**: 실제 근본 원인
4. **Debugging Process**: 디버깅 과정 (잘못된 방향 포함)
5. **Solution**: 해결 방법
6. **Key Insights**: 핵심 교훈 및 학습 내용
7. **Prevention**: 향후 예방 방법

**예시**:
- `20260107_05_pdf_text_extraction_fix_insight.md`
- `20260107_03_chat_room_delete_issue_summary.md`

---

## 3. Development Workflow

### Before Work
1. Check `docs/plan.md` and `docs/current_state.md`
2. Identify current phase and checklist (`docs/ondev/phase_X_plan.md`)
3. Review recent decisions in `docs/decisions.md`

### TDD Execution Workflow
Following Kent Beck's methodology:

1. **Find Next Test** (from plan.md or phase plan)
   - Identify the smallest next increment
   - Read the test specification

2. **Red Phase - Write Failing Test**
   - Write ONE test at a time
   - Test should fail for the right reason
   - Meaningful test name describing expected behavior
   - Clear, informative failure message

3. **Green Phase - Minimum Implementation**
   - Write the LEAST code to make test pass
   - No premature optimization
   - No extra features "just in case"
   - Run test to confirm it passes

4. **Refactor Phase - Improve Structure** (Only if needed)
   - Clean up duplications
   - Improve naming and clarity
   - Ensure tests still pass after each change
   - Stop when code is clean enough

5. **Commit**
   - Commit ONLY when tests pass
   - Small, frequent commits
   - Clear commit messages (structural vs behavioral)
   - Update checklist

6. **Repeat** for next test

### Commit Discipline
**ONLY commit when ALL of these are true:**
- ✅ All tests passing
- ✅ No compiler/linter warnings
- ✅ Single logical unit of work
- ✅ Clear message: structural ("chore:", "refactor:") vs behavioral ("feat:", "fix:")
- ✅ Checklist updated if applicable

**Commit Types:**
- `feat(scope): add feature X` - Behavioral change
- `fix(scope): correct bug Y` - Behavioral change
- `refactor(scope): extract method Z` - Structural change
- `chore(scope): update constants` - Structural change

---

## 4. Coding Conventions

- **Naming**: Intent-revealing, no abbreviations
- **Error Handling**: try-catch for async, user-friendly messages
- **Components**: Reusable UI in `components/ui`, logic in hooks
- **Security**: No API keys in code, use `.env` (EXPO_PUBLIC_* prefix)

---

## 5. Environment


### Git Config
```bash
git config http.postBuffer 524288000
```

### .gitignore
- `.env`, `node_modules/`, `build/`, `.expo/`
- `.apk`, `.aab`, `.ipa`
- `docs/` (optional)

---

## 6. Checklist (Before Commit)

**Code**: Tests pass? DRY? SRP? No hardcoding? Error handling? Pattern consistent?
**Docs**: Updated? Decisions logged? Checklist updated?
**Security**: No secrets? Env vars set? RLS applied?
**Commit**: Clear message? Structural/behavioral separated? No warnings?

---
