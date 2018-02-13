unit MapControl;

interface

uses
  System.Classes,
  Vcl.Controls,
  MapTypes,
  Renderers,
  CommonGeometry;

type
  TToolState = set of (mcsZooming, mcsPanning);

  TMapControl = class(TCustomControl)
  private
    { Private declarations }
    FWorkWin: TWorkWindow;
    FTool: TToolState;
    FWorldPos: TVertex;
    FOnChange: TNotifyEvent;
    procedure MouseEnter(Sender: TObject);
    procedure SetWin(const Value: TWorkWindow);
    function GetData: TLayerGroup;
  protected
    { Protected declarations }
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Change;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure Resize; override;
    procedure PanDown;
    procedure PanLeft;
    procedure PanRight;
    procedure PanUp;
    procedure Zoom1x1;
    procedure ZoomAll;
    procedure ZoomIn;
    procedure ZoomOut;
    procedure PanTo(AVertex: TVertex);
    function HasData: boolean;
    property Canvas;
    property Data: TLayerGroup read GetData;
    property Win: TWorkWindow read FWorkWin write SetWin;
    property Tool: TToolState read FTool write FTool;
    property WorldPos: TVertex read FWorldPos;
  published
    { Published declarations }
    property Align;
    property Anchors;
    property Caption;
    property Color;
    property OnResize;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

procedure Register;

implementation

uses
  System.Types,
  Vcl.Graphics,
  Vcl.Forms;

procedure Register;
begin
  RegisterComponents('Samples', [TMapControl]);
end;

{ TMapControl }

procedure TMapControl.Change;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

constructor TMapControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DoubleBuffered := True;
  FTool := [];
  OnMouseEnter := MouseEnter;
end;

destructor TMapControl.Destroy;
begin
  inherited;
end;

function TMapControl.GetData: TLayerGroup;
begin
  Result := TLayerGroup(FWorkWin.Child);
end;

function TMapControl.HasData: boolean;
begin
  Result := Assigned(Data);
end;

procedure TMapControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if not HasData then
    Exit;
  Assert(Assigned(FWorkWin));

  if mcsZooming in Tool then begin
    FWorldPos := FWorkWin.TransformToWorld(MakeVertex(X, Y));
    // panning directly on Win to avoid double invocation of Paint
    FWorkWin.PanTo(FWorldPos);
    if Button = mbLeft then
      ZoomIn
    else
    if Button = mbRight then
      ZoomOut;
  end
  else
  if mcsPanning in Tool then begin
    FWorldPos := FWorkWin.TransformToWorld(MakeVertex(X, Y));
    PanTo(FWorldPos);
  end;
end;

procedure TMapControl.MouseEnter(Sender: TObject);
begin
  SetFocus;
end;

procedure TMapControl.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  // TODO -oDVF : Inherited after? See Form.MapControl1MouseMove
  inherited;
  if not HasData then
    Exit;
  Assert(Assigned(FWorkWin));
  FWorldPos := FWorkWin.TransformToWorld(MakeVertex(X, Y));
end;

procedure TMapControl.Paint;
var
  renderer: TGDIPlusRenderer;
begin
  if csDesigning in ComponentState then
    with Canvas do
    begin
      Pen.Style := psDash;
      Brush.Style := bsClear;
      Rectangle(0, 0, Width, Height);
    end;

  if HasData then begin
    renderer := TGDIPlusRenderer.Create(Canvas.Handle);
    try
      renderer.Render(FWorkWin);
    finally
      renderer.Free;
    end;
  end;
end;

procedure TMapControl.ZoomIn;
begin
  with FWorkWin do
    Scale := Scale * 2;
  Invalidate;
end;

procedure TMapControl.ZoomOut;
begin
  with FWorkWin do
    Scale := Scale / 2;
  Invalidate;
end;

procedure TMapControl.PanTo(AVertex: TVertex);
begin
  FWorkWin.PanTo(AVertex);
  Invalidate;
end;

procedure TMapControl.Zoom1x1;
begin
  FWorkWin.Scale := 1;
  Invalidate;
end;

procedure TMapControl.ZoomAll;
begin
  FWorkWin.ZoomAll;
  Invalidate;
end;

procedure TMapControl.PanDown;
begin
  FWorkWin.PanTo(pmdDown);
  Invalidate;
end;

procedure TMapControl.PanLeft;
begin
  FWorkWin.PanTo(pmdLeft);
  Invalidate;
end;

procedure TMapControl.PanRight;
begin
  FWorkWin.PanTo(pmdRight);
  Invalidate;
end;

procedure TMapControl.PanUp;
begin
  FWorkWin.PanTo(pmdUp);
  Invalidate;
end;

procedure TMapControl.Resize;
begin
  inherited;
  if Assigned(FWorkWin) then
    FWorkWin.Rect := ClientRect;
  Invalidate;
end;

procedure TMapControl.SetWin(const Value: TWorkWindow);
begin
  FWorkWin := Value;
  FWorkWin.Rect := ClientRect;
end;

end.
