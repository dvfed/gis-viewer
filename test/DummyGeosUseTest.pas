{
  Test some GEOS library functionality
}
unit DummyGeosUseTest;

interface

uses
  TestFramework,
  Geos_c;

type
  Vertex2D = record
    X , Y : Double;
  end;

  Vertex2DArray = array [0..4] of Vertex2D;

  // No need to override SetUp & TearDown.
  // GEOS starts in DummyGeosUse unit.
  TGeosTest = class(TTestCase)
  private
    procedure CheckSeqCoords(ASeq: PGEOSCoordSequence; var ACoords: Vertex2DArray;
        ASize: Integer);
    procedure CreateSeqChecked(var ASeq: PGEOSCoordSequence; ASize: Integer);
    procedure FillCoordSeq(ASeq: PGEOSCoordSequence; var ACoords: Vertex2DArray;
        ASize: Integer);
  published
    procedure TestVersion;
    procedure TestCoordSeqCreation;
    procedure TestPointCreation;
    procedure TestLinearRingCreation;
    procedure TestUnclosedLinearRingCreationFail;
    procedure TestLineStringCreation;
    procedure TestPolygonCreationShellOnly;
    procedure TestPolygonCreationWithHoles;
    procedure TestWKTReader;
    procedure TestWKTWriter;
    procedure TestWKBReader;
    procedure TestWKBWriter;
  end;

implementation

uses
  DummyGeosUse,
  System.SysUtils;

var
  coords : Vertex2DArray = (
    (X : 1 ; Y : 1),
    (X : 61 ; Y : 1),
    (X : 61 ; Y : 61),
    (X : 1 ; Y : 61),
    (X : 1 ; Y : 1)
  );

  coordsWKT: string = 'LINESTRING (1 1, 61 1, 61 61, 1 61, 1 1)';
  coordsWKBHex: string = '010200000005000000000000000000F03F000000000000F03F0000000000804E40000000000000F03F0000000000804E400000000000804E40000000000000F03F0000000000804E40000000000000F03F000000000000F03F';

  coords0 : Vertex2DArray = (
    (X : 11 ; Y : 11),
    (X : 21 ; Y : 11),
    (X : 21 ; Y : 21),
    (X : 11 ; Y : 21),
    (X : 11 ; Y : 11)
  );

  coords1 : Vertex2DArray = (
    (X : 31 ; Y : 31),
    (X : 51 ; Y : 31),
    (X : 51 ; Y : 51),
    (X : 31 ; Y : 51),
    (X : 31 ; Y : 31)
  );

// thanks, internet :)
function xHexToBin(const HexStr: String): TBytes;
const
  HexSymbols = '0123456789ABCDEF';
var
  i, j: Integer;
  B: Byte;
begin
  SetLength(Result, (Length(HexStr) + 1) shr 1);
  B := 0;
  i :=  0;
  while i < Length(HexStr) do begin
    j:= 0;
    while j < Length(HexSymbols) do begin
      if HexStr[i + 1] = HexSymbols[j + 1] then Break;
      Inc(j);
    end;
    if j = Length(HexSymbols) then ; // error
    if Odd(i) then
      Result[i shr 1] := B shl 4 + j
    else
      B := j;
    Inc(i);
  end;
  if Odd(i) then
    Result[i shr 1] := B;
end;

procedure TGeosTest.CheckSeqCoords(aSeq: PGEOSCoordSequence; var aCoords:
    Vertex2DArray; aSize: Integer);
var
  Y: Double;
  X: Double;
  I: Integer;
begin
  for I := 0 to aSize - 1 do
  begin
    Check(GEOSCoordSeq_getX(aSeq, i, @X) <> 0, 'GEOSCoordSeq_getX exeption');
    Check(GEOSCoordSeq_getY(aSeq, i, @Y) <> 0, 'GEOSCoordSeq_getY exeption');
    CheckEquals(aCoords[I].X, X, 'X not equals');
    CheckEquals(aCoords[I].Y, Y, 'Y not equals');
  end;
end;

