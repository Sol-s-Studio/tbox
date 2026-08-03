--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/cframe")

Helper.expectFail(Type:runtimeTypeCheck(Type.CFrame(), 123), "CFrame expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.CFrame()), "CFrame")
Helper.expectEqual(Type:format(Type.CFrame()), "TCFrame")

const function mockVector3(x: number, y: number, z: number)
	const v = { X = x, Y = y, Z = z, Magnitude = math.sqrt(x * x + y * y + z * z) }
	function v.Cross(self, other)
		return mockVector3(
			self.Y * other.Z - self.Z * other.Y,
			self.Z * other.X - self.X * other.Z,
			self.X * other.Y - self.Y * other.X
		)
	end
	function v.Dot(self, other)
		return self.X * other.X + self.Y * other.Y + self.Z * other.Z
	end
	return v
end

-- 정규직교 검사는 Rotation:FuzzyEq(Rotation:Orthonormalize(), eps) 하나만 호출하므로,
-- 결과를 그대로 흉내낸다
const function mockRotation(isOrthonormal: boolean)
	const rotation = {}
	function rotation.Orthonormalize(_self)
		return "orthonormalized"
	end
	function rotation.FuzzyEq(_self, _other, _eps)
		return isOrthonormal
	end
	return rotation
end

-- rightHandedOnly 는 XVector:Cross(YVector):Dot(ZVector) 의 부호만 본다
const function mockCFrame(
	position: { X: number, Y: number, Z: number, Magnitude: number },
	isOrthonormal: boolean,
	isRightHanded: boolean
)
	return {
		Position = position,
		Rotation = mockRotation(isOrthonormal),
		XVector = mockVector3(1, 0, 0),
		YVector = mockVector3(0, 1, 0),
		ZVector = if isRightHanded then mockVector3(0, 0, 1) else mockVector3(0, 0, -1),
	}
end

const schema = Type.CFrame({
	positionMin = mockVector3(0, 0, 0) :: any,
	positionMax = mockVector3(10, 10, 10) :: any,
	minPositionMagnitude = 1,
	maxPositionMagnitude = 20,
	notNan = true,
})

Helper.expectOk(Def.runtimeConstraintChecker(schema, mockCFrame(mockVector3(5, 5, 5), true, true)))
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockCFrame(mockVector3(0 / 0, 0, 0), true, true)),
	"nan is not allowed in cframe position"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockCFrame(mockVector3(20, 0, 0), true, true)),
	"position x value too big. maximum allowed x value is 10"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockCFrame(mockVector3(-1, 5, 5), true, true)),
	"position x value too small. minimum allowed x value is 0"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockCFrame(mockVector3(0.1, 0.1, 0.1), true, true)),
	"position too close to origin. minimum allowed magnitude is 1"
)

const orthonormalOnly = Type.CFrame({ orthonormalOnly = true })
Helper.expectOk(Def.runtimeConstraintChecker(orthonormalOnly, mockCFrame(mockVector3(0, 0, 0), true, true)))
Helper.expectFail(
	Def.runtimeConstraintChecker(orthonormalOnly, mockCFrame(mockVector3(0, 0, 0), false, true)),
	"cframe rotation must be orthonormal"
)

const rightHandedOnly = Type.CFrame({ rightHandedOnly = true })
Helper.expectOk(Def.runtimeConstraintChecker(rightHandedOnly, mockCFrame(mockVector3(0, 0, 0), true, true)))
Helper.expectFail(
	Def.runtimeConstraintChecker(rightHandedOnly, mockCFrame(mockVector3(0, 0, 0), true, false)),
	"cframe rotation must be right-handed. mirrored rotation is not allowed"
)

return true
