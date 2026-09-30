--!strict

const module = {}

const escapes = {
    ["\\"] = "\\\\",
    ['"'] = '\\"',
    ["\n"] = "\\n",
    ["\t"] = "\\t",
    ["\f"] = "\\f",
    ["\b"] = "\\b",
    ["\r"] = "\\r",
    ["\a"] = "\\a",
    ["\v"] = "\\v",
}

const reserved = {
    ["and"] = true,
    ["break"] = true,
    ["do"] = true,
    ["else"] = true,
    ["elseif"] = true,
    ["end"] = true,
    ["false"] = true,
    ["for"] = true,
    ["function"] = true,
    ["if"] = true,
    ["in"] = true,
    ["local"] = true,
    ["nil"] = true,
    ["not"] = true,
    ["or"] = true,
    ["repeat"] = true,
    ["return"] = true,
    ["then"] = true,
    ["true"] = true,
    ["until"] = true,
    ["while"] = true,
}

function module.isValidIdent(ident: string): boolean
    if string.match(ident, "^[%a_][%w_]*$") and not reserved[ident] then
        return true
    end
    return false
end

-- 결과를 "..." 로 감싸면 원래 문자열로 다시 읽히는 Luau 문자열 리터럴이 되도록 이스케이프한다.
-- 제어문자를 그대로 두면 NUL 처럼 리터럴 자체가 깨지거나 사람이 읽을 수 없는 출력이 되므로 전부 이스케이프한다.
-- 0x80 이상 바이트는 그대로 두어도 리터럴로 안전하고, UTF-8 문자열을 읽기 좋게 유지하기 위해 건드리지 않는다.
function module.escapeLuauString(value: string): string
    return (
        string.gsub(value, '[%c\\"]', function(char: string): string
            -- 이름 있는 이스케이프가 없는 제어문자는 \ddd 로 바꾼다. 항상 세 자리로 채워야
            -- 뒤에 숫자가 이어져도("\0" .. "1" -> "\01") 다른 문자로 읽히지 않는다.
            return escapes[char] or string.format("\\%03d", string.byte(char))
        end)
    )
end

function module.indent(str: string): string
    return "  " .. string.gsub(str, "\n", "\n  ")
end

return module