procedure TGeosTest.CreateSeqChecked(var aSeq: PGEOSCoordSequence; aSize: Integer);
begin
  aSeq := GEOSCoordSeq_create(aSize, 2);
  Check(Assigned(aSeq), 'ASeq = nil');
end;

procedure TGeosTest.FillCoordSeq(aSeq: PGEOSCoordSequence; var aCoords:
    Vertex2DArray; aSize: Integer);
var
  I: Integer;
begin
  for I := 0 to aSize - 1 do
  begin
    Check(GEOSCoordSeq_setX(aSeq, I, aCoords[I].X) <> 0, 'GEOSCoordSeq_setX exception');
    Check(GEOSCoordSeq_setY(aSeq, I, aCoords[I].Y) <> 0, 'GEOSCoordSeq_setY exception');
  end;
end;

procedure TGeosTest.TestCoordSeqCreation;
var
  cs: PGEOSCoordSequence;
  cs_size: Integer;
begin
  cs_size := 5;
  CreateSeqChecked(cs, cs_size);

  FillCoordSeq(cs, coords, cs_size);
  CheckSeqCoords(cs, coords, cs_size);

  GEOSCoordSeq_destroy(cs);
  //it doesn't make nil
  //Check(not Assigned(cs), 'cs <> nil');
end;

procedure TGeosTest.TestLinearRingCreation;
var
  cs: PGEOSCoordSequence;
  cs_size: Integer;
  geom: PGEOSGeometry;
begin
  // closed sequence
  cs_size := 5;
  CreateSeqChecked(cs, cs_size);

  FillCoordSeq(cs, coords, cs_size);

  geom := GEOSGeom_createLinearRing(cs);
  Check(Assigned(geom), 'Geom = nil');

  // get const* CoordSeq
  cs := GEOSGeom_getCoordSeq(geom);
  Check(Assigned(cs), 'cs = nil');

  CheckSeqCoords(cs, coords, cs_size);

  // destroy with CoordSequence that belongs to geometry
  GEOSGeom_destroy(geom);
end;

procedure TGeosTest.TestUnclosedLinearRingCreationFail;
var
  cs: PGEOSCoordSequence;
  cs_size: Integer;
  geom: PGEOSGeometry;
begin
  // unclosed sequence
  cs_size := 3;
  CreateSeqChecked(cs, cs_size);

  FillCoordSeq(cs, coords, cs_size);

  geom := GEOSGeom_createLinearRing(cs);
  CheckFalse(Assigned(geom), 'Unclosed LinearRing created?!');

  GEOSGeom_destroy(geom);
end;

procedure TGeosTest.TestLineStringCreation;
var
  cs: PGEOSCoordSequence;
  cs_size: Integer;
  geom: PGEOSGeometry;
begin
  cs_size := 3;
  CreateSeqChecked(cs, cs_size);

  FillCoordSeq(cs, coords, cs_size);

  geom := GEOSGeom_createLineString(cs);
  Check(Assigned(geom), 'Geom = nil');

  cs := GEOSGeom_getCoordSeq(geom);
  Check(Assigned(cs), 'cs = nil');

  CheckSeqCoords(cs, coords, cs_size);

  GEOSGeom_destroy(geom);
end;

procedure TGeosTest.TestPointCreation;
var
  cs: PGEOSCoordSequence;
  cs_size: Integer;
  geom: PGEOSGeometry;
begin
  cs_size := 1;
  CreateSeqChecked(cs, cs_size);
  { TODO -oDVF: Если не заполнить, то тест срабатывает, когда координата точки 0,0 }
  FillCoordSeq(cs, coords, cs_size);

  geom := GEOSGeom_createPoint(cs);
  Check(Assigned(geom), 'Geom = nil');

  cs := GEOSGeom_getCoordSeq(geom);
  Check(Assigned(cs), 'cs = nil');

  CheckSeqCoords(cs, coords, cs_size);

  GEOSGeom_destroy(geom);
end;

procedure TGeosTest.TestPolygonCreationShellOnly;
var
  cs: PGEOSCoordSequence;
  cs_size: Integer;
  shell, poly: PGEOSGeometry;
