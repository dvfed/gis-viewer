{
  Wrappers around GEOS library structures.
}

unit GeosGeometry;

interface

uses
  System.Classes,
  System.Contnrs,
  Math,
  Geos_c,
  CommonGeometry;

type
  { TODO -oDVF:
    - Exception handling
    - Add: Clone, GetSequence/GetVertices (?)
  }
  { OGC Geometry
    Root of wrappers' family.
    If owns the wrapped geometry will be destroyed, otherwise will be destroyed wrapper only.
  }
  TGeosGeometryWrapper = class abstract
  private
    FGEOSGeomOwned: Boolean;
    FPGEOSGeom: PGEOSGeometry;
    procedure SetEmpty;
    { Functions that work with reference to internal GEOSGeom }
    // assigns without owning
    procedure Assign(PGEOSGeom: PGEOSGeometry);
    // assigns with owning
    procedure Capture(PGEOSGeom: PGEOSGeometry);
    // return the reference to internal GEOSGeometry
    function Get: PGEOSGeometry;
    // return the reference to internal GEOSGeometry and clears owning flag (wrapper becames empty)
    function Release: PGEOSGeometry;
    // makes a wrapper by GEOSGeometry type
    class function MakeWrapper(PGEOSGeom: PGEOSGeometry): TGeosGeometryWrapper;
  public
    // constructs empty wrapper
    constructor Create;
    destructor Destroy; override;
    class function MakeFromWKT(const AWKT: string): TGeosGeometryWrapper;
    { OGC standard }
    function Envelope: TGeosGeometryWrapper;
    function GeometryType: String;
    function GeometryTypeId: GEOSGeomTypes;
    { not standard }
    function Bounds: TBounds;
  end;

  { OGC Point }
  TGeosPointWrapper = class(TGeosGeometryWrapper)
  private
    function GetValue: TVertex;
    procedure SetValue(const Value: TVertex);
  public
    constructor Create; overload;
    constructor Create(AVertex: TVertex); overload;
    property Value: TVertex read GetValue write SetValue;
  end;

  { OGÑ LineString }
  TGeosLineStringWrapper = class(TGeosGeometryWrapper)
  private
    function GetValue(Index: Integer): TVertex;
    procedure SetValue(Index: Integer; const Value: TVertex);
  public
    constructor Create; overload;
    constructor Create(AVertices: TVertexList); overload;
    function Count: Integer;
    property Value[Index: Integer]: TVertex read GetValue write SetValue;
  end;

  { OGÑ LineRing }
  TGeosLinearRingWrapper = class(TGeosLineStringWrapper)
  public
    constructor Create; overload;
    constructor Create(AVertices: TVertexList); overload;
  end;

  { OGÑ Polygon }
  TGeosPolygonWrapper = class(TGeosGeometryWrapper)
  private
    // used to reach the internal rings
    FLinearRing: TGeosLinearRingWrapper;
    function GetRing(Index: Integer): TGeosLinearRingWrapper;
    function GetShell: TGeosLinearRingWrapper;
    procedure SetRing(Index: Integer; const Value: TGeosLinearRingWrapper);
    procedure SetShell(const Value: TGeosLinearRingWrapper);
  public
    constructor Create; overload;
    /// <summary>
    /// Captures the internal Geos structures and destroys the wrappers.
    /// </summary>
    constructor Create(AShell: TGeosLinearRingWrapper; ARings: array of TGeosLinearRingWrapper);
        overload;
    destructor Destroy; override;
    function RingsCount: Integer;
    /// <summary>
    /// Returns wrapper that does not own the internal GEOS geometry.
    /// </summary>
    property Rings[Index: Integer]: TGeosLinearRingWrapper read GetRing write SetRing;
    /// <summary>
    /// Returns wrapper that does not own the internal GEOS geometry.
    /// </summary>
    property Shell: TGeosLinearRingWrapper read GetShell write SetShell;
  end;

  TGeometryList = class
  private
    FList: TObjectList;
    function GetValue(Index: Integer): TGeosGeometryWrapper;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(AGeometry: TGeosGeometryWrapper): TGeometryList;
    procedure Clear;
    function Count: Integer;
    property Value[Index: Integer]: TGeosGeometryWrapper read GetValue; default;
  end;

implementation

