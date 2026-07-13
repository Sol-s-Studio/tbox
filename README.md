tbox 는 시리얼라이징이나 디시리얼라이징에 아무 영향을 미치지 않는


모든 스키마는 defaultUntypedNamespace 에 기본적으로 등록되어야합니다

## Code styles

### 왜 타입 명에 TString 과 같이 T 를 접두사로 사용하나요?

이 라이브러리는 타입에 관한 라이브러리로써, 데이터 컨테이너 또는 타입클래스와는 연관이 없습니다. 허나 `Array`, `String` 과 같이 타입을 작명하게 될 경우, 일부 사용자 정의 함수 시그니처로써 이것이 타입에 관한 것인지 알 수 없게 됩니다. 따라서 모호함을 해결하고자 `TArray`, `TString` 과 같은 작명을 사용합니다.

### 일부 함수 명은 왜 파스칼 케이스입니까?

팩토리 함수와 생성자 함수에 대해서 파스칼 케이스를 사용합니다.

## Why x is not exist?

### Default 없는 이유?

따로 시리얼라이저를 강제하는 라이브러리가 아니기 때문에 input 타입과 output 타입이 달라질 수 없습니다. 따라서 `TDefault<TString>` 이 있다면 input 은 `string?` 의 루아 타입을 가지지만, output 은 `string` 의 타입을 가져 문제가 발생합니다. 또한 Default 내의 값은 항상 복사되지 않으면 부작용이 발생하는 등 많은 문제가 있으므로, default 는 구현하지 않습니다.

### Intersect 없는 이유?

루아우의 교집합은 heterogeneous 한 primitive 에 또한 수행될 수 있으며 이는 의도되지 않은 문제를 발생시킵니다. Typescript 의 경우

```typescript
type a = number & string
// A is never
```

와 같이 존재 불가 타입을 처리하지만, luau 의 교집합은 처리 불가 타입에 대해 있는 그대로 Intersect 를 반환합니다.

이는 실제로 never 와 같으며 존재할 수 없는 타입이므로 TBox 에선 존재해선 안됩니다. 따라서 해당 문제를 해결하기 위해 오직 `TObject` 에 대해서만 합집합 생성을 가능케 합니다. `TMerge` 를 확인하세요.


<!-- 부분집합 Partial 필요 -->
