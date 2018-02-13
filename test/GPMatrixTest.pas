unit GPMatrixTest;

interface

uses
  TestFramework,
  GDIPOBJ,
  GDIPAPI;

type
  TGPMatrixTest = class(TTestCase)
  private
    FMatrix: TGPMatrix;
    FTestPoint: array[0..0] of TGPPointF;
    procedure CheckArraysEqual(const got, expected: TMatrixArray);
    procedure CheckPointsEqual(const got, expected: TGPPointF);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestIdentity;
    procedure TestSetElement;
    procedure TestScale;
    procedure TestTranslate;
    procedure TestRotate;
    procedure TestTranslateRotate;
    procedure TestTranslateRotateScale;
    procedure TestRotateAt;
  end;

implementation

uses
  System.Math;

{ TGDIPlusTest }

procedure TGPMatrixTest.CheckArraysEqual(const got, expected: TMatrixArray);
var
  i: Integer;
begin
  Check(High(got) = High(expected), 'Arrays sizes not equals!');
  for i := Low(got) to High(got) do
    Check(SameValue(got[i], expected[i], 0.0001), 'Arrays not equals!');
end;

procedure TGPMatrixTest.CheckPointsEqual(const got, expected: TGPPointF);
begin
  Check(SameValue(got.X, expected.X, 0.0001), 'Points X not equals!');
  Check(SameValue(got.Y, expected.Y, 0.0001), 'Points Y not equals!');
end;

procedure TGPMatrixTest.SetUp;
begin
  inherited;
  // identity matrix
  FMatrix := TGPMatrix.Create;
  FTestPoint[0].X := 1.0;
  FTestPoint[0].Y := 0.0;
end;

procedure TGPMatrixTest.TearDown;
begin
  inherited;
  FMatrix.Free;
end;

procedure TGPMatrixTest.TestIdentity;
var
  got: TMatrixArray;
  expected: TMatrixArray;
  expectedPoint: TGPPointF;
begin
  expected[0] := 1;    //m11
  expected[1] := 0;      //m12
  expected[2] := 0;      //m21
  expected[3] := 1;     //m22
  expected[4] := 0;  //dx
  expected[5] := 0;   //dy

  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);

  expectedPoint := MakePoint(1.0, 0.0);

  FMatrix.TransformPoints(PGPPoint(@FTestPoint), 1);
  CheckPointsEqual(FTestPoint[0], expectedPoint);
end;

procedure TGPMatrixTest.TestRotate;
var
  got: TMatrixArray;
  expected: TMatrixArray;
  expectedPoint: TGPPointF;
begin
  {0.86602540378	0.50000000000
  -0.50000000000	0.86602540378
  }
  expected[0] := 0.86602540378;    //m11
  expected[1] := 0.5;      //m12
  expected[2] := -0.5;      //m21
  expected[3] := 0.86602540378;     //m22
  expected[4] := 0;  //dx
  expected[5] := 0;   //dy

  // counter clockwise?
  FMatrix.Rotate(30);

  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);

  expectedPoint := MakePoint(0.86602540378, 0.5);

  FMatrix.TransformPoints(PGPPointF(@FTestPoint));
  CheckPointsEqual(FTestPoint[0], expectedPoint);
end;

procedure TGPMatrixTest.TestRotateAt;
const
  offsetX = 10.0;
  offsetY = 20.0;
  rotAngle = 30;
var
  got,
  expected: TMatrixArray;
  expectedMatrix: TGPMatrix;
begin
  expectedMatrix := TGPMatrix.Create;
  // 1st approach
  expectedMatrix.Translate(-offsetX, -offsetY, MatrixOrderAppend);
  expectedMatrix.Rotate(rotAngle, MatrixOrderAppend);
  expectedMatrix.Translate(offsetX, offsetY, MatrixOrderAppend);

  // 2nd approach

  // 3rd approach

  expectedMatrix.GetElements(expected);
  expectedMatrix.Free;

  FMatrix.RotateAt(rotAngle, MakePoint(offsetX, offsetY));
  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);
end;

procedure TGPMatrixTest.TestTranslateRotate;
var
  got: TMatrixArray;
  expected: TMatrixArray;
  expectedPoint: TGPPointF;
begin
  expected[0] := 0.86602540378;    //m11
  expected[1] := 0.5;      //m12
  expected[2] := -0.5;      //m21
  expected[3] := 0.86602540378;     //m22
  expected[4] := 10;  //dx
  expected[5] := 20;   //dy

  // 1st approach
  FMatrix.Translate(10, 20);
  FMatrix.Rotate(30);

  // 2nd approach
