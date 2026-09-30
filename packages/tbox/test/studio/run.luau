--!strict

-- Roblox Studio 전용 진입점. scripts/studio-bundle.luau 가 만든 청크가 이 모듈을 require 한다.
-- standalone luau 에서는 Roblox 전역이 없어 실행할 수 없으므로 test/run.luau 는 이 디렉터리를 require 하지 않는다.
-- 주의: Studio MCP 의 execute_luau 는 요청 크기 제한(약 100KB) 때문에 이 진입점 전체를 한 번에 받지 못한다.
-- 그 경로에서는 스크립트의 cli-core / cli-roblox / studio 파트로 나눠 돌린다 (scripts/studio-bundle.luau 머리말 참고).
--
-- 1. CLI 스위트 전체(test/run.luau)를 먼저 그대로 돌린다 — Roblox 안에서도 통과해야 한다.
-- 2. test/schema/roblox/* 가 mock 테이블로 확인한 시나리오를 실제 Roblox 값으로 다시 돌린다 (test/studio/roblox/*).
--    mock 으로는 태울 수 없던 typeof 분기(Instance 클래스 판별, EnumItem 의 EnumType 판별 등)도 여기서 확인한다.
-- 3. 실제 동작 때문에 드러났지만 src 수정 여부가 아직 결정되지 않은 불일치(Helper.pending)를 모아 출력한다.
-- require 대상은 test/run.luau 와 같은 이유로 항상 문자열 리터럴로 적는다.

const Helper = require("../helper")

require("../run")

print("[studio] Vector2")
require("./roblox/vector2")

print("[studio] Vector3")
require("./roblox/vector3")

print("[studio] CFrame")
require("./roblox/cframe")

print("[studio] Color3")
require("./roblox/color3")

print("[studio] ColorSequence")
require("./roblox/colorSequence")

print("[studio] ColorSequenceKeypoint")
require("./roblox/colorSequenceKeypoint")

print("[studio] NumberRange")
require("./roblox/numberRange")

print("[studio] NumberSequence")
require("./roblox/numberSequence")

print("[studio] NumberSequenceKeypoint")
require("./roblox/numberSequenceKeypoint")

print("[studio] Rect")
require("./roblox/rect")

print("[studio] Region3")
require("./roblox/region3")

print("[studio] UDim")
require("./roblox/udim")

print("[studio] UDim2")
require("./roblox/udim2")

print("[studio] DateTime")
require("./roblox/dateTime")

print("[studio] Instance")
require("./roblox/instance")

print("[studio] Enum")
require("./roblox/enum")

print("[studio] EnumItem")
require("./roblox/enumItem")

-- pending 은 실패로 치지 않는다. 결정이 필요한 항목으로 보고만 한다.
print(`[studio] known discrepancies: {#Helper.knownDiscrepancies}`)
for _, entry in Helper.knownDiscrepancies do
    warn(`[pending] {entry}`)
end

print("all studio tests passed.")

return true
