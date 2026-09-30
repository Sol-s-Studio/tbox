--!strict

-- src/util.luau 직접 단위 테스트. util 함수들은 스키마 테스트에서도 간접적으로 실행되지만,
-- 거기서는 평범한 입력만 지나가므로 예약어/제어문자/여러 줄 같은 엣지 케이스는 여기서 직접 확인한다.
-- 결과가 Luau 소스로 쓰이는 함수(isValidIdent, escapeLuauString)는 기대값을 손으로 적는 것에 더해
-- Helper.loadChunk 로 실제 Luau 파서에 넣어 보고, 파서와 판단이 일치하는지까지 확인한다.

const Util = require("../src/util")
const Helper = require("./helper")

-- 주어진 소스가 Luau 파서를 통과하는가
const function compiles(source: string): boolean
    return (Helper.loadChunk(source)) ~= nil
end

----------------------------------------------------------------------------------------------------
-- isValidIdent
----------------------------------------------------------------------------------------------------

-- TObject 의 luauBuild 는 isValidIdent 가 참이면 키를 그대로 `{ key: T }` 로 쓰고, 거짓이면
-- `{ ["key"]: T }` 로 쓴다. 그래서 "참"이면 테이블 타입 필드 이름으로 파싱돼야 한다.
const function expectIdent(ident: string)
    Helper.expectTrue(Util.isValidIdent(ident), `'{ident}' should be a valid identifier`)
    Helper.expectTrue(
        compiles(`type T = \{ {ident}: number }`),
        `'{ident}' is judged valid, but luau does not accept it as a table type field name`
    )
end

const function expectNotIdent(ident: string)
    Helper.expectTrue(not Util.isValidIdent(ident), `'{ident}' should not be a valid identifier`)
end

expectIdent("a")
expectIdent("A")
expectIdent("_")
expectIdent("_a1")
expectIdent("camelCase")
expectIdent("SCREAMING_CASE_9")

-- 문맥 키워드는 Luau 에서 식별자로 쓸 수 있으므로 유효해야 한다 (예약어 목록에 넣으면 안 된다)
expectIdent("continue")
expectIdent("type")
expectIdent("export")
expectIdent("typeof")
expectIdent("const")

expectNotIdent("")
expectNotIdent("1a")
expectNotIdent("9")
expectNotIdent("a b")
expectNotIdent("a-b")
expectNotIdent("a.b")
expectNotIdent("a\n")
expectNotIdent("\na")
-- %a 는 ASCII 글자만 매칭하므로 비 ASCII 식별자는 거부된다 (Luau 도 마찬가지로 받지 않는다)
expectNotIdent("한글")
expectNotIdent("é")

-- Luau 예약어 전체 목록. 각각 거부되어야 하고, 실제로 Luau 도 식별자로 받지 않는지 교차 확인한다.
-- 예약어 목록에서 하나가 빠지면 `{ and: number }` 처럼 파싱되지 않는 타입이 생성되므로 중요하다.
const reservedWords = {
    "and",
    "break",
    "do",
    "else",
    "elseif",
    "end",
    "false",
    "for",
    "function",
    "if",
    "in",
    "local",
    "nil",
    "not",
    "or",
    "repeat",
    "return",
    "then",
    "true",
    "until",
    "while",
}
for _, word in reservedWords do
    expectNotIdent(word)
    Helper.expectTrue(not compiles(`local {word} = 1`), `'{word}' is expected to be a reserved word in luau`)
    -- 예약어라도 대소문자가 다르면 평범한 식별자다
    expectIdent(string.upper(word))
end

----------------------------------------------------------------------------------------------------
-- escapeLuauString
----------------------------------------------------------------------------------------------------

-- 이스케이프 결과를 "..." 로 감싸 Luau 로 읽었을 때 원래 문자열이 그대로 복원되는지 확인한다
const function expectRoundTrip(value: string)
    const escaped = Util.escapeLuauString(value)
    const chunk, err = Helper.loadChunk(`return "{escaped}"`)
    if not chunk then
        error(`escaped string does not compile: "{escaped}"\n  {err}`, 2)
    end
    if chunk() ~= value then
        error(`escaped string does not round-trip: "{escaped}"`, 2)
    end
    -- TSingleton 의 luauBuild 는 같은 결과를 문자열 싱글톤 타입으로도 쓴다
    if not compiles(`type T = "{escaped}"`) then
        error(`escaped string is not a valid singleton type: "{escaped}"`, 2)
    end
