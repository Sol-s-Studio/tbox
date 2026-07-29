# CLAUDE.md

TBox 저장소에서 작업하는 에이전트를 위한 안내입니다.

## 프로젝트 개요

TBox 는 Roblox 엔진 언어인 **Luau** 용 스키마 라이브러리로, TypeScript 생태계의
[TypeBox](https://github.com/sinclairzx81/typebox) 와 같은 역할을 합니다. 스키마 객체 하나로 네 가지를 얻습니다.

1. **정적 Luau 타입** — `Type.Static<typeof(schema)>` 로 컴파일 타임 타입을 추출
2. **런타임 타입 검사** — `Type:runtimeTypeCheck(schema, value)`
3. **런타임 제약 검사** — `Type:runtimeConstraintCheck(schema, value)` (min/max/length 등)
4. **문자열화** — `Type:luauBuild(schema)` (Luau 타입 소스), `Type:format(schema)` (사람이 읽는 형태)

TBox 는 **시리얼라이저가 아닙니다.** 값을 변환하거나 기본값을 채우지 않으며, 입력 타입과 출력 타입이
항상 동일합니다. (`README.md` 의 "Why x is not exist?" 참고 — 그래서 `Default`, `Never`, `Intersect` 가 없습니다.)

## 실행 / 검증

```bash
luau test.luau      # 저장소 루트에서. 스모크 테스트 겸 사용 예제. 실행 결과가 주석과 일치해야 함
stylua src test.luau  # 포매팅 (stylua.toml: Luau 문법, 120컬럼, 스페이스 4칸)
```

- 정식 테스트 프레임워크는 없습니다. `test.luau` 가 실행 가능한 문서 역할을 하며,
  각 `print` 아래에 `-- INFO:` 주석으로 기대 출력이 적혀 있습니다. **기능을 추가하면 여기에 예제를 추가하세요.**
- `default.project.json` 은 Rojo 프로젝트로 `src` 를 `ReplicatedStorage.TBox` 에 매핑합니다.
- 정적 분석은 luau-lsp(new solver) 기준입니다 (`.vscode/settings.json`).

### 중요: 실행 환경은 Roblox 가 아닙니다

`luau` CLI 에는 `Vector3`, `CFrame`, `Color3` 등 Roblox 전역이 **존재하지 않습니다.**
따라서 `src/schema/roblox/*` 모듈은 로드 시점에 Roblox 전역을 절대 참조하면 안 되고,
런타임 판별은 오직 `typeof(value) == "Vector3"` 같은 문자열 비교로만 해야 합니다.
자세한 내용과 데이터타입별 API 는 **`RobloxApi.md`** 를 보세요.

## 코드 스타일

- **`const` 지역 선언**을 기본으로 씁니다. 재할당이 필요할 때만 `local` 을 씁니다.
- **명시적 타입 인자 호출** `f<<T>>(...)` 문법을 씁니다. 예: `Base.SchemaFactory<<TNumber>>(...)`.
  new solver 의 추론 부작용을 피하기 위한 의도적인 선택입니다.
- 타입 이름은 `T` 접두사(`TString`, `TArray`)를 씁니다. 데이터 컨테이너가 아니라 "타입에 관한 것"임을
  시그니처에서 구분하기 위함입니다.
- 팩토리 / 생성자 함수는 파스칼 케이스(`String`, `Object`), 그 외 함수는 카멜 케이스입니다.
- **주석은 한국어로 작성합니다.** 기존 파일의 밀도와 톤을 따르세요 (왜 그렇게 했는지를 적는 편).
- 에러 메시지 문자열은 영어, 소문자로 시작합니다. 예: `` `number too big. maximum allowed value is {schema.max}` ``

## 아키텍처

```
src/
  init.luau      기본 네임스페이스 구성 + 공개 타입 재수출 (진입점)
  base.luau      TSchema / TypeDef 정의, SchemaFactory / TypeDefFactory
  registry.luau  TypeNamespace — tag → TypeDef 디스패치
  types.luau     타입 함수(type function) 유틸: Static, Merge, Union, Tuple ...
  util.luau      식별자 검사, 문자열 이스케이프, 들여쓰기
  collect.luau   미사용 (아이디어 메모만 있음)
  schema/        각 타입 정의 1파일 = 1타입
    json/        JSON 표현이 가능한 컨테이너 타입 (object, array, merge)
    roblox/      Roblox 데이터타입 — 현재 전부 빈 파일 (구현 대상)
```

### 스키마 값과 TypeDef

스키마 **인스턴스**는 평범한 테이블입니다: `{ tag, id?, title?, description?, ...타입별 필드 }`.
`tag` 가 디스패치 키입니다.

각 `src/schema/*.luau` 모듈은 `Base.TypeDefFactory(typeName, factoryFunc, hooks)` 의 결과를 반환합니다.
훅은 여섯 가지입니다 (`src/base.luau`):

| 훅 | 필수 | 역할 |
| --- | --- | --- |
| `runtimeTypeChecker(schema, value)` | O | 런타임 타입이 맞는가. 실패 시 **에러 메시지를 만드는 함수**를 반환, 성공 시 `nil` |
| `runtimeConstraintChecker(schema, value)` | X | min/max/length 등 제약. **타입 검사를 이미 통과했다고 가정** |
| `luauBuilder(schema)` | O | 실제 Luau 타입 소스 문자열 (`"number"`, `"{ a: string }"`) |
| `formatter(schema)` | O | 디버깅용 표현 (`"TNumber"`, `"TArray<TString>"`) |
| `canBeNil(schema)` | X | nil 을 허용하는가. `TObject` 가 필수 필드 여부를 판단할 때 사용 |
| `inspectInner(schema)` | X | 내부 스키마 목록. 문서/타입 수집 용도 |

**타입 검사와 제약 검사를 나눈 이유**가 이 설계의 핵심입니다. `TUnion` 은 분기를 고를 때
`runtimeTypeChecker` 만 사용합니다 — 제약 조건까지 섞으면 "길이가 안 맞아서 다른 분기가 선택되는"
Luau 타입과 어긋난 동작이 생기기 때문입니다. 그래서 제약 검사는 타입이 확정된 뒤에만 돕니다.

에러를 문자열이 아니라 **클로저**로 반환하는 것도 의도적입니다. `TUnion` 처럼 실패가 정상 흐름인
곳에서 문자열 포매팅 비용을 내지 않기 위함입니다. 실제로 필요할 때만 호출하세요.

### 네임스페이스 (registry.luau)

`TypeNamespace` 는 `tag → TypeDef` 맵이자 디스패치 지점입니다. 모든 훅은 네임스페이스 메서드로 감싸져 있고
(`ns:runtimeTypeCheck`, `ns:luauBuild`, ...), 컨테이너 타입은 내부 스키마를 처리할 때 이 메서드를 다시 호출합니다.

컨테이너 스키마 모듈들은 `require("../registry").defaultUntypedNamespace` 를 직접 import 해서 재귀합니다.
즉 **재귀 호출은 항상 기본 네임스페이스로 고정**되며, `clone()` 으로 만든 커스텀 네임스페이스는
최상위 호출에만 영향을 줍니다. (알려진 한계입니다. 고칠 거면 훅 시그니처에 네임스페이스를 넘기는 리팩터가 필요합니다.)

`README.md` 규칙: **모든 스키마는 `defaultUntypedNamespace` 에 기본 등록되어야 합니다.**

### 타입 레벨 (types.luau)

정적 타입 추출은 스키마 타입에 붙은 팬텀 필드로 동작합니다.

- `Types.InnerType<T>` = `{ __inner: T }` — `Static<S>` 가 여기서 실제 Luau 타입을 꺼냅니다.
- `Types.NamedType<"Object">` = `{ __name: "Object" }` — 타입 함수가 스키마 종류를 판별할 때 씁니다
  (`TMerge` 가 병합 대상이 Object/Merge 인지 컴파일 타임에 검사).
- `Types.Merge<A, B>` — 옵션 테이블 타입 합성용. Luau 교집합(`&`)이 `?` 와 섞이면 깨지는 문제를 우회합니다.
- `Types.Tuple<T...>` / `Types.TupleType<T...>` — 가변 스키마 인자를 받는 통로.
  `TUnion`, `TMerge` 는 `Components...` 대신 `Tuple` 을 받습니다. new solver 가 pack 을 추론하면
  뒤따르는 인자(`options`)까지 오염되기 때문입니다. 그래서 사용부가 `Type.Union(Type.Tuple(a, b), opts)` 형태입니다.
- `GetTupleType`, `StaticTuple`, `StaticNameTuple`, `UnionInner`, `MergeInner`, `TObjectPropsFlatten`
  은 위 구조를 다루는 보조 타입 함수입니다.

## 새 스키마 타입 추가하기

`src/schema/<name>.luau` 를 만들고 아래 골격을 따릅니다 (`src/schema/number.luau` 가 가장 좋은 참고 대상,
컨테이너라면 `src/schema/json/array.luau`).

```luau
--!strict

const Base = require("../base")
const Types = require("../types")
-- 내부 스키마를 재귀 처리한다면:
-- const Util = require("../util")
-- const defaultUntypedNamespace = require("../registry").defaultUntypedNamespace

export type TFoo =
    { someOption: number? }
    & Base.TSchema
    & Types.InnerType<Foo>          -- 이 스키마가 표현하는 실제 Luau 타입
    & Types.NamedType<"Foo">        -- TypeDefFactory 의 typeName 과 반드시 동일
export type TFooOptions = Types.Merge<{ someOption: number? }, Base.TSchemaOptions>

const function Foo(options: TFooOptions?): TFoo
    options = options or ({} :: TFooOptions)
    return Base.SchemaFactory<<TFoo>>("Foo", options, {
        someOption = options.someOption,
    })
end

const function luauBuilder(_schema: TFoo): string
    return "Foo"
end

const function formatter(_schema: TFoo): string
    return "TFoo"
end

const function runtimeTypeChecker(_schema: TFoo, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "Foo" then
        return function()
            return `Foo expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TFoo, value: Foo): (() -> string)?
    -- value 는 이미 타입 검사를 통과했다고 가정한다
    return nil
