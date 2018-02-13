unit CommonGeometry;

interface

uses
  System.Classes,
  Math;

type
  PVertex = ^TVertex;
  TVertex = record
  public
    X, Y, Z, M: Double;
    procedure CopyX(const Other: TVertex);
    procedure CopyY(const Other: TVertex);
    function IsGreater(const Other: TVertex): Boolean;
    function IsLesser(const Other: TVertex): Boolean;
    function IsXGreater(const Other: TVertex): Boolean;
    function IsXLesser(const Other: TVertex): Boolean;
    function IsYGreater(const Other: TVertex): Boolean;
    function IsYLesser(const Other: TVertex): Boolean;
    procedure SetNull;
    //
    constructor Create(const V: TVertex); overload;
    constructor Create(const X, Y: Double; const Z: Double = 0.0; const M: Double = 0.0); overload;
    //operator overloads
    // TODO -oDVF: tolerance for equality function?
    class operator Equal(const Lhs, Rhs: TVertex): Boolean;
    class operator NotEqual(const Lhs, Rhs: TVertex): Boolean;
    function Equals2D(const Other: TVertex): Boolean; overload;
    function Equals3D(const Other: TVertex): Boolean; overload;
    procedure SetLocation(const aX, aY: Double; const aZ: Double = 0.0; const aM: Double = 0.0); overload;
    procedure SetLocation(const P: TVertex); overload;
    procedure Offset(const DX, DY: Double; const DZ: Double = 0.0); overload;
    // TODO -oDVF: 2D or 3D?
    procedure Offset(const Point: TVertex); overload;
    // TODO -oDVF: 2D or 3D?
    function IsZero: Boolean;
  end;

  // inspired by VCL sources
  TBounds = record
  private
    LeftBottom, RightTop : TVertex;
    function GetWidth: Double;
    procedure SetWidth(const Value: Double);
    function GetHeight: Double;
    procedure SetHeight(const Value: Double);
    function GetLocation: TVertex;
    function GetCenter: TVertex;
    procedure SetCenter(const Point: TVertex);
  public
    // empty rect at given origin
    constructor Create(const Origin: TVertex); overload;
    // at TPoint of origin with width and height
    constructor Create(const Origin: TVertex; const Width, Height: Double); overload;
    // at x, y with width and height
    constructor Create(const aLeft, aBottom, aRight, aTop: Double); overload;
    // with corners specified by p1 and p2
    constructor Create(const P1, P2: TVertex; Normalize: Boolean = False); overload;
    constructor Create(const R: TBounds; Normalize: Boolean = False); overload;
    class function Empty: TBounds; inline; static;
    // utility methods
    // makes sure RightTop is above and to the right of LeftBottom
    procedure NormalizeRect;
    // returns true if left = right or top = bottom
    function IsEmpty: Boolean;
    function Contains(const Point: TVertex): Boolean; overload;
    function Contains(const Other: TBounds): Boolean; overload;
    function IntersectsWith(const Other: TBounds): Boolean;
    // replaces current rectangle with its union with R
    procedure Union(const R: TBounds);
    // offsets the rectangle origin relative to current position
    procedure Offset(const DX, DY: Double);
    // sets new origin
    procedure SetLocation(const X, Y: Double); overload;
    procedure SetLocation(const Point: TVertex); overload;
    // inflate by DX and DY
    procedure Inflate(const DX, DY: Double); overload;
    procedure Expand(const Point: TVertex); overload;
    procedure Expand(const Other: TBounds); overload;
    property Bottom: Double read LeftBottom.Y write LeftBottom.Y;
    property Left: Double read LeftBottom.X write LeftBottom.X;
    property Top: Double read RightTop.Y write RightTop.Y;
    property Right: Double read RightTop.X write RightTop.X;
    // changing the width is always relative to Left
    property Width: Double read GetWidth write SetWidth;
    // changing the Height is always relative to Bottom
    property Height: Double read GetHeight write SetHeight;
    property Location: TVertex read GetLocation write SetLocation;
    property Center: TVertex read GetCenter write SetCenter;
  end;

  { TODO -oDVF: UnClose, UnDo, Delete, ToSequence
  }
  TVertexList = class
  private
    FList: TList;
    function GetValue(Index: Integer): TVertex;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const Value: TVertex): TVertexList;
    procedure Clear;
    function Close: TVertexList;
    function Count: Integer;
    function IsClosed: Boolean;
    property Value[Index: Integer]: TVertex read GetValue; default;
  end;

/// <summary>
/// Constructs vertex
/// </summary>
function MakeVertex(X, Y: Double; Z: Double = 0.0; M: Double = 0.0): TVertex;

/// <summary>
/// Constructs bound rect
/// </summary>
function MakeRect(LB, RT: TVertex): TBounds;

implementation

{ Global functions }

function MakeVertex(X, Y: Double;
  Z: Double = 0.0; M: Double = 0.0): TVertex;
