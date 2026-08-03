--!strict

const Type = require("../../../src")
const Helper = require("../../helper")

-- 실사용 예: Type.Instance<<BasePart>>("BasePart"). 클래스 판별(IsA/ClassName)에 필요한
-- 메서드만 흉내낸 목(mock) Instance 를 사용해 확인한다.
const function mockInstance(className: string, name: string, isA: (className: string) -> boolean, children: { string }?)
	const instance = { ClassName = className, Name = name }
	function instance.IsA(_self, target: string): boolean
		return isA(target)
	end
	function instance.FindFirstChild(_self, childName: string): boolean
		for _, child in children or {} do
			if child == childName then
				return true
			end
		end
		return false
	end
	return instance
end

const schema = Type.Instance("BasePart")
Helper.expectFail(Type:runtimeTypeCheck(schema, 123), "Instance expected, but got number")
Helper.expectEqual(Type:luauBuild(schema), "BasePart")
Helper.expectEqual(Type:format(schema), "TInstance<BasePart>")

const exact = Type.Instance("Part", { exactClassName = true })
Helper.expectEqual(Type:luauBuild(exact), "Part")

-- 주의: IsA/ClassName 을 사용한 클래스 판별은 runtimeTypeChecker 안에서
-- typeof(value) == "Instance" 를 먼저 확인한 뒤에 이뤄진다. 목(mock) 테이블의 typeof 는 항상
-- "table" 이라 이 분기는 standalone luau 에서 재현할 수 없다 (repo CLAUDE.md 참고).
-- nameMatch/requiredChildren 은 runtimeConstraintChecker 에 있고 typeof 를 보지 않으므로
-- 여기서 직접 확인할 수 있다.
const constrained = Type.Instance("BasePart", { nameMatch = "^Part%d+$", requiredChildren = { "Highlight" } })
const isBasePart = function()
	return true
end
Helper.expectOk(Type:runtimeConstraintCheck(constrained, mockInstance("Part", "Part1", isBasePart, { "Highlight" })))
Helper.expectFail(
	Type:runtimeConstraintCheck(constrained, mockInstance("Part", "NotAPart", isBasePart, { "Highlight" })),
	"Instance name 'NotAPart' does not match pattern '^Part%d+$'"
)
Helper.expectFail(
	Type:runtimeConstraintCheck(constrained, mockInstance("Part", "Part1", isBasePart, {})),
	"Instance is missing required child 'Highlight'"
)

return true
