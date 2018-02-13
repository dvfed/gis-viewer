unit Renderers;

interface

uses
  Winapi.Windows,
  CommonGeometry,
  GeosGeometry,
  MapTypes,
  GDIPOBJ,
  GDIPAPI,
  Generics.Collections,
  Matrices;

type
  TGDIPlusRenderer = class(TVisitor)
  private
  type
    TStyleManagerStack = TStack<TStyleManager>;
    TBoundsStack = TStack<TBounds>;
    TMatrixPair = TPair<TMatrix2D, TMatrix2D>;
    TMatrix2DStack = TStack<TMatrixPair>;
  private
    FPixelsPerMM: Single;
    FGPGraphics: TGPGraphics;
    FPen: TGPPen;
    FBrush: TGPSolidBrush;
    FCurrentStyleManager: TStyleManager;
    FStyleManagerStack: TStyleManagerStack;
    FCurrentModelViewBounds: TBounds;
    FModelViewBoundsStack: TBoundsStack;
    FSurfaceToModelMatrix: TMatrix2D;
    FModelToSurfaceMatrix: TMatrix2D;
    FMatricesStack: TMatrix2DStack;
    { helper precalculated bounds }
    FMinVisibleSize: Double;
    FTrashholdVisibleSize: Double;
    FModelMinVisibleBounds: TBounds;
    FTrashholdVisibleBounds: TBounds;
    { helpers }
    function PreparePoints(out Points: TPointFDynArray; APolyline: TGeosLineStringWrapper): Integer;
    procedure AddPolygonToPath(AGPath: TGPGraphicsPath; APolyline: TGeosLineStringWrapper);
    function FeatureInCurrentModelViewBounds(AFeature: TFeature): Boolean;
    function FeatureHasMeaningfulSize(AFeature: TFeature): Boolean;
    procedure CalcHelperBounds;
    { drawing }
    procedure DrawPoint(AGeometry: TGeosGeometryWrapper);
    procedure DrawPolyline(AGeometry: TGeosGeometryWrapper);
    procedure DrawPolygon(AGeometry: TGeosGeometryWrapper);
    procedure DrawFakePolygon(ABounds: TBounds);
    procedure DrawRectangle(ABounds: TBounds);
    procedure ApplyStyle(AStyle: TDrawStyle);
    procedure SetTransform(AViewport: TBaseViewPort);
    procedure SetClip(AClipper: TGeosGeometryWrapper);
    { state }
    procedure SaveStyleManagerState;
    procedure RestoreStyleManagerState;
    procedure SaveModelViewBounds;
    procedure RestoreModelViewBounds;
    procedure SaveMatrices;
    procedure RestoreMatrices;
  public
    constructor Create(AHandle: HDC);
    destructor Destroy; override;
    procedure Render(AFeature: TFeature);
    procedure VisitPointFeature(AFeature: TFeature); override;
    procedure VisitLinearFeature(AFeature: TFeature); override;
    procedure VisitPolygonFeature(AFeature: TFeature); override;
    procedure VisitModel(AModel: TFeature); override;
    procedure VisitViewPort(AViewPort: TFeature); override;
    procedure VisitWorkWindow(AWorkWindow: TFeature); override;
    procedure VisitLayer(ALayer: TFeature); override;
    procedure VisitLayerGroup(ALayerGroup: TFeature); override;
  end;

implementation

uses
  Features;

{ TGDIPlusRenderer }

procedure TGDIPlusRenderer.CalcHelperBounds;
var
  v1, v2: TVertex;
begin
  v1 := FSurfaceToModelMatrix.TransformPoint(MakeVertex(0.0, 0.0));
  v2 := FSurfaceToModelMatrix.TransformPoint(MakeVertex(FMinVisibleSize, FMinVisibleSize));
  FModelMinVisibleBounds := TBounds.Create(v1, v2, True);
  v1 := FSurfaceToModelMatrix.TransformPoint(MakeVertex(0.0, 0.0));
  v2 := FSurfaceToModelMatrix.TransformPoint(MakeVertex(FTrashholdVisibleSize, FTrashholdVisibleSize));
  FTrashholdVisibleBounds := TBounds.Create(v1, v2, True);
