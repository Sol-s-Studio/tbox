--!strict

const module = {}

const escapes = {
    ["\n"] = "\\n",
    ["\t"] = "\\t",
    ["\f"] = "\\f",
    ["\b"] = "\\b",
    ["\r"] = "\\r",
    ['"'] = '\\"',
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

function module.isVaildIdent(ident: string): boolean
    if string.match(ident, "^[%a_][%w_]*$") and not reserved[ident] then
        return true
    end
    return false
end

function module.escapeLuauString(value: string): string
    local formatted = string.gsub(value, "\\", "\\\\")
    formatted = string.gsub(formatted, '[\n\t\f\b\r"]', escapes)
    return formatted
end

function module.indent(str: string): string
    return "  " .. string.gsub(str, "\n", "\n  ")
end

return module