type
  TGeosTypeStrings = array[GEOSGeomTypes] of string;

var
  GeosTypeStrings: TGeosTypeStrings = (
    'Point',
    'LineString',
    'LinearRing',
    'Polygon',
    'MultiPoint',
    'MultiLineString',
    'MultiPolygon',
    'GeometryCollection'
  );

{ Helper functions }

function CreateSequence(AVertex: TVertex): PGEOSCoordSequence; overload;
var
  PSeq: PGEOSCoordSequence;
begin
  PSeq := GEOSCoordSeq_create(1, 3);
  Assert(Assigned(PSeq));
  if (GEOSCoordSeq_setX(PSeq, 0, AVertex.X) = 0) or
     (GEOSCoordSeq_setY(PSeq, 0, AVertex.Y) = 0) or
     (GEOSCoordSeq_setZ(PSeq, 0, AVertex.Z) = 0) then
      Assert(False);
  Result := PSeq;
end;

function CreateSequence(AVertices: TVertexList): PGEOSCoordSequence; overload;
var
  PSeq: PGEOSCoordSequence;
  I: Integer;
begin
  PSeq := GEOSCoordSeq_create(AVertices.Count, 3);
  Assert(Assigned(PSeq));
  for I := 0 to AVertices.Count - 1 do
  begin
    if (GEOSCoordSeq_setX(PSeq, I, AVertices.Value[I].X) = 0) or
       (GEOSCoordSeq_setY(PSeq, I, AVertices.Value[I].Y) = 0) or
       (GEOSCoordSeq_setZ(PSeq, I, AVertices.Value[I].Z) = 0) then
        Assert(False);
  end;
  Result := PSeq;
end;

function GetVertex(PGEOSGeom: PGEOSGeometry; Index: Integer): TVertex;
var
  LVertex: TVertex;
  LPCoordSeq: PGEOSCoordSequence;
begin
  LPCoordSeq := GEOSGeom_getCoordSeq(PGEOSGeom);
  Assert(Assigned(LPCoordSeq));
  if (GEOSCoordSeq_getX(LPCoordSeq, Index, @LVertex.X) = 0) or
     (GEOSCoordSeq_getY(LPCoordSeq, Index, @LVertex.Y) = 0) or
     (GEOSCoordSeq_getZ(LPCoordSeq, Index, @LVertex.Z) = 0) then
      Assert(False);
  Result := LVertex;
end;

function GetGeosGeomType(PGEOSGeom: PGEOSGeometry): GEOSGeomTypes;
var
  typeID: Integer;
begin
  typeID := GEOSGeomTypeId(PGEOSGeom);
  Assert(typeID <> -1);
  Result := GEOSGeomTypes(typeID);
end;

{ TGeosPointWrapper }

constructor TGeosPointWrapper.Create;
begin
  inherited;
end;

constructor TGeosPointWrapper.Create(AVertex: TVertex);
var
  LPGEOSGeom: PGEOSGeometry;
begin
  inherited Create;
  LPGEOSGeom := GEOSGeom_createPoint(CreateSequence(AVertex));
  Capture(LPGEOSGeom);
end;

function TGeosPointWrapper.GetValue: TVertex;
begin
  Result := GetVertex(FPGEOSGeom, 0);
end;

procedure TGeosPointWrapper.SetValue(const Value: TVertex);
begin
  // TODO
end;

{ TGeosLineStringWrapper }

constructor TGeosLineStringWrapper.Create;
begin
  inherited;
end;

function TGeosLineStringWrapper.Count: Integer;
begin
  Result := GEOSGetNumCoordinates(FPGEOSGeom);
  Assert(Result <> -1);
end;

constructor TGeosLineStringWrapper.Create(AVertices: TVertexList);
var
  LPGEOSGeom: PGEOSGeometry;
begin
  inherited Create;
  LPGEOSGeom := GEOSGeom_createLineString(CreateSequence(AVertices));
  Capture(LPGEOSGeom);
end;

function TGeosLineStringWrapper.GetValue(Index: Integer): TVertex;
begin
  Result := GetVertex(FPGEOSGeom, Index);
end;

procedure TGeosLineStringWrapper.SetValue(Index: Integer; const Value: TVertex);
begin
  // TODO
end;

{ TGeosGeometryWrapper }