begin
  Result.SetLocation(X, Y, Z, M);
end;

function MakeRect(LB, RT: TVertex): TBounds;
begin
  Result.Create(LB, RT);
end;

{ Helper functions }

function VertexEquals2D(const Lhs, Rhs: TVertex): Boolean;
begin
  Result := SameValue(Lhs.X, Rhs.X) and SameValue(Lhs.Y, Rhs.Y);
end;

function VertexEquals3D(const Lhs, Rhs: TVertex): Boolean;
begin
  Result := VertexEquals2D(Lhs, Rhs) and SameValue(Lhs.Z, Rhs.Z);
end;

function UnionBoundsRect(out Rect: TBounds; const R1, R2: TBounds): Boolean;
begin
  Rect := R1;
  if not R2.IsEmpty then
  begin
    if R2.Left < R1.Left then Rect.Left := R2.Left;
    if R2.Bottom < R1.Bottom then Rect.Bottom := R2.Bottom;
    if R2.Right > R1.Right then Rect.Right := R2.Right;
    if R2.Top > R1.Top then Rect.Top := R2.Top;
  end;
  Result := not Rect.IsEmpty;
  if not Result then begin
    Rect.Top := 0.0;
    Rect.Bottom := 0.0;
    Rect.Left := 0.0;
    Rect.Right := 0.0;
  end;
end;

{ TVertexList }

constructor TVertexList.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TVertexList.Destroy;
var
  P: PVertex;
begin
  for P in FList do
    Dispose(P);
  FList.Free;
  inherited;
end;

function TVertexList.Add(const Value: TVertex): TVertexList;
var
  LPVertex : PVertex;
begin
  New(LPVertex);
  LPVertex^ := Value;
  FList.Add(LPVertex);
  Result := Self;
end;

procedure TVertexList.Clear;
begin
  FList.Clear;
end;

function TVertexList.Close: TVertexList;
begin
  if IsClosed then
    Result := Self
  else
    Result := Add(GetValue(0));
end;

function TVertexList.Count: Integer;
begin
  Result := FList.Count;
end;

function TVertexList.GetValue(Index: Integer): TVertex;
begin
  Result := TVertex(FList.Items[Index]^);
end;

function TVertexList.IsClosed: Boolean;
begin
  Result := GetValue(0).Equals2D(GetValue(Count - 1));
end;

{ TVertex }

procedure TVertex.CopyX(const Other: TVertex);
begin
  X := Other.X;
end;

procedure TVertex.CopyY(const Other: TVertex);
begin
  Y := Other.Y;
end;

constructor TVertex.Create(const V: TVertex);
begin
  Self.X := V.X;
  Self.Y := V.Y;
  Self.X := V.Z;
  Self.Y := V.M;
end;

constructor TVertex.Create(const X, Y: Double; const Z: Double = 0.0; const M: Double = 0.0);
begin
  Self.X := X;
  Self.Y := Y;
  Self.X := Z;
  Self.Y := M;
end;

class operator TVertex.Equal(const Lhs, Rhs: TVertex): Boolean;
begin
  Result := VertexEquals2D(Lhs, Rhs);
end;

function TVertex.Equals2D(const Other: TVertex): Boolean;
begin
  Result := VertexEquals2D(Self, Other);
end;

function TVertex.Equals3D(const Other: TVertex): Boolean;
begin
  Result := VertexEquals3D(Self, Other);
end;

function TVertex.IsGreater(const Other: TVertex): Boolean;
begin
  Result := IsXGreater(Other) and IsYGreater(Other);
end;

function TVertex.IsLesser(const Other: TVertex): Boolean;
begin
  Result := IsXLesser(Other) and IsYLesser(Other);
end;

function TVertex.IsXGreater(const Other: TVertex): Boolean;
begin
  Result := X > Other.X;
end;

function TVertex.IsXLesser(const Other: TVertex): Boolean;
begin
  Result := X < Other.X;
end;

function TVertex.IsYGreater(const Other: TVertex): Boolean;
begin
  Result := Y > Other.Y;
end;

function TVertex.IsYLesser(const Other: TVertex): Boolean;
begin
  Result := Y < Other.Y;
end;

function TVertex.IsZero: Boolean;
begin
  Result := SameValue(X, 0.0) and SameValue(Y, 0.0)  and SameValue(Z, 0.0);
end;

class operator TVertex.NotEqual(const Lhs, Rhs: TVertex): Boolean;
begin
  Result := not VertexEquals2D(Lhs, Rhs);
end;

procedure TVertex.Offset(const DX, DY: Double; const DZ: Double = 0.0);
begin
  Self.X := Self.X + DX;
  Self.Y := Self.Y + DY;
  Self.Z := Self.Z + DZ;
end;

procedure TVertex.Offset(const Point: TVertex);
begin
  Self.X := Self.X + Point.X;
  Self.Y := Self.Y + Point.Y;
  Self.Z := Self.Z + Point.Z;
end;

