--!strict

-- src/ 와 test/ 를 Roblox Studio 에서 그대로 실행할 수 있는 Luau 청크 하나로 묶어 stdout 으로 낸다.
-- 사용: (packages/tbox 에서) lute run scripts/studio-bundle.luau [파트, 기본 all] > bundle.luau
--       또는 저장소 루트에서 mise run studio-bundle -- [파트]
-- 만든 청크는 Studio MCP 의 execute_luau(Edit) 등에 그대로 넘긴다.
--
-- 파트:
--   all        test/studio/run 하나를 실행한다 (CLI 스위트 전체 + 실제 값 테스트). 청크가 약 130KB 라
--              execute_luau 로는 보낼 수 없다 (아래 참고). 크기 제한이 없는 경로에서 쓰는 기준 진입점이다.
--   cli-core   test/run.luau 가 require 하는 모듈 중 schema/roblox 가 아닌 것
--   cli-roblox test/run.luau 가 require 하는 schema/roblox/* (mock 테스트)
--   studio     test/studio/run.luau 가 require 하는 실제 값 테스트 (../run 제외)
-- Studio MCP 프록시는 요청 본문이 약 100KB(JSON 이스케이프 후)를 넘으면 PayloadTooLargeError 로 거부한다.
-- src 만 해도 이스케이프 후 약 51KB 라서 전체를 한 번에 보낼 수 없다. 그래서 all 을 위 세 파트로 나눠
-- 각각 독립적으로(트리를 새로 만들고 지우며) 실행한다. 세 파트가 모두 OK 이면 all 이 OK 인 것과 같다.
-- 파트 목록은 test/run.luau, test/studio/run.luau 의 require 문에서 읽어오므로 따로 관리하지 않는다.
--
-- 청크는 파일 트리를 부모가 nil 인 Folder/ModuleScript 트리로 재구성한다. 디렉터리에 init.luau 가 있으면
-- 그 디렉터리가 곧 ModuleScript 가 되므로(Luau require-by-string 과 같은 규칙) "../src", "@self/..." 같은
-- 경로가 파일시스템과 똑같이 풀린다. src 는 항상 통째로 넣고, test 는 파트가 실행할 모듈에서 시작해
-- 문자열 리터럴 require 를 따라가며 필요한 파일만 넣는다. 트리를 DataModel 에 붙이지 않고 실행 후 Destroy
-- 하므로 플레이스에 흔적을 남기지 않는다. 출력은 LogService 로 모아 청크의 반환값으로 돌려준다
-- (Studio 에 남기지 않고 밖으로 뺀다).
--
-- Lute 로 실행한다 (Lune 과 달리 `const` 를 파싱한다). 전송 크기를 줄이려고 darklua 로 주석/공백/타입 표기를 지우고 지역 변수 이름을 짧게 바꾼 사본을 묶는다
-- (청크 전체를 execute_luau 인자로 그대로 넘겨야 하므로 크기가 곧 비용이다). darklua 0.19 가 이 저장소
-- 문법(`const`, `f<<T>>`)을 올바르게 처리하는지는 같은 설정으로 가공한 사본에서 `luau test/run.luau` 가
-- 통과하는 것으로 확인했다. 이름 변경은 지역 변수에만 적용되므로 에러 메시지 문자열이나 Roblox 전역
-- (Vector3 등)은 바뀌지 않는다.

const fs = require("@std/fs")
const process = require("@std/process")

-- Lute 의 process.args[1] 은 스크립트 경로다
const partName = process.args[2] or "all"
const workDir = "/tmp/tbox-studio-bundle-" .. tostring(os.time())

const function run(command: { string })
    const result = process.run(command)
    if not result.ok then
        error(`{command[1]} failed:\n{result.stderr}`)
    end
end

const function isFile(path: string): boolean
    return fs.exists(path) and fs.type(path) == "file"
end

const function isDir(path: string): boolean
    return fs.exists(path) and fs.type(path) == "dir"
end

-- 원본 소스에서 문자열 리터럴 require 대상을 순서대로 뽑는다.
-- `(require :: any)("@lute/luau")` 같은 동적 호출은 일부러 걸리지 않는다 (Studio 에서는 쓰이지 않는 경로).
const function readRequires(path: string): { string }
    const result = {}
    for target in string.gmatch(fs.readFileToString(path), 'require%(%s*"([^"]+)"%s*%)') do
        table.insert(result, target)
    end
    return result
end

const function dirname(path: string): string
    return string.match(path, "^(.*)/[^/]*$") or ""
end

-- base 디렉터리 기준으로 relative 를 풀어 저장소 기준 경로를 만든다 ("." / ".." 처리)
const function joinPath(base: string, relative: string): string
    const segments = {}
    for segment in string.gmatch(base, "[^/]+") do
        table.insert(segments, segment)
    end
    for segment in string.gmatch(relative, "[^/]+") do
        if segment == ".." then
            table.remove(segments)
        elseif segment ~= "." then
            table.insert(segments, segment)
        end
    end
    return table.concat(segments, "/")
end

const function moduleFile(modulePath: string): string
    if isFile(modulePath .. ".luau") then
        return modulePath .. ".luau"
    elseif isFile(modulePath .. "/init.luau") then
        return modulePath .. "/init.luau"
    end
    error(`cannot find module '{modulePath}'`)
end

const function isSrc(path: string): boolean
    return path == "src" or string.sub(path, 1, 4) == "src/"
end

-- test 쪽에서 실제로 필요한 파일 집합. src 는 항상 통째로 넣으므로 따라가지 않는다.
-- 주의: init.luau 는 기준 디렉터리 규칙이 다르지만 test 에는 init.luau 가 없으므로 여기서는 다루지 않는다.
const included: { [string]: boolean } = {}
const function include(file: string)
    if included[file] then
        return
    end
    included[file] = true
    for _, target in readRequires(file) do
        if string.sub(target, 1, 1) ~= "@" then
            const resolved = joinPath(dirname(file), target)
            if not isSrc(resolved) then
                include(moduleFile(resolved))
            end
        end
    end
end

-- entryFile 이 require 하는 모듈 목록(저장소 기준, 확장자 없음) 중 keep 을 통과한 것만 돌려준다
const function entryModules(entryFile: string, keep: (target: string) -> boolean): { string }
    const result = {}
    for _, target in readRequires(entryFile) do
        if keep(target) then
            table.insert(result, joinPath(dirname(entryFile), target))
        end
    end
    return result
end

local modules: { string }
if partName == "all" then
    modules = { "test/studio/run" }
elseif partName == "cli-core" then
    modules = entryModules("test/run.luau", function(target)
        return string.sub(target, 1, 16) ~= "./schema/roblox/"
    end)
elseif partName == "cli-roblox" then
    modules = entryModules("test/run.luau", function(target)
        return string.sub(target, 1, 16) == "./schema/roblox/"
    end)
elseif partName == "studio" then
    modules = entryModules("test/studio/run.luau", function(target)
        return target ~= "../run" and target ~= "../helper"
    end)
else
    error(`unknown part '{partName}'. expected one of all, cli-core, cli-roblox, studio`)
end

-- 분할 파트는 끝에 Helper.knownDiscrepancies 를 직접 출력하므로 helper 는 항상 넣는다
include("test/helper.luau")
for _, modulePath in modules do
    include(moduleFile(modulePath))
end

fs.writeStringToFile(
    workDir .. ".json",
    '{ "rules": ["remove_comments", "remove_spaces", "remove_types", '
        .. '{ "rule": "rename_variables", "include_functions": true }, "remove_unused_variable"] }'
)
for _, dir in { "src", "test" } do
    run({ "darklua", "process", "--config", workDir .. ".json", dir, `{workDir}/{dir}` })
end

-- darklua 가 주석/타입을 지운 자리에 빈 줄이 대량으로 남는다(전체의 약 1/3). 이 저장소에는 여러 줄에 걸친
-- 문자열 리터럴이 없으므로(여러 줄 기대값은 모두 \n 이스케이프로 쓴다) 빈 줄을 지워도 의미가 바뀌지 않는다.
-- 여러 줄 문자열을 추가하게 되면 이 처리를 다시 검토할 것.
const function stripBlankLines(source: string): string
    const kept = {}
    for line in string.gmatch(source .. "\n", "([^\n]*)\n") do
        if string.find(line, "%S") then
            table.insert(kept, line)
        end
    end
    return table.concat(kept, "\n")
end

-- 소스를 담을 수 있는 가장 짧은 long bracket 을 고른다
const function longString(source: string): string
    source = stripBlankLines(source)
    local level = 0
    while string.find(source, "]" .. string.rep("=", level) .. "]", 1, true) do
        level += 1
    end
    const eq = string.rep("=", level)
    -- 여는 괄호 바로 뒤의 개행은 버려지므로 하나 덧붙여 원문을 보존한다
    return `[{eq}[\n{source}]{eq}]`
end

-- relPath 파일을 청크에 넣어야 하는가 (src 는 전부, test 는 include 로 모은 것만)
const function wanted(relPath: string): boolean
    return isSrc(relPath) or included[relPath] == true
end

-- relPath 디렉터리 아래에 넣을 파일이 하나라도 있는가
const function dirWanted(relPath: string): boolean
    if isSrc(relPath) then
        return true
    end
    const prefix = relPath .. "/"
    for file in included do
        if string.sub(file, 1, #prefix) == prefix then
            return true
        end
    end
    return false
end

const lines: { string } = {}
local nextId = 0

-- relPath 디렉터리를 parentVar 아래에 재구성하고, 만들어진 인스턴스 변수 이름을 돌려준다.
-- 소스는 darklua 가 가공한 workDir 쪽 사본에서 읽는다.
const function emitDir(relPath: string, name: string, parentVar: string): string
    nextId += 1
    const var = `n{nextId}`
    const processedDir = `{workDir}/{relPath}`
    if isFile(processedDir .. "/init.luau") then
        table.insert(
            lines,
            `local {var} = node("ModuleScript", "{name}", {parentVar}, {longString(
                fs.readFileToString(processedDir .. "/init.luau")
            )})`
        )
    else
        table.insert(lines, `local {var} = node("Folder", "{name}", {parentVar}, nil)`)
    end
    const entries: { string } = {}
    for _, entry in fs.listDirectory(processedDir) do
        table.insert(entries, entry.name)
    end
    table.sort(entries)
    for _, entryName in entries do
        const childRel = relPath .. "/" .. entryName
        if isDir(`{workDir}/{childRel}`) then
            if dirWanted(childRel) then
                emitDir(childRel, entryName, var)
            end
        elseif entryName ~= "init.luau" and string.sub(entryName, -5) == ".luau" and wanted(childRel) then
            const moduleName = string.sub(entryName, 1, -6)
            table.insert(
                lines,
                `node("ModuleScript", "{moduleName}", {var}, {longString(fs.readFileToString(`{workDir}/{childRel}`))})`
            )
        end
    end
    return var
end

-- 트리 구성부터 모듈 실행까지를 전부 하나의 pcall 안에 넣는다. 트리를 만드는 도중(Source 대입 등)에
-- 실패하더라도 로그 연결 해제와 root:Destroy() 는 반드시 실행되어야 하기 때문이다.
table.insert(lines, "local logs = {}")
table.insert(
    lines,
    'local connection = game:GetService("LogService").MessageOut:Connect(function(message, messageType) table.insert(logs, `[{messageType.Name}] {message}`) end)'
)
table.insert(lines, 'local root = Instance.new("Folder")')
table.insert(lines, 'root.Name = "tbox_studio_test"')
table.insert(lines, "local ok, err = pcall(function()")
table.insert(lines, "local function node(className, name, parent, source)")
table.insert(lines, "\tlocal instance = Instance.new(className)")
table.insert(lines, "\tinstance.Name = name")
table.insert(lines, "\tif source then instance.Source = source end")
table.insert(lines, "\tinstance.Parent = parent")
table.insert(lines, "\treturn instance")
table.insert(lines, "end")
emitDir("src", "src", "root")
emitDir("test", "test", "root")

-- 모듈을 순서대로 실행한다. 모듈 안의 에러는 require 가 "Requested module experienced an error" 로
-- 뭉개버리므로, 실제 메시지는 LogService 로 받은 출력에서 확인한다.
const quoted = {}
for _, modulePath in modules do
    table.insert(quoted, `"{modulePath}"`)
end
table.insert(lines, "local function find(path)")
table.insert(lines, "\tlocal target = root")
table.insert(
    lines,
    '\tfor part in string.gmatch(path, "[^/]+") do target = target:FindFirstChild(part) or error(`module not found: {path}`) end'
)
table.insert(lines, "\treturn target")
table.insert(lines, "end")
table.insert(lines, `for _, path in \{ {table.concat(quoted, ", ")} } do`)
table.insert(lines, "\tprint(`[part] {path}`)")
table.insert(lines, "\trequire(find(path))")
table.insert(lines, "end")
-- all 은 test/studio/run 이 직접 출력하므로 분할 파트일 때만 pending 목록을 출력한다
if partName ~= "all" then
    table.insert(lines, 'local discrepancies = require(find("test/helper")).knownDiscrepancies')
    table.insert(lines, "print(`[part] known discrepancies: {#discrepancies}`)")
    table.insert(lines, "for _, entry in discrepancies do warn(`[pending] {entry}`) end")
end
table.insert(lines, "end)")
table.insert(lines, "task.wait()")
table.insert(lines, "connection:Disconnect()")
table.insert(lines, "root:Destroy()")
table.insert(
    lines,
    `return (if ok then "RESULT: OK ({partName})" else \`RESULT: FAIL ({partName}) \{err}\`) .. "\\n" .. table.concat(logs, "\\n")`
)

fs.removeDirectory(workDir, { recursive = true })
fs.remove(workDir .. ".json")
print(table.concat(lines, "\n"))