end;

constructor TGDIPlusRenderer.Create(AHandle: HDC);
begin
  inherited Create;
  FGPGraphics := TGPGraphics.Create(AHandle);
  FPixelsPerMM := FGPGraphics.GetDpiX / 25.4;
  FGPGraphics.SetPageUnit(UnitPixel);
  FPen := TGPPen.Create({GDIPAPI.}aclBlack, 0.0 {/ FPixelsPerMM});
  FBrush := TGPSolidBrush.Create(aclLightGray);
  FStyleManagerStack := TStyleManagerStack.Create;
  FModelViewBoundsStack := TBoundsStack.Create;
  FMatricesStack := TMatrix2DStack.Create;
  { surface units }
  FMinVisibleSize := 1.0;
  FTrashholdVisibleSize := 5.0;
end;

destructor TGDIPlusRenderer.Destroy;
begin
  FGPGraphics.Free;
  FPen.Free;
  FBrush.Free;
  FStyleManagerStack.Free;
  FModelViewBoundsStack.Free;
  FMatricesStack.Free;
  inherited;
end;

procedure TGDIPlusRenderer.DrawFakePolygon(ABounds: TBounds);
var
  drawBounds: TBounds;
begin
  drawBounds := FModelMinVisibleBounds;
  drawBounds.Center := ABounds.Center;
  DrawRectangle(drawBounds);
end;

procedure TGDIPlusRenderer.DrawPoint(AGeometry: TGeosGeometryWrapper);
var
  x, y, size: Single;
  point: TGeosPointWrapper;
begin
  Assert(AGeometry is TGeosPointWrapper);
  point := TGeosPointWrapper(AGeometry);
  // TODO -oDVF: Point size should be set somehow
  size := 0.3;
  x := point.Value.X - size / 2;
  y := point.Value.Y - size / 2;
  FGPGraphics.DrawEllipse(FPen, x, y, size, size);
end;

procedure TGDIPlusRenderer.DrawPolyline(AGeometry: TGeosGeometryWrapper);
var
  Count: Integer;
  LineString: TGeosLineStringWrapper;
  Points: TPointFDynArray;
begin
  Assert(AGeometry is TGeosLineStringWrapper);
  LineString := TGeosLineStringWrapper(AGeometry);
  Count := PreparePoints(Points, LineString);
  FGPGraphics.DrawLines(FPen, PGPPointF(Points), Count);
end;

procedure TGDIPlusRenderer.DrawPolygon(AGeometry: TGeosGeometryWrapper);
var
  I: Integer;
  Polygon: TGeosPolygonWrapper;
  Ring,
  Shell: TGeosLineStringWrapper; {TGeosLinearRingWrapper}
  GraphicsPath: TGPGraphicsPath;
begin
  Assert(AGeometry is TGeosPolygonWrapper);
  Polygon := TGeosPolygonWrapper(AGeometry);
  GraphicsPath := TGPGraphicsPath.Create;
  Shell := TGeosLineStringWrapper(Polygon.Shell);
  AddPolygonToPath(GraphicsPath, Shell);
  for I := 0 to Polygon.RingsCount - 1 do begin
      Ring := TGeosLineStringWrapper(Polygon.Rings[I]);
      AddPolygonToPath(GraphicsPath, Ring);
  end;
  FGPGraphics.FillPath(FBrush, GraphicsPath);
  FGPGraphics.DrawPath(FPen, GraphicsPath);
  GraphicsPath.Free;
end;

procedure TGDIPlusRenderer.SaveMatrices;
begin
  FMatricesStack.Push(
    TMatrixPair.Create(FModelToSurfaceMatrix, FSurfaceToModelMatrix)
  );
end;

procedure TGDIPlusRenderer.SaveModelViewBounds;
begin
  FModelViewBoundsStack.Push(FCurrentModelViewBounds);
end;

procedure TGDIPlusRenderer.SaveStyleManagerState;
begin
  FStyleManagerStack.Push(FCurrentStyleManager);
end;

