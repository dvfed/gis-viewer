unit Matrix2DTest;

interface

uses
  TestFramework,
  CommonGeometry,
  GeosGeometry,
  Matrices;

type
  TMatrix2DTest = class(TTestCase)
  private
    FMatrix: TMatrix2D;
    FTestPoint: TVertex;
    procedure CheckArraysEqual(const got, expected: TMatrix2DArray);
    procedure CheckPointsEqual(const got, expected: TVertex);
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

{ TMatrix2DTest }

procedure TMatrix2DTest.CheckArraysEqual(const got, expected: TMatrix2DArray);
var
  i: Integer;
begin
  Check(High(got) = High(expected), 'Arrays sizes not equals!');
  for i := Low(got) to High(got) do
    Check(SameValue(got[i], expected[i], 0.0001), 'Arrays not equals!');
end;

procedure TMatrix2DTest.CheckPointsEqual(const got, expected: TVertex);
begin
  Check(SameValue(got.X, expected.X, 0.0001), 'Points X not equals!');
  Check(SameValue(got.Y, expected.Y, 0.0001), 'Points Y not equals!');
end;

procedure TMatrix2DTest.SetUp;
begin
  inherited;
  // identity matrix
  FMatrix := TMatrix2D.Create;
  FTestPoint.X := 1.0;
  FTestPoint.Y := 0.0;
end;

procedure TMatrix2DTest.TearDown;
begin
  inherited;
end;

procedure TMatrix2DTest.TestIdentity;
var
  got: TMatrix2DArray;
  expected: TMatrix2DArray;
  gotPoint,
  expectedPoint: TVertex;
begin
  expected[0] := 1;    //m11
  expected[1] := 0;      //m12
  expected[2] := 0;      //m21
  expected[3] := 1;     //m22
  expected[4] := 0;  //dx
  expected[5] := 0;   //dy

  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);

  expectedPoint := MakeVertex(1.0, 0.0);

  gotPoint := FMatrix.TransformPoint(FTestPoint);
  CheckPointsEqual(gotPoint, expectedPoint);
end;

procedure TMatrix2DTest.TestRotate;
var
  got: TMatrix2DArray;
  expected: TMatrix2DArray;
  gotPoint,
  expectedPoint: TVertex;
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

  expectedPoint := MakeVertex(0.86602540378, 0.5);

  gotPoint := FMatrix.TransformPoint(FTestPoint);
  CheckPointsEqual(gotPoint, expectedPoint);
end;

procedure TMatrix2DTest.TestRotateAt;
const
  offsetX = 10.0;
  offsetY = 20.0;
  rotAngle = 30;
var
  got,
  expected: TMatrix2DArray;
  expectedMatrix: TMatrix2D;
begin
  expectedMatrix := TMatrix2D.Create;
  // 1st approach
//  expectedMatrix.Translate(-offsetX, -offsetY, moAppend);
//  expectedMatrix.Rotate(rotAngle, moAppend);
//  expectedMatrix.Translate(offsetX, offsetY, moAppend);

  // 2nd approach
  expectedMatrix.Translate(offsetX, offsetY);
  expectedMatrix.Rotate(rotAngle);
  expectedMatrix.Translate(-offsetX, -offsetY);

  // 3rd approach

  expectedMatrix.GetElements(expected);

  // 1st approach
//  FMatrix.RotateAt(rotAngle, MakeVertex(offsetX, offsetY), moAppend);
  // 2nd approach
  FMatrix.RotateAt(rotAngle, MakeVertex(offsetX, offsetY));

  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);
end;

procedure TMatrix2DTest.TestTranslateRotate;
var
  got,
  expected: TMatrix2DArray;
  gotPoint,
  expectedPoint: TVertex;
begin
  expected[0] := 0.86602540378;    //m11
  expected[1] := 0.5;      //m12
  expected[2] := -0.5;      //m21
  expected[3] := 0.86602540378;     //m22
  expected[4] := 10;  //dx
  expected[5] := 20;   //dy

  // 1st approach
//  FMatrix.Translate(10, 20);
//  FMatrix.Rotate(30);

  // 2nd approach
//  FMatrix.Rotate(30);
//  FMatrix.Translate(10, 20, moAppend);

  // 3rd approach
  FMatrix.Rotate(-30);
  FMatrix.Translate(-10, -20);
  FMatrix.Invert;

  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);

  expectedPoint := MakeVertex(10.86602540378, 20.5);

  { (x y 1) * (m11 m12 0  = (x' y' 1)
               m21 m22 0
               dx  dy  1)

    x' = x * eM11 + y * eM21 + eDX
    y' = x * eM12 + y * eM22 + eDY
  }
  // multiply vector (TestPoint) by matrix (self)
  gotPoint := FMatrix.TransformPoint(FTestPoint);
  CheckPointsEqual(gotPoint, expectedPoint);
end;

procedure TMatrix2DTest.TestTranslateRotateScale;
var
  got: TMatrix2DArray;
  expected: TMatrix2DArray;
  gotPoint,
  expectedPoint: TVertex;
begin
  expected[0] := 0.86602540378/2;    //m11
  expected[1] := 0.5/2;      //m12
  expected[2] := -0.5/2;      //m21
  expected[3] := 0.86602540378/2;     //m22
  expected[4] := 10;  //dx
  expected[5] := 20;   //dy

  // 1st approach
//  FMatrix.Translate(10, 20);
//  FMatrix.Rotate(30);
//  FMatrix.Scale(0.5, 0.5);

  // 2nd approach
//  FMatrix.Scale(0.5, 0.5);
//  FMatrix.Rotate(30, moAppend);
//  FMatrix.Translate(10, 20, moAppend);

  // 3rd approach
  FMatrix.Scale(2, 2);
  FMatrix.Rotate(-30);
  FMatrix.Translate(-10, -20);
  FMatrix.Invert;

  FMatrix.GetElements(got);
  CheckArraysEqual(got, expected);

  expectedPoint := MakeVertex(10.43301, 20.25);

  { (x y 1) * (m11 m12 0  = (x' y' 1)
               m21 m22 0
               dx  dy  1)

    x' = x * eM11 + y * eM21 + eDX
    y' = x * eM12 + y * eM22 + eDY
  }
  // multiply vector (TestPoint) by matrix (self)
  gotPoint := FMatrix.TransformPoint(FTestPoint);
  CheckPointsEqual(gotPoint, expectedPoint);
end;

procedure TMatrix2DTest.TestScale;
var
  got: TMatrix2DArray;
  expected: TMatrix2DArray;
  gotPoint,
  expectedPoint: TVertex;
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

  expectedPoint := MakeVertex(2.0, 0.0);

  gotPoint := FMatrix.TransformPoint(FTestPoint);
  CheckPointsEqual(gotPoint, expectedPoint);
end;

procedure TMatrix2DTest.TestSetElement;
var
  got: TMatrix2DArray;
  expected: TMatrix2DArray;
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

procedure TMatrix2DTest.TestTranslate;
var
  got,
  expected: TMatrix2DArray;
  gotPoint,
  expectedPoint: TVertex;
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

  expectedPoint := MakeVertex(1001.0, 2000.0);

  gotPoint := FMatrix.TransformPoint(FTestPoint);
  CheckPointsEqual(gotPoint, expectedPoint);
end;

initialization

  RegisterTest(TMatrix2DTest.Suite);

end.
