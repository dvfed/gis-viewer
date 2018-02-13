unit Storages;

interface

uses
  System.Classes,
  MapTypes,
  Features;

type
  {
    Reading simplest text file. Each feature starts of number of points,
    then point list it self. After the last feature's point one line is skipped.
    Example:

    N
    X1 Y1
    X2 Y2
    ...
    XN YN
    <empty line>
    and so on

    Features must have LineString/LinearRing geometry only.
  }
  TTxtStorage = class(TStorage)
  private
    FFeature: TGeometryEnabledFeature;
    FDataLine: Integer;
    FDataStrings: TStringList;
    FModel: TModel;
    { Low level helpers }
    function HasData: Boolean;
    procedure MoveToNextData;
    function CurrentData: string;
    { Overriden methods }
    procedure LoadMetaData; virtual;
    function LoadNext: TGeometryEnabledFeature; virtual;
    { Template methods }
    function GetFeature: TGeometryEnabledFeature;
    function HasNext: Boolean;
  public
    constructor Create(AFileName: string);
    destructor Destroy; override;
    procedure LoadTo(AModel: TModel); override;
  end;

  TMifStorage = class(TTxtStorage)
  private
  type
    TColumnDef = record
      Name: string;
      Kind: string;
      Width: Integer;
      Decimals: Integer;
    end;
    TColumnDefDynArray = array of TColumnDef;
  private
    FAttrFileName: string;
    FAttrLine: Integer;
    FAttrStrings: TStringList;
    FAttrDelimiter: Char;
    FColumnDefs: TColumnDefDynArray;
    FColumnsCount: Integer;
    function HasAttribute: Boolean;
    procedure MoveToNextAttribute;
    function CurrentAttribute: string;
    procedure LoadMetaData; override;
    function LoadNext: TGeometryEnabledFeature; override;
  public
    constructor Create(AFileName: string);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  CommonGeometry,
  GeosGeometry,
  System.RegularExpressions,
  Properties;

{ RegEx helpers }

const
  cVersionPattern = '^\s*VERSION';
  cCharsetPattern = '^\s*CHARSET';
  cDelimiterPattern = '^\s*DELIMITER\s+"(?P<delimiter>.)"';
  cCoordsysPattern = '^\s*COORDSYS';
  cColumnsCountPattern = '^\s*COLUMNS\s+(?P<column_count>\d+)';
  cColumnDefPattern = '^\s*(?P<name>\w+)\s+(?P<kind>\w+)(\s*\((?P<width>\d+)(,?(?P<decimals>\d+)?)\))?';
  cAttributePattern = '(,|^)("(?:[^"]|"")*"|[^,]*)?';
  cDataPattern = '^\s*DATA';
  cPointPattern = '^\s*POINT\s+(?P<x>[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+))\s+(?P<y>[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+))';
  cLinePattern = '^\s*LINE\s+(?P<x1>[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+))\s+(?P<y1>[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+))\s+(?P<x2>[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+))\s+(?P<y2>[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+))';
  cPlinePattern = '^\s*PLINE\s+(?P<vertex_count>\d+)';
  cRegionPattern = '^\s*REGION\s+(?P<polygon_count>\d+)';
  cCountPattern = '^\s*(?P<count>\d+)';
  cXYPairPattern = '^\s*(?P<x>[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+))\s+(?P<y>[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+))';
  cPenPattern = '^\s*PEN';
  cBrushPattern = '^\s*BRUSH';
  cSymbolPattern = '^\s*SYMBOL';
  cSmoothPattern = '^\s*SMOOTH';
  cCenterPattern = '^\s*CENTER';

var
  VersionRegExp: TRegEx;
  CharsetRegExp: TRegEx;
  DelimeterRegExp: TRegEx;
  CoordsysRegExp: TRegEx;
  ColumnsCountRegExp: TRegEx;
  ColumnDefRegExp: TRegEx;
  AttributeRegExp: TRegEx;
  DataRegExp: TRegEx;
  PointRegExp: TRegEx;
  LineRegExp: TRegEx;
  PlineRegExp: TRegEx;
  RegionRegExp: TRegEx;
  CountRegExp: TRegEx;
  XYPairRegExp: TRegEx;
  PenRegExp: TRegEx;
  BrushRegExp: TRegEx;
  SymbolRegExp: TRegEx;
  SmoothRegExp: TRegEx;
  CenterRegExp: TRegEx;

