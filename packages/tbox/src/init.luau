--!strict
const Types = require("@self/types")

const String = require("@self/schema/string")
const Object = require("@self/schema/json/object")
const Merge = require("@self/schema/json/merge")
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
const Vector = require("@self/schema/vector")

-- Roblox 데이터타입. 이 모듈들은 Roblox 전역을 값으로 참조하지 않으므로
-- 전역이 없는 standalone luau 에서도 안전하게 로드됩니다.
const Vector2 = require("@self/schema/roblox/vector2")
const Vector3 = require("@self/schema/roblox/vector3")
const CFrame = require("@self/schema/roblox/cframe")
const Color3 = require("@self/schema/roblox/color3")
const ColorSequence = require("@self/schema/roblox/colorSequence")
const ColorSequenceKeypoint = require("@self/schema/roblox/colorSequenceKeypoint")
const NumberRange = require("@self/schema/roblox/numberRange")
const NumberSequence = require("@self/schema/roblox/numberSequence")
const NumberSequenceKeypoint = require("@self/schema/roblox/numberSequenceKeypoint")
const Rect = require("@self/schema/roblox/rect")
const Region3 = require("@self/schema/roblox/region3")
const UDim = require("@self/schema/roblox/udim")
const UDim2 = require("@self/schema/roblox/udim2")
const DateTime = require("@self/schema/roblox/dateTime")
const Instance = require("@self/schema/roblox/instance")
const Enum = require("@self/schema/roblox/enum")
const EnumItem = require("@self/schema/roblox/enumItem")

export type Static<T> = Types.Static<T>
export type Tuple<Components...> = Types.Tuple<Components...>

export type TString = String.TString
export type TStringOptions = String.TStringOptions
export type TObject<Props> = Object.TObject<Props>
export type TObjectOptions = Object.TObjectOptions
export type TObjectProps = Object.TObjectProps
export type TMerge<Tuple> = Merge.TMerge<Tuple>
export type TMergeOptions = Merge.TMergeOptions
export type TNumber = Number.TNumber
export type TNumberOptions = Number.TNumberOptions
export type TNumberFormat = Number.TNumberFormat
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
export type TVector = Vector.TVector
export type TVectorOptions = Vector.TVectorOptions

export type TVector2 = Vector2.TVector2
export type TVector2Options = Vector2.TVector2Options
export type TVector3 = Vector3.TVector3
export type TVector3Options = Vector3.TVector3Options
export type TCFrame = CFrame.TCFrame
export type TCFrameOptions = CFrame.TCFrameOptions
export type TColor3 = Color3.TColor3
export type TColor3Options = Color3.TColor3Options
export type TColorSequence = ColorSequence.TColorSequence
export type TColorSequenceOptions = ColorSequence.TColorSequenceOptions
export type TColorSequenceKeypoint = ColorSequenceKeypoint.TColorSequenceKeypoint
export type TColorSequenceKeypointOptions = ColorSequenceKeypoint.TColorSequenceKeypointOptions
export type TNumberRange = NumberRange.TNumberRange
export type TNumberRangeOptions = NumberRange.TNumberRangeOptions
export type TNumberSequence = NumberSequence.TNumberSequence
export type TNumberSequenceOptions = NumberSequence.TNumberSequenceOptions
export type TNumberSequenceKeypoint = NumberSequenceKeypoint.TNumberSequenceKeypoint
export type TNumberSequenceKeypointOptions = NumberSequenceKeypoint.TNumberSequenceKeypointOptions
export type TRect = Rect.TRect
export type TRectOptions = Rect.TRectOptions
export type TRegion3 = Region3.TRegion3
export type TRegion3Options = Region3.TRegion3Options
export type TUDim = UDim.TUDim
export type TUDimOptions = UDim.TUDimOptions
export type TUDim2 = UDim2.TUDim2
export type TUDim2Options = UDim2.TUDim2Options
export type TDateTime = DateTime.TDateTime
export type TDateTimeOptions = DateTime.TDateTimeOptions
export type TInstance<InstanceType> = Instance.TInstance<InstanceType>
export type TInstanceOptions = Instance.TInstanceOptions
export type TEnum = Enum.TEnum
export type TEnumOptions = Enum.TEnumOptions
export type TEnumItem<ItemType> = EnumItem.TEnumItem<ItemType>
export type TEnumItemOptions = EnumItem.TEnumItemOptions

const registry = require("@self/registry")

const defaultNamespace = registry.defaultUntypedNamespace
    :registerType(String)
    :registerType(Object)
    :registerType(Merge)
    :registerType(Number)
    :registerType(Boolean)
    :registerType(Unsafe)
    :registerType(Nil)
    :registerType(Any)
    :registerType(Optional)
    :registerType(Singleton)
    :registerType(Array)
    :registerType(Union)
    :registerType(Map)
    :registerType(Vector)
    :registerType(Vector2)
    :registerType(Vector3)
    :registerType(CFrame)
    :registerType(Color3)
    :registerType(ColorSequence)
    :registerType(ColorSequenceKeypoint)
    :registerType(NumberRange)
    :registerType(NumberSequence)
    :registerType(NumberSequenceKeypoint)
    :registerType(Rect)
    :registerType(Region3)
    :registerType(UDim)
    :registerType(UDim2)
    :registerType(DateTime)
    :registerType(Instance)
    :registerType(Enum)
    :registerType(EnumItem) :: registry.TypeNamespace & {
    String: typeof(String.factoryFunc),
    Object: typeof(Object.factoryFunc),
    Merge: typeof(Merge.factoryFunc),
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
    Vector: typeof(Vector.factoryFunc),
    Vector2: typeof(Vector2.factoryFunc),
    Vector3: typeof(Vector3.factoryFunc),
    CFrame: typeof(CFrame.factoryFunc),
    Color3: typeof(Color3.factoryFunc),
    ColorSequence: typeof(ColorSequence.factoryFunc),
    ColorSequenceKeypoint: typeof(ColorSequenceKeypoint.factoryFunc),
    NumberRange: typeof(NumberRange.factoryFunc),
    NumberSequence: typeof(NumberSequence.factoryFunc),
    NumberSequenceKeypoint: typeof(NumberSequenceKeypoint.factoryFunc),
    Rect: typeof(Rect.factoryFunc),
    Region3: typeof(Region3.factoryFunc),
    UDim: typeof(UDim.factoryFunc),
    UDim2: typeof(UDim2.factoryFunc),
    DateTime: typeof(DateTime.factoryFunc),
    Instance: typeof(Instance.factoryFunc),
    Enum: typeof(Enum.factoryFunc),
    EnumItem: typeof(EnumItem.factoryFunc),
    Tuple: typeof(Types.Tuple),
}

defaultNamespace.Tuple = Types.Tuple

return defaultNamespace
