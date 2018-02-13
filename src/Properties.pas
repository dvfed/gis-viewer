{
  Properties are kept in the pool with reference counting to avoid duplication
  and reduce memory usage.

  - Create PropertyDefTable;
  - Populate it with PropertyDefs;
  - Create PropertyPool feeding PropertyDefTable as a parameter;
  - Add/get Properties to/from the Pool

  See also "Feature Properties.pdf" for UML diagram.
}
unit Properties;

interface

uses
  System.Classes,
  Generics.Defaults,
  Generics.Collections;

type
  TPropertyDef = class(TObject)
  private
    FName: string;
  public
    constructor Create(AName: string);
    destructor Destroy; override;
    property Name: string read FName;
  end;

  TPropertyValue = class(TObject)
  private
    FValue: string;
    function GetAsString: string;
    procedure SetAsString(const Value: string);
  public
    constructor Create(const AValue: string);
    destructor Destroy; override;
    property AsString: string read GetAsString;
  end;

  TProperty = class(TObject)
  private
    FPropDef: TPropertyDef;
    FPropValue: TPropertyValue;
    function GetName: string;
    function GetValue: TPropertyValue;
  public
    constructor Create(ADef: TPropertyDef; AValue: TPropertyValue);
    destructor Destroy; override;
    function Equals(Other: TObject): Boolean; override;
    function GetHashCode: Integer; override;
    property Name: string read GetName;
    property Def: TPropertyDef read FPropDef;
    property Value: TPropertyValue read GetValue;
  end;

  TPropertyList = TList<TProperty>;

  TPropertyComparer = class(TInterfacedObject, IEqualityComparer<TProperty>)
  public
    function Equals(const Left, Right: TProperty): Boolean;
    function GetHashCode(const Value: TProperty): Integer;
  end;

  TPropertyDefTable = class(TObject)
  private
    FPropDefs: TObjectDictionary<string,TPropertyDef>;
    function GetDefs: TEnumerable<TPropertyDef>;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: Integer;
    procedure Add(ADef: TPropertyDef);
    function FindDef(AName: string): TPropertyDef;
    property Defs: TEnumerable<TPropertyDef> read GetDefs;
  end;

  TPropertyPool = class(TObject)
  private
    type
      TPropertyCountPair = TPair<TProperty,Integer>;
  private
    FProps: TObjectDictionary<TProperty,TPropertyCountPair>;
    FPropDefTable: TPropertyDefTable;
  public
    constructor Create(APropDefTable: TPropertyDefTable);
    destructor Destroy; override;
    function Count: Integer;
    function FindOrCreate(const AName, AValue: string): TProperty;
    procedure Delete(AProp: TProperty);
  end;

implementation

{ Hashcode helper functions }

function GetHashCodeString(const Value: string): Integer;
begin
  Result := BobJenkinsHash(PChar(Value)^, SizeOf(Char) * Length(Value), 0);
end;

{$IFOPT Q+}
  {$DEFINE OverflowChecksEnabled}
  {$Q-}
{$ENDIF}
function CombinedHash(const Values: array of Integer): Integer;
var
  Value: Integer;
begin
  Result := 17;
  for Value in Values do begin
    Result := Result * 37 + Value;
  end;
end;
{$IFDEF OverflowChecksEnabled}
  {$Q+}
{$ENDIF}

{ Equality helper }

function IsPropertiesEquals(const Left, Right: TProperty): Boolean;
begin
  Result := (Left.Def = Right.Def)
        and ((Left.Value = Right.Value)
          or (Left.Value.AsString = Right.Value.AsString));
end;

{ TPropertyDef }

constructor TPropertyDef.Create(AName: string);
begin
  FName := AName;
end;

destructor TPropertyDef.Destroy;
begin
  inherited;
end;

{ TPropertyValue }

constructor TPropertyValue.Create(const AValue: string);
begin
  inherited Create;
  SetAsString(AValue);
end;

destructor TPropertyValue.Destroy;
begin
  inherited;
end;

function TPropertyValue.GetAsString: string;
begin
  Result := FValue;
end;

