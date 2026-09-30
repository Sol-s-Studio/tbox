--!strict

-- 테스트 전용 최소 어서션 헬퍼. 정식 테스트 프레임워크는 두지 않기로 했으므로
-- (레포 루트 CLAUDE.md 참고) 실패 시 그냥 error() 로 즉시 중단시키는 것으로 충분하다.

const Helper = {}

-- 클로저가 실패를 반환하되, 그 실패 메시지가 정확히 expected 와 일치하는지 확인한다
function Helper.expectFail(check: (() -> string)?, expected: string)
    if not check then
        error(`expected a failure (message: "{expected}"), but the check passed`, 2)
    end
    const message = check()
    if message ~= expected then
        error(`expected failure message:\n  {expected}\nbut got:\n  {message}`, 2)
    end
end

-- 클로저가 nil(성공)을 반환하는지 확인한다
function Helper.expectOk(check: (() -> string)?)
    if check then
        error(`expected success, but the check failed with: {check()}`, 2)
    end
end

-- 클로저 대신 error() 로 실패하는 API(네임스페이스 조회 등)용. fn 이 에러를 던지고, 그 메시지가
-- expected 로 끝나는지 확인한다. error() 가 앞에 붙이는 "파일:줄: " 위치 정보는 비교하지 않는다.
function Helper.expectError(fn: () -> (), expected: string)
    const ok, err = pcall(fn)
    if ok then
        error(`expected an error (message: "{expected}"), but it succeeded`, 2)
    end
    const message = tostring(err)
    if string.sub(message, -#expected) ~= expected then
        error(`expected error message ending with:\n  {expected}\nbut got:\n  {message}`, 2)
    end
end

-- 소스 문자열을 컴파일해 함수로 돌려준다. 실패하면 nil 과 컴파일 에러 메시지를 돌려준다 (loadstring 과 같은 모양).
-- 이 스위트는 luau CLI, Lute, Roblox Studio 에서 모두 돌아야 하는데, Lute 에는 전역 loadstring 이 없어서
-- 대신 @lute/luau 의 compile/load 를 쓴다 (compile 은 항상 성공하고 문법 에러는 load 에서 난다).
function Helper.loadChunk(source: string): ((...any) -> ...any, string?)
    const globalLoadstring: any = (_G :: any).loadstring or (loadstring :: any)
    if globalLoadstring then
        return (globalLoadstring :: any)(source)
    end
    const luau = (require :: any)("@lute/luau")
    const ok, result = pcall(luau.load, luau.compile(source), "chunk")
    if not ok then
        return nil :: any, tostring(result)
    end
    return result, nil
end

-- luauBuild 결과가 Luau 타입 문법으로 파싱되는지 확인한다. 컴파일만 하므로 이름 해석이나 타입 검사는
-- 하지 않는다 — Roblox 타입 이름(Vector3 등)이 이 환경에 없어도 통과한다.
function Helper.expectParsableType(source: string)
    const chunk, err = Helper.loadChunk(`type T = {source}\nreturn nil`)
    if not chunk then
        error(`generated luau type does not parse:\n  {source}\n  {err}`, 2)
    end
end

-- 두 값이 정확히 같은지 확인한다 (luauBuild/format 결과 비교용)
function Helper.expectEqual(actual: any, expected: any)
    if actual ~= expected then
        error(`expected:\n  {expected}\nbut got:\n  {actual}`, 2)
    end
end

-- condition 이 참인지 확인한다
function Helper.expectTrue(condition: boolean, message: string)
    if not condition then
        error(message, 2)
    end
end

-- 실제 환경(Roblox Studio 등)에서 드러났지만 아직 src 를 고칠지 결정하지 않은 불일치를 모아두는 목록.
-- 이런 기대값을 그냥 어서션으로 쓰면 스위트 전체가 멈춰서 나머지 검사를 못 돌리게 되고, 반대로 지워버리면
-- 문제가 잊힌다. 그래서 실패를 여기에 기록만 하고 진행하며, 진입 스크립트(test/studio/run.luau)가
-- 마지막에 목록을 출력한다.
Helper.knownDiscrepancies = {} :: { string }

-- fn 안의 어서션은 "올바른 동작이라면 이래야 한다" 는 기대값이다. 실패하면 description 과 함께 기록하고
-- 계속 진행한다. 통과하면 src 가 고쳐졌다는 뜻이므로 pending 을 풀라는 메모를 남긴다.
function Helper.pending(description: string, fn: () -> ())
    const ok, err = pcall(fn)
    if ok then
        table.insert(Helper.knownDiscrepancies, `[resolved? remove pending] {description}`)
    else
        table.insert(Helper.knownDiscrepancies, `{description}\n    {tostring(err)}`)
    end
end

return Helper
