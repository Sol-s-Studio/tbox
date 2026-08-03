# CLAUDE.md (packages/tbox_squish)

`packages/tbox_squish` (pesde 이름 `qwreey/tbox_squish`) 에서 작업하는 에이전트를 위한 안내입니다.
워크스페이스 공통 규칙은 저장소 루트 `CLAUDE.md`를, tbox 스키마 자체의 아키텍처는
`packages/tbox/CLAUDE.md`를 보세요.

## 목적과 상태

`tbox` 스키마로 기술된 값을 `buffer` 로 압축 직렬화/역직렬화하는 라이브러리입니다. 특정 직렬화
라이브러리에 종속되지 않고, 호출측이 원하는 buffer-cursor 라이브러리(예: Squash 계열)의 push/pop
함수를 주입해서 쓰는 방식입니다.

`compile(schema, codecs)` (`src/init.luau`) 가 스키마를 재귀적으로 순회하며 그 스키마 전용
`Codec<Cursor, Value>` 를 만들어줍니다. 현재 지원하는 태그: `Number`(format 힌트에 따라 고정폭
codec 로 대체 가능), `String`, `Boolean`, `Singleton`(버퍼에 아무것도 안 씀 - 값이 스키마에 이미
고정되어 있으므로), `Optional`, `Array`(가변 길이 + `fixedLength`), `Object`/`Merge`(필수/Optional
필드 혼합), `Union`(tbox 와 동일하게 첫 일치 분기 우선), `Map`. `Any`/`Nil`/`Unsafe`/`Vector`/Roblox
데이터타입은 아직 지원하지 않고 compile 시점에 error 를 냅니다 (TODO).

### 코덱 조합 규약: 컨테이너는 합성 빌더에 위임, Union 만 예외

처음에는 Object/Array/Map/Optional 도 원시 push/pop 을 직접 나열해서 구현했는데, 그러려면
"같은 cursor 에 여러 값을 push 한 뒤 pop 은 반드시 역순으로 해야 한다"는 스택(LIFO) 규약을
tbox_squish 스스로 알고 모든 컨테이너 조합 로직에서 필드/요소를 손으로 역순 재배치해야 했습니다.
이건 사용자가 지적한 대로 불필요한 복잡함이었습니다 - `Squish.record`/`Squish.array`/`Squish.map`/
`Squish.opt` 처럼, 애초에 "여러 값을 묶어 **한 번의** ser/des 호출로 왕복시키는" 합성 SerDes 를
라이브러리가 이미 제공하기 때문입니다. 그래서 지금은 `Codecs<Cursor>` 에 `record`/`array`/`map`/
`optional` 합성 빌더 자체를 주입받고, `compile()` 은 그걸 그대로 호출만 합니다 - 내부 배치가 어떻게
되든 tbox_squish 는 전혀 알 필요가 없습니다 (`Squish.record({ x = ..., pos = Squish.record({...}) })`
처럼 중첩해서 스키마 트리 전체를 한 번의 ser/des 로 묶을 수 있다는 것도 직접 확인했습니다).

**Union 만 예외입니다.** Union 의 분기는 값 자체를 보고(`runtimeTypeCheck`) 나서야 어떤 분기인지
정해지는 동적 구조라, record 처럼 고정된 필드 집합으로 미리 묶어둘 수 없습니다 (실제로
`Squish.variant()` 를 직접 테스트해보니, 서로 다른 두 branch 가 둘 다 `typeof == "table"` 이면
`"field N (table) is repeated"` 로 아예 거부합니다 - `Union<Object, Object>` 처럼 tbox 에서는 흔한
패턴인데도 squish 기본 `variant` 로는 표현이 안 됩니다). 그래서 Union 만 이 파일이 직접 raw push 를
두 번(payload, 분기 번호 순으로) 호출하고, pop 은 분기 번호 → payload 순으로 읽습니다. 이때 필요한
스택(LIFO) 규약은 `anexpia/squish` 로 직접 실험해서 확인한 내용입니다 - 같은 cursor 에 여러 값을
`ser`(push) 하면 `des`(pop) 는 그 **역순**으로 호출해야 원래 값이 나옵니다 (squish 의 Cursor 가
ser 할 때는 위치를 버퍼 앞에서부터 늘리고 des 할 때는 버퍼 끝에서부터 줄이는 구조라 그렇습니다).
자세한 설명은 `src/init.luau` 의 `Codec`/`Codecs` 타입 주석에 있습니다.

