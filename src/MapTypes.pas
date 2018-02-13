unit MapTypes;

interface

uses
  Winapi.Windows,
  System.Classes,
  Generics.Collections,
  CommonGeometry,
  GeosGeometry,
  GDIPAPI,
  Matrices,
  Properties;

type
  TStorage = class;
  TVisitor = class;
  TFeature = class;

  TDrawStyle = record
    PenColor: {GDIPAPI.}ARGB;
    BrushColor: {GDIPAPI.}ARGB;
  end;

  TStyleManager = class
  private
    type
      TPropertyStyleMap = TDictionary<TProperty,TDrawStyle>;
  private
    FDefaultStyle: TDrawStyle;
    FPropertyStyleMap: TPropertyStyleMap;
    FPropertyPool: TPropertyPool;
  public
    constructor Create(APropPool: TPropertyPool);
    destructor Destroy; override;
    procedure Add(const APropName, APropValue: string; AStyle: TDrawStyle);
    procedure Clear;
    /// <summary> If has no styles - return Default </summary>
    function GetStyle(AFeature: TFeature): TDrawStyle;
    property DefaultStyle: TDrawStyle read FDefaultStyle write FDefaultStyle;
  end;

  TFeature = class abstract
  private
    FParent: TFeature;
    FAttached: Boolean;
    FBoundsChanged: Boolean;
    FCachedBounds: TBounds;
  protected
    function CalcBounds: TBounds; virtual; abstract;
    property BoundsChanged: Boolean read FBoundsChanged write FBoundsChanged;
  public
    constructor Create(AParent: TFeature);
    destructor Destroy; override;
    function Bounds: TBounds;
    procedure Accept(AVisitor: TVisitor); virtual; abstract;
    property Parent: TFeature read FParent write FParent;
    property Attached: Boolean read FAttached write FAttached;
  end;

  TFeatureList = TObjectList<TFeature>;

  TPropertyEnabledFeature = class abstract(TFeature)
  private
    FProps: TPropertyList;
    function FindPropertyByName(const AName: string; out AProp: TProperty): Boolean;
    function GetPropertyByName(AName: string): string;
    procedure SetPropertyByName(AName: string; const Value: string);
    function GetClassifierTag: string;
    procedure SetClassifierTag(const Value: string);
    function GetPropertyPool: TPropertyPool;
  public
    constructor Create(AParent: TFeature);
    destructor Destroy; override;
    procedure EnsureHasRoomForProperties(Amount: Integer);
    property ClassifierTag: string read GetClassifierTag write SetClassifierTag;
    property PropertyByName[Index: string]: string read GetPropertyByName write SetPropertyByName;
    property Properties: TPropertyList read FProps;
  end;

  TVisitor = class abstract
    procedure VisitPointFeature(AFeature: TFeature); virtual; abstract;
    procedure VisitLinearFeature(AFeature: TFeature); virtual; abstract;
    procedure VisitPolygonFeature(AFeature: TFeature); virtual; abstract;
    procedure VisitModel(AModel: TFeature); virtual; abstract;
    procedure VisitViewPort(AViewPort: TFeature); virtual; abstract;
    procedure VisitWorkWindow(AWorkWindow: TFeature); virtual; abstract;
    procedure VisitLayer(ALayer: TFeature); virtual; abstract;
    procedure VisitLayerGroup(ALayerGroup: TFeature); virtual; abstract;
  end;

  TCompositeFeature = class abstract(TFeature)
  private
    FFeatures: TFeatureList;
  protected
    function CalcBounds: TBounds; override;
  public
    constructor Create(AParent: TFeature);
    destructor Destroy; override;
    property Features: TFeatureList read FFeatures;
    procedure Add(AFeature: TFeature);
    function HasFeatures: Boolean;
  end;

  TModel = class(TCompositeFeature)
  private
    FScale: Double;
    FUnitFactor: Double;
    FPropertyNames: TStringList;
    FPropertyValues: TStringList;
    FPropertyDefTable: TPropertyDefTable;
    FPropertyPool: TPropertyPool;
    procedure AddDefaultPropertyDefs;
    procedure CollectPropertyNames;
    procedure CollectPropertyValues(const APropertyName: string);
    function GetTopoScale: Double;
    procedure SetTopoScale(const Value: Double);
  public
    constructor Create(AParent: TFeature);
    destructor Destroy; override;
    procedure Load(AStorage: TStorage);
    procedure Accept(AVisitor: TVisitor); override;
    function GetPropertyNames: TStringList;
    function GetPropertyValues(const APropertyName: string): TStringList;
    function GetClassifierTags: TStringList;
    property PropertyDefTable: TPropertyDefTable read FPropertyDefTable;
    property PropertyPool: TPropertyPool read FPropertyPool;
    property Scale: Double read FScale write FScale;
    property TopoScale: Double read GetTopoScale write SetTopoScale;
  end;

  TLayout = class(TModel)
  public
    constructor Create(AParent: TFeature);
    destructor Destroy; override;
  end;

  TStorage = class abstract
  protected
    FFileName: string;
  public
    constructor Create(AFileName: string);
    procedure LoadTo(AModel: TModel); virtual; abstract;
  end;

  TPanMoveDirection = (pmdLeft, pmdRight, pmdUp, pmdDown);

  TBaseViewPort = class abstract(TPropertyEnabledFeature)
  private
    FSurfaceUnitsPerMM: Double;
    FScale: Double;
    FRotate: Double;
    FModelViewCenter: TVertex;
    FModelViewBounds: TBounds;
    FToClientMatrix: TMatrix2D;
    FToWorldMatrix: TMatrix2D;
    FModel: TFeature;
    function GetModelViewBounds: TBounds;
    procedure SetModelViewBounds(const Value: TBounds);
    function GetScale: Double;
    procedure SetScale(const Value: Double);
    procedure CalcTransformationMatrices; virtual; abstract;
    procedure UpdateModelViewBounds;
  public
    constructor Create(AParent: TFeature);
    destructor Destroy; override;
    procedure Add(AFeature: TFeature);
    procedure PanTo(ADir: TPanMoveDirection); overload;
    procedure PanTo(AModelViewCenter: TVertex); overload;
    procedure ZoomAll;
    procedure ZoomExactly(const AModelViewBounds: TBounds);
    procedure ZoomToFit(const AModelViewBounds: TBounds);
    function GetToClientTransformParams: TMatrix2DArray;
    function GetToWorldTransformParams: TMatrix2DArray;
    function TransformToClient(APoint: TVertex): TVertex;
    function TransformToWorld(APoint: TVertex): TVertex;
    property ToClientMatrix: TMatrix2D read FToClientMatrix;
    property ToWorldMatrix: TMatrix2D read FToWorldMatrix;
    property Child: TFeature read FModel;
    property Rotate: Double read FRotate write FRotate;
    property ModelViewBounds: TBounds read GetModelViewBounds
      write SetModelViewBounds;
    property Scale: Double read GetScale write SetScale;
  end;

  TViewPort = class(TBaseViewPort)
  private
    FClipper: TGeosGeometryWrapper;
    procedure CalcTransformationMatrices; override;
  protected
    function CalcBounds: TBounds; override;
  public
    constructor Create(AParent: TFeature);
    destructor Destroy; override;
    function HasClipper: Boolean;
    property Clipper: TGeosGeometryWrapper read FClipper write FClipper;
    procedure Accept(AVisitor: TVisitor); override;
  end;

  TWorkWindow = class(TBaseViewPort)
  private
    FRect: TRect;
    FKeepBoundsWhileResizing: Boolean;
    procedure SetRect(const Value: TRect);
    procedure CalcTransformationMatrices; override;
  protected
    function CalcBounds: TBounds; override;
  public
    constructor Create(AParent: TFeature; AResolution: Double = 96.0);
    destructor Destroy; override;
    property Rect: TRect read FRect write SetRect;
    procedure Accept(AVisitor: TVisitor); override;
    property KeepBoundsWhileResizing: Boolean read FKeepBoundsWhileResizing write FKeepBoundsWhileResizing;
  end;

  TLayer = class(TFeature)
  private
    FModel: TModel;
    FStyleManager: TStyleManager;
  protected
    function CalcBounds: TBounds; override;
  public
    constructor Create(AParent: TFeature; AModel: TModel);
    destructor Destroy; override;
    procedure Accept(AVisitor: TVisitor); override;
    procedure SetDefaultStyle(AStyle: TDrawStyle);
    procedure ClearStyles;
    procedure AddStyle(const APropName, APropValue: string; AStyle: TDrawStyle);
    property Model: TModel read FModel;
    property StyleManager: TStyleManager read FStyleManager;
  end;

  TLayerGroup = class(TCompositeFeature)
  private
    FActiveLayer: TLayer;
    FScale: Double;
  public
    constructor Create(AParent: TFeature);
    destructor Destroy; override;
    procedure Accept(AVisitor: TVisitor); override;
    property ActiveLayer: TLayer read FActiveLayer write FActiveLayer;
    // TODO stub, should get by chain active layer - model?
    property Scale: Double read FScale write FScale;
  end;

