--!strict

-- test/studio/roblox/* 가 공통으로 쓰는 보조 함수. 이 디렉터리는 Roblox Studio 에서만 돌린다
-- (scripts/studio-bundle.luau 참고). test/run.luau 는 이 디렉터리를 require 하지 않는다.
const Type = require("../../src")

const Common = {}

-- 실제 값은 반드시 Type:runtimeTypeCheck 를 먼저 통과해야 한다. mock 테이블로는 typeof 분기를
-- 태울 수 없었다는 것이 이 스위트를 따로 둔 이유이므로, 제약 검사만 따로 부르지 않고 항상 이 경로를 거친다.
-- 타입 검사를 통과하면 Type:runtimeConstraintCheck 의 결과를 돌려주어 expectOk/expectFail 로 이어 쓴다.
function Common.check(schema: any, value: any): (() -> string)?
    const typeCheck = Type:runtimeTypeCheck(schema, value)
    if typeCheck then
        error(`expected the type check to pass before the constraint check, but it failed with: {typeCheck()}`, 2)
    end
    return Type:runtimeConstraintCheck(schema, value)
end

-- 테스트용 Instance 는 부모를 nil 로 둔 채(DataModel 에 절대 붙이지 않음) 만들고, 본문이 실패하더라도
-- 반드시 Destroy 한다. Studio 는 저장소가 아니므로 플레이스에 어떤 흔적도 남기지 않기 위해서다.
-- body 는 make(className, name, parent?) 로 인스턴스를 만든다. 만든 순서의 역순으로 정리한다.
function Common.withInstances(body: (make: (className: string, name: string, parent: Instance?) -> Instance) -> ())
    const created: { Instance } = {}
    const function make(className: string, name: string, parent: Instance?): Instance
        const instance = Instance.new(className)
        table.insert(created, instance)
        instance.Name = name
        instance.Parent = parent
        return instance
    end

    const ok, err = pcall(body, make)
    for index = #created, 1, -1 do
        created[index]:Destroy()
    end
    if not ok then
        -- 원래 에러 메시지(어서션 위치 포함)를 그대로 다시 던진다
        error(err, 0)
    end
end

return Common