procedure InitRegExpMatchers;
begin
  VersionRegExp := TRegEx.Create(cVersionPattern, [roIgnoreCase, roCompiled]);
  CharsetRegExp := TRegEx.Create(cCharsetPattern, [roIgnoreCase, roCompiled]);
  DelimeterRegExp := TRegEx.Create(cDelimiterPattern, [roIgnoreCase, roCompiled]);
  CoordsysRegExp := TRegEx.Create(cCoordsysPattern, [roIgnoreCase, roCompiled]);
  ColumnsCountRegExp := TRegEx.Create(cColumnsCountPattern, [roIgnoreCase, roCompiled]);
  ColumnDefRegExp := TRegEx.Create(cColumnDefPattern, [roIgnoreCase, roCompiled]);
  AttributeRegExp := TRegEx.Create(cAttributePattern, [roIgnoreCase, roCompiled]);
  DataRegExp := TRegEx.Create(cDataPattern, [roIgnoreCase, roCompiled]);
  PointRegExp := TRegEx.Create(cPointPattern, [roIgnoreCase, roCompiled]);
  LineRegExp := TRegEx.Create(cLinePattern, [roIgnoreCase, roCompiled]);
  PlineRegExp := TRegEx.Create(cPlinePattern, [roIgnoreCase, roCompiled]);
  RegionRegExp := TRegEx.Create(cRegionPattern, [roIgnoreCase, roCompiled]);
  CountRegExp := TRegEx.Create(cCountPattern, [roCompiled]);
  XYPairRegExp := TRegEx.Create(cXYPairPattern, [roCompiled]);
  PenRegExp := TRegEx.Create(cPenPattern, [roIgnoreCase, roCompiled]);
  BrushRegExp := TRegEx.Create(cBrushPattern, [roIgnoreCase, roCompiled]);
  SymbolRegExp := TRegEx.Create(cSymbolPattern, [roIgnoreCase, roCompiled]);
  SmoothRegExp := TRegEx.Create(cSmoothPattern, [roIgnoreCase, roCompiled]);
  CenterRegExp := TRegEx.Create(cCenterPattern, [roIgnoreCase, roCompiled]);
end;

{ TTxtStorage }

constructor TTxtStorage.Create(AFileName: string);
begin
  inherited;
  FDataStrings := TStringList.Create;
  FDataStrings.LoadFromFile(FFileName);
  FDataLine := 0;
end;

destructor TTxtStorage.Destroy;
begin
  FDataStrings.Free;
  inherited;
end;

function TTxtStorage.CurrentData: string;
begin
  Result := FDataStrings[FDataLine];
end;

function TTxtStorage.GetFeature: TGeometryEnabledFeature;
begin
  Result := FFeature;
end;

function TTxtStorage.HasNext: Boolean;
begin
  FFeature := LoadNext;
  Result := Assigned(FFeature);
end;

function TTxtStorage.HasData: Boolean;
begin
  Result := FDataLine < FDataStrings.Count;
end;

procedure TTxtStorage.LoadTo(AModel: TModel);
begin
  FModel := AModel;
  LoadMetaData;
  while HasNext do
    AModel.Add(GetFeature);
end;

procedure TTxtStorage.MoveToNextData;
begin
  FDataLine := FDataLine + 1;
end;

procedure TTxtStorage.LoadMetaData;
begin
  // do nothing
end;

function TTxtStorage.LoadNext: TGeometryEnabledFeature;
var
  LCurrentStr: string;
  LVertexCount, I: Integer;
  X, Y : Double;
  LStringPartList : TStringList;
  LVertices: TVertexList;
begin
  Result := nil;
  LStringPartList := TStringList.Create;

  try
    if HasData then
    begin
      LCurrentStr := CurrentData;
      LVertexCount := StrToInt(LCurrentStr);
      LVertices := TVertexList.Create;
      try
        for I := 1 to LVertexCount do
        begin
          MoveToNextData;
          LCurrentStr := CurrentData;

          LStringPartList.DelimitedText := LCurrentStr;
          X := StrToFloat(LStringPartList.Strings[0]);
          Y := StrToFloat(LStringPartList.Strings[1]);
          LStringPartList.Clear;

          LVertices.Add(
            //file keeps coordinates in Decart order, our model does so too
            MakeVertex(X, Y)
          );
        end;

        MoveToNextData;
        MoveToNextData;

        Result := TLinearFeature.Create(FModel, LVertices);
        Result.ClassifierTag := 'Атрибут ' + IntToStr(LVertexCount mod 3);
      finally
        LVertices.Free;
      end;
    end;
  finally
    LStringPartList.Free;
  end;
end;

{ TMifStorage }

constructor TMifStorage.Create(AFileName: string);
begin
  inherited Create(AFileName);
  FAttrFileName := ChangeFileExt(AFileName, '.mid');
  FAttrStrings := TStringList.Create;
  FAttrStrings.LoadFromFile(FAttrFileName);
  FAttrLine := 0;
  FAttrDelimiter := #09;
  InitRegExpMatchers;
end;

destructor TMifStorage.Destroy;
begin
  FAttrStrings.Free;
  inherited;
end;