implementation

uses
  Math;

const
  mmPerInch = 25.4;

  cClassifierTagPropertyName = '@CLASSIFIER_TAG';

  cDefaultStyle: TDrawStyle = (
    PenColor : {GDIPAPI.}aclBlack;
    BrushColor : {GDIPAPI.}aclLightGray
  );

{ TFeature }

function TFeature.Bounds: TBounds;
begin
  if FBoundsChanged then begin
    FCachedBounds := CalcBounds;
    FBoundsChanged := False;
  end;
  Result := FCachedBounds;
end;

constructor TFeature.Create(AParent: TFeature);
begin
  inherited Create;
  FParent := AParent;
  FAttached := False;
  FBoundsChanged := True;
end;

destructor TFeature.Destroy;
begin
  inherited;
end;

{ TPropertyEnabledFeature }

constructor TPropertyEnabledFeature.Create(AParent: TFeature);
begin
  inherited;
  FParent := AParent;
  FAttached := False;
  FProps := TPropertyList.Create;
end;

destructor TPropertyEnabledFeature.Destroy;
begin
  // TODO remove props from pool
  FProps.Free;
  inherited;
end;

procedure TPropertyEnabledFeature.EnsureHasRoomForProperties(Amount: Integer);
begin
  FProps.Capacity := FProps.Count + Amount;