constructor TGeosGeometryWrapper.Create;
begin
  inherited;
  SetEmpty;
end;

destructor TGeosGeometryWrapper.Destroy;
begin
  if FGEOSGeomOwned then begin
    Assert(Assigned(FPGEOSGeom));
    GEOSGeom_destroy(FPGEOSGeom);
  end;
  inherited;
end;

procedure TGeosGeometryWrapper.Assign(PGEOSGeom: PGEOSGeometry);
begin
  Assert(not FGEOSGeomOwned);
  Assert(Assigned(PGEOSGeom));
  FPGEOSGeom := PGEOSGeom;
end;

function TGeosGeometryWrapper.GeometryType: String;
begin
  Result := GeosTypeStrings[GeometryTypeId];
end;

function TGeosGeometryWrapper.GeometryTypeId: GEOSGeomTypes;
begin
  Result := GetGeosGeomType(FPGEOSGeom);
end;

function TGeosGeometryWrapper.Envelope: TGeosGeometryWrapper;
var
  LPGeom: PGEOSGeometry;
begin
  LPGeom := GEOSEnvelope(FPGEOSGeom);
  Assert(Assigned(LPGeom));
  Result := MakeWrapper(LPGeom);
end;

function TGeosGeometryWrapper.Bounds: TBounds;
var
  LGeom: TGeosGeometryWrapper;
  LVert0, LVert2: TVertex;
begin
  LGeom := Envelope;
  Assert(Assigned(LGeom));
  // Envelope can be point (for POINT or empty geometry)
  if LGeom is TGeosPointWrapper then begin
    LVert0 := TGeosPointWrapper(LGeom).Value;
    LVert2 := TGeosPointWrapper(LGeom).Value;
    LVert0.Offset(-0.5, -0.5);
    LVert2.Offset(+0.5, +0.5);
    Result := TBounds.Create(LVert0, LVert2);
  end
  // for the rest it is polygon
  else if LGeom is TGeosPolygonWrapper then begin
    // assuming polygon is clockwise, first point is left bottom (see GEOS API)
    LVert0 := TGeosPolygonWrapper(LGeom).Shell.Value[0];
    LVert2 := TGeosPolygonWrapper(LGeom).Shell.Value[2];
    Result := TBounds.Create(LVert0, LVert2);
  end;
  LGeom.Free;
end;

procedure TGeosGeometryWrapper.Capture(PGEOSGeom: PGEOSGeometry);
begin
  Assign(PGEOSGeom);
  FGEOSGeomOwned := True;
end;

function TGeosGeometryWrapper.Get: PGEOSGeometry;
begin
  Result := FPGEOSGeom;
end;

function TGeosGeometryWrapper.Release: PGEOSGeometry;
begin
  Result := FPGEOSGeom;
  SetEmpty;
end;

class function TGeosGeometryWrapper.MakeFromWKT(
  const AWKT: string): TGeosGeometryWrapper;
var
  PGEOSGeom: PGEOSGeometry;
  reader: PGEOSWKTReader;
  wkt: PAnsiChar;
begin
  reader := GEOSWKTReader_create;
  Assert(Assigned(reader));
  wkt := PAnsiChar(AnsiString(AWKT));
  PGEOSGeom := GEOSWKTReader_read(reader, PGEOSChar(wkt));
  Assert(Assigned(PGEOSGeom));
  GEOSWKTReader_destroy(reader);
  Result := MakeWrapper(PGEOSGeom);
end;

class function TGeosGeometryWrapper.MakeWrapper(PGEOSGeom: PGEOSGeometry):
  TGeosGeometryWrapper;
begin
  Result := nil;
  // TODO -oDVF: add the rest geometry types
  case GetGeosGeomType(PGEOSGeom) of
    GEOS_POINT:
      Result := TGeosPointWrapper.Create;
    GEOS_LINESTRING:
      Result := TGeosLineStringWrapper.Create;
    GEOS_LINEARRING:
      Result := TGeosLinearRingWrapper.Create;
    GEOS_POLYGON:
      Result := TGeosPolygonWrapper.Create;
  else
    Assert(False);
  end;
  Result.Capture(PGEOSGeom);
end;

procedure TGeosGeometryWrapper.SetEmpty;
begin
  FPGEOSGeom := nil;
  FGEOSGeomOwned := False;
