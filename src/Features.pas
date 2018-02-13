unit Features;

interface

uses
  CommonGeometry,
  GeosGeometry,
  MapTypes;

type
  TGeometryEnabledFeature = class abstract(TPropertyEnabledFeature)
  private
    FGeometry: TGeosGeometryWrapper;
  protected
    function CalcBounds: TBounds; override;
  public
    constructor Create(AParent: TFeature; AGeometry: TGeosGeometryWrapper); overload;
    destructor Destroy; override;
    property Geometry: TGeosGeometryWrapper read FGeometry write FGeometry;
  end;

  TPointFeature = class(TGeometryEnabledFeature)
  public
    constructor Create(AParent: TFeature; AGeometry: TGeosGeometryWrapper); overload;
    constructor Create(AParent: TFeature; AVertex: TVertex); overload;
    destructor Destroy; override;
    procedure Accept(AVisitor: TVisitor); override;
  end;

  TLinearFeature = class(TGeometryEnabledFeature)
  public
    constructor Create(AParent: TFeature; AGeometry: TGeosGeometryWrapper); overload;
    constructor Create(AParent: TFeature; AVertices: TVertexList); overload;
    destructor Destroy; override;
    procedure Accept(AVisitor: TVisitor); override;
  end;

  TPolygonFeature = class(TGeometryEnabledFeature)
  public
    constructor Create(AParent: TFeature; AGeometry: TGeosGeometryWrapper); overload;
    destructor Destroy; override;
    procedure Accept(AVisitor: TVisitor); override;
  end;

implementation

uses
  System.Classes;

{ TLinearFeature }

procedure TLinearFeature.Accept(AVisitor: TVisitor);
begin
  AVisitor.VisitLinearFeature(Self);
end;

constructor TLinearFeature.Create(AParent: TFeature;
  AGeometry: TGeosGeometryWrapper);
begin
  Assert(AGeometry is TGeosLineStringWrapper);
  inherited;
end;

constructor TLinearFeature.Create(AParent: TFeature; AVertices: TVertexList);
begin
  Create(AParent, TGeosLineStringWrapper.Create(AVertices));
end;

destructor TLinearFeature.Destroy;
begin
  inherited;
end;

{ TPointFeature }

procedure TPointFeature.Accept(AVisitor: TVisitor);
begin
  AVisitor.VisitPointFeature(Self);
end;

constructor TPointFeature.Create(AParent: TFeature; AVertex: TVertex);
begin
  Create(AParent, TGeosPointWrapper.Create(AVertex));
end;

constructor TPointFeature.Create(AParent: TFeature;
  AGeometry: TGeosGeometryWrapper);
begin
  Assert(AGeometry is TGeosPointWrapper);
  inherited;
end;

destructor TPointFeature.Destroy;
begin
  inherited;
end;

{ TPolygonFeature }

procedure TPolygonFeature.Accept(AVisitor: TVisitor);
begin
  AVisitor.VisitPolygonFeature(Self);
end;

constructor TPolygonFeature.Create(AParent: TFeature;
  AGeometry: TGeosGeometryWrapper);
begin
  Assert(AGeometry is TGeosPolygonWrapper);
  inherited;
end;

destructor TPolygonFeature.Destroy;
begin
  inherited;
end;

{ TGeometryEnabledFeature }

function TGeometryEnabledFeature.CalcBounds: TBounds;
begin
  Result := FGeometry.Bounds;
end;

constructor TGeometryEnabledFeature.Create(AParent: TFeature;
  AGeometry: TGeosGeometryWrapper);
begin
  inherited Create(AParent);
  FGeometry := AGeometry;
end;

destructor TGeometryEnabledFeature.Destroy;
begin
  FGeometry.Free;
  inherited;
end;

end.
