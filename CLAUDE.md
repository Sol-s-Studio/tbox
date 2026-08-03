# CLAUDE.md

TBox 저장소(모노레포)에서 작업하는 에이전트를 위한 안내입니다.
패키지별 세부 아키텍처는 각 패키지 디렉터리의 `CLAUDE.md` 를 보세요 — 예:
`packages/tbox/CLAUDE.md`. 이 문서는 워크스페이스 전체에 적용되는 내용만 다룹니다.

## 프로젝트 개요

TBox 는 Roblox 엔진 언어인 **Luau** 용 스키마 라이브러리입니다. 핵심 원칙은 라이브러리를 가볍게
유지하는 것입니다 — 스키마 정의, 런타임 타입/제약 검사, 타입 문자열화(`luauBuild`/`format`)만 제공하고,
직렬화나 압축, 네트워킹 같은 나머지는 별도 패키지로 분리합니다. Luau 의 `require` 는 모듈 전체를
불러오는 구조라 "타입만 가져오고 런타임 구현은 선택적으로 연동" 하는 것이 어렵기 때문에, 하나의 거대한
패키지 대신 **pesde 워크스페이스(모노레포)** 로 여러 개의 작은 패키지를 두는 구조를 택했습니다.

## 워크스페이스 구조

```
pesde.toml              워크스페이스 루트 매니페스트 (private = true, workspace_members = ["packages/*"])
packages/
  tbox/                 qwreey/tbox         — 핵심 스키마 라이브러리 (구현 완료)
  tbox_squish/          qwreey/tbox_squish  — buffer 압축 직렬화 (Squash 바인딩, compile() 구현 진행 중)
  tbox_remote/          qwreey/tbox_remote  — RemoteEvent/RemoteFunction 페이로드 검증 (스캐폴드만 존재)
```

각 패키지는 독립된 `pesde.toml`, `src/`, `test/`, `default.project.json` 을 가지는
**하나의 pesde 패키지**입니다. `tbox_squish`, `tbox_remote` 는 `tbox` 를 워크스페이스 의존성으로 참조합니다.

```toml
# packages/tbox_squish/pesde.toml 발췌
[dependencies]
tbox = { workspace = "qwreey/tbox", version = "^" }
```

새 패키지를 추가할 땐 `packages/<name>/` 아래에 `pesde.toml` (`name = "qwreey/<name>"`,
`[target] environment = "roblox", lib = "src/init.luau", build_files = ["src"]`) 을 만들고
루트에서 `pesde install` 을 실행해 워크스페이스에 편입시키세요. 패키지 이름의 `<name>` 부분은
pesde 규칙상 **소문자, 숫자, `_` 만 허용**됩니다 (하이픈 불가) — 디렉터리명도 이에 맞춥니다.

## pesde 사용법

```bash
pesde install     # 저장소 루트에서. 워크스페이스 전체(모든 packages/*)의 의존성을 한 번에 해석/링크
```

- `pesde.lock` (루트 + 각 패키지)은 커밋합니다. 재현 가능한 설치를 위한 잠금 파일입니다.
- `roblox_packages/`, `luau_packages/`, `lune_packages/` 는 `pesde install` 이 생성하는 설치 결과물이며
  `.gitignore` 에 등록되어 있습니다. 커밋하지 마세요.
- **scope 는 `qwreey`** 로 통일합니다 (개인 계정 기준, 아직 실제 registry 에 publish 하지 않았습니다).
  회사(Sol-s-Studio) 스코프가 필요해지면 별도 스코프로 동시 배포하는 방식을 고려 중이며, 지금 임의로
  스코프를 바꾸거나 추가하지 마세요.
- **알려진 pesde 이슈**: `pesde install` 시 각 패키지에서 "failed to parse file to extract types" 라는
  긴 ERROR 로그가 출력됩니다. 이는 pesde 의 부가적인 타입 스텁 추출기가 이 저장소 전역에서 쓰는
  `const` 지역 선언 문법(코드 스타일 참고)을 아직 파싱하지 못해서입니다. **설치 자체는 정상 동작**하며
  (`roblox_packages/<pkg>.luau` 는 실제 소스로의 require 를 그대로 링크합니다), 이 에러는 무시해도
  됩니다. `const` 를 `local` 로 바꿔서 이 경고를 없애려 하지 마세요 — 코드 스타일 위반입니다.