end;

function TPropertyEnabledFeature.FindPropertyByName(const AName: string; out AProp: TProperty): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FProps.Count - 1 do
    if FProps[I].Name = AName then begin
      AProp := FProps[I];
      Result := True;
      break;
    end;
end;

function TPropertyEnabledFeature.GetClassifierTag: string;
begin
  Result := PropertyByName[cClassifierTagPropertyName];
end;

function TPropertyEnabledFeature.GetPropertyByName(AName: string): string;
var
  found: Boolean;
  Prop: TProperty;
begin
  Result := '';
  found := FindPropertyByName(AName, Prop);
  if found then
    Result := Prop.Value.AsString;
end;

function TPropertyEnabledFeature.GetPropertyPool: TPropertyPool;
begin
  Assert(Assigned(Parent) and (Parent is TModel));
  Result := TModel(Parent).PropertyPool;
end;

procedure TPropertyEnabledFeature.SetClassifierTag(const Value: string);
begin
  PropertyByName[cClassifierTagPropertyName] := Value;
end;

procedure TPropertyEnabledFeature.SetPropertyByName(AName: string; const Value: string);
var
  found: Boolean;
  Prop: TProperty;
begin
  found := FindPropertyByName(AName, Prop);
  if found then begin
    if Prop.Value.AsString = Value then
      // do nothing
      Exit
    else begin
      FProps.Remove(Prop);
      GetPropertyPool.Delete(Prop);
    end;
  end;
  Prop := GetPropertyPool.FindOrCreate(AName, Value);
  FProps.Add(Prop);
end;

{ TModel }

constructor TModel.Create(AParent: TFeature);
begin
  inherited Create(AParent);
  FUnitFactor := 1000; {1000 MM = 1 Meter}
  FScale := 1;
  FPropertyNames := TStringList.Create;
  FPropertyValues := TStringList.Create;
  FPropertyDefTable := TPropertyDefTable.Create;
  FPropertyPool := TPropertyPool.Create(FPropertyDefTable);
  AddDefaultPropertyDefs;
end;

procedure TModel.AddDefaultPropertyDefs;
begin
  FPropertyDefTable.Add(
    TPropertyDef.Create(cClassifierTagPropertyName)
  );
end;

destructor TModel.Destroy;
begin
  FPropertyNames.Free;
  FPropertyValues.Free;
  FPropertyPool.Free;
  FPropertyDefTable.Free;
  inherited;
end;

procedure TModel.Accept(AVisitor: TVisitor);
begin
  AVisitor.VisitModel(Self);
