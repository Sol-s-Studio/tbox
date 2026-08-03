# tbox (workspace)

TBox 는 Roblox 엔진 언어인 Luau 용 스키마 라이브러리입니다. TypeScript 생태계의
[TypeBox](https://github.com/sinclairzx81/typebox) 처럼, 스키마 객체 하나로 정적 타입 / 런타임 타입 검사 /
런타임 제약 검사 / 문자열화를 모두 얻습니다. 시리얼라이저는 아닙니다 — 값을 바꾸거나 채우지 않으며
입력과 출력 타입이 항상 같습니다.

이 저장소는 [pesde](https://pesde.dev) 워크스페이스로 구성된 모노레포입니다. 핵심 스키마 기능은 최대한
가볍게 유지하고, 직렬화/압축/네트워킹 같은 기능은 별도 패키지로 분리해 필요한 것만 골라 쓸 수 있게 합니다.

## 패키지

| 패키지 | pesde 이름 | 상태 | 설명 |
| --- | --- | --- | --- |
| [`packages/tbox`](packages/tbox) | `qwreey/tbox` | 구현 완료 | 핵심 스키마 라이브러리 |
| [`packages/tbox_squish`](packages/tbox_squish) | `qwreey/tbox_squish` | 스캐폴드 | tbox 스키마 값을 buffer 로 압축 직렬화 (Squash 바인딩) |
| [`packages/tbox_remote`](packages/tbox_remote) | `qwreey/tbox_remote` | 스캐폴드 | tbox 스키마로 RemoteEvent/RemoteFunction 페이로드 검증 |

각 패키지의 자세한 사용법과 설계는 해당 디렉터리의 `README.md` 를 보세요.

## 설치

```bash
pesde install
```

저장소 루트에서 실행하면 워크스페이스 내 모든 패키지의 의존성이 한 번에 해석/링크됩니다.

## 개발

```bash
luau packages/tbox/test.luau   # 스모크 테스트 겸 사용 예제
stylua packages                # 포매팅
```

기여 시 지켜야 할 규칙은 [`CLAUDE.md`](CLAUDE.md) 와 각 패키지의 `CLAUDE.md` 를 참고하세요.
