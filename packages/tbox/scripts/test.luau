--!strict

-- pesde 는 [scripts] 를 Lune 런타임으로 실행하지만, 이 저장소는 `const` 지역 선언 문법(코드 스타일
-- 참고)을 전역적으로 쓰고 Lune 은 이를 파싱하지 못한다 (0.10.5 에서도 확인). 그래서 이 파일 자체는
-- `const` 없이 순수 Lune 호환 문법으로 작성하고, 실제 테스트 실행은 `const` 를 지원하는 luau CLI
-- 서브프로세스에 위임한다. Lune 버전은 pesde.toml 의 [engines] 로 고정한다 (process.exec 는 0.9 부터).

local process = require("@lune/process")

local result = process.exec("luau", { "test/run.luau" }, { stdio = "forward" })

-- luau 의 종료 코드를 그대로 돌려준다. 실패 내용은 luau 가 이미 출력했으므로 error() 로 Lune 스택을 덧붙이지 않는다
process.exit(result.code)