begin
  // closed sequence
  cs_size := 5;
  CreateSeqChecked(cs, cs_size);
  FillCoordSeq(cs, coords, cs_size);
  shell := GEOSGeom_createLinearRing(cs);
  Check(Assigned(shell), 'shell = nil');

  // construct polygon with no holes
  poly := GEOSGeom_createPolygon(shell, nil, 0);
  Check(Assigned(poly), 'poly = nil');

  shell := GEOSGetExteriorRing(poly);
  Check(Assigned(shell), 'shell = nil');

  cs := GEOSGeom_getCoordSeq(shell);
  Check(Assigned(cs), 'cs = nil');
  CheckSeqCoords(cs, coords, cs_size);

  GEOSGeom_destroy(poly);
end;

procedure TGeosTest.TestPolygonCreationWithHoles;
var
  cs: PGEOSCoordSequence;
  cs_size, holes_cnt: Integer;
  shell, poly, hole_ret: PGEOSGeometry;
  holes : PPGEOSGeometry;
begin
  // closed sequence
  cs_size := 5;
  CreateSeqChecked(cs, cs_size);
  FillCoordSeq(cs, coords, cs_size);
  shell := GEOSGeom_createLinearRing(cs);
  Check(Assigned(shell), 'shell = nil');

  // holes - again closed sequences
  SetLength(holes, 2);
  //
  cs_size := 5;
  CreateSeqChecked(cs, cs_size);
  FillCoordSeq(cs, coords0, cs_size);
  holes[0] := GEOSGeom_createLinearRing(cs);
  Check(Assigned(holes[0]), 'holes[0] = nil');
  //
  cs_size := 5;
  CreateSeqChecked(cs, cs_size);
  FillCoordSeq(cs, coords1, cs_size);
  holes[1] := GEOSGeom_createLinearRing(cs);
  Check(Assigned(holes[1]), 'holes[1] = nil');

  // construct polygon with holes
  poly := GEOSGeom_createPolygon(shell, holes, 2);
  Check(Assigned(poly), 'poly = nil');

  shell := GEOSGetExteriorRing(poly);
  Check(Assigned(shell), 'shell = nil');
  cs := GEOSGeom_getCoordSeq(shell);
  Check(Assigned(cs), 'cs = nil');
  CheckSeqCoords(cs, coords, cs_size);

  holes_cnt := GEOSGetNumInteriorRings(poly);
  Check(holes_cnt <> -1, 'GEOSGetNumInteriorRings exeption');
  Check(holes_cnt = 2, 'GEOSGetNumInteriorRings <> 2');

  hole_ret := GEOSGetInteriorRingN(poly, 0);
  Check(Assigned(hole_ret), 'hole_ret0 = nil');
  cs := GEOSGeom_getCoordSeq(hole_ret);
  Check(Assigned(cs), 'cs = nil');
  CheckSeqCoords(cs, coords0, cs_size);
  //
  hole_ret := GEOSGetInteriorRingN(poly, 1);
  Check(Assigned(hole_ret), 'hole_ret1 = nil');
  cs := GEOSGeom_getCoordSeq(hole_ret);
  Check(Assigned(cs), 'cs = nil');
  CheckSeqCoords(cs, coords1, cs_size);

  GEOSGeom_destroy(poly);
end;

procedure TGeosTest.TestVersion;
var
  ver: string;
  buf: PGEOSChar;
begin
  buf := GEOSversion;
  ver := string(PAnsiChar(buf));
  CheckEqualsString('3.4.2-CAPI-1.8.2 r3921', ver);
  { No need to free.
    GEOSFree(buf);
  }
end;

procedure TGeosTest.TestWKBReader;
var
  cs: PGEOSCoordSequence;
  cs_size: Integer;
  geom: PGEOSGeometry;
  reader: PGEOSWKBReader;
  wkb: TBytes;
  size: Integer;