procedure TPropertyValue.SetAsString(const Value: string);
begin
  FValue := Value;
end;

{ TProperty }

constructor TProperty.Create(ADef: TPropertyDef; AValue: TPropertyValue);
begin
  FPropDef := ADef;
  FPropValue := AValue;
end;

destructor TProperty.Destroy;
begin
  { FPropDef is destroyed by TPropertyDefTable }
  FPropValue.Free;
  inherited;
end;

function TProperty.Equals(Other: TObject): Boolean;
begin
  Result := IsPropertiesEquals(Self, TProperty(Other));
end;

function TProperty.GetHashCode: Integer;
begin
  Result := CombinedHash(
    [GetHashCodeString(Name),
     GetHashCodeString(Value.AsString)]);
end;

function TProperty.GetName: string;
begin
  Result := FPropDef.Name;
end;

function TProperty.GetValue: TPropertyValue;
begin
  Result := FPropValue;
end;

{ TPropertyDefTable }

procedure TPropertyDefTable.Add(ADef: TPropertyDef);
begin
  FPropDefs.Add(ADef.Name, ADef);
end;

function TPropertyDefTable.Count: Integer;
begin
  Result := FPropDefs.Count;
end;

constructor TPropertyDefTable.Create;
begin
  FPropDefs := TObjectDictionary<string,TPropertyDef>.Create([doOwnsValues]);
end;

destructor TPropertyDefTable.Destroy;
begin
  FPropDefs.Free;
  inherited;
end;

function TPropertyDefTable.FindDef(AName: string): TPropertyDef;
var
  isDefExist: boolean;
begin
  isDefExist := FPropDefs.TryGetValue(AName, Result);
  Assert(isDefExist, 'TPropertyDefTable: Property definition not found!');
end;

function TPropertyDefTable.GetDefs: TEnumerable<TPropertyDef>;
begin
  Result := FPropDefs.Values;
end;

{ TPropertyPool }

function TPropertyPool.Count: Integer;
begin
  Result := FProps.Count;
end;

constructor TPropertyPool.Create(APropDefTable: TPropertyDefTable);
begin
  FProps := TObjectDictionary<TProperty,TPropertyCountPair>.Create(
    [doOwnsKeys],
    TPropertyComparer.Create);
  FPropDefTable := APropDefTable;
end;

procedure TPropertyPool.Delete(AProp: TProperty);
var
  isPropExist: boolean;
  count: Integer;
  Pair: TPropertyCountPair;
begin
  isPropExist := FProps.TryGetValue(AProp, Pair);
  Assert(isPropExist, 'TPropertyPool: Can''t delete an unexistent property!');
  count := Pair.Value;
  if count > 1 then begin
    count := count - 1;
    Pair.Value := count;
    FProps.Items[AProp] := Pair;
  end
  else
    FProps.Remove(AProp);
end;

destructor TPropertyPool.Destroy;
begin
  FProps.Free;
  inherited;
end;

function TPropertyPool.FindOrCreate(const AName, AValue: string): TProperty;
var
  isPropExist: boolean;
  count: Integer;
  prop: TProperty;
  def: TPropertyDef;
  value: TPropertyValue;
  Pair: TPropertyCountPair;
begin
  def := FPropDefTable.FindDef(AName);
  value := TPropertyValue.Create(AValue);
  prop := TProperty.Create(def, value);

  isPropExist := FProps.TryGetValue(prop, Pair);
  if isPropExist then begin
    count := Pair.Value;
    count := count + 1;
    Pair.Value := count;
    FProps.Items[prop] := Pair;
    Result := Pair.Key;
    // already found existed so kill the sample
    prop.Free;
  end
  else begin
    Pair := TPropertyCountPair.Create(prop, 1);
    FProps.Add(prop, Pair);
    Result := prop;
  end;
end;

{ TPropertyComparer }

function TPropertyComparer.Equals(const Left, Right: TProperty): Boolean;
begin
  Result := IsPropertiesEquals(Left, Right);
end;

function TPropertyComparer.GetHashCode(const Value: TProperty): Integer;
begin
  Result := Value.GetHashCode;
end;

end.
