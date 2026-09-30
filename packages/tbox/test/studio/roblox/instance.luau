--!strict

-- test/schema/roblox/instance.luau 의 mock 시나리오를 실제 Instance 로 다시 돌리고, mock 으로는 도달할 수 없었던
-- 타입 검사 안의 클래스 판별(IsA / exactClassName) 분기를 확인한다.
-- 모든 Instance 는 Common.withInstances 로 부모 nil 상태에서 만들고 끝나면 Destroy 한다.
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

const basePart = Type.Instance("BasePart")
Helper.expectFail(Type:runtimeTypeCheck(basePart, 123), "Instance expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(basePart, Vector3.new()), "Instance expected, but got Vector3")
Helper.expectFail(Type:runtimeTypeCheck(basePart, nil), "Instance expected, but got nil")
Helper.expectEqual(Type:luauBuild(basePart), "BasePart")
Helper.expectEqual(Type:format(basePart), "TInstance<BasePart>")

Common.withInstances(function(make)
    const part = make("Part", "Part1")
    const wedge = make("WedgePart", "Wedge")
    const folder = make("Folder", "Folder")
    const model = make("Model", "Model")

    -- 기본(IsA) 판별은 하위 클래스도 받는다
    Helper.expectOk(Type:runtimeTypeCheck(basePart, part))
    Helper.expectOk(Type:runtimeTypeCheck(basePart, wedge))
    Helper.expectFail(
        Type:runtimeTypeCheck(basePart, folder),
        "Instance of class 'BasePart' (or subclass) expected, but got 'Folder'"
    )

    -- 클래스명을 생략하면 "Instance" 이고, IsA("Instance") 는 모든 Instance 에 대해 참이다
    const anyInstance = Type.Instance()
    Helper.expectEqual(Type:luauBuild(anyInstance), "Instance")
    Helper.expectOk(Common.check(anyInstance, part))
    Helper.expectOk(Common.check(anyInstance, folder))

    -- exactClassName 은 ClassName 이 정확히 같아야 한다. 하위 클래스도, 추상 상위 클래스 이름도 거부한다
    const exactPart = Type.Instance("Part", { exactClassName = true })
    Helper.expectOk(Common.check(exactPart, part))
    Helper.expectFail(Type:runtimeTypeCheck(exactPart, wedge), "Instance of class 'Part' expected, but got 'WedgePart'")
    Helper.expectFail(
        Type:runtimeTypeCheck(Type.Instance("BasePart", { exactClassName = true }), part),
        "Instance of class 'BasePart' expected, but got 'Part'"
    )

    -- 존재하지 않는 클래스명은 IsA 가 에러 없이 false 를 돌려주므로(Studio 에서 확인) 그냥 타입 검사 실패가 된다
    Helper.expectFail(
        Type:runtimeTypeCheck(Type.Instance("NotARealClass"), part),
        "Instance of class 'NotARealClass' (or subclass) expected, but got 'Part'"
    )

    -- 클래스 판별이 타입 검사에 있으므로 유니온 분기 선택에 쓰인다. 제약 검사도 선택된 분기의 것을 따른다.
    const partOrModel = Type.Union(
        Type.Tuple(Type.Instance("BasePart", { nameMatch = "^Part%d+$" }), Type.Instance("Model", { nameMatch = "^M" }))
    )
    Helper.expectOk(Common.check(partOrModel, part))
    Helper.expectOk(Common.check(partOrModel, model))
    Helper.expectFail(
        Type:runtimeTypeCheck(partOrModel, folder),
        "union value check failed. value did not match any of the union members.\n"
            .. "  branch 1: Instance of class 'BasePart' (or subclass) expected, but got 'Folder'\n"
            .. "  branch 2: Instance of class 'Model' (or subclass) expected, but got 'Folder'"
    )
    Helper.expectFail(Common.check(partOrModel, wedge), "Instance name 'Wedge' does not match pattern '^Part%d+$'")
end)

-- nameMatch / requiredChildren 을 실제 자식 트리로 확인한다
Common.withInstances(function(make)
    const constrained = Type.Instance("BasePart", { nameMatch = "^Part%d+$", requiredChildren = { "Highlight" } })

    const withChild = make("Part", "Part1")
    make("Highlight", "Highlight", withChild)
    Helper.expectOk(Common.check(constrained, withChild))

    const badName = make("Part", "NotAPart")
    make("Highlight", "Highlight", badName)
    Helper.expectFail(Common.check(constrained, badName), "Instance name 'NotAPart' does not match pattern '^Part%d+$'")

    const noChild = make("Part", "Part2")
    Helper.expectFail(Common.check(constrained, noChild), "Instance is missing required child 'Highlight'")

    -- requiredChildren 은 FindFirstChild(name) 만 보므로 이름만 같으면 클래스는 따지지 않고,
    -- 손자(재귀)는 보지 않는다
    const wrongClassChild = make("Part", "Part3")
    make("Folder", "Highlight", wrongClassChild)
    Helper.expectOk(Common.check(constrained, wrongClassChild))

    const grandChild = make("Part", "Part4")
    const middle = make("Folder", "Middle", grandChild)
    make("Highlight", "Highlight", middle)
    Helper.expectFail(Common.check(constrained, grandChild), "Instance is missing required child 'Highlight'")
end)

return true
