--!strict
const Types = require("@self/types")

const String = require("@self/schema/string")
const Object = require("@self/schema/json/object")
const Number = require("@self/schema/number")
const Boolean = require("@self/schema/boolean")
const Unsafe = require("@self/schema/unsafe")
const Nil = require("@self/schema/nil")
const Any = require("@self/schema/any")

const Optional = require("@self/schema/optional")
const Singleton = require("@self/schema/singleton")

const Array = require("@self/schema/json/array")
const Union = require("@self/schema/union")
const Map = require("@self/schema/map")

export type Static<T> = Types.Static<T>
export type Tuple<Components...> = Types.Tuple<Components...>

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
export type TNil = Nil.TNil
export type TNilOptions = Nil.TNilOptions
export type TAny = Any.TAny
export type TAnyOptions = Any.TAnyOptions

export type TOptional<InnerSchema> = Optional.TOptional<InnerSchema>
export type TOptionalOptions = Optional.TOptionalOptions
export type TSingleton<ConstType> = Singleton.TSingleton<ConstType>
export type TSingletonOptions = Singleton.TSingletonOptions

export type TArray<InnerSchema> = Array.TArray<InnerSchema>
export type TArrayOptions = Array.TArrayOptions
export type TUnion<Tup> = Union.TUnion<Tup>
export type TUnionOptions = Union.TUnionOptions
export type TMap<Key, Value> = Map.TMap<Key, Value>
export type TMapOptions = Map.TMapOptions

const registry = require("@self/registry")

const defaultNamespace = registry.defaultUntypedNamespace
    :registerType(String)
    :registerType(Object)
    :registerType(Number)
    :registerType(Boolean)
    :registerType(Unsafe)
    :registerType(Nil)
    :registerType(Any)
    :registerType(Optional)
    :registerType(Singleton)
    :registerType(Array)
    :registerType(Union)
    :registerType(Map) :: registry.TypeNamespace & {
    String: typeof(String.factoryFunc),
    Object: typeof(Object.factoryFunc),
    Number: typeof(Number.factoryFunc),
    Boolean: typeof(Boolean.factoryFunc),
    Unsafe: typeof(Unsafe.factoryFunc),
    Nil: typeof(Nil.factoryFunc),
    Any: typeof(Any.factoryFunc),
    Optional: typeof(Optional.factoryFunc),
    Singleton: typeof(Singleton.factoryFunc),
    Array: typeof(Array.factoryFunc),
    Union: typeof(Union.factoryFunc),
    Map: typeof(Map.factoryFunc),
    Tuple: typeof(Types.Tuple),
}

const jsonCompatNamespace = registry
    .newNamespace("JsonCompat")
    :registerType(String)
    :registerType(Object)
    :registerType(Number)
    :registerType(Boolean)
    :registerType(Unsafe)
    :registerType(Nil)
    :registerType(Any)
    :registerType(Optional)
    :registerType(Singleton)
    :registerType(Array)
    :registerType(Union) :: registry.TypeNamespace & {
    String: typeof(String.factoryFunc),
    Object: typeof(Object.factoryFunc),
    Number: typeof(Number.factoryFunc),
    Boolean: typeof(Boolean.factoryFunc),
    Unsafe: typeof(Unsafe.factoryFunc),
    Nil: typeof(Nil.factoryFunc),
    Any: typeof(Any.factoryFunc),
    Optional: typeof(Optional.factoryFunc),
    Singleton: typeof(Singleton.factoryFunc),
    Array: typeof(Array.factoryFunc),
    Union: typeof(Union.factoryFunc),
    Tuple: typeof(Types.Tuple),
}

defaultNamespace.Tuple = Types.Tuple

return defaultNamespace