//  FMatrix.Rotate(30);
//  FMatrix.Translate(10, 20, MatrixOrderAppend);

  // 3rd approach
//  FMatrix.Rotate(-30);
//  FMatrix.Translate(-10, -20);
//  FMatrix.Invert;

  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);

  expectedPoint := MakePoint(10.86602540378, 20.5);

  { (x y 1) * (m11 m12 0  = (x' y' 1)
               m21 m22 0
               dx  dy  1)

    x' = x * eM11 + y * eM21 + eDX
    y' = x * eM12 + y * eM22 + eDY
  }
  // multiply vector (TestPoint) by matrix (self)
  FMatrix.TransformPoints(PGPPointF(@FTestPoint));
  CheckPointsEqual(FTestPoint[0], expectedPoint);
end;

procedure TGPMatrixTest.TestTranslateRotateScale;
var
  got: TMatrixArray;
  expected: TMatrixArray;
  expectedPoint: TGPPointF;
begin
  expected[0] := 0.86602540378/2;    //m11
  expected[1] := 0.5/2;      //m12
  expected[2] := -0.5/2;      //m21
  expected[3] := 0.86602540378/2;     //m22
  expected[4] := 10;  //dx
  expected[5] := 20;   //dy

  // 1st approach
  FMatrix.Translate(10, 20);
  FMatrix.Rotate(30);
  FMatrix.Scale(0.5, 0.5);

  // 2nd approach
//  FMatrix.Scale(0.5, 0.5);
//  FMatrix.Rotate(30, MatrixOrderAppend);
//  FMatrix.Translate(10, 20, MatrixOrderAppend);

  // 3rd approach
//  FMatrix.Scale(2, 2);
//  FMatrix.Rotate(-30);
//  FMatrix.Translate(-10, -20);
//  FMatrix.Invert;

  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);

  expectedPoint := MakePoint(10.43301, 20.25);

  { (x y 1) * (m11 m12 0  = (x' y' 1)
               m21 m22 0
               dx  dy  1)

    x' = x * eM11 + y * eM21 + eDX
    y' = x * eM12 + y * eM22 + eDY
  }
  // multiply vector (TestPoint) by matrix (self)
  FMatrix.TransformPoints(PGPPointF(@FTestPoint));
  CheckPointsEqual(FTestPoint[0], expectedPoint);
end;

procedure TGPMatrixTest.TestScale;
var
  got: TMatrixArray;
  expected: TMatrixArray;
  expectedPoint: TGPPointF;
begin
  expected[0] := 2;    //m11
  expected[1] := 0;      //m12
  expected[2] := 0;      //m21
  expected[3] := 2;     //m22
  expected[4] := 0;  //dx
  expected[5] := 0;   //dy

  FMatrix.Scale(2.0, 2.0);

  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);

  expectedPoint := MakePoint(2.0, 0.0);

  FMatrix.TransformPoints(PGPPointF(@FTestPoint));
  CheckPointsEqual(FTestPoint[0], expectedPoint);
end;

procedure TGPMatrixTest.TestSetElement;
var
  got: TMatrixArray;
  expected: TMatrixArray;
begin
  expected[0] := 0.9;    //m11
  expected[1] := 0.5;      //m12
  expected[2] := -0.5;      //m21
  expected[3] := 1.1;     //m22
  expected[4] := 21000;  //dx
  expected[5] := 1000;   //dy

  //m11, m12, m21, m22, dx, dy
  FMatrix.SetElements(0.9, 0.5, -0.5, 1.1, 21000, 1000);

  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);
end;

procedure TGPMatrixTest.TestTranslate;
var
  got: TMatrixArray;
  expected: TMatrixArray;
  expectedPoint: TGPPointF;
begin
  expected[0] := 1;    //m11
  expected[1] := 0;      //m12
  expected[2] := 0;      //m21
  expected[3] := 1;     //m22
  expected[4] := 1000;  //dx
  expected[5] := 2000;   //dy

  FMatrix.Translate(1000, 2000);

  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);

  expectedPoint := MakePoint(1001.0, 2000.0);

  FMatrix.TransformPoints(PGPPointF(@FTestPoint), 1);
  CheckPointsEqual(FTestPoint[0], expectedPoint);
end;

initialization

  // Register any test cases with the test runner
  RegisterTest(TGPMatrixTest.Suite);

end.
