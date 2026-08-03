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

return Helper