procedure TVertex.SetLocation(const P: TVertex);
begin
  Self := P;
end;

procedure TVertex.SetLocation(const aX, aY: Double; const aZ: Double = 0.0; const aM: Double = 0.0);
begin
  X := aX;
  Y := aY;
  Z := aZ;
  M := aM;
end;

procedure TVertex.SetNull;
begin
  SetLocation(0.0, 0.0);
end;

{ TBoundsRect }

constructor TBounds.Create(const aLeft, aBottom, aRight, aTop: Double);
begin
  LeftBottom.X := aLeft;
  LeftBottom.Y := aBottom;
  RightTop.X := aRight;
  RightTop.Y := aTop;
end;

constructor TBounds.Create(const Origin: TVertex; const Width, Height: Double);
begin
  LeftBottom.X := Origin.X;
  LeftBottom.Y := Origin.Y;
  RightTop.X := Origin.X + Width;
  RightTop.Y := Origin.Y + Height;
end;

constructor TBounds.Create(const Origin: TVertex);
begin
  LeftBottom := Origin;
  RightTop := LeftBottom;
end;

function TBounds.Contains(const Point: TVertex): Boolean;
begin
  Result := (Point.X > Self.Left) and
            (Point.X < Self.Right) and
            (Point.Y > Self.Bottom) and
            (Point.Y < Self.Top);
end;

function TBounds.Contains(const Other: TBounds): Boolean;
begin
  Result := Contains(Other.LeftBottom) and Contains(Other.RightTop);
end;

constructor TBounds.Create(const R: TBounds; Normalize: Boolean);
begin
  Self := R;
  if Normalize then
    NormalizeRect;
end;

constructor TBounds.Create(const P1, P2: TVertex; Normalize: Boolean);
begin
  Self.LeftBottom := P1;
  Self.RightTop := P2;
  if Normalize then
    NormalizeRect;
end;

class function TBounds.Empty: TBounds;
begin
  Result := TBounds.Create(0.0, 0.0, 0.0, 0.0);
end;

procedure TBounds.Expand(const Point: TVertex);
var
  R: TBounds;
begin
  R := Create(Point);
  Expand(R);
end;

procedure TBounds.Expand(const Other: TBounds);
begin
    if Other.Left < Self.Left then Self.Left := Other.Left;
    if Other.Bottom < Self.Bottom then Self.Bottom := Other.Bottom;
    if Other.Right > Self.Right then Self.Right := Other.Right;
    if Other.Top > Self.Top then Self.Top := Other.Top;
end;

function TBounds.GetCenter: TVertex;
begin
  Result.X := (Right - Left) / 2.0 + Left;
  Result.Y := (Top - Bottom) / 2.0 + Bottom;
end;

function TBounds.GetHeight: Double;
begin
  Result := Self.Top - Self.Bottom;
end;

function TBounds.GetLocation: TVertex;
begin
  Result := LeftBottom;
end;

function TBounds.GetWidth: Double;
begin
  Result := Self.Right - Self.Left;
end;

procedure TBounds.Inflate(const DX, DY: Double);
begin
  LeftBottom.Offset(-DX, -DY);
  RightTop.Offset(DX, DY);
end;

function TBounds.IntersectsWith(const Other: TBounds): Boolean;
begin
  Result := not ( (Self.Right < Other.Left) or
                  (Self.Bottom > Other.Top) or
                  (Other.Right < Self.Left) or
                  (Other.Bottom > Self.Top) );
end;

function TBounds.IsEmpty: Boolean;
begin
  Result := (Right < Left) or SameValue(Right, Left) or (Bottom < Top) or
    SameValue(Bottom, Top);
end;

procedure TBounds.NormalizeRect;
var
  temp: Double;
begin
  if Top < Bottom then
  begin
    temp := Top;
    Top := Bottom;
    Bottom := temp;
  end;
  if Left > Right then
  begin
    temp := Left;
    Left := Right;
    Right := temp;
  end
end;

procedure TBounds.Offset(const DX, DY: Double);
begin
  LeftBottom.Offset(DX, DY);
  RightTop.Offset(DX, DY);
end;

procedure TBounds.SetCenter(const Point: TVertex);
var
  DX, DY: Double;
begin
  DX := Point.X - GetCenter.X;
  DY := Point.Y - GetCenter.Y;
  Offset(DX, DY);
end;

procedure TBounds.SetHeight(const Value: Double);
begin
  Self.Top := Self.Bottom + Value;
end;

procedure TBounds.SetLocation(const Point: TVertex);
begin
  Offset(Point.X - Left, Point.Y - Bottom);
end;

procedure TBounds.SetLocation(const X, Y: Double);
begin
  Offset(X - Left, Y - Bottom);
end;

procedure TBounds.SetWidth(const Value: Double);
begin
  Self.Right := Self.Left + Value;
end;

procedure TBounds.Union(const R: TBounds);
begin
  UnionBoundsRect(Self, Self, R);
end;

end.
