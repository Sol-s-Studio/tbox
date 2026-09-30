--!strict

-- test/schema/roblox/rect.luau 의 mock 시나리오를 실제 Rect 로 다시 돌린다
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

Helper.expectOk(Type:runtimeTypeCheck(Type.Rect(), Rect.new()))
Helper.expectFail(Type:runtimeTypeCheck(Type.Rect(), 123), "Rect expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(Type.Rect(), Vector2.new(1, 2)), "Rect expected, but got Vector2")

const schema = Type.Rect({ normalizedOnly = true, maxWidth = 10, minWidth = 1, maxHeight = 10, minHeight = 1 })

Helper.expectOk(Common.check(schema, Rect.new(0, 0, 5, 5)))
Helper.expectOk(Common.check(schema, Rect.new(Vector2.new(0, 0), Vector2.new(5, 5))))

-- RobloxApi.md 는 "Rect.new 는 Min <= Max 를 강제하지 않는다" 고 적었지만, 실제 엔진은 두 생성자 모두
-- 모서리를 정규화해서 저장한다 (Studio 에서 확인: Rect.new(5, 0, 0, 5) → Min (0, 0), Max (5, 5)).
-- 그래서 mock 의 "정규화되지 않은 Rect" 는 실제로 만들 수 없고, 같은 입력은 normalizedOnly 를 통과한다.
const swapped = Rect.new(5, 0, 0, 5)
Helper.expectEqual(swapped.Min, Vector2.new(0, 0))
Helper.expectEqual(swapped.Max, Vector2.new(5, 5))
Helper.expectOk(Common.check(schema, swapped))
Helper.expectOk(Common.check(schema, Rect.new(Vector2.new(5, 0), Vector2.new(0, 5))))

Helper.expectFail(Common.check(schema, Rect.new(0, 0, 20, 5)), "width too big. maximum allowed width is 10")
Helper.expectFail(Common.check(schema, Rect.new(0, 0, 0.5, 5)), "width too small. minimum allowed width is 1")
Helper.expectFail(Common.check(schema, Rect.new(0, 0, 5, 20)), "height too big. maximum allowed height is 10")
Helper.expectFail(Common.check(schema, Rect.new(0, 0, 5, 0.5)), "height too small. minimum allowed height is 1")

const bounded = Type.Rect({ min = Vector2.new(0, 0), max = Vector2.new(10, 10) })
Helper.expectOk(Common.check(bounded, Rect.new(0, 0, 10, 10)))
Helper.expectFail(Common.check(bounded, Rect.new(0, 0, 20, 5)), "max.x too big. maximum allowed max.x value is 10")
Helper.expectFail(Common.check(bounded, Rect.new(-1, 0, 5, 5)), "min.x too small. minimum allowed min.x value is 0")
Helper.expectFail(Common.check(bounded, Rect.new(0, 0, 5, 11)), "max.y too big. maximum allowed max.y value is 10")

return true