end

-- 기대하는 출력 형태를 그대로 고정한다
Helper.expectEqual(Util.escapeLuauString(""), "")
Helper.expectEqual(Util.escapeLuauString("hello world"), "hello world")
Helper.expectEqual(Util.escapeLuauString('say "hi"'), 'say \\"hi\\"')
Helper.expectEqual(Util.escapeLuauString("it's"), "it's")
Helper.expectEqual(Util.escapeLuauString("a\\b"), "a\\\\b")
-- 백슬래시와 n 두 글자는 개행이 아니다. 백슬래시만 이스케이프되어야 한다
Helper.expectEqual(Util.escapeLuauString("\\n"), "\\\\n")
Helper.expectEqual(Util.escapeLuauString("\n\t\r\f\b\a\v"), "\\n\\t\\r\\f\\b\\a\\v")
-- 이름 있는 이스케이프가 없는 제어문자는 항상 세 자리 \ddd 로 쓴다
Helper.expectEqual(Util.escapeLuauString("\0"), "\\000")
Helper.expectEqual(Util.escapeLuauString("\27[0m"), "\\027[0m")
Helper.expectEqual(Util.escapeLuauString("\127"), "\\127")
-- 세 자리로 채우지 않으면 "\0" 뒤의 "1" 이 붙어 \01 (0x01) 로 읽히게 된다
Helper.expectEqual(Util.escapeLuauString("\0" .. "1"), "\\0001")
-- 문자열 보간이나 다른 따옴표 형식의 특수문자는 "..." 안에서 의미가 없으므로 그대로 둔다
Helper.expectEqual(Util.escapeLuauString("{x} `y` [[z]]"), "{x} `y` [[z]]")
-- 0x80 이상 바이트(UTF-8 포함)는 그대로 둔다
Helper.expectEqual(Util.escapeLuauString("한글 é"), "한글 é")
Helper.expectEqual(Util.escapeLuauString("\255"), "\255")

-- gsub 의 두 번째 반환값(치환 횟수)이 새어 나오지 않아야 한다
Helper.expectEqual(select("#", Util.escapeLuauString("a\nb")), 1)

-- 모든 바이트에 대해, 앞뒤에 글자나 숫자가 붙어 있어도 복원되는지 확인한다
for byte = 0, 255 do
    const char = string.char(byte)
    expectRoundTrip(char)
    expectRoundTrip(`a{char}z`)
    expectRoundTrip(`{char}123`)
end
const allBytes = {}
for byte = 0, 255 do
    table.insert(allBytes, string.char(byte))
end
expectRoundTrip(table.concat(allBytes))
expectRoundTrip('\\"\\\\"\\')

----------------------------------------------------------------------------------------------------
-- indent
----------------------------------------------------------------------------------------------------

Helper.expectEqual(Util.indent("a"), "  a")
Helper.expectEqual(Util.indent("a\nb\nc"), "  a\n  b\n  c")
-- 중첩된 컨테이너의 에러 메시지는 indent 가 여러 번 겹쳐 적용되므로 누적되어야 한다
Helper.expectEqual(Util.indent(Util.indent("a\nb")), "    a\n    b")
Helper.expectEqual(Util.indent(`x\n{Util.indent("a\nb")}`), "  x\n    a\n    b")
-- 빈 줄이나 끝의 개행 뒤에도 공백이 붙는다. 에러 메시지 전용이라 이 동작을 그대로 둔다
Helper.expectEqual(Util.indent(""), "  ")
Helper.expectEqual(Util.indent("a\n"), "  a\n  ")
Helper.expectEqual(Util.indent("a\n\nb"), "  a\n  \n  b")
-- \n 만 줄 경계로 본다. \r\n 은 \r 이 앞 줄 끝에 남은 채로 들여쓰기된다
Helper.expectEqual(Util.indent("a\r\nb"), "  a\r\n  b")

Helper.expectEqual(select("#", Util.indent("a\nb")), 1)

return true
