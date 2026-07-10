--!strict

export type InnerType<T> = { __inner: T }

-- hasDefault 를 적용하여 __inner: T 를 얻습니다
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

return {}