- **알려진 이슈: 로컬 크로스 패키지 테스트가 막혀 있습니다.** `tbox_squish`, `tbox_remote` 처럼 다른
  워크스페이스 패키지를 실제 require 하는 코드는 지금 이 환경에서 `luau` 로도 `lune` 으로도
  실행/테스트할 수 없습니다 (pesde 가 워크스페이스 의존성을 심볼릭 링크로 연결하는데, `luau` CLI 는
  심볼릭 링크를 못 따라가고, `lune` 0.8.9 는 `const` 문법을 못 읽습니다). 의도적으로 보류된 상태이니
  이 상태를 "고치려고" 코드 스타일을 바꾸지 마세요. 자세한 내용과 재현 방법은
  `packages/tbox_squish/CLAUDE.md` 의 "알려진 이슈" 절을 보세요.

## 코드 스타일 (모든 패키지 공통)

- **`const` 지역 선언**을 기본으로 씁니다. 재할당이 필요할 때만 `local` 을 씁니다.
- **명시적 타입 인자 호출** `f<<T>>(...)` 문법을 씁니다. new solver 의 추론 부작용을 피하기 위한
  의도적인 선택입니다.
- 팩토리 / 생성자 함수는 파스칼 케이스, 그 외 함수는 카멜 케이스입니다.
- **주석은 한국어로 작성합니다.** 기존 파일의 밀도와 톤을 따르세요 (왜 그렇게 했는지를 적는 편).
- 에러 메시지 문자열은 영어, 소문자로 시작합니다. 예: `` `number too big. maximum allowed value is {schema.max}` ``
- `stylua.toml` 은 루트에 하나만 두고 전체 패키지에 재귀 적용합니다: `stylua packages`.
- `.vscode/settings.json` (luau-lsp new solver 설정) 도 루트에서 워크스페이스 전체에 적용됩니다.
- **위험: 이 환경의 stylua(2.5.2, `syntax = "Luau"`)는 `f<<T>>(...)` 명시적 타입 인자 호출 문법을
  모릅니다.** `<<`/`>>` 를 시프트 연산자로 오해해서, 뒤따르는 나머지 토큰이 우연히도 시프트 식으로
  파싱 가능하면 **에러 없이 조용히** `f<<T>>(...)` 를 `f << T >> (...)` 로 잘못 재작성해버립니다
  (예: `Type.Unsafe<<number>>({...})` → `Type.Unsafe << number >> {...}`, 의미가 완전히 깨짐).
  파싱이 안 되는 경우에만(예: 인자가 여러 개인 함수 호출) 정상적으로 파싱 에러를 냅니다. 즉 **exit
  code 0 도 안전을 보장하지 않습니다.** `f<<T>>` 를 쓰는 파일(현재 `src/` 전역, `test/schema/unsafe.luau`
  등)에 stylua 를 돌린 뒤에는 diff 를 직접 확인해서 `<<`/`>>` 가 시프트 연산자로 바뀌지 않았는지
  확인하세요. 이 문제 자체를 "고치려고" 코드 스타일(`f<<T>>` 문법)을 바꾸지 마세요.

패키지별 타입 네이밍 규칙(`T` 접두사 등)이나 아키텍처는 해당 패키지의 `CLAUDE.md` 를 보세요.

### require 경로 규칙 — `init.luau` 는 "자기가 들어있는 폴더" 입니다

Luau 의 require-by-string 은 `init.luau` 를 **그 파일이 들어있는 디렉터리 그 자체**로 취급합니다.
그래서 `init.luau` 안에서의 상대 경로는 다른 파일과 기준이 다릅니다. `packages/<pkg>/src/init.luau`
기준으로:

| 표기 | 가리키는 곳 |
| --- | --- |
| `@self/types` | `packages/<pkg>/src/types.luau` (init.luau 의 **형제**, 즉 자기 아래 요소) |
| `./roblox_packages/tbox` | `packages/<pkg>/roblox_packages/tbox.luau` (init.luau 가 든 폴더의 **형제**) |
| `../foo` | `packages/foo` — 패키지 바깥. **거의 항상 버그입니다.** |

- **워크스페이스/pesde 의존성은 항상 `require("./roblox_packages/<name>")` 로 씁니다.**
  `require("../roblox_packages/<name>")` 는 `packages/roblox_packages/...` 를 찾게 되어 실패합니다
  (실제로 `packages/tbox_squish/src/init.luau` 가 이 실수로 깨져 있었습니다).
- **자기 패키지 내부 모듈은 `@self/...`** 로 씁니다 (`packages/tbox/src/init.luau` 가 올바른 예시).
- `init.luau` **가 아닌** 파일(`src/schema/*.luau`, `test/*.luau` 등)은 평범한 "파일이 있는 디렉터리
  기준" 상대 경로입니다. 즉 `src/schema/number.luau` 의 `require("../base")` 는 맞는 코드이니
  일괄 치환하지 마세요. 이 규칙은 **오직 `init.luau` 에만** 특별하게 적용됩니다.
- 워크스페이스 간 require 는 심볼릭 링크 문제로 로컬에서 실행 검증이 불가능합니다
  (`packages/tbox_squish/CLAUDE.md` 의 "알려진 이슈" 절). 즉 경로가 틀려도 실행 중에 안 걸리므로
  **눈으로 검토해야 합니다.** 규칙 자체를 확인하고 싶으면 스크래치 디렉터리에 `pkg/src/init.luau` +
  `pkg/roblox_packages/x.luau` 를 만들어 `luau` 로 직접 돌려보면 즉시 재현됩니다.

## 실행 / 검증

정식 테스트 프레임워크는 없습니다. 각 패키지의 `test/` 디렉터리(`test/run.luau` 진입점 +
`test/schema/*.luau` 가 `src/schema/*` 를 1:1로 미러링)가 실행 가능한 문서 겸 스모크 테스트입니다.
실패하면 어서션이 그냥 `error()` 로 중단시킵니다 (`packages/tbox/test/helper.luau` 의
`expectOk`/`expectFail`/`expectEqual` 참고) — 별도 테스트 프레임워크를 억지로 두지 않았습니다.

```bash
pesde run test                              # 저장소 루트 또는 각 패키지 디렉터리에서
luau packages/tbox/test/run.luau            # 또는 cd packages/tbox && luau test/run.luau
```

- `pesde run` 은 스크립트를 항상 Lune 으로 실행하는데, Lune 0.8.9 는 이 저장소 전역의 `const`
  문법을 파싱하지 못합니다. 그래서 각 패키지의 `pesde.toml` 은 `[scripts] test = "scripts/test.luau"`
  로 **Lune 호환(= `const` 미사용) 브릿지 스크립트**를 가리키고, 그 브릿지가
  `process.exec("luau", { "test/run.luau" }, ...)` 로 실제 테스트를 서브프로세스에 위임합니다.
  `scripts/test.luau` 자체를 고칠 때는 이 파일만은 `const` 를 쓰지 않아야 한다는 것을 기억하세요.
- **테스트 엔트리 파일을 `init.luau` 로 이름 짓지 마세요.** 이 저장소의 `luau` 빌드는 `init.luau` 를
  디렉터리 인덱스 모듈로 특별 취급하는데, 엔트리 파일도 `init.luau` 라면 그 파일이 재귀적으로 require
  하는 `src/init.luau` 와 이름이 겹쳐 `could not reset to requiring context (ambiguous)` 같은 오류를
  일으킵니다. `test/run.luau` 처럼 다른 이름을 쓰세요.
- 패키지를 추가/수정하면 `test/schema/` 아래에 대응 파일을 추가/갱신하고 `test/run.luau` 의
  require 목록에도 반영하세요. require 대상은 항상 문자열 리터럴로 적습니다 (동적 경로도 같은
  "ambiguous" 오류를 유발할 수 있습니다).

### 중요: 실행 환경은 Roblox 가 아닙니다

