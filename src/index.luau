--!strict
const Types = require("./types")

const String = require("./schema/string")
const Object = require("./schema/object")
const Number = require("./schema/number")
const Boolean = require("./schema/boolean")
const Unsafe = require("./schema/unsafe")
const Any = require("./schema/any")

const Default = require("./schema/default")
const Optional = require("./schema/optional")
const Singleton = require("./schema/singleton")

const Array = require("./schema/array")
-- const Map

export type Static<T> = Types.Static<T>

export type TString = String.TString
export type TStringOptions = String.TStringOptions
export type TObject<Props> = Object.TObject<Props>
export type TObjectOptions = Object.TObjectOptions
export type TNumber = Number.TNumber
export type TNumberOptions = Number.TNumberOptions
export type TBoolean = Boolean.TBoolean
export type TBooleanOptions = Boolean.TBooleanOptions
export type TUnsafe<T> = Unsafe.TUnsafe<T>
export type TUnsafeOptions = Unsafe.TUnsafeOptions
export type TAny = Any.TAny
export type TAnyOptions = Any.TAnyOptions

export type TDefault<InnerSchema> = Default.TDefault<InnerSchema>
export type TDefaultOptions = Default.TDefaultOptions
export type TOptional<InnerSchema> = Optional.TOptional<InnerSchema>
export type TOptionalOptions = Optional.TOptionalOptions
export type TSingleton<ConstType> = Singleton.TSingleton<ConstType>
export type TSingletonOptions = Singleton.TSingletonOptions

export type TArray<InnerSchema> = Array.TArray<InnerSchema>
export type TArrayOptions = Array.TArrayOptions

const registry = require("./registry")

const defaultNs = registry.defaultUntypedNamespace
    :registerType(String)
    :registerType(Object)
    :registerType(Number)
    :registerType(Boolean)
    :registerType(Unsafe)
    :registerType(Any)
    :registerType(Default)
    :registerType(Optional)
    :registerType(Singleton)
    :registerType(Array) :: registry.TypeNamespace & {
    String: typeof(String.factoryFunc),
    Object: typeof(Object.factoryFunc),
    Number: typeof(Number.factoryFunc),
    Boolean: typeof(Boolean.factoryFunc),
    Unsafe: typeof(Unsafe.factoryFunc),
    Any: typeof(Any.factoryFunc),
    Default: typeof(Default.factoryFunc),
    Optional: typeof(Optional.factoryFunc),
    Singleton: typeof(Singleton.factoryFunc),
    Array: typeof(Array.factoryFunc),
}

return defaultNs