begin
  cs_size := 5;
  CreateSeqChecked(cs, cs_size);
  FillCoordSeq(cs, coords, cs_size);

  reader := GEOSWKBReader_create;
  Check(Assigned(reader), 'reader = nil');

  size := Length(coordsWKBHex) div 2;
  wkb := xHexToBin(coordsWKBHex);

  geom := GEOSWKBReader_read(reader, PGEOSUChar(wkb), size);
  Check(Assigned(geom), 'Geom = nil');

  cs := GEOSGeom_getCoordSeq(geom);
  Check(Assigned(cs), 'cs = nil');

  CheckSeqCoords(cs, coords, cs_size);

  GEOSGeom_destroy(geom);
  GEOSWKBReader_destroy(reader);
end;

procedure TGeosTest.TestWKBWriter;
var
  cs: PGEOSCoordSequence;
  cs_size: Integer;
  geom: PGEOSGeometry;
  writer: PGEOSWKBWriter;
  wkb: TBytes;
  buf: PGEOSUChar;
  dim: Integer;
  i, size: Integer;
begin
  cs_size := 5;
  CreateSeqChecked(cs, cs_size);
  FillCoordSeq(cs, coords, cs_size);

  geom := GEOSGeom_createLineString(cs);
  Check(Assigned(geom), 'Geom = nil');

  writer := GEOSWKBWriter_create;
  Check(Assigned(writer), 'writer = nil');

  dim := GEOSWKBWriter_getOutputDimension(writer);
  Check(dim = 2, 'dim <> 2');

  // expected
  wkb := xHexToBin(coordsWKBHex);
  // got
  buf := GEOSWKBWriter_write(writer, geom, @size);

  Check(Length(wkb) = size, 'Length(wkb) <> size');

  for i := Low(wkb) to High(wkb) do
    Check(wkb[i] = PByte(buf)[i], 'wkb <> buf');

  GEOSGeom_destroy(geom);
  GEOSWKBWriter_destroy(writer);
  GEOSFree(buf);
end;

procedure TGeosTest.TestWKTReader;
var
  cs: PGEOSCoordSequence;
  cs_size: Integer;
  geom: PGEOSGeometry;
  reader: PGEOSWKTReader;
  wkt: PAnsiChar;
begin
  cs_size := 5;
  CreateSeqChecked(cs, cs_size);
  FillCoordSeq(cs, coords, cs_size);

  reader := GEOSWKTReader_create;
  Check(Assigned(reader), 'reader = nil');

  wkt := PAnsiChar(AnsiString(coordsWKT));
  geom := GEOSWKTReader_read(reader, PGEOSChar(wkt));
  Check(Assigned(geom), 'Geom = nil');

  cs := GEOSGeom_getCoordSeq(geom);
  Check(Assigned(cs), 'cs = nil');

  CheckSeqCoords(cs, coords, cs_size);

  GEOSGeom_destroy(geom);
  GEOSWKTReader_destroy(reader);
end;

procedure TGeosTest.TestWKTWriter;
var
  cs: PGEOSCoordSequence;
  cs_size: Integer;
  geom: PGEOSGeometry;
  writer: PGEOSWKTWriter;
  wkt: string;
  buf: PGEOSChar;
  dim: Integer;
begin
  cs_size := 5;
  CreateSeqChecked(cs, cs_size);
  FillCoordSeq(cs, coords, cs_size);

  geom := GEOSGeom_createLineString(cs);
  Check(Assigned(geom), 'Geom = nil');

  writer := GEOSWKTWriter_create;
  Check(Assigned(writer), 'writer = nil');

  dim := GEOSWKTWriter_getOutputDimension(writer);
  Check(dim = 2, 'dim <> 2');

  GEOSWKTWriter_setRoundingPrecision(writer, 0);
  buf := GEOSWKTWriter_write(writer, geom);
  wkt := string(AnsiString(PAnsiChar(buf)));

  Check(coordsWKT = wkt, 'coordsWKT <> wkt: ' + wkt);

  GEOSGeom_destroy(geom);
  GEOSWKTWriter_destroy(writer);
  GEOSFree(buf);
end;

initialization

  RegisterTest(TGeosTest.Suite);

end.


