- [ ] 함수의 구현 필요 유무 검토
- [ ] TString 에 format 필드로 regex 확인 가능하게 options 추가
- [ ] type function Check 를 만들어주는게 좋을듯. 이러면 타입 에러 났을 때 좀더 미려하게 어디에 뭐가 없어서 난건지 알려주면 좋겠다 싶음 (근데 아무리 봐도 필요는 없어보이긴 함. 이미 잘 나오는듯)
- [ ] enum 은 어떻게 할 지 모르겠음.. 그냥 @qwreey-js 처럼 StrEnum 을 구축한 후 `Union<T...>` 하는게 좋을지도
- [ ] TMerge 구현
- [ ] Map 구현

문서화하기...
일단 기본적으로
runtimeTypeCheck: 런타임에 타입이 맞는지 체크. 유니온에서 이것을 통해 적절한 요소가 선택될 수 있음.
runtimeConstraintCheck: 런타임에 제약조건이 맞는지 체크. 숫자의 최대치나 최소치 등을 확인하는데 사용.

not null 이나 부분타입 등 어떻게 만들지

런타임 데이터 구조도 필요

Squash 바인딩 필요
https://data-oriented-house.github.io/Squash/api/Squash/#array
