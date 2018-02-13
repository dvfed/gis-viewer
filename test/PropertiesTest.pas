unit PropertiesTest;

interface

uses
  TestFramework,
  Properties;

type
  TPropertyDefTableTest = class(TTestCase)
  private
    FDefTable: TPropertyDefTable;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestConstruction;
    procedure TestFindDef;
  end;

  TPropertyPoolTest = class(TTestCase)
  private
    FDefTable: TPropertyDefTable;
    FPool: TPropertyPool;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestEmptyAfterCreation;
    procedure TestAddEqualProperties;
    procedure TestAddDifferentProperties;
    procedure TestAddAnyProperties;
    procedure TestSamePropertyFound;
    procedure TestDelete;
  end;

implementation

{ TPropertyPoolTest }

procedure TPropertyDefTableTest.SetUp;
var
  first, second: TPropertyDef;
begin
  inherited;
  FDefTable := TPropertyDefTable.Create;

  first := TPropertyDef.Create('First');
  second := TPropertyDef.Create('Second');

  FDefTable.Add(first);
  FDefTable.Add(second);
end;

procedure TPropertyDefTableTest.TearDown;
begin
  inherited;
  FDefTable.Free;
end;

procedure TPropertyDefTableTest.TestConstruction;
begin
  Check(Assigned(FDefTable), 'FDefTable = nil');
  Check(FDefTable.Count = 2, 'Count <> 2');
end;

procedure TPropertyDefTableTest.TestFindDef;
var
  def: TPropertyDef;
begin
  def := FDefTable.FindDef('First');
  Check(Assigned(def), 'def = nil');
  Check(def.Name = 'First', 'Name <> First');
end;

{ TPropertyPoolTest }

procedure TPropertyPoolTest.SetUp;
begin
  inherited;
  FDefTable := TPropertyDefTable.Create;
  FDefTable.Add(TPropertyDef.Create('First'));
  FDefTable.Add(TPropertyDef.Create('Second'));
  FDefTable.Add(TPropertyDef.Create('Third'));

  FPool := TPropertyPool.Create(FDefTable);
end;

procedure TPropertyPoolTest.TearDown;
begin
  inherited;
  FPool.Free;
  FDefTable.Free;
end;

procedure TPropertyPoolTest.TestAddAnyProperties;
begin
  FPool.FindOrCreate('First', 'String1');
  FPool.FindOrCreate('First', 'String2');
  FPool.FindOrCreate('Second', '2.000');
  FPool.FindOrCreate('Second', '2.000');

  Check(FPool.Count = 3, 'Count <> 3');
end;

procedure TPropertyPoolTest.TestAddDifferentProperties;
begin
  FPool.FindOrCreate('First', 'String1');
  FPool.FindOrCreate('First', 'String2');
  FPool.FindOrCreate('Second', '2.000');
  FPool.FindOrCreate('Second', '4.000');

  Check(FPool.Count = 4, 'Count <> 4');
end;

procedure TPropertyPoolTest.TestAddEqualProperties;
begin
  FPool.FindOrCreate('First', 'String');
  FPool.FindOrCreate('First', 'String');
  FPool.FindOrCreate('Second', '2.000');
  FPool.FindOrCreate('Second', '2.000');

  Check(FPool.Count = 2, 'Count <> 2');
end;

procedure TPropertyPoolTest.TestDelete;
var
  prop: TProperty;
begin
  // one property - two usages
  prop := FPool.FindOrCreate('First', 'String');
  FPool.FindOrCreate('First', 'String');
  Check(FPool.Count = 1, 'Count <> 1');

  FPool.Delete(prop);
  Check(FPool.Count = 1, 'Count <> 1 after Delete');

  FPool.Delete(prop);
  Check(FPool.Count = 0, 'Count <> 0 after second Delete');
end;

procedure TPropertyPoolTest.TestSamePropertyFound;
var
  prop1, prop2: TProperty;
begin
  prop1 := FPool.FindOrCreate('First', 'String');
  prop2 := FPool.FindOrCreate('First', 'String');

  Check(FPool.Count = 1, 'Count <> 1');
  Check(prop1 = prop2, 'Must be the same object!')
end;

procedure TPropertyPoolTest.TestEmptyAfterCreation;
begin
  Check(Assigned(FPool), 'FPool = nil');
  Check(FPool.Count = 0, 'Count <> 0');
end;

initialization

  RegisterTest(TPropertyDefTableTest.Suite);
  RegisterTest(TPropertyPoolTest.Suite);

end.
