# tbox_squish

`tbox` 스키마로 기술된 값을 `buffer` 로 압축 직렬화/역직렬화하기 위한 라이브러리입니다. 특정
직렬화 라이브러리에 종속되지 않고, 호출측이 [Squash](https://github.com/Data-Oriented-House/Squash)
등 원하는 buffer-cursor 라이브러리의 push/pop 함수를 주입해서 쓰는 방식을 목표로 합니다 — 왜
squash 를 직접 의존성으로 두지 않는지는 `CLAUDE.md` 를 보세요.

`compile(schema, codecs)` 가 tbox 스키마를 순회하며 `Codec<Cursor, Value>` 를 만들어줍니다.
`Number`/`String`/`Boolean`/`Singleton`/`Optional`/`Array`(가변·고정 길이)/`Object`/`Merge`/`Union`/`Map`
을 지원합니다. `Any`/`Nil`/`Unsafe`/`Vector`/Roblox 데이터타입은 아직 지원하지 않고 compile 시점에
에러를 냅니다 (TODO). `Optional`/`Array`/`Object`/`Map` 은 `codecs` 에 주입된 `record`/`array`/`map`/
`optional` 합성 빌더에 그대로 위임하고(스키마 트리 전체가 한 번의 ser/des 로 묶입니다), `Union` 만
분기 태그+payload 를 직접 다룹니다 - 자세한 이유와 코덱 조합 규약은 `src/init.luau` 와 `CLAUDE.md`
에 설명되어 있습니다.

`pesde.toml` 이 `qwreey/tbox` 를 워크스페이스 의존성으로 참조하도록 설정되어 있습니다.
