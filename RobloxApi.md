# Roblox API 레퍼런스 (src/schema/roblox 구현용)

`src/schema/roblox/*.luau` 를 구현하기 위해 필요한 Roblox 데이터타입 정보만 추린 문서입니다.
출처: [Roblox/creator-docs](https://github.com/Roblox/creator-docs) `content/en-us/reference/engine/datatypes/*.yaml`
(2026-07-29 기준 main 브랜치에서 확인).

## 0. 환경 전제 (매우 중요)

- 이 저장소의 테스트는 **standalone `luau` CLI** 로 실행됩니다. 그 환경에는 `Vector3`, `CFrame`,
  `Color3` 등 **Roblox 전역이 존재하지 않습니다.** (확인함: `Vector3.new` → `attempt to index nil`)
- 따라서 roblox 스키마 모듈은 **모듈 최상위(load 시점)에서 Roblox 전역을 참조하면 안 됩니다.**
  `Color3.new(...)` 같은 호출을 상수로 캐싱하지 마세요. 요구 시점(생성자 인자로 들어온 값)만 사용합니다.
- 타입 어노테이션(`Types.InnerType<Vector3>`)은 런타임에 지워지므로 실행에는 문제가 없습니다.
  단, Roblox 타입 정의가 없는 환경의 정적 분석에서는 미해결 타입으로 보일 수 있습니다.
- 런타임 판별은 전부 `typeof(value) == "<타입명>"` 로 합니다. Roblox 밖에서는 절대 참이 되지 않으므로 안전합니다.
- `type()` 과 `typeof()` 는 다릅니다. Roblox 의 `Vector3` 는 네이티브 `vector` 로 표현되지만
  `typeof()` 는 `"Vector3"` 를 반환합니다. standalone 에서 `typeof(vector.create(1,2,3))` 는 `"vector"` 입니다
  (확인함). 기존 `src/schema/vector.luau` (네이티브 `vector`) 와 `roblox/vector3.luau` 는 별개 타입으로 다뤄야 합니다.

## 1. typeof 문자열 표

| 스키마 파일 | `typeof()` 반환값 | luauBuild 출력 후보 |
| --- | --- | --- |
| `vector2.luau` | `"Vector2"` | `Vector2` |
| `vector3.luau` | `"Vector3"` | `Vector3` |
| `cframe.luau` | `"CFrame"` | `CFrame` |
| `color3.luau` | `"Color3"` | `Color3` |
| `colorSequence.luau` | `"ColorSequence"` | `ColorSequence` |
| `colorSequenceKeypoint.luau` | `"ColorSequenceKeypoint"` | `ColorSequenceKeypoint` |
| `numberRange.luau` | `"NumberRange"` | `NumberRange` |
| `numberSequence.luau` | `"NumberSequence"` | `NumberSequence` |
| `numberSequenceKeypoint.luau` | `"NumberSequenceKeypoint"` | `NumberSequenceKeypoint` |
| `rect.luau` | `"Rect"` | `Rect` |
| `region3.luau` | `"Region3"` | `Region3` |
| `udim2.luau` | `"UDim2"` | `UDim2` |
| (미존재, 필요) `udim.luau` | `"UDim"` | `UDim` |
| `dateTime.luau` | `"DateTime"` | `DateTime` |
| `instance.luau` | `"Instance"` | 클래스명 (`Part`, `BasePart`, `Instance` …) |
| `enum.luau` | `"Enum"` | `Enum` |
| `enumItem.luau` | `"EnumItem"` | `Enum.<EnumName>` (예: `Enum.Material`) |

전역 `Enum` 컨테이너 자체는 `typeof(Enum) == "Enums"` 입니다 (별개 타입).

## 2. 데이터타입 상세

### Vector2

- 생성자: `Vector2.new(x: number = 0, y: number = 0)`
- 상수: `Vector2.zero`, `.one`, `.xAxis`, `.yAxis`
- 프로퍼티: `X`, `Y` (number), `Magnitude` (number), `Unit` (Vector2)
- 메서드: `Cross`, `Abs`, `Ceil`, `Floor`, `Sign`, `Angle(other, isSigned)`, `Dot`, `Lerp`, `Max`, `Min`, `FuzzyEq`
- 제약 옵션 후보: `min`/`max` (Vector2 또는 성분별), `minMagnitude`/`maxMagnitude`, `integerOnly`,
  `notNan`/`isFinite` (성분별 NaN/inf 검사)
- 참고: `src/schema/vector.luau` 의 magnitude/성분 min·max 검사 로직을 그대로 따라 하면 일관성이 유지됩니다.

### Vector3

- 생성자: `Vector3.new(x = 0, y = 0, z = 0)`, `Vector3.FromNormalId(normal: Enum.NormalId)`,
  `Vector3.FromAxis(axis: Enum.Axis)`
- 상수: `Vector3.zero`, `.one`, `.xAxis`, `.yAxis`, `.zAxis`
- 프로퍼티: `X`, `Y`, `Z`, `Magnitude`, `Unit`
- 메서드: `Abs`, `Ceil`, `Floor`, `Sign`, `Cross`, `Angle(other, axis?)`, `Dot`, `FuzzyEq(other, epsilon)`,
  `Lerp`, `Max(...)`, `Min(...)`
- 제약 옵션 후보: Vector2 와 동일 + z 성분

### CFrame

- 생성자 (오버로드 다수):
  `CFrame.new()`, `CFrame.new(pos: Vector3)`, `CFrame.new(pos, lookAt)`, `CFrame.new(x, y, z)`,
  `CFrame.new(x, y, z, qX, qY, qZ, qW)`, `CFrame.new(x, y, z, R00..R22)` (12 인자),
  `CFrame.lookAt(at, lookAt, up?)`, `CFrame.lookAlong(at, direction, up?)`,
  `CFrame.fromRotationBetweenVectors(from, to)`, `CFrame.fromEulerAngles(rx, ry, rz, order?)`,
  `CFrame.fromEulerAnglesXYZ`, `CFrame.fromEulerAnglesYXZ`, `CFrame.Angles`(= XYZ),
  `CFrame.fromOrientation`(= YXZ), `CFrame.fromAxisAngle(axis, rotation)`,
  `CFrame.fromMatrix(pos, vX, vY, vZ?)`
- 상수: `CFrame.identity`
- 프로퍼티: `Position`, `Rotation` (CFrame), `X`, `Y`, `Z`,
  `LookVector`, `RightVector`, `UpVector`, `XVector`, `YVector`, `ZVector`
- 메서드: `Inverse`, `Lerp`, `Orthonormalize`, `ToWorldSpace`, `ToObjectSpace`,
  `PointToWorldSpace`, `PointToObjectSpace`, `VectorToWorldSpace`, `VectorToObjectSpace`,
  `GetComponents`, `ToEulerAngles(order?)`, `ToEulerAnglesXYZ`, `ToEulerAnglesYXZ`, `ToOrientation`,
  `ToAxisAngle`, `FuzzyEq`, `AngleBetween`
- 제약 옵션: `positionMin`/`positionMax`, `minPositionMagnitude`/`maxPositionMagnitude`, `notNan`,
  `orthonormalOnly` (+`orthonormalEpsilon`), `rightHandedOnly`
- 주의: CFrame 은 성분이 12개라 formatter/에러 메시지는 `cf.Position` 정도만 노출하는 편이 읽기 좋습니다.

#### 회전 성분의 불변식 — `orthonormalOnly` 와 `rightHandedOnly` 를 나눈 이유

CFrame 의 회전 부분은 쿼터니언이 아니라 **9개 raw float(기저벡터 3개)** 이고, 일부 생성 경로는
이를 전혀 검증하지 않습니다. 검증 없이 통과하는 경로는 `CFrame.fromMatrix(pos, vX, vY, vZ)` (4인자)
와 12성분 `CFrame.new` 두 개뿐이며, 이것이 정확히 역직렬화 코드가 쓰는 경로입니다.
반대로 `CFrame.new(pos)`, `CFrame.Angles`, `lookAt`, 쿼터니언 생성자, 3인자 `fromMatrix`,
그리고 정상 CFrame 끼리의 곱은 항상 올바른 회전을 만듭니다.

| 옵션 | 검사 내용 | 겨냥하는 위협 |
| --- | --- | --- |
| `orthonormalOnly` | 기저벡터가 길이 1이고 서로 수직인가 (`rotation:FuzzyEq(rotation:Orthonormalize(), eps)`) | 누적 부동소수 드리프트, 스케일/shear 혼입 |
| `rightHandedOnly` | 행렬식이 양수인가 (`XVector:Cross(YVector):Dot(ZVector) > 0`) | 조작·손상된 역직렬화 입력 |

둘을 합치지 않은 이유:

- 누적 오차는 행렬식을 1에서 조금 흔들 뿐 **부호를 뒤집지 못합니다.** 즉 드리프트 시나리오에서
  거울상은 나오지 않으므로, 내부 계산 결과를 검증할 때는 `orthonormalOnly` 만 켜면 충분합니다.
- 반대로 **`Orthonormalize()` 는 그람-슈미트라 손잡이를 보존하므로 거울상을 고치지 못합니다.**
  "들어온 값은 일단 정규직교화한다" 는 통상적 방어책이 유일하게 무력한 결함이라, 신뢰 경계에서는
  `rightHandedOnly` 를 따로 켜야 합니다.
- 왼손 좌표계(행렬식 -1)는 회전이 아니라 회전+거울반사입니다. 어떤 물리적 회전으로도 도달할 수 없어
  `Lerp` 중간에 납작해지고, 외적 부호가 전부 뒤집히며, `ToEulerAngles`/`ToAxisAngle`/쿼터니언 변환이
  순수 회전을 전제하므로 왕복 시 값이 조용히 바뀝니다. (단 `Inverse()` 는 직교행렬이면 부호와 무관하게
  전치와 같으므로 정상 동작합니다.)

참고로 **짐벌락은 이 두 옵션 중 어느 것으로도 잡히지 않으며, 잡을 대상도 아닙니다.** 짐벌락은
오일러각이라는 *표현법*의 특이점이지 CFrame 값의 결함이 아니고, 짐벌락 상태의 행렬도 정규직교이며
행렬식이 +1 입니다. 회전을 오일러각 3개로 저장하는 스키마를 쓰지 않는 것이 유일한 대응입니다.

### Color3

- 생성자: `Color3.new(r = 0, g = 0, b = 0)` — 성분은 0~1 부동소수,
  `Color3.fromRGB(r = 0, g = 0, b = 0)` — 0~255,
  `Color3.fromHSV(h, s, v)` — 0~1, `Color3.fromHex(hex: string)` — `"#FFFFFF"` / `"FFFFFF"` / 3자리 축약
- 프로퍼티: `R`, `G`, `B` (0~1 number)
- 메서드: `Lerp(goal, alpha)`, `ToHSV() -> (h, s, v)`, `ToHex() -> string`
- 제약 옵션 후보: `min`/`max` (Color3 또는 성분별 0~1), `clampedOnly` (성분이 0~1 밖으로 나가지 않았는지 —
  `Color3.new` 는 범위 밖 값도 그대로 저장합니다), `grayscaleOnly`, `allowedColors` 목록
- 주의: `Color3.fromRGB` 로 만든 값도 저장은 0~1 실수라 정확히 `n/255` 로 떨어지지 않습니다.
  RGB 정수 검사를 넣는다면 반올림 오차 허용치가 필요합니다.

### ColorSequenceKeypoint

- 생성자: `ColorSequenceKeypoint.new(time: number, color: Color3)`
- 프로퍼티: `Time` (0~1), `Value` (Color3)
- 제약 옵션 후보: `minTime`/`maxTime`, 내부 Color3 스키마 위임

### ColorSequence

- 생성자: `ColorSequence.new(color: Color3)`, `ColorSequence.new(c0: Color3, c1: Color3)`,
  `ColorSequence.new(keypoints: {ColorSequenceKeypoint})`
- 프로퍼티: `Keypoints` — 읽기 전용 `{ColorSequenceKeypoint}`
- 엔진 강제 제약 (문서 명시):
  - 키포인트는 **최소 2개**
  - `Time` 은 **비내림차순**
  - 첫 키포인트 `Time == 0`, 마지막 키포인트 `Time == 1`
  - (미확인) 최대 키포인트 개수 20 제한이 있는 것으로 알려져 있음 — 구현 시 옵션으로 두고 기본은 끄는 편이 안전
- 제약 옵션 후보: `minKeypoints`/`maxKeypoints`, 키포인트 요소용 하위 스키마

### NumberSequenceKeypoint

- 생성자: `NumberSequenceKeypoint.new(time, value)`, `NumberSequenceKeypoint.new(time, value, envelope)`
- 프로퍼티: `Time` (0~1), `Value` (number), `Envelope` (number, 값의 허용 변동폭)
- 제약 옵션 후보: `minValue`/`maxValue`, `maxEnvelope`, `envelopeMustBeZero`

### NumberSequence

- 생성자: `NumberSequence.new(n: number)`, `NumberSequence.new(n0, n1)`,
  `NumberSequence.new(keypoints: {NumberSequenceKeypoint})`
- 프로퍼티: `Keypoints` — 읽기 전용 `{NumberSequenceKeypoint}`
- 제약: ColorSequence 와 동일 (최소 2개 / 비내림차순 / 0 시작 / 1 종료)

### NumberRange

- 생성자: `NumberRange.new(value)` (min = max = value), `NumberRange.new(minimum, maximum)`
  — `minimum <= maximum` 이어야 하며 아니면 에러
- 프로퍼티: `Min`, `Max`
- 주의: Min/Max 는 **32비트 float** 로 저장됩니다. 아주 큰 정수는 정밀도가 손실됩니다.
- 제약 옵션 후보: `min`/`max` (전체 범위 한계), `maxSpan` (Max - Min 상한), `disallowEmpty` (Min == Max 금지)

### Rect

- 생성자: `Rect.new()`, `Rect.new(min: Vector2, max: Vector2)`, `Rect.new(minX, minY, maxX, maxY)`
- 프로퍼티: `Min` (Vector2), `Max` (Vector2), `Width` (number), `Height` (number)
- 제약 옵션 후보: `maxWidth`/`maxHeight`/`minWidth`/`minHeight`, `min`/`max` 경계 Vector2,
  `normalizedOnly` (Min <= Max 보장 — 생성자는 이를 강제하지 않음)

### Region3

- 생성자: `Region3.new(min: Vector3, max: Vector3)`
- 프로퍼티: `CFrame` (중심), `Size` (Vector3)
- 메서드: `ExpandToGrid(resolution: number) -> Region3`
- 제약 옵션 후보: `maxSize`/`minSize` (Vector3), `maxVolume`, `alignedToGrid` (resolution 배수 여부)
- 주의: `Min`/`Max` 프로퍼티는 **없습니다.** `CFrame.Position ± Size/2` 로 계산해야 합니다.

### UDim / UDim2

- `UDim.new(scale = 0, offset = 0)` — 프로퍼티 `Scale`, `Offset`
- `UDim2.new()`, `UDim2.new(xScale, xOffset, yScale, yOffset)`, `UDim2.new(x: UDim, y: UDim)`,
  `UDim2.fromScale(xScale, yScale)`, `UDim2.fromOffset(xOffset, yOffset)`
- UDim2 프로퍼티: `X` (UDim), `Y` (UDim), `Width` (= X, UDim), `Height` (= Y, UDim)
- UDim2 메서드: `Lerp(goal, alpha)`
- 제약 옵션:
  - `UDim` — `minScale`/`maxScale`, `minOffset`/`maxOffset`, `integerOffsetOnly`,
    `scaleOnly`/`offsetOnly` (한쪽 성분이 0인지)
  - `UDim2` — X 와 Y 는 서로 독립적인 UDim 이므로 **수치 범위 제약은 축별로 분리**되어 있습니다:
    `minXScale`/`maxXScale`/`minXOffset`/`maxXOffset`, `minYScale`/`maxYScale`/`minYOffset`/`maxYOffset`.
    `integerOffsetOnly`, `scaleOnly`, `offsetOnly` 는 값 전체의 성격에 대한 제약이라 두 축에 공통 적용됩니다.
    에러 메시지에는 어느 축인지가 `x` / `y` 접두사로 붙습니다.

### DateTime

- 생성자: `DateTime.now()`, `DateTime.fromUnixTimestamp(unixTimestamp)`,
  `DateTime.fromUnixTimestampMillis(unixTimestampMillis)`,
  `DateTime.fromUniversalTime(year = 1970, month = 1, day = 1, hour = 0, minute = 0, second = 0, millisecond = 0)`,
  `DateTime.fromLocalTime(...)` (동일 시그니처),
  `DateTime.fromIsoDate(isoDate: string)` — **파싱 실패 시 `nil` 반환** (에러 아님)
- 프로퍼티: `UnixTimestamp` (초), `UnixTimestampMillis` (밀리초)
- 메서드: `ToUniversalTime() -> Dictionary`, `ToLocalTime() -> Dictionary`, `ToIsoDate() -> string`,
  `FormatUniversalTime(format, locale)`, `FormatLocalTime(format, locale)`
  - 시간 테이블 키: `Year`, `Month`, `Day`, `Hour`, `Minute`, `Second`, `Millisecond`
- 유효 범위 (문서 명시): `UnixTimestamp` 는 `-17,987,443,200` ~ `253,402,300,799`
  (밀리초는 `-17,987,443,200,000` ~ `253,402,300,799,999`) — 대략 서기 1400 ~ 9999년
- 제약 옵션 후보: `min`/`max` (DateTime 또는 unix timestamp), `notFuture`/`notPast`
  (단, 이런 옵션은 검사 시점 의존이라 순수하지 않음 — 넣을지 신중히 결정),
  `wholeSecondsOnly` (Millis % 1000 == 0)

### Instance

- 생성: `Instance.new(className: string, parent: Instance?)` — 생성 불가 클래스면 에러
- 검사에 쓰는 멤버:
  - `value.ClassName` — 정확한 클래스명 문자열
  - `value:IsA(className: string) -> boolean` — 상위 클래스 포함(공변) 검사. `IsA("Instance")` 는 항상 true
  - `value.Name`, `value.Parent`, `value:GetFullName()`, `value:IsDescendantOf(ancestor)`,
    `value:FindFirstChild(name, recursive?)`, `value:GetAttribute(name)`
- 제약 옵션 후보:
  - `className` — `IsA` 기반 (공변 허용, 기본 권장)
  - `exactClassName` — `ClassName ==` 기반
  - `mustBeInDataModel` / `requireParent` — `value:IsDescendantOf(game)` 로 검사
  - `requiredChildren`, `requiredAttributes`
- 주의:
  - 존재하지 않는 프로퍼티 인덱싱은 **에러를 던집니다.** 사용자 지정 프로퍼티를 읽을 땐 `pcall` 필수.
  - `luauBuilder` 는 클래스명을 그대로 Luau 타입으로 쓸 수 있습니다 (`Part`, `BasePart`, `Instance`).
    Roblox 타입 정의가 없는 환경에서는 미해결 타입이 되므로, `TUnsafe` 처럼 제네릭 인자로
    정적 타입을 받는 형태(`Type.Instance<<BasePart>>("BasePart")`)를 검토하세요.

### Enum / EnumItem / Enums

- 전역 `Enum` 은 `Enums` 타입의 컨테이너입니다: `typeof(Enum) == "Enums"`, `Enum:GetEnums() -> {Enum}`
- `Enum` (예: `Enum.Material`): `typeof(Enum.Material) == "Enum"`
  - `:GetEnumItems() -> {EnumItem}`
  - `:FromName(name: string) -> EnumItem?`
  - `:FromValue(value: number) -> EnumItem?`
  - `tostring(Enum.Material)` → `"Material"`
- `EnumItem` (예: `Enum.Material.Plastic`): `typeof(...) == "EnumItem"`
  - 프로퍼티: `Name` (string), `Value` (number), `EnumType` (Enum)
  - `tostring(Enum.Material.Plastic)` → `"Enum.Material.Plastic"`
- 스키마 설계 힌트:
  - `enum.luau` — 값이 Enum 컨테이너 자체인 경우 (드묾). `typeof == "Enum"` 만 확인.
  - `enumItem.luau` — 실사용 대상. 스키마에 사용자가 넘긴 Enum 객체(`Enum.Material`)를 저장하고
    `value.EnumType == schema.enumType` 으로 검사. 특정 항목만 허용하려면 `allowedItems` 집합 사용.
  - `luauBuilder` 는 `Enum.{tostring(schema.enumType)}` 로 만들면 Roblox 타입과 정확히 일치합니다.
  - `TODO.md` 에 "그냥 StrEnum 만들고 `Union<T...>` 하는 게 낫지 않나" 라는 메모가 있으니,
    문자열 기반 열거는 기존 `TSingleton` + `TUnion` 조합으로 충분함을 유의하세요.

## 3. 아직 파일이 없는, 추가 검토 가치가 있는 Roblox 데이터타입

`UDim`, `Ray`, `Axes`, `Faces`, `BrickColor`, `Font`, `TweenInfo`, `PhysicalProperties`,
`Vector2int16`, `Vector3int16`, `Region3int16`, `RaycastParams`, `RaycastResult`, `OverlapParams`,
`PathWaypoint`, `Random`, `Content`, `SharedTable`, `CatalogSearchParams`, `Secret`, `buffer`

이 중 실사용 빈도는 `UDim`, `BrickColor`, `Font`, `TweenInfo`, `Ray`, `Vector3int16` 순으로 높습니다.
