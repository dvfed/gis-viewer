{
  TMatrix2D
  ----------
  Matrix realization that uses Double, similar to GDI+ TGPMatrix
}
unit Matrices;

interface

uses
  CommonGeometry;

type
  //m11, m12, m21, m22, dx, dy
  TMatrix2DArray = array[0..5] of Double;
  TMultiplyOrder = (moPrepend, moAppend);
  //matrix 3x3 for internal using
  TMatrix9 = array[0..2, 0..2] of Double;

  TMatrix2D = record
  private
    FMatrix: TMatrix9;
  public
    class function Create: TMatrix2D; static;
    procedure GetElements(var AMatrixArray: TMatrix2DArray);
    procedure SetElements(AM11, AM12, AM21, AM22, ADx, ADy: Double);
    procedure Reset;
    procedure Multiply(AMatrix: TMatrix2D; AOrder: TMultiplyOrder = moPrepend);
    procedure Translate(ADx, ADy: Double; AOrder: TMultiplyOrder = moPrepend);
    procedure Scale(AScaleX, AScaleY: Double; AOrder: TMultiplyOrder = moPrepend);
    procedure Rotate(AAngle: Double; AOrder: TMultiplyOrder = moPrepend);
    procedure RotateAt(AAngle: Double; ACenter: TVertex; AOrder: TMultiplyOrder = moPrepend);
    procedure Invert;
    function TransformPoint(APoint: TVertex): TVertex;
//    procedure TransformPoints(APoints: array of TVertex);
  end;

implementation

uses
  Math;

const
  cMathPrecision = 1E-40;

  cIdentityMatrix9: TMatrix9 =
    ((1, 0, 0),
     (0, 1, 0),
     (0, 0, 1));


function MatrixMultiply(M1, M2: TMatrix9): TMatrix9;
var
  I, J: Integer;
begin
  for I := 0 to 2 do
    for J := 0 to 2 do
      Result[I, J] := M1[I, 0] * M2[0, J] +
                      M1[I, 1] * M2[1, J] +
                      M1[I, 2] * M2[2, J];
end;

function RotateMatrix(M: TMatrix9; Ang: Double): TMatrix9;
var
  MRot: TMatrix9;
begin
  MRot := cIdentityMatrix9;
  Ang := DegToRad(Ang);
  MRot[0, 0] := cos(Ang);
  MRot[0, 1] := sin(Ang);
  MRot[1, 0] := -sin(Ang);
  MRot[1, 1] := cos(Ang);
  Result := MatrixMultiply(M, MRot);
end;

function ScaleMatrix(M: TMatrix9; ScaleX, ScaleY: Double): TMatrix9;
var
  M2: TMatrix9;
begin
  M2 := cIdentityMatrix9;
  M2[0, 0] := ScaleX;
  M2[1, 1] := ScaleY;
  Result := MatrixMultiply(M, M2);
end;

function TranslateMatrix(M: TMatrix9; DeltaX, DeltaY: Double): TMatrix9;
var
  M2: TMatrix9;
begin
  M2 := cIdentityMatrix9;
  M2[2, 0] := DeltaX;
  M2[2, 1] := DeltaY;
  Result := MatrixMultiply(M, M2);
end;

function MatrixDeterminant(M: TMatrix9): Double;
begin

  Result :=  M[0, 0] * (M[1, 1] * M[2, 2] - M[2, 1] * M[1, 2]) -
             M[0, 1] * (M[1, 0] * M[2, 2] - M[2, 0] * M[1, 2]) +
             M[0, 2] * (M[1, 0] * M[2, 1] - M[2, 0] * M[1, 1]);
end;

function AdjointMatrix(var M: TMatrix9): TMatrix9;
var
   a1, a2, a3,
   b1, b2, b3,
   c1, c2, c3: Double;
begin
   a1 := M[0, 0]; a2:= M[0, 1]; a3:= M[0, 2];
   b1 := M[1, 0]; b2:= M[1, 1]; b3:= M[1, 2];
   c1 := M[2, 0]; c2:= M[2, 1]; c3:= M[2, 2];

   Result[0, 0] := (b2*c3 - c2*b3);
   Result[1, 0] :=-(b1*c3 - c1*b3);
   Result[2, 0] := (b1*c2 - c1*b2);

   Result[0, 1] :=-(a2*c3 - c2*a3);
   Result[1, 1] := (a1*c3 - c1*a3);
   Result[2, 1] :=-(a1*c2 - c1*a2);

   Result[0, 2] := (a2*b3 - b2*a3);
   Result[1, 2] :=-(a1*b3 - b1*a3);
   Result[2, 2] := (a1*b2 - b1*a2);
end;

function InvertMatrix(M: TMatrix9): TMatrix9;
var
  I: Integer;
  Det, Scale: Double;