**이건 우연한 제약이 아니라 `Squish.variant` 의 근본적인 한계입니다** - squish 소스(`anyFrom`/
`subtypeof`)를 직접 읽어 확인했습니다. 분기 판별은 오직 `typeof(x)` 문자열 하나로만 이루어지고
(`local tid = toindex[t]`), `subtypeof` 가 제공하는 유일한 예외는 `EnumItem` 하드코딩
(`` `EnumItem:{tostring(v.EnumType)}` ``) 뿐입니다 - `Instance:{ClassName}` 조차 주석 처리되어
비활성 상태고, 임의의 테이블 내용(필드 구성 등)을 보고 서브타입을 정하는 확장 지점은 아예 없습니다.
즉 `Squish.variant` 는 `typeof` 값 자체가 서로 다른 분기(`number | string | boolean` 같은)를
구분하는 용도로 설계된 것이지, tbox 의 `Union` 이 흔히 표현하는 "여러 `Object`/`Array`/`Map` 분기"
처럼 `typeof` 가 같은 구조적 유니온을 구분하는 용도가 아닙니다. 설령 `typeof` 가 전부 다른 특수
케이스에 한해 `codecs.variant` 를 추가로 주입받아 쓰더라도, 그러려면 우리 `Codec<Cursor, Value>`
자체에 squish 의 `.type` 문자열 개념을 얹어야 해서 Cursor/Codec 을 불투명하게 두겠다는 설계
원칙과 충돌합니다 - 그래서 도입하지 않았습니다. (재현은 `Squish.variant({ Squish.record{...},
Squish.array(...) })` 처럼 `typeof == "table"` 인 SerDes 두 개를 넣어보면 언제든 다시 확인할 수
있습니다. `subtypeof`/`anyFrom` 은 squish 소스 파일 200번째 줄, 5237번째 줄 부근입니다.)

대신 다른 방법(분기마다 `optional` 슬롯을 두고 값이 든 슬롯만 채우는 방식)도 검토했습니다 - 이러면
Union 도 LIFO 지식 없이 합성 빌더만으로 표현되지만, 분기 수만큼 presence-flag 바이트가 낭비되고
분기가 많아질수록 비효율적입니다. 사용자가 태그+payload 방식(공간 효율 우선)을 선택했습니다.

## 설계: 특정 직렬화 라이브러리를 런타임 의존성으로 두지 않습니다

`pesde.toml` 의 `[dependencies]` 에는 squash 류 라이브러리를 두지 않습니다. `Cursor` 는
`src/init.luau` 안에서 **완전히 불투명한 제네릭 타입 파라미터** (`Codec<Cursor, Value>`,
`Codecs<Cursor>`) 로만 존재합니다 — tbox_squish 는 Cursor 내부를 절대 들여다보지 않고 주입받은
push/pop·합성 빌더 사이로 그대로 전달만 하므로, 특정 라이브러리의 구체적인 shape 를 알 필요가
애초에 없습니다. (`[dev_dependencies]` 에는 아래 이유로 `anexpia/squish` 를 참조용으로 두고
있습니다.)

이렇게 정한 이유(실제로 후보들을 조사한 결과입니다 — 이 판단을 뒤집기 전에 다시 조사하세요):

- **업스트림 Data-Oriented-House/Squash 는 pesde 레지스트리에 아예 없습니다** (Wally/복붙 배포만
  존재). pesde 에는 제3자 미러/포크가 두 개 있습니다:
  - `jiwonz/squash` — 업스트림 `v3.0.0` 커밋(2025-06-21)에서 멈춘 **정지된 포크**입니다. 업스트림은
    그 뒤로 `v3.1.0` → `v4.0.0` → `v4.1.0` → `v5.0.0` (2026-01-04) 까지 진행됐고, **v4.0.0 에서
    `Cursor` 구조 자체가 바뀌었습니다** (`{ Buf: buffer, Pos: number }` → `{ buffer }` 단일 원소
    배열 + 위치를 buffer 첫 4바이트에 packing, 원시 타입 생성자 이름도 `uint(n)/int(n)/number(n)` →
    `u8()/i16()/f32()/f64()` 류로 변경). 즉 이 포크는 **현재 실제 업스트림과도 호환되지 않는** 낡은
    shape 를 갖고 있습니다.
  - `anexpia/squish` — Data-Oriented-House/Squash 의 포크이지만, `jiwonz/squash` 와 반대로
    **활발히 유지보수되고 있습니다** (최근 커밋 2026-07-26, pesde 등록도 2026-07-22로 최근). MIT
    라이선스, pesde 에 네이티브로 직접 배포(+ Wally 병행 배포). SerDes 종류 확장(variant, number,
    instances 등), 유틸리티 함수 추가, 성능 개선을 표방합니다. 다만 GitHub 스타/포크/워처가 전부
    0이고 단독 유지보수자 1인 프로젝트라 외부 검증/채택 실적은 없습니다. Cursor 구조는
    `{ [number]: buffer, pos: number, size: number, refs: {any}?, ... }` 로 위 두 shape 와도
    또 다른 **세 번째 shape** 입니다.
  - (참고: `anexpia/squish` 를 처음 조사할 때 웹 검색만으로는 존재를 확인하지 못하고 무관한
    `anexpia/BufferEncoder` 를 잘못 짚었습니다. **pesde 패키지 존재 여부는 웹 검색이 아니라
    `pesde add <name>` 로 직접 확인하세요** — 신생/소규모 패키지는 검색엔진에 잘 안 걸립니다.)