procedure TGDIPlusRenderer.SetClip(AClipper: TGeosGeometryWrapper);
var
  Ring: TGeosLineStringWrapper; {TGeosLinearRingWrapper}
  GraphicsPath: TGPGraphicsPath;
begin
  Ring := TGeosLineStringWrapper(AClipper);
  GraphicsPath := TGPGraphicsPath.Create;
  AddPolygonToPath(GraphicsPath, Ring);
  FGPGraphics.SetClip(GraphicsPath);
  GraphicsPath.Free;
end;

procedure TGDIPlusRenderer.ApplyStyle(AStyle: TDrawStyle);
begin
  FPen.SetColor(AStyle.PenColor);
  FBrush.SetColor(AStyle.BrushColor);
end;

procedure TGDIPlusRenderer.SetTransform(AViewport: TBaseViewPort);
var
  MatElem: TMatrix2DArray;
  curMatrix, addMatrix: TGPMatrix;
begin
  { setting GDI+ Graphics transform parameters }
  MatElem := AViewport.GetToClientTransformParams;
  curMatrix := TGPMatrix.Create;
  addMatrix := TGPMatrix.Create;
  addMatrix.SetElements(MatElem[0], MatElem[1], MatElem[2], MatElem[3], MatElem[4], MatElem[5]);
  FGPGraphics.GetTransform(curMatrix);
  curMatrix.Multiply(addMatrix, MatrixOrderPrepend);
  FGPGraphics.SetTransform(curMatrix);
  curMatrix.Free;
  addMatrix.Free;
  { Keep tracking model-to-surface and vise-versa double-sizes matrices.
    This is stuff which is parallel to GDI+ but it is slightly easier to use. }
  FModelToSurfaceMatrix.Multiply(AViewPort.ToClientMatrix, moPrepend);
  FSurfaceToModelMatrix.Multiply(AViewPort.ToWorldMatrix, moAppend);
  CalcHelperBounds;
end;

procedure TGDIPlusRenderer.VisitLayer(ALayer: TFeature);
var
  Layer: TLayer;
begin
  Layer := TLayer(ALayer);
  SaveStyleManagerState;
    FCurrentStyleManager := Layer.StyleManager;
    Layer.Model.Accept(Self);
  RestoreStyleManagerState;
end;

procedure TGDIPlusRenderer.VisitLayerGroup(ALayerGroup: TFeature);
var
  f: TFeature;
  LayerGroup: TLayerGroup;
begin
  LayerGroup := TLayerGroup(ALayerGroup);
  if LayerGroup.HasFeatures then
    for f in LayerGroup.Features do
    begin
      f.Accept(Self);
    end;
end;

procedure TGDIPlusRenderer.VisitLinearFeature(AFeature: TFeature);
var
  s: TDrawStyle;
begin
  if not FeatureInCurrentModelViewBounds(AFeature) then
    Exit;
  s := FCurrentStyleManager.GetStyle(AFeature);
  ApplyStyle(s);
  DrawPolyline(TLinearFeature(AFeature).Geometry);
end;

procedure TGDIPlusRenderer.VisitModel(AModel: TFeature);
var
  f: TFeature;
  LModel: TModel;
  s: TDrawStyle;
begin
  LModel := TModel(AModel);
  s := FCurrentStyleManager.DefaultStyle;
  ApplyStyle(s);
  DrawRectangle(LModel.Bounds);

  if LModel.HasFeatures then
    for f in LModel.Features do
    begin
      f.Accept(Self);
    end;
end;

procedure TGDIPlusRenderer.VisitPointFeature(AFeature: TFeature);
var
  s: TDrawStyle;
begin
  if not FeatureInCurrentModelViewBounds(AFeature) then
    Exit;
  s := FCurrentStyleManager.GetStyle(AFeature);
  ApplyStyle(s);
  DrawPoint(TPointFeature(AFeature).Geometry);
end;

procedure TGDIPlusRenderer.VisitPolygonFeature(AFeature: TFeature);
var
  s: TDrawStyle;
begin
  if not (FeatureInCurrentModelViewBounds(AFeature)) then
    Exit;
  s := FCurrentStyleManager.GetStyle(AFeature);
  ApplyStyle(s);
  if FeatureHasMeaningfulSize(AFeature) then
    DrawPolygon(TPolygonFeature(AFeature).Geometry)
  else
    DrawFakePolygon(AFeature.Bounds);