end;

procedure TModel.CollectPropertyValues(const APropertyName: string);
var
  i: Integer;
begin
  FPropertyValues.Sorted := True;
  FPropertyValues.Duplicates := dupIgnore;
  FPropertyValues.Clear;
  for i := 0 to FFeatures.Count - 1 do begin
    Assert(FFeatures[i] is TPropertyEnabledFeature);
    FPropertyValues.Add(
      TPropertyEnabledFeature(FFeatures[i]).PropertyByName[APropertyName]);
  end;
end;

procedure TModel.CollectPropertyNames;
var
  def: TPropertyDef;
begin
  FPropertyNames.Clear;
  for def in FPropertyDefTable.Defs do
  begin
    FPropertyNames.Add(def.Name);
  end;
end;

function TModel.GetClassifierTags: TStringList;
begin
  Result := GetPropertyValues(cClassifierTagPropertyName);
end;

function TModel.GetPropertyNames: TStringList;
begin
  CollectPropertyNames;
  Result := FPropertyNames;
end;

function TModel.GetPropertyValues(const APropertyName: string): TStringList;
begin
  CollectPropertyValues(APropertyName);
  Result := FPropertyValues;
end;

function TModel.GetTopoScale: Double;
begin
  Result := FUnitFactor / FScale;
end;

procedure TModel.Load(AStorage: TStorage);
begin
  AStorage.LoadTo(Self);
end;

procedure TModel.SetTopoScale(const Value: Double);
begin
  FScale := FUnitFactor / Value;
end;

{ TStorage }

