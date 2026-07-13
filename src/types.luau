--!strict

export type InnerType<T> = { __inner: T }

-- Schema 의 __inner: T 를 얻습니다
export type function Static(target: type): type
    if target:is("intersection") or target:is("union") then
        for _, comp in target:components() do
            const recursive: type = Static(comp)
            if not recursive:is("never") then
                return recursive
            end
        end
    elseif target:is("table") then
        return target:readproperty(types.singleton("__inner")) or types.never
    end

    return types.never
end

-- Object props 부분을 받아 내부 요소에 대해 Static 을 가한
-- props 를 얻습니다.
export type function TObjectPropsFlatten(inner: type): type
    if inner:is("any") then
        return types.newtable()
    end

    const propList: { [type]: { read: type?, write: type? } } = {}
    for key, value in inner:properties() do
        const prop: { read: type?, write: type? } = {}
        if value.read then
            prop.read = Static(value.read)
        end
        if value.write then
            prop.write = Static(value.write)
        end
        propList[key] = prop
    end
    return types.newtable(propList)
end

-- ({} & {}) | nil 상황에서 내부 & 조인을 Merge 하지 않으면
-- 문제가 발생합니다. 따라서 합쳐 문제를 해결합니다.
export type function MergeInner(fn: type): type
    const head: { type } = fn:parameters().head or {}
    const tbl = types.newtable()

    for _, param in head do
        for key, prop in param:properties() do
            if prop.read and prop.write and prop.read == prop.write then
                tbl:setproperty(key, prop.read)
            else
                if prop.read then
                    tbl:setreadproperty(key, prop.read)
                end
                if prop.write then
                    tbl:setwriteproperty(key, prop.write)
                end
            end
        end
    end

    return tbl
end
export type Merge<T...> = MergeInner<(T...) -> ()>

-- 함수나 union 등에서 여러 타입을 받기 위한 tuple 구조
-- 내부에 타입을 TupleType 으로 보존하면서, 받은 런타임 인자를
-- [number]: any 에 저장합니다.
export type TupleType<Components...> = (Components...) -> ()
export type Tuple<Components...> = { [number]: any, n: number, _tup: TupleType<Components...> }
const function Tuple<Components...>(...: Components...): Tuple<Components...>
    return table.pack<<any>>(...) :: Tuple<Components...>
end
export type function GetTupleType(tup: type): type
    if tup:is("any") then
        return types.any
    end
    const inner = tup:readproperty(types.singleton("_tup"))
    if not inner then
        print("GetTupleType: tup is not tuple")
        return types.never
    end
    return inner
end

-- TupleType 내부 요소를 Schema 라고 가정 후 __inner: T 를 얻어 새로운
-- TupleType<T...> 를 생성합니다
export type function StaticTuple(tupty: type): type
    if tupty:is("any") then
        return types.newfunction({ head = { types.any } })
    end
    const head: { type } = tupty:parameters().head or {}
    const staticHead = table.create(#head) :: { type }
    for _, innerType in head do
        table.insert(staticHead, Static(innerType) :: type)
    end
    return types.newfunction({ head = staticHead })
end

return { Tuple = Tuple }