end;

procedure TGDIPlusRenderer.VisitViewPort(AViewPort: TFeature);
var
  s: TDrawStyle;
  LViewPort: TViewPort;
  savedState: GraphicsState;
begin
  if not FeatureInCurrentModelViewBounds(AViewPort) then
    Exit;
  LViewPort := TViewPort(AViewPort);
  Assert(LViewPort.HasClipper and (LViewPort.Clipper is TGeosLineStringWrapper));
  savedState := FGPGraphics.Save;
  SaveModelViewBounds;
  SaveMatrices;
    SetClip(LViewPort.Clipper);
    SetTransform(LViewPort);
    FCurrentModelViewBounds := LViewPort.ModelViewBounds;
    LViewPort.Child.Accept(Self);
  RestoreMatrices;
  RestoreModelViewBounds;
  FGPGraphics.Restore(savedState);
  s := FCurrentStyleManager.GetStyle(LViewPort);
  ApplyStyle(s);
  DrawPolyline(LViewPort.Clipper);
end;

procedure TGDIPlusRenderer.VisitWorkWindow(AWorkWindow: TFeature);
var
  WorkWindow: TWorkWindow;
begin
  WorkWindow := TWorkWindow(AWorkWindow);
  FCurrentModelViewBounds := WorkWindow.ModelViewBounds;
  SetTransform(WorkWindow);
  WorkWindow.Child.Accept(Self);
end;

procedure TGDIPlusRenderer.DrawRectangle(ABounds: TBounds);
begin
  with ABounds do
    FGPGraphics.DrawRectangle(FPen, Left, Bottom, Width, Height);
end;

function TGDIPlusRenderer.FeatureHasMeaningfulSize(AFeature: TFeature): Boolean;
var
  fb: TBounds;
begin
  Result := True;
  fb := AFeature.Bounds;
  if (fb.Width < FTrashholdVisibleBounds.Width) and
     (fb.Height < FTrashholdVisibleBounds.Height) then
    Result := False;
end;

function TGDIPlusRenderer.FeatureInCurrentModelViewBounds(
  AFeature: TFeature): Boolean;
var
  featureBounds: TBounds;
begin
  featureBounds := AFeature.Bounds;
  Result := FCurrentModelViewBounds.Contains(featureBounds)
         or FCurrentModelViewBounds.IntersectsWith(featureBounds);
end;

procedure TGDIPlusRenderer.AddPolygonToPath(AGPath: TGPGraphicsPath;
  APolyline: TGeosLineStringWrapper);
var
  Count: Integer;
  Points: TPointFDynArray;
begin
  Count := PreparePoints(Points, APolyline);
  AGPath.AddPolygon(PGPPointF(Points), Count);
end;

function TGDIPlusRenderer.PreparePoints(out Points: TPointFDynArray;
  APolyline: TGeosLineStringWrapper): Integer;
var
  I, Count: Integer;
begin
  Count := APolyline.Count;
  SetLength(Points, Count);
  for I := 0 to Count - 1 do begin
    Points[I].X := APolyline.Value[I].X;
    Points[I].Y := APolyline.Value[I].Y;
  end;
  Result := Count;
end;

procedure TGDIPlusRenderer.Render(AFeature: TFeature);
begin
  FModelToSurfaceMatrix.Reset;
  FSurfaceToModelMatrix.Reset;
  AFeature.Accept(self);
end;

procedure TGDIPlusRenderer.RestoreMatrices;
var
  mp: TMatrixPair;
begin
  mp := FMatricesStack.Pop;
  FModelToSurfaceMatrix := mp.Key;
  FSurfaceToModelMatrix := mp.Value;
  CalcHelperBounds;
end;

procedure TGDIPlusRenderer.RestoreModelViewBounds;
begin
  FCurrentModelViewBounds := FModelViewBoundsStack.Pop;
end;

procedure TGDIPlusRenderer.RestoreStyleManagerState;
begin
  FCurrentStyleManager := FStyleManagerStack.Pop;
end;

end.

