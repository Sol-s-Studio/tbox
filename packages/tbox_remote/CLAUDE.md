# CLAUDE.md (packages/tbox_remote)

`packages/tbox_remote` (pesde 이름 `qwreey/tbox_remote`) 에서 작업하는 에이전트를 위한 안내입니다.
워크스페이스 공통 규칙은 저장소 루트 `CLAUDE.md`를, tbox 스키마 자체의 아키텍처는
`packages/tbox/CLAUDE.md`를 보세요.

## 목적과 상태

`tbox` 스키마로 Roblox `RemoteEvent`/`RemoteFunction` 페이로드를 검증하는 라이브러리입니다.
**현재는 스캐폴드 단계이며 구현되어 있지 않습니다** (`src/init.luau`, `src/collect.luau` 모두 빈 모듈).
`pesde.toml` 은 `qwreey/tbox` 를 `[dependencies]` 워크스페이스 의존성으로 참조하도록 이미 설정돼
있습니다 (검증 대상 스키마를 다뤄야 하므로 tbox_squish 의 squash 와 달리 이건 필수 런타임
의존성입니다 — 주입 패턴을 쓸 이유가 없습니다).

## 알려진 이슈: 로컬 크로스 패키지 테스트가 막혀 있습니다

`tbox_squish` 와 동일한 문제를 공유합니다 — `require("./roblox_packages/tbox")` 로 실제 tbox 를
불러오는 코드를 지금 이 환경에서 `luau` 로도 `lune` 으로도 실행/테스트할 수 없습니다. 원인과 상세는
`packages/tbox_squish/CLAUDE.md` 의 "알려진 이슈" 절을 보세요. 실제 구현에 착수하기 전에 먼저 그
문제를 해결하세요.

## 코드 스타일

워크스페이스 공통 규칙(`const`, 한국어 주석, 에러 메시지 등)을 그대로 따릅니다. 자세한 건 루트
`CLAUDE.md` 참고.