begin
  Det := MatrixDeterminant(M);
  if Abs(Det) < cMathPrecision then
    Result := cIdentityMatrix9
  else
  begin
    Result := AdjointMatrix(M);
    Scale := 1 / Det;
    for I := 0 to 2 do
    begin
      Result[I, 0] := Result[I, 0] * Scale;
      Result[I, 1] := Result[I, 1] * Scale;
      Result[I, 2] := Result[I, 2] * Scale;
    end;
  end;
end;

function Transform(V: TVertex; M: TMatrix9): TVertex;
begin
  Result.X := V.X * M[0, 0] + V.Y * M[1, 0] + M[2, 0];
  Result.Y := V.X * M[0, 1] + V.Y * M[1, 1] + M[2, 1];
end;


{ TMatrix2d }

class function TMatrix2D.Create: TMatrix2D;
begin
  Result.FMatrix := cIdentityMatrix9;
end;

procedure TMatrix2D.GetElements(var AMatrixArray: TMatrix2DArray);
begin
  AMatrixArray[0]:= FMatrix[0, 0];  //m11
  AMatrixArray[1]:= FMatrix[0, 1];  //m12
  AMatrixArray[2]:= FMatrix[1, 0];  //m21
  AMatrixArray[3]:= FMatrix[1, 1];  //m22
  AMatrixArray[4]:= FMatrix[2, 0];  //m31 dX
  AMatrixArray[5]:= FMatrix[2, 1];  //m32 dY
end;

procedure TMatrix2D.Invert;
begin
  FMatrix := InvertMatrix(FMatrix);
end;

procedure TMatrix2D.Multiply(AMatrix: TMatrix2D; AOrder: TMultiplyOrder);
begin
  if AOrder = moAppend then
    FMatrix := MatrixMultiply(FMatrix, AMatrix.FMatrix)
  else
    FMatrix := MatrixMultiply(AMatrix.FMatrix, FMatrix);
end;

procedure TMatrix2D.Reset;
begin
  FMatrix := cIdentityMatrix9;
end;

procedure TMatrix2D.Rotate(AAngle: Double; AOrder: TMultiplyOrder);
var
  MRot: TMatrix9;
begin
  MRot := cIdentityMatrix9;
  AAngle := DegToRad(AAngle);
  MRot[0, 0] := cos(AAngle);
  MRot[0, 1] := sin(AAngle);
  MRot[1, 0] := -sin(AAngle);
  MRot[1, 1] := cos(AAngle);
  if AOrder = moAppend then
    FMatrix := MatrixMultiply(FMatrix, MRot)
  else
    FMatrix := MatrixMultiply(MRot, FMatrix);
end;

procedure TMatrix2D.RotateAt(AAngle: Double; ACenter: TVertex;
  AOrder: TMultiplyOrder);
begin
  if AOrder = moAppend then begin
    Translate(-ACenter.X, -ACenter.Y, AOrder);
    Rotate(AAngle, AOrder);
    Translate(ACenter.X, ACenter.Y, AOrder);
  end
  else begin
    Translate(ACenter.X, ACenter.Y, AOrder);
    Rotate(AAngle, AOrder);
    Translate(-ACenter.X, -ACenter.Y, AOrder);
  end;
end;

procedure TMatrix2D.Scale(AScaleX, AScaleY: Double; AOrder: TMultiplyOrder);
var
  M2: TMatrix9;
begin
  M2 := cIdentityMatrix9;
  M2[0, 0] := AScaleX;
  M2[1, 1] := AScaleY;
  if AOrder = moAppend then
    FMatrix := MatrixMultiply(FMatrix, M2)
  else
    FMatrix := MatrixMultiply(M2, FMatrix);
end;

procedure TMatrix2D.SetElements(AM11, AM12, AM21, AM22, ADx, ADy: Double);
begin
  FMatrix := cIdentityMatrix9;
  FMatrix[0, 0] := AM11;  //m11
  FMatrix[0, 1] := AM12;  //m12
  FMatrix[1, 0] := AM21;  //m21
  FMatrix[1, 1] := AM22;  //m22
  FMatrix[2, 0] := ADx;  //m31 dX
  FMatrix[2, 1] := ADy;  //m32 dY
end;

function TMatrix2D.TransformPoint(APoint: TVertex): TVertex;
begin
  Result := Transform(APoint, FMatrix);
  Result.Z := APoint.Z;
  Result.M := APoint.M;
end;

//procedure TMatrix2d.TransformPoints(APoints: array of TVertex);
//begin
//
//end;

procedure TMatrix2D.Translate(ADx, ADy: Double; AOrder: TMultiplyOrder);
var
  M2: TMatrix9;
begin
  M2 := cIdentityMatrix9;
  M2[2, 0] := ADx;
  M2[2, 1] := ADy;
  if AOrder = moAppend then
    FMatrix := MatrixMultiply(FMatrix, M2)
  else
    FMatrix := MatrixMultiply(M2, FMatrix);
end;


end.
