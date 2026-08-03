--!strict

-- src/schema/* 를 1:1로 미러링하는 test/schema/* 를 전부 require 해 스모크 테스트를 실행한다.
-- 각 테스트 모듈은 require 되는 시점에 자신의 어서션을 즉시 실행하고, 실패하면 error() 로
-- 그 자리에서 중단된다 (정식 테스트 프레임워크는 두지 않기로 했다 - 레포 루트 CLAUDE.md 참고).
-- require 대상은 항상 문자열 리터럴로 명시한다 (동적 경로는 이 luau 빌드의 require 캐시에서
-- "could not reset to requiring context (ambiguous)" 오류를 일으킨다).
-- 새 스키마 타입을 추가하면 이 목록에도 동일한 순서로 추가할 것.

print("[test] Any")
require("./schema/any")

print("[test] Boolean")
require("./schema/boolean")

print("[test] Nil")
require("./schema/nil")

print("[test] String")
require("./schema/string")

print("[test] Number")
require("./schema/number")

print("[test] Vector")
require("./schema/vector")

print("[test] Unsafe")
require("./schema/unsafe")

print("[test] Singleton")
require("./schema/singleton")

print("[test] Optional")
require("./schema/optional")

print("[test] Union")
require("./schema/union")

print("[test] Map")
require("./schema/map")

print("[test] Object")
require("./schema/json/object")

print("[test] Array")
require("./schema/json/array")

print("[test] Merge")
require("./schema/json/merge")

print("[test] Vector2")
require("./schema/roblox/vector2")

print("[test] Vector3")
require("./schema/roblox/vector3")

print("[test] CFrame")
require("./schema/roblox/cframe")

print("[test] Color3")
require("./schema/roblox/color3")

print("[test] ColorSequence")
require("./schema/roblox/colorSequence")

print("[test] ColorSequenceKeypoint")
require("./schema/roblox/colorSequenceKeypoint")

print("[test] NumberRange")
require("./schema/roblox/numberRange")

print("[test] NumberSequence")
require("./schema/roblox/numberSequence")

print("[test] NumberSequenceKeypoint")
require("./schema/roblox/numberSequenceKeypoint")

print("[test] Rect")
require("./schema/roblox/rect")

print("[test] Region3")
require("./schema/roblox/region3")

print("[test] UDim")
require("./schema/roblox/udim")

print("[test] UDim2")
require("./schema/roblox/udim2")

print("[test] DateTime")
require("./schema/roblox/dateTime")

print("[test] Instance")
require("./schema/roblox/instance")

print("[test] Enum")
require("./schema/roblox/enum")

print("[test] EnumItem")
require("./schema/roblox/enumItem")

print("all schema tests passed.")
