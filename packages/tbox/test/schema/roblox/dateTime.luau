--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/dateTime")

Helper.expectFail(Type:runtimeTypeCheck(Type.DateTime(), 123), "DateTime expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.DateTime()), "DateTime")
Helper.expectEqual(Type:format(Type.DateTime()), "TDateTime")

const schema = Type.DateTime({ minUnixTimestampMillis = 0, maxUnixTimestampMillis = 1000, wholeSecondsOnly = true })

Helper.expectOk(Def.runtimeConstraintChecker(schema, { UnixTimestampMillis = 0 }))
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { UnixTimestampMillis = 1500 }),
	"datetime too far in the future. maximum allowed unix timestamp millis is 1000"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { UnixTimestampMillis = -500 }),
	"datetime too far in the past. minimum allowed unix timestamp millis is 0"
)

const wholeSecondsSchema = Type.DateTime({ wholeSecondsOnly = true })
Helper.expectFail(
	Def.runtimeConstraintChecker(wholeSecondsSchema, { UnixTimestampMillis = 1234 }),
	"datetime must not have sub-second precision, but got 1234 unix timestamp millis"
)

-- Roblox 지원 범위 (대략 서기 1400 ~ 9999년) 밖은 withinRobloxRange 를 켰을 때만 걸러진다
const rangedSchema = Type.DateTime({ withinRobloxRange = true })
Helper.expectOk(Def.runtimeConstraintChecker(rangedSchema, { UnixTimestampMillis = 0 }))
Helper.expectFail(
	Def.runtimeConstraintChecker(rangedSchema, { UnixTimestampMillis = 300000000000000 }),
	"datetime out of roblox supported range (-17987443200000 ~ 253402300799999 unix timestamp millis)"
)

return true