`luau` CLI 에는 `Vector3`, `CFrame`, `Color3` 등 Roblox 전역이 **존재하지 않습니다.** Roblox 데이터타입을
다루는 모듈은 로드 시점에 Roblox 전역을 절대 참조하면 안 되고, 런타임 판별은 오직
`typeof(value) == "Vector3"` 같은 문자열 비교로만 해야 합니다. 자세한 내용은
`packages/tbox/RobloxApi.md`, `packages/tbox/CLAUDE.md` 를 보세요.

## 저장소 상태에 대한 참고

- git remote 는 현재 `Sol-s-Studio/tbox` (조직 레포) 입니다. 추후 개인 계정으로 옮겨 개발하고,
  조직 레포는 안정화된 변경만 반영하는 방식으로 분리할 계획입니다 — `pesde.toml` 의 `repository` 필드나
  git remote 를 임의로 바꾸지 마세요.
- 라이선스는 MIT 입니다. 루트와 각 패키지 디렉터리에 `LICENSE` 파일이 있고, 각 패키지 `pesde.toml` 에
  `license = "MIT"` 가 설정되어 있습니다.

### 인수인계 메모 (단일 플랫 패키지 → pesde 모노레포 전환)

원래 플랫 구조(저장소 루트에 `src/`, `test.luau` 등)였던 이 저장소를 지금의 `packages/tbox`,
`packages/tbox_squish`, `packages/tbox_remote` 워크스페이스 구조로 옮기고, `tbox_squish` 의
`compile()` 을 실제로 구현하는 작업을 막 마친 상태입니다.

- **현재 모든 변경은 `git add` 로 스테이징만 되어 있고 커밋되지 않았습니다** (사용자가 명시적으로
  요청하기 전까지 커밋하지 않는다는 표준 방침 때문입니다). `git status` 로 확인하면 대부분 `A`/`R`
  (모노레포 이동으로 인한 rename 포함)이고, `packages/tbox/src/schema/json/array.luau` 는 사용자가
  이 세션 시작 전부터 갖고 있던 별개의 우선 작업(`numericIndexOnly` 옵션 제거)이 이동 과정에 실려
  함께 스테이징돼 있습니다 — 이건 건드리지 마세요.
- `packages/tbox_squish/src/init.luau` 의 `compile()` 은 `Number`/`String`/`Boolean`/`Singleton`/
  `Optional`/`Array`/`Object`/`Merge`/`Union`/`Map` 을 지원하는 실제 구현입니다. `Any`/`Nil`/`Unsafe`/
  `Vector`/Roblox 데이터타입은 아직 미지원(TODO, compile 시점 error). 설계 근거와 최근 리팩터
  (컨테이너는 주입된 `record`/`array`/`map`/`optional` 합성 빌더에 위임, `Union` 만 태그+payload 직접
  처리, `Squish.variant` 를 쓸 수 없는 이유)는 `packages/tbox_squish/CLAUDE.md` 를 보세요.
- `packages/tbox_remote` 는 여전히 스캐폴드만 있고 구현은 없습니다 (다음 후보 작업).
- 로컬에서 워크스페이스 간 실제 `require` 를 실행하는 표준 방법이 없다는 문제(위 "알려진 이슈"
  참고)는 아직 해결되지 않았습니다. `tbox_squish` 의 `compile()` 은 이 문제를 우회하는 임시
  스크립트(커밋 안 함, `packages/tbox_squish/CLAUDE.md` "알려진 이슈" 절에 재현 방법 있음)로만
  검증했습니다.

## 하지 말 것

- `Default`, `Never`, `Intersect` 타입을 추가하지 마세요 (의도적으로 제외됨, 이유는
  `packages/tbox/README.md` 참고). 객체 합성이 필요하면 `TMerge` 를 씁니다.
- `.trash/` 는 gitignore 된 폐기 코드 보관소입니다. 참고만 하고 수정하지 마세요.
- 워크스페이스 밖(저장소 루트)에 `src/`, `test/` 등을 다시 만들지 마세요 — 모든 실제 구현은
  `packages/<name>/` 아래에 있어야 합니다.
