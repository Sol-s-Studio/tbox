--!strict

-- pesde 는 [scripts] 를 항상 Lune 런타임으로 실행하지만, 이 저장소는 `const` 지역 선언
-- 문법(코드 스타일 참고)을 전역적으로 쓰고 Lune 0.8.9 는 이를 파싱하지 못한다
-- (repo CLAUDE.md "알려진 이슈" 참고). 그래서 이 파일 자체는 `const` 없이 순수 Lune 호환
-- 문법으로 작성하고, 실제 테스트 실행은 `const` 를 지원하는 luau CLI 서브프로세스에 위임한다.

local process = require("@lune/process")

local result = process.exec("luau", { "test/run.luau" }, { stdio = "forward" })

-- process.exit() 로 종료하면 pesde 가 내장한 lune 스케줄러가 패닉을 일으킨다
-- (pesde 0.7.3 + lune 0.8.9 조합의 알려진 문제). error() 로 실패를 알리는 것으로 대신한다.
if not result.ok then
	error(`test/run.luau exited with code {result.code}`)
end