end;

{ TGeometryList }

constructor TGeometryList.Create;
begin
  inherited Create;
  FList := TObjectList.Create(True);
end;

destructor TGeometryList.Destroy;
begin
  FList.Free;
  inherited;
end;

function TGeometryList.Add(AGeometry: TGeosGeometryWrapper): TGeometryList;
begin
  FList.Add(AGeometry);
  Result := Self;
end;

procedure TGeometryList.Clear;
begin
  FList.Clear;
end;

function TGeometryList.Count: Integer;
begin
  Result := FList.Count;
end;

function TGeometryList.GetValue(Index: Integer): TGeosGeometryWrapper;
begin
  Result := TGeosGeometryWrapper(FList.Items[Index]);
end;

{ TGeosLinearRingWrapper }

constructor TGeosLinearRingWrapper.Create;
begin
  inherited;
end;

constructor TGeosLinearRingWrapper.Create(AVertices: TVertexList);
var
  LPGEOSGeom: PGEOSGeometry;
begin
  Assert(AVertices.IsClosed);
  inherited Create;
  LPGEOSGeom := GEOSGeom_createLinearRing(CreateSequence(AVertices));
  Capture(LPGEOSGeom);
end;

{ TGeosPolygonWrapper }

constructor TGeosPolygonWrapper.Create;
begin
  inherited;
  FLinearRing := TGeosLinearRingWrapper.Create;
end;

constructor TGeosPolygonWrapper.Create(AShell: TGeosLinearRingWrapper;
  ARings: array of TGeosLinearRingWrapper);
var
  I: Integer;
  LPGEOSGeom,
  LPGeosGeomShell: PGEOSGeometry;
  LPGeosGeomRings: PPGEOSGeometry;
  ringsCount: Integer;
begin
  Create;
  Assert(Assigned(AShell));
  LPGeosGeomShell := AShell.Release;
  AShell.Free;
  LPGeosGeomRings := nil;
  ringsCount := Length(ARings);
  if ringsCount > 0 then begin
    SetLength(LPGeosGeomRings, ringsCount);
    for I := 0 to ringsCount - 1 do begin
      LPGeosGeomRings[I] := ARings[I].Release;
      ARings[I].Free;
    end;
  end;
  LPGEOSGeom := GEOSGeom_createPolygon(LPGeosGeomShell, LPGeosGeomRings, ringsCount);
  Capture(LPGEOSGeom);
end;

destructor TGeosPolygonWrapper.Destroy;
begin
  FLinearRing.Free;
  inherited;
end;

function TGeosPolygonWrapper.GetRing(Index: Integer): TGeosLinearRingWrapper;
var
  LPGEOSIntRing: PGEOSGeometry;
begin
  Assert(Index < RingsCount);
  LPGEOSIntRing := GEOSGetInteriorRingN(FPGEOSGeom, Index);
  Assert(Assigned(FLinearRing));
  FLinearRing.Assign(LPGEOSIntRing);
  Result := FLinearRing;
end;

function TGeosPolygonWrapper.GetShell: TGeosLinearRingWrapper;
var
  LPGEOSExtRing: PGEOSGeometry;
begin
  LPGEOSExtRing := GEOSGetExteriorRing(FPGEOSGeom);
  Assert(Assigned(FLinearRing));
  FLinearRing.Assign(LPGEOSExtRing);
  Result := FLinearRing;
end;

function TGeosPolygonWrapper.RingsCount: Integer;
begin
  Result := GEOSGetNumInteriorRings(FPGEOSGeom);
  Assert(Result <> -1);
end;

procedure TGeosPolygonWrapper.SetRing(Index: Integer; const Value: TGeosLinearRingWrapper);
begin
  // TODO
end;

procedure TGeosPolygonWrapper.SetShell(const Value: TGeosLinearRingWrapper);
begin
  // TODO
end;

{ GEOS library callback functions: internal errors }

procedure GEOSNoticeProc(fmt: PGEOSChar; args: array of const); cdecl;
begin
  // TODO
end;

procedure GEOSErrorProc(fmt: PGEOSChar; args: array of const); cdecl;
begin
  // TODO
end;

initialization

initGEOS(GEOSNoticeProc, GEOSErrorProc);

finalization

finishGEOS;

end.
