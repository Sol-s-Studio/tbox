# test-todo.md — `packages/tbox` 테스트 작업 인수인계

이 문서는 `/clear` 이후 후속 에이전트가 이어받을 수 있도록, `packages/tbox` 테스트 스위트 작업의
현재 상태와 남은 일을 정리한 것입니다. 작업 배경/설계 결정은 `packages/tbox/CLAUDE.md` 의
"실행 / 검증" 절에도 반영되어 있으니 먼저 그쪽을 읽으세요. 이 파일은 다 끝나면 지워도 됩니다.

## 현재 상태: 1차 완료, 전부 통과

`test.luau` (단일 파일) 를 `src/schema/` 구조를 1:1로 미러링하는 `test/` 디렉터리로 쪼갰고,
`src/schema/` 아래 **모든 리프 파일(31개)에 대응하는 테스트가 존재하며 전부 통과**합니다.

```bash
luau test/run.luau     # 직접 실행
pesde run test          # scripts/test.luau 브릿지를 거쳐 동일한 걸 실행
```

둘 다 마지막 줄에 `all schema tests passed.` 가 나오면 정상입니다. 실패하면 `error()` 로 그 자리에서
중단되고 어떤 파일의 어떤 어서션인지 스택트레이스에 나옵니다.

### 구조

```
test/
  run.luau            진입점. 문자열 리터럴로 test/schema/* 를 순서대로 require
  helper.luau         expectOk/expectFail/expectEqual/expectTrue 어서션 (실패 시 error())
  schema/             src/schema/ 를 1:1로 미러링 (any, boolean, number, string, union, map, ...)
    json/             object, array, merge
    roblox/            vector2, vector3, cframe, color3, ... (17개, RobloxApi.md 목록과 동일)
scripts/
  test.luau           pesde run test 용 Lune 호환 브릿지 (const 미사용, process.exec 로 luau 위임)
```

## 이 세션에서 발견한 것 (반드시 읽을 것)

1. **`src/schema/vector.luau` 버그를 발견해서 고쳤습니다.** `Vector()` 팩토리가 세 번째 인자로
   빈 테이블 `{}` 을 넘겨서 `min`/`max`/`minMagnitude`/`maxMagnitude` 옵션이 스키마에 전혀
   반영되지 않고 있었습니다 (제약 검사가 항상 통과). 다른 스키마들과 동일한 패턴으로 고쳤고
   `test/schema/vector.luau` 가 이 회귀를 잡아냅니다.
2. **테스트 엔트리 파일을 `init.luau` 로 이름 지으면 안 됩니다.** 이 환경의 `luau` 는 `init.luau`
   를 디렉터리 인덱스로 특별 취급해서, `src/init.luau` 와 이름이 겹치면
   `could not reset to requiring context (ambiguous)` 오류가 납니다. 그래서 진입점 이름이
   `test/run.luau` 입니다 — 다시 `init.luau` 로 바꾸지 마세요.
3. **stylua 가 `f<<T>>(...)` 명시적 타입 인자 호출 문법을 이해하지 못합니다.** `<<`/`>>` 를
   시프트 연산자로 오해하고, 뒤 토큰이 우연히 시프트 식으로 파싱되면 **에러 없이 조용히** 코드를
   깨뜨립니다 (`Type.Unsafe<<number>>({...})` → `Type.Unsafe << number >> {...}` 로 재작성해버림).
   실제로 `test/schema/unsafe.luau` 가 이렇게 한 번 깨졌다가 diff 로 잡아서 고쳤습니다. `<<>>` 를
   쓰는 파일에 stylua 를 돌린 뒤에는 **반드시 diff 를 눈으로 확인**하세요. 자세한 내용은 루트
   `CLAUDE.md` "코드 스타일" 절에 경고로 남겨뒀습니다.