function TMifStorage.CurrentAttribute: string;
begin
  Result := FAttrStrings[FAttrLine];
end;

function TMifStorage.HasAttribute: Boolean;
begin
  Result := FAttrLine < FAttrStrings.Count;
end;

procedure TMifStorage.LoadMetaData;

  procedure LoadHeaderData;
  begin
    if HasData and VersionRegExp.IsMatch(CurrentData) then
      MoveToNextData;
    if HasData and CharsetRegExp.IsMatch(CurrentData) then
      MoveToNextData;
    if HasData and DelimeterRegExp.IsMatch(CurrentData) then begin
      FAttrDelimiter := DelimeterRegExp.Match(CurrentData).Groups['delimiter'].Value[1];
      MoveToNextData;
    end;
    if HasData and CoordsysRegExp.IsMatch(CurrentData) then
      MoveToNextData;
  end;

  procedure LoadColumnDefs;
  var
    I: Integer;
  begin
    FColumnsCount := 0;
    Assert(ColumnsCountRegExp.IsMatch(CurrentData));
    if HasData and ColumnsCountRegExp.IsMatch(CurrentData) then begin
      FColumnsCount := StrToInt(ColumnsCountRegExp.Match(CurrentData).Groups['column_count'].Value);
      MoveToNextData;
    end;
    SetLength(FColumnDefs, FColumnsCount);
    for I := 0 to FColumnsCount - 1 do begin
      Assert(ColumnDefRegExp.IsMatch(CurrentData));
      FColumnDefs[I].Name := UpperCase(ColumnDefRegExp.Match(CurrentData).Groups['name'].Value);
      FColumnDefs[I].Kind := UpperCase(ColumnDefRegExp.Match(CurrentData).Groups['kind'].Value);
      if FColumnDefs[I].Kind = 'CHAR' then
          FColumnDefs[I].Width := StrToInt(ColumnDefRegExp.Match(CurrentData).Groups['width'].Value);
      if FColumnDefs[I].Kind = 'DECIMAL' then begin
          FColumnDefs[I].Width := StrToInt(ColumnDefRegExp.Match(CurrentData).Groups['width'].Value);
          FColumnDefs[I].Decimals := StrToInt(ColumnDefRegExp.Match(CurrentData).Groups['decimals'].Value);
      end;
      MoveToNextData;
    end;
    if HasData and DataRegExp.IsMatch(CurrentData) then
      MoveToNextData;
  end;

  procedure ApplyColumnDefsToModel;
  var
    I: Integer;
    PropDef: TPropertyDef;
  begin
    for I := 0 to FColumnsCount - 1 do begin
      PropDef := TPropertyDef.Create(FColumnDefs[I].Name);
      FModel.PropertyDefTable.Add(PropDef);
    end;
  end;

begin
  LoadHeaderData;
  LoadColumnDefs;
  ApplyColumnDefsToModel;
end;