- `peer_dependencies` 도 검토했지만 채택하지 않았습니다 — pesde 를 전면적으로 쓰지 않는 실제
  Roblox 소비 환경(Wally, 수동 Rojo 동기화 등)에서는 require 경로가 pesde 링크 규칙에 의존하는
  peer dependency 해석이 보장되지 않습니다.
- 결론: pesde 에서 구할 수 있는 두 후보의 Cursor shape 가 서로 다르고, 업스트림 자체도 이미 한 번
  shape 를 바꾼 전례가 있으므로, **런타임에는 어떤 특정 라이브러리에도 타입 수준에서 종속되지 않는
  것**이 가장 안전한 선택입니다. `tbox` 본체가 Roblox 전역을 직접 참조하지 않고 `typeof(value)`
  문자열 비교만 쓰는 것과 같은 철학입니다 (`packages/tbox/CLAUDE.md`).
- `anexpia/squish` 를 `[dev_dependencies]` 로 남겨둔 이유는 실제 구현체를 만들 때 참조할 구체적인
  예시가 필요하기 때문입니다 (jiwonz/squash 보다 최신이고 활발히 유지보수되므로 참조 대상으로
  더 적합합니다). 소비 패키지에는 전이 설치되지 않습니다.

## 알려진 이슈: 로컬 크로스 패키지 테스트가 막혀 있습니다

`tbox` 를 워크스페이스 의존성으로 require 하는 코드(`src/init.luau` 의 `require("./roblox_packages/tbox")`)를
현재 이 환경에서 표준 방식으로 실행/테스트할 수 없습니다.

- pesde 는 워크스페이스 내부 의존성을 **심볼릭 링크**로 연결합니다
  (`roblox_packages/.pesde/<pkg>/<ver>/tbox/src` → 실제 `packages/tbox/src`).
- **`luau` CLI 는 심볼릭 링크를 전혀 따라가지 못합니다** — 심볼릭 링크된 디렉터리를 `require` 하면
  `could not resolve child component` 로 항상 실패합니다 (경로 어디에 심볼릭 링크가 끼어 있든 동일).
- **`lune`** 은 심볼릭 링크는 따라가지만, 현재 설치된 버전(0.8.9)이 이 저장소 전역에서 쓰는
  `const` 지역 선언 문법(정식 Luau RFC 기능)을 파싱하지 못해 `tbox` 자체를 읽지 못합니다.

즉 지금은 어느 실행기로도 "다른 워크스페이스 패키지를 실제 require 하는" 테스트를 돌릴 수 없습니다.
(Rojo/실제 Roblox 환경에서 이 문제가 재현되는지는 별개로 확인이 필요합니다 — Rojo 는 Luau require
리졸버를 쓰지 않으므로 무관할 가능성이 높습니다.)

**이 문제는 여전히 근본적으로 해결되지 않았습니다.** 다만 `compile()` 실제 구현을 검증할 때 다음과
같은 **임시 우회**로 직접 돌려봤습니다: `src/init.luau` 를 스크래치 디렉터리에 복사해 `require("./
roblox_packages/tbox")` 한 줄만 `require("../tbox/src")` (워크스페이스 심볼릭 링크를 거치지 않는
sibling 패키지 실경로) 로 바꾸고, 같은 방식으로 `anexpia/squish` (dev_dependency 라 애초에
`roblox_packages/.pesde/anexpia+squish/...` 밑에 심볼릭 링크 없이 실제 소스로 설치되어 있음) 를
직접 require 해서 전체 스키마 태그(Number/String/Boolean/Singleton/Optional/Array/fixedLength
Array/Object/Merge/Union(table 타입 branch 2개 포함)/Map, 중첩 Array<Object>)에 대해 실제 값을
buffer 로 왕복시켜 확인했고 전부 통과했습니다. 이 과정에서 컨테이너를 합성 빌더에 위임하는
리팩터(위 "코덱 조합 규약" 절)도 같이 검증했고, 서로 다른 두 top-level 값을 같은 cursor 에 연속
push 하면 그 사이에서는 squish 자체의 스택 규약이 여전히 그대로 보인다는 것(tbox_squish 의 책임
범위 밖이라는 것)도 재현해 확인했습니다.

이 우회는 **검증용 스크립트에서만** 썼고 커밋하지 않았습니다 — `src/init.luau` 자체의
`require("./roblox_packages/tbox")` 는 pesde 워크스페이스 규약대로 그대로 둡니다. 정식 `test/`
스위트를 tbox 의 다른 패키지들처럼 갖추려면 이 우회를 상시화할지(예: 테스트 전용 require 별칭)
아니면 다른 방법(lune 버전을 올려 const 지원 여부 확인 등)을 쓸지 다시 논의가 필요합니다. `const` 를
`local` 로 바꿔서 회피하지 마세요 (코드 스타일 위반).

## 코드 스타일

워크스페이스 공통 규칙(`const`, 한국어 주석, 에러 메시지 등)을 그대로 따릅니다. 자세한 건 루트
`CLAUDE.md` 참고.