end

return Base.TypeDefFactory("Foo", Foo, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
```

주의: `SchemaFactory` 의 첫 인자(tag), `TypeDefFactory` 의 첫 인자(typeName), `NamedType<...>` 의 문자열
**세 개가 전부 같아야 합니다.** 하나라도 어긋나면 런타임에
`Type schema 'X' does not exist in this type namespace` 로 터집니다.

그다음 `src/init.luau` 의 **네 곳**을 모두 수정합니다.

1. `const Foo = require("@self/schema/foo")`
2. `export type TFoo = Foo.TFoo` / `export type TFooOptions = Foo.TFooOptions`
3. `:registerType(Foo)` 를 체인에 추가
4. 체인 뒤 교집합 타입 어노테이션에 `Foo: typeof(Foo.factoryFunc),` 추가
   — 이걸 빠뜨리면 런타임엔 동작하지만 `Type.Foo` 가 타입 에러가 납니다.

마지막으로 `test.luau` 에 사용 예제와 기대 출력 주석을 추가하고 `luau test.luau` 로 확인합니다.

## 현재 상태 / 작업 대상

### `src/schema/roblox/` — 17개 타입 구현 완료

`Vector2`, `Vector3`, `CFrame`, `Color3`, `ColorSequence`, `ColorSequenceKeypoint`, `NumberRange`,
`NumberSequence`, `NumberSequenceKeypoint`, `Rect`, `Region3`, `UDim`, `UDim2`, `DateTime`,
`Instance`, `Enum`, `EnumItem` 이 모두 `defaultUntypedNamespace` 에 등록되어 있습니다.

Roblox 타입을 다룰 때 알아야 할 것:

- 데이터타입별 생성자/프로퍼티/제약과 아직 없는 타입 목록은 **`RobloxApi.md`** 에 있습니다.
- `luau` CLI 에는 Roblox 전역이 없습니다. **모듈 어디에서도 `Color3.new(...)` 같은 전역 참조를 하지 마세요.**
  검사 대상 `value` 의 프로퍼티/메서드와 사용자가 옵션으로 넘긴 값만 쓸 수 있습니다.
- 그래서 `test.luau` 에서는 Roblox 값을 만들 수 없습니다. 새 Roblox 타입을 추가하면 타입 빌드
  (`luauBuild`/`format`)와 음성 경로(`runtimeTypeCheck(schema, 123)`)만 테스트에 넣으세요.
  제약 검사기를 확인하려면 `require("./src/schema/roblox/<name>")` 로 모듈을 직접 가져와
  `Def.runtimeConstraintChecker(schema, mock)` 에 프로퍼티 모양만 흉내낸 테이블을 넘기면 됩니다.
- `src/schema/vector.luau` (네이티브 `vector`, `typeof == "vector"`) 와 `roblox/vector3.luau`
  (Roblox `Vector3`, `typeof == "Vector3"`) 는 별개 타입입니다.
- `Instance` 와 `EnumItem` 은 `TUnsafe<T>` 처럼 정적 타입을 명시적 타입 인자로 받습니다:
  `Type.Instance<<BasePart>>("BasePart")`, `Type.EnumItem<<Enum.Material>>(Enum.Material)`.
  런타임 판별에 필요한 정보(클래스명, Enum 객체)는 별도로 첫 인자로 넘깁니다.
- `Instance` 의 클래스 판별(`IsA`/`ClassName`)과 `EnumItem` 의 `EnumType` 판별은 **타입 검사**에 있습니다.
  유니온 분기 선택에 쓰여야 하기 때문입니다. `nameMatch`, `requiredChildren`, `allowedItems` 는 제약 검사입니다.
- 시퀀스 타입의 `strictKeypointOrder` 는 기본 꺼짐입니다. 엔진이 생성 시점에 이미 강제하는 규칙이라
  명시적으로 켰을 때만 검사합니다.

### 알려진 이슈

- `src/schema/json/array.luau` 의 `numericIndexOnly` 옵션이 `TArrayOptions` 에만 있고 `TArray` 타입엔 없습니다.
- `TSchema.id` 필드는 정의만 되어 있고 아무도 사용하지 않습니다 (`$ref` 유사 기능 미구현).
- `src/collect.luau` 는 아이디어 메모뿐인 빈 모듈입니다.

남은 계획은 `TODO.md` 에 있습니다.

## 하지 말 것

- `Default`, `Never`, `Intersect` 타입을 추가하지 마세요. 의도적으로 제외된 것이며 이유는 `README.md` 에 있습니다.
  객체 합성이 필요하면 `TMerge` 를 씁니다.
- `runtimeConstraintChecker` 안에서 타입 검사를 다시 하지 마세요. 호출 규약상 타입은 이미 보장됩니다.
- 에러 메시지를 즉시 문자열로 만들어 반환하지 마세요. 반드시 클로저로 감쌉니다.
- `.trash/` 는 gitignore 된 폐기 코드 보관소입니다. 참고만 하고 수정하지 마세요.