function TMifStorage.LoadNext: TGeometryEnabledFeature;

  procedure LoadVertices(out Vertices: TVertexList; Count: Integer);
  var
    I: Integer;
    X, Y : Double;
    Match: TMatch;
  begin
    for I := 1 to Count do begin
      MoveToNextData;
      Assert(HasData);
      Match := XYPairRegExp.Match(CurrentData);
      Assert(Match.Success, 'Input Line: ' + IntToStr(FDataLine) + ' Data: ' + CurrentData);
      X := StrToFloat(Match.Groups['x'].Value);
      Y := StrToFloat(Match.Groups['y'].Value);

      Vertices.Add(
        //file keeps coordinates in Decart order, our model does so too
        MakeVertex(X, Y)
      );
    end;
  end;

  function LoadPoint: TGeometryEnabledFeature;
  var
    Vertex: TVertex;
    X, Y : Double;
    Match: TMatch;
  begin
    Match := PointRegExp.Match(CurrentData);
    X := StrToFloat(Match.Groups['x'].Value);
    Y := StrToFloat(Match.Groups['y'].Value);
    Vertex := MakeVertex(X, Y);

    MoveToNextData;
    if HasData and SymbolRegExp.IsMatch(CurrentData) then
      MoveToNextData;

    Result := TPointFeature.Create(FModel, Vertex);
  end;

  function LoadLine: TGeometryEnabledFeature;
  var
    Vertices: TVertexList;
    X1, Y1, X2, Y2 : Double;
    Match: TMatch;
  begin
    Vertices := TVertexList.Create;
    try
      Match := LineRegExp.Match(CurrentData);
      X1 := StrToFloat(Match.Groups['x1'].Value);
      Y1 := StrToFloat(Match.Groups['y1'].Value);
      Vertices.Add(
        MakeVertex(X1, Y1)
      );
      X2 := StrToFloat(Match.Groups['x2'].Value);
      Y2 := StrToFloat(Match.Groups['y2'].Value);
      Vertices.Add(
        MakeVertex(X2, Y2)
      );

      MoveToNextData;
      if HasData and PenRegExp.IsMatch(CurrentData) then
        MoveToNextData;

      Result := TLinearFeature.Create(FModel, Vertices);
    finally
      Vertices.Free;
    end;
  end;

  function LoadPline: TGeometryEnabledFeature;
  var
    VertexCount: Integer;
    Vertices: TVertexList;
  begin
    VertexCount := StrToInt(PlineRegExp.Match(CurrentData).Groups['vertex_count'].Value);
    Vertices := TVertexList.Create;
    try
      LoadVertices(Vertices, VertexCount);

      MoveToNextData;
      if HasData and PenRegExp.IsMatch(CurrentData) then
        MoveToNextData;
      if HasData and SmoothRegExp.IsMatch(CurrentData) then
        MoveToNextData;

      Result := TLinearFeature.Create(FModel, Vertices);
    finally
      Vertices.Free;
    end;
  end;

  function LoadRegion: TGeometryEnabledFeature;
  var
    I, PolygonCount: Integer;
    VertexCount: Integer;
    Vertices: TVertexList;
    Polygon: TGeosPolygonWrapper;
    Shell: TGeosLinearRingWrapper;
    Rings: array of TGeosLinearRingWrapper;
  begin
    PolygonCount := StrToInt(RegionRegExp.Match(CurrentData).Groups['polygon_count'].Value);
    MoveToNextData;
    Assert(HasData);
    VertexCount := StrToInt(CountRegExp.Match(CurrentData).Groups['count'].Value);
    Vertices := TVertexList.Create;
    try
      LoadVertices(Vertices, VertexCount);
      Shell := TGeosLinearRingWrapper.Create(Vertices);
    finally
      Vertices.Free;
    end;
    if PolygonCount > 1 then begin
      SetLength(Rings, PolygonCount - 1);
      for I := 1 to PolygonCount - 1 do begin
        MoveToNextData;
        Assert(HasData);
        VertexCount := StrToInt(CountRegExp.Match(CurrentData).Groups['count'].Value);
        Vertices := TVertexList.Create;
        try
          LoadVertices(Vertices, VertexCount);
          Rings[I - 1] := TGeosLinearRingWrapper.Create(Vertices);
        finally
          Vertices.Free;
        end;
      end;
    end;

    MoveToNextData;
    if HasData and PenRegExp.IsMatch(CurrentData) then
      MoveToNextData;
    if HasData and BrushRegExp.IsMatch(CurrentData) then
      MoveToNextData;
    if HasData and CenterRegExp.IsMatch(CurrentData) then
      MoveToNextData;

    Polygon := TGeosPolygonWrapper.Create(Shell, Rings);
    Result := TPolygonFeature.Create(FModel, Polygon);
  end;

  procedure LoadAttributes(AFeature: TGeometryEnabledFeature);
  var
    I: Integer;
    From: Integer;
    Matches: TMatchCollection;
  begin
    From := 0;
    if (FColumnsCount > 0) then begin
      Assert(HasAttribute);
      if (FColumnsCount = 1) and (CurrentAttribute = '') then
        AFeature.PropertyByName[FColumnDefs[0].Name] := ''
      else begin
        Assert(AttributeRegExp.IsMatch(CurrentAttribute));
        Matches := AttributeRegExp.Matches(CurrentAttribute);
        if Pos(',', CurrentAttribute) = 1 then begin
          Assert(Matches.Count = FColumnsCount - 1);
          AFeature.PropertyByName[FColumnDefs[0].Name] := '';
          From := 1;
        end
        else
          Assert(Matches.Count = FColumnsCount);
        for I := From to FColumnsCount - 1 do begin
          AFeature.PropertyByName[FColumnDefs[I].Name] :=
            Matches.Item[I - From].Groups[2].Value;
        end;
      end;
      MoveToNextAttribute;
    end;
  end;

begin
  Result := nil;
  if HasData then
  begin
    if PointRegExp.IsMatch(CurrentData) then begin
      Result := LoadPoint;
    end
    else if LineRegExp.IsMatch(CurrentData) then begin
      Result := LoadLine;
    end
    else if PlineRegExp.IsMatch(CurrentData) then begin
      Result := LoadPline;
    end
    else if RegionRegExp.IsMatch(CurrentData) then begin
      Result := LoadRegion;
    end
    else
      Assert(False, 'TMifStorage.LoadNext: Unknown feature type!');

    Assert(Assigned(Result));
    LoadAttributes(Result);
  end;
end;

procedure TMifStorage.MoveToNextAttribute;
begin
  FAttrLine := FAttrLine + 1;
end;

end.