constructor TStorage.Create(AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
end;

{ TStyleManager }

constructor TStyleManager.Create(APropPool: TPropertyPool);
begin
  inherited Create;
  FDefaultStyle := cDefaultStyle;
  FPropertyPool := APropPool;
  FPropertyStyleMap := TPropertyStyleMap.Create(TPropertyComparer.Create);
end;

destructor TStyleManager.Destroy;
begin
  { FPropertyPool is destroyed by TModel }
  Clear;
  FPropertyStyleMap.Free;
  inherited;
end;

procedure TStyleManager.Add(const APropName, APropValue: string; AStyle: TDrawStyle);
var
  Prop: TProperty;
begin
  Assert(Assigned(FPropertyPool));
  Prop := FPropertyPool.FindOrCreate(APropName, APropValue);
  FPropertyStyleMap.AddOrSetValue(Prop, AStyle);
end;

procedure TStyleManager.Clear;
var
  P: TProperty;
begin
  for P in FPropertyStyleMap.Keys do
    FPropertyPool.Delete(P);
  FPropertyStyleMap.Clear;
end;

function TStyleManager.GetStyle(AFeature: TFeature): TDrawStyle;
var
  Style: TDrawStyle;
  Prop: TProperty;
begin
  Assert(AFeature is TPropertyEnabledFeature);
  Result := DefaultStyle;
  for Prop in TPropertyEnabledFeature(AFeature).Properties do
    if FPropertyStyleMap.TryGetValue(Prop, Style) then begin
      Result := Style;
      break;
    end;
end;

{ TViewPort }

procedure TViewPort.Accept(AVisitor: TVisitor);
begin
  AVisitor.VisitViewPort(Self);
end;

function TViewPort.CalcBounds: TBounds;
begin
  Assert(HasClipper);
  Result := FClipper.Bounds;
end;

procedure TViewPort.CalcTransformationMatrices;
begin
  FToClientMatrix.Reset;
  FToClientMatrix.Translate(-ModelViewBounds.Location.X, -ModelViewBounds.Location.Y,
    moAppend);
  FToClientMatrix.Scale(FScale, FScale, moAppend);
  FToClientMatrix.Translate(Bounds.Location.X, Bounds.Location.Y, moAppend);
  FToClientMatrix.RotateAt(Rotate, Bounds.Center, moAppend);
  FToWorldMatrix := FToClientMatrix;
  FToWorldMatrix.Invert;
end;

constructor TViewPort.Create(AParent: TFeature);
begin
  inherited Create(AParent);
  FClipper := nil;
end;

destructor TViewPort.Destroy;
begin
  FClipper.Free;
  inherited;
end;

function TViewPort.HasClipper: Boolean;
begin
  Result := Assigned(FClipper);
end;

{ TWorkWindow }

procedure TWorkWindow.Accept(AVisitor: TVisitor);
begin
  AVisitor.VisitWorkWindow(Self);
end;

function TWorkWindow.CalcBounds: TBounds;
begin
  Result := TBounds.Empty;
  Result.Left := FRect.Left;
  Result.Bottom := FRect.Top;
  Result.Height := FRect.Height;
  Result.Width := FRect.Width;
end;

procedure TWorkWindow.CalcTransformationMatrices;
begin
  FToClientMatrix.Reset;
  FToClientMatrix.Translate(-ModelViewBounds.Location.X, -ModelViewBounds.Location.Y,
    moAppend);
  // revert Y-coordinate
  FToClientMatrix.Scale(1, -1, moAppend);
  FToClientMatrix.Translate(0, ModelViewBounds.Height, moAppend);
  //
  FToClientMatrix.Scale(FScale, FScale, moAppend);
  FToClientMatrix.Translate(Bounds.Location.X, Bounds.Location.Y, moAppend);
  FToClientMatrix.RotateAt(Rotate, Bounds.Center, moAppend);
  FToWorldMatrix := FToClientMatrix;
  FToWorldMatrix.Invert;
end;

constructor TWorkWindow.Create(AParent: TFeature; AResolution: Double = 96.0);
begin
  inherited Create(AParent);
  FSurfaceUnitsPerMM := AResolution / mmPerInch;
  FRect.Create(0, 0, 1, 1);
  FKeepBoundsWhileResizing := True;
end;

destructor TWorkWindow.Destroy;
begin
  inherited;
end;

procedure TWorkWindow.SetRect(const Value: TRect);
begin
  if FRect <> Value then begin
    FRect := Value;
    BoundsChanged := True;
    if KeepBoundsWhileResizing then
      ZoomExactly(FModelViewBounds)
    else
      UpdateModelViewBounds;
  end;
end;

{ TBaseViewPort }

procedure TBaseViewPort.Add(AFeature: TFeature);
begin
  { TViewPort child has to be TLayerGroup only }
  Assert(AFeature is TLayerGroup);
  FModel := AFeature;
end;

constructor TBaseViewPort.Create(AParent: TFeature);
begin
  inherited Create(AParent);
  FScale := 1.0;
  FRotate := 0;
  FModelViewBounds.Create(0.0, 0.0, 1.0, 1.0);
  FSurfaceUnitsPerMM := 1.0;
end;

destructor TBaseViewPort.Destroy;
begin
  FModel.Free;
  inherited;
end;

function TBaseViewPort.GetToClientTransformParams: TMatrix2DArray;
begin
  FToClientMatrix.GetElements(Result);
end;

function TBaseViewPort.GetToWorldTransformParams: TMatrix2DArray;
begin
  FToWorldMatrix.GetElements(Result);
end;

function TBaseViewPort.GetModelViewBounds: TBounds;
begin
  Result := FModelViewBounds;
end;

procedure TBaseViewPort.PanTo(ADir: TPanMoveDirection);
const
  OffsetFactorDenominator = 3.0;
var
  viewCenter: TVertex;
begin
  viewCenter := FModelViewCenter;
  if ADir = pmdDown then
    viewCenter.Offset(0, -FModelViewBounds.Height / OffsetFactorDenominator)
  else if ADir = pmdUp then
    viewCenter.Offset(0, FModelViewBounds.Height / OffsetFactorDenominator)
  else if ADir = pmdLeft then
    viewCenter.Offset(-FModelViewBounds.Width / OffsetFactorDenominator, 0)
  else if ADir = pmdRight then
    viewCenter.Offset(FModelViewBounds.Width / OffsetFactorDenominator, 0);

  PanTo(viewCenter);
end;

procedure TBaseViewPort.PanTo(AModelViewCenter: TVertex);
begin
  FModelViewCenter := AModelViewCenter;
  UpdateModelViewBounds;
end;

procedure TBaseViewPort.SetModelViewBounds(const Value: TBounds);
begin
  ZoomToFit(Value);
end;

function TBaseViewPort.TransformToClient(APoint: TVertex): TVertex;
begin
  Result := FToClientMatrix.TransformPoint(APoint);
end;

function TBaseViewPort.TransformToWorld(APoint: TVertex): TVertex;
begin
  Result := FToWorldMatrix.TransformPoint(APoint);
end;

procedure TBaseViewPort.UpdateModelViewBounds;
begin
  FModelViewBounds := TBounds.Empty;
  FModelViewBounds.Height := Bounds.Height / FScale;
  FModelViewBounds.Width := Bounds.Width / FScale;
  FModelViewBounds.Center := FModelViewCenter;
  CalcTransformationMatrices;
end;

procedure TBaseViewPort.ZoomAll;
begin
  Assert(Assigned(FModel));
  ZoomToFit(FModel.Bounds);
end;

procedure TBaseViewPort.ZoomExactly(const AModelViewBounds: TBounds);
begin
  { fit by Height only }
  FScale := Bounds.Height / AModelViewBounds.Height;
  FModelViewCenter := AModelViewBounds.Center;
  UpdateModelViewBounds;
end;

procedure TBaseViewPort.ZoomToFit(const AModelViewBounds: TBounds);
begin
  // fit by side and reduce 5%
  FScale := Min(Bounds.Width / AModelViewBounds.Width,
    Bounds.Height / AModelViewBounds.Height) * 0.95;
  FModelViewCenter := AModelViewBounds.Center;
  UpdateModelViewBounds;
end;

procedure TBaseViewPort.SetScale(const Value: Double);
begin
  // see GetScale comments
  FScale := Value * TLayerGroup(Child).Scale * FSurfaceUnitsPerMM;
  UpdateModelViewBounds;
end;

function TBaseViewPort.GetScale: Double;
begin
  // to get view on screen same size as on paper
  // we must take into account map scale and screen resolution
  Result := FScale / (TLayerGroup(Child).Scale * FSurfaceUnitsPerMM);
end;

{ TLayout }

constructor TLayout.Create(AParent: TFeature);
begin
  inherited Create(AParent);
  FUnitFactor := 1; {1 MM = 1 MM}
end;

destructor TLayout.Destroy;
begin
  inherited;
end;

{ TCompositeFeature }

procedure TCompositeFeature.Add(AFeature: TFeature);
begin
  FFeatures.Add(AFeature);
  AFeature.Attached := True;
end;

function TCompositeFeature.HasFeatures: Boolean;
begin
  Result := FFeatures.Count > 0;
end;

function TCompositeFeature.CalcBounds: TBounds;
var
  I: Integer;
begin
  if HasFeatures then
  begin
    Result := TBounds.Create(FFeatures[0].Bounds);
    for I := 1 to FFeatures.Count - 1 do
    begin
      Result.Expand(FFeatures[I].Bounds);
    end;
  end
  else
    Result := TBounds.Create(0.0, 0.0, 1.0, 1.0);
end;

constructor TCompositeFeature.Create(AParent: TFeature);
begin
  inherited Create(AParent);
  FFeatures := TFeatureList.Create(True);
end;

destructor TCompositeFeature.Destroy;
begin
  FFeatures.Free;
  inherited;
end;

{ TLayer }

procedure TLayer.Accept(AVisitor: TVisitor);
begin
  AVisitor.VisitLayer(Self);
end;

procedure TLayer.AddStyle(const APropName, APropValue: string;
  AStyle: TDrawStyle);
begin
  StyleManager.Add(APropName, APropValue, AStyle);
end;

function TLayer.CalcBounds: TBounds;
begin
  Result := FModel.Bounds;
end;

procedure TLayer.ClearStyles;
begin
  FStyleManager.Clear;
end;

constructor TLayer.Create(AParent: TFeature; AModel: TModel);
begin
  Assert(Assigned(AModel));
  inherited Create(AParent);
  FModel := AModel;
  FStyleManager := TStyleManager.Create(FModel.PropertyPool);
end;

destructor TLayer.Destroy;
begin
  { Model is destroyed explicitly by Project }
  FStyleManager.Free;
  inherited;
end;

procedure TLayer.SetDefaultStyle(AStyle: TDrawStyle);
begin
  FStyleManager.DefaultStyle := AStyle;
end;

{ TLayerGroup }

procedure TLayerGroup.Accept(AVisitor: TVisitor);
begin
  AVisitor.VisitLayerGroup(Self);
end;

constructor TLayerGroup.Create(AParent: TFeature);
begin
  inherited Create(AParent);
end;

destructor TLayerGroup.Destroy;
begin

  inherited;
end;

end.