4. **`Instance`/`EnumItem` 의 클래스·Enum 판별 분기는 mock 으로 테스트할 수 없습니다.**
   `runtimeTypeChecker` 안에서 `typeof(value) == "Instance"` (또는 `"EnumItem"`) 를 먼저 확인하는데,
   mock 테이블의 `typeof` 는 항상 `"table"` 이라 이 분기엔 절대 도달할 수 없습니다. 그래서
   `test/schema/roblox/instance.luau`, `enumItem.luau` 는 이 부분을 의도적으로 테스트하지 않고
   주석으로 이유를 남겼습니다. "커버리지 채우려고" mock 을 억지로 만들지 마세요 — 안 됩니다.

## 남은 일 (우선순위 순)

- [ ] **`src/util.luau` 직접 단위 테스트 없음.** `isVaildIdent`, `escapeLuauString`, `indent` 는
      다른 스키마 테스트를 통해 간접적으로만 exercise 됩니다. `test/util.luau` 를 만들어 엣지 케이스
      (예약어 식별자, 이스케이프 문자 조합, 여러 줄 indent)를 직접 확인하면 좋습니다.
- [ ] **`src/registry.luau` 직접 단위 테스트 없음.** `TypeNamespace:clone()`, 커스텀 네임스페이스에
      `registerType` 했을 때 기본 네임스페이스가 오염되지 않는지, 등록 안 된 tag 조회 시
      에러 메시지가 맞는지 등은 테스트되지 않았습니다.
- [ ] **컨테이너 타입의 더 깊은 중첩 케이스.** 현재 테스트는 각 타입을 1~2단계 정도만 조합합니다.
      `Union<Union<...>>`, `Array<Array<...>>`, `Object` 안에 `Merge`, `Map` 의 value 로 `Object`
      등 더 깊은 중첩에서 에러 메시지 들여쓰기(`Util.indent`)가 누적되는지 확인하는 테스트가 없습니다.
- [ ] **Roblox 목 테스트는 실제 Roblox 환경에서 한 번도 검증되지 않았습니다.** 이 저장소는 `luau`/
      `lune` 로만 실행 가능해서 `mockVector2` 같은 목 테이블이 실제 Roblox 데이터타입의 동작과
      진짜로 일치하는지는 육안 검토로만 확인했습니다. Rojo + Studio 테스트 러너(또는 test-cli 같은
      실제 Roblox 실행 환경)가 생기면 `RobloxApi.md` 기준으로 한 번 교차검증하는 게 좋습니다.
- [ ] **`packages/tbox_squish`, `packages/tbox_remote` 에는 테스트가 아예 없습니다.** 이번 작업
      범위 밖입니다 (`tbox_squish` 는 `compile()` 이 막 구현됨, `tbox_remote` 는 스캐폴드만 존재 —
      루트 `CLAUDE.md` "인수인계 메모" 참고). `tbox_squish` 부터 이 `test/` 구조를 참고해서 시작하면
      될 것 같습니다. 단, 루트 CLAUDE.md 의 "로컬 크로스 패키지 테스트가 막혀 있습니다" 이슈부터
      확인하세요 (워크스페이스 심볼릭 링크를 `luau` 가 못 따라가고 `lune` 은 `const` 를 못 읽음).
- [ ] (선택) CI 연동. 지금은 사람이 `pesde run test` 를 수동으로 돌려야 합니다. GitHub Actions 등에
      아직 연결 안 되어 있습니다 — 필요하면 `luau`/`pesde` 설치 스텝부터 고민해야 합니다.

## 참고

- `test/run.luau` 에 새 스키마 타입을 추가할 땐 `require` 대상을 항상 문자열 **리터럴**로 쓰세요.
  동적 경로(테이블에 경로를 담고 루프 도는 방식)도 시도해봤는데 "ambiguous" 오류가 나서 리터럴
  나열 방식으로 되돌렸습니다.
- 새 Roblox 타입을 추가하면: 타입 빌드(`luauBuild`/`format`) + 음성 경로(`runtimeTypeCheck(schema, 123)`)
  는 `Type` 네임스페이스로, 제약 검사는 `require("../../../src/schema/roblox/<name>")` 로 모듈을
  직접 가져와 `Def.runtimeConstraintChecker(schema, mock)` 로 확인하세요 (`test/schema/roblox/*.luau`
  아무 파일이나 참고).
