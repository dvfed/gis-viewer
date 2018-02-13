unit RegExpTest;

interface

uses
  TestFramework,
  System.RegularExpressions;

type
  TRegExpTest = class(TTestCase)
  private
    FRegExp: TRegEx;
    FPattern: string;
    FInput: string;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCharColumnMatch;
    procedure TestExtractGroupValueByNumber;
    procedure TestExtractGroupValueByName;
    procedure TestUniversalColumnMatch;
    procedure TestDelimiterMatch;
    procedure TestVersionMatch;
    procedure TestAttributesListMatchNoEmpty;
    procedure TestAttributesListMatchNoEmptyQuoted;
    procedure TestAttributesListMatchFirstEmpty;
    procedure TestAttributesListMatchLastEmpty;
    procedure TestAttributesListMatchOnlyOneField;
    procedure TestAttributesListMatchOnlyOneFieldEmptyFails;
    procedure TestAttributesListMatchTwoFieldsEmpty;
    procedure TestCharsetMatch;
    procedure TestColumnsNumberMatch;
    procedure TestPairOfXYCoords;
    procedure TestStartWithCoordSys;
  end;

implementation

uses
  System.SysUtils;

{ TRegExpTest }

procedure TRegExpTest.SetUp;
begin
  inherited;
  { for TestAttributes family only }
  { Kept as inspiration
    FPattern := '(?<=^|,)(\"(?:[^\"]|\"\")*\"|[^,]*)';
    FPattern := '(,|^)([^",]*|"(?:[^"]|"")*")?';
  }
  FPattern := '(,|^)("(?:[^"]|"")*"|[^,]*)?';
end;

procedure TRegExpTest.TearDown;
begin
  inherited;

end;

procedure TRegExpTest.TestAttributesListMatchNoEmpty;
begin
  FInput := '102631446,27701,RA_NO_202,20040128,350006747,20040128,0';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput), 'NoEmpty fail');
  Check(FRegExp.Matches(FInput).Count = 7, 'Count=' + IntToStr(FRegExp.Matches(FInput).Count));
  Check(FRegExp.Matches(FInput).Item[0].Groups[1].Value = '', '[0][1]=' + FRegExp.Matches(FInput).Item[0].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[0].Groups[2].Value = '102631446', '[0][2]=' + FRegExp.Matches(FInput).Item[0].Groups[2].Value);
  Check(FRegExp.Matches(FInput).Item[1].Groups[1].Value = ',', '[1][1]=' + FRegExp.Matches(FInput).Item[1].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[1].Groups[2].Value = '27701', '[1][2]=' + FRegExp.Matches(FInput).Item[1].Groups[2].Value);
  Check(FRegExp.Matches(FInput).Item[5].Groups[1].Value = ',', '[5][1]=' + FRegExp.Matches(FInput).Item[5].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[5].Groups[2].Value = '20040128', '[5][2]=' + FRegExp.Matches(FInput).Item[5].Groups[2].Value);
end;

procedure TRegExpTest.TestAttributesListMatchNoEmptyQuoted;
begin
  FInput := '"4","37","Äàíèëåâñêîãî","óë.","","3, ""×È×ÈÁÀÁÈÍÀ"" ÁÎÐÈÑÀ ÓË.","L"';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput), 'NoEmptyQuoted fail');
  Check(FRegExp.Matches(FInput).Item[0].Groups[1].Value = '', '[0][1]=' + FRegExp.Matches(FInput).Item[0].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[0].Groups[2].Value = '"4"', '[0][2]=' + FRegExp.Matches(FInput).Item[0].Groups[2].Value);
  Check(FRegExp.Matches(FInput).Item[2].Groups[1].Value = ',', '[2][1]=' + FRegExp.Matches(FInput).Item[1].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[2].Groups[2].Value = '"Äàíèëåâñêîãî"', '[2][2]=' + FRegExp.Matches(FInput).Item[1].Groups[2].Value);
  Check(FRegExp.Matches(FInput).Item[5].Groups[1].Value = ',', '[5][1]=' + FRegExp.Matches(FInput).Item[5].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[5].Groups[2].Value = '"3, ""×È×ÈÁÀÁÈÍÀ"" ÁÎÐÈÑÀ ÓË."', '[5][2]=' + FRegExp.Matches(FInput).Item[5].Groups[2].Value);
end;

procedure TRegExpTest.TestAttributesListMatchOnlyOneField;
begin
  FInput := '0';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput), 'IsMatch failed');
  Check(FRegExp.Matches(FInput).Count = 1, 'Count=' + IntToStr(FRegExp.Matches(FInput).Count));
  Check(FRegExp.Matches(FInput).Item[0].Groups[1].Value = '', '[0][1]=' + FRegExp.Matches(FInput).Item[0].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[0].Groups[2].Value = '0', '[0][2]=' + FRegExp.Matches(FInput).Item[0].Groups[2].Value);
end;

procedure TRegExpTest.TestAttributesListMatchOnlyOneFieldEmptyFails;
begin
  FInput := '';
  FRegExp.Create(FPattern);
  Check(not FRegExp.IsMatch(FInput), 'IsMatch should fail');
end;

procedure TRegExpTest.TestAttributesListMatchTwoFieldsEmpty;
begin
  FInput := ',';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput), 'IsMatch failed');
  Check(FRegExp.Matches(FInput).Count = 1, 'Count=' + IntToStr(FRegExp.Matches(FInput).Count));
  Check(FRegExp.Matches(FInput).Item[0].Groups[1].Value = ',', '[0][1]=' + FRegExp.Matches(FInput).Item[0].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[0].Groups[2].Value = '', '[0][2]=' + FRegExp.Matches(FInput).Item[0].Groups[2].Value);
end;

procedure TRegExpTest.TestAttributesListMatchFirstEmpty;
begin
  FInput := ',27701,RA_NO_202,20040128,350006747,20040128,';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput), 'IsMatch failed');
  Check(FRegExp.Matches(FInput).Count = 6, 'Count=' + IntToStr(FRegExp.Matches(FInput).Count));
  Check(FRegExp.Matches(FInput).Item[0].Groups[1].Value = ',', '[0][1]=' + FRegExp.Matches(FInput).Item[0].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[0].Groups[2].Value = '27701', '[0][2]=' + FRegExp.Matches(FInput).Item[0].Groups[2].Value);
  Check(FRegExp.Matches(FInput).Item[1].Groups[1].Value = ',', '[1][1]=' + FRegExp.Matches(FInput).Item[1].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[1].Groups[2].Value = 'RA_NO_202', '[1][2]=' + FRegExp.Matches(FInput).Item[1].Groups[2].Value);
  Check(FRegExp.Matches(FInput).Item[5].Groups[1].Value = ',', '[5][1]=' + FRegExp.Matches(FInput).Item[5].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[5].Groups[2].Value = '', '[5][2]=' + FRegExp.Matches(FInput).Item[5].Groups[2].Value);
end;

procedure TRegExpTest.TestAttributesListMatchLastEmpty;
begin
  FInput := '0,27701,RA_NO_202,20040128,350006747,20040128,';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput), 'IsMatch failed');
  Check(FRegExp.Matches(FInput).Count = 7, 'Count=' + IntToStr(FRegExp.Matches(FInput).Count));
  Check(FRegExp.Matches(FInput).Item[0].Groups[1].Value = '', '[0][1]=' + FRegExp.Matches(FInput).Item[0].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[0].Groups[2].Value = '0', '[0][2]=' + FRegExp.Matches(FInput).Item[0].Groups[2].Value);
  Check(FRegExp.Matches(FInput).Item[2].Groups[1].Value = ',', '[2][1]=' + FRegExp.Matches(FInput).Item[2].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[2].Groups[2].Value = 'RA_NO_202', '[2][2]=' + FRegExp.Matches(FInput).Item[2].Groups[2].Value);
  Check(FRegExp.Matches(FInput).Item[6].Groups[1].Value = ',', '[6][1]=' + FRegExp.Matches(FInput).Item[6].Groups[1].Value);
  Check(FRegExp.Matches(FInput).Item[6].Groups[2].Value = '', '[6][2]=' + FRegExp.Matches(FInput).Item[6].Groups[2].Value);
end;

procedure TRegExpTest.TestCharColumnMatch;
begin
  FPattern := '^\s*\w+\s+\w+\s*\(\d+\)';
  FInput := '  NAME_UKR Char(64)';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput));
end;

procedure TRegExpTest.TestCharsetMatch;
begin
  FPattern := '^\s*CHARSET\s+"(?P<charset>\w+)"';

  FInput := 'Charset "WindowsCyrillic"';
  FRegExp.Create(FPattern, [roIgnoreCase]);
  Check(FRegExp.IsMatch(FInput));
  Check(FRegExp.Match(FInput).Groups['charset'].Value = 'WindowsCyrillic');
end;

procedure TRegExpTest.TestColumnsNumberMatch;
begin
  FPattern := '^\s*COLUMNS\s+(?P<columns_number>\d+)';

  FInput := 'COLUMNS 7';
  FRegExp.Create(FPattern, [roIgnoreCase]);
  Check(FRegExp.IsMatch(FInput));
  Check(FRegExp.Match(FInput).Groups['columns_number'].Value = '7');
end;

procedure TRegExpTest.TestDelimiterMatch;
begin
  FPattern := '^\s*DELIMITER\s+"(?P<delimiter>.)"';

  FInput := 'DELIMITER ","';
  FRegExp.Create(FPattern, [roIgnoreCase]);
  Check(FRegExp.IsMatch(FInput));
  Check(FRegExp.Match(FInput).Groups['delimiter'].Value = ',');

  FInput := 'Delimiter ","';
  FRegExp.Create(FPattern, [roIgnoreCase]);
  Check(FRegExp.IsMatch(FInput));
  Check(FRegExp.Match(FInput).Groups['delimiter'].Value = ',');
end;

procedure TRegExpTest.TestUniversalColumnMatch;
begin
  FPattern := '^\s*(?P<name>\w+)\s+(?P<type>\w+)(\s*\((?P<length>\d+)(,?(?P<precision>\d+)?)\))?';

  FInput := '    PFI_CREATED date';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput), 'date match fails');
  Check(FRegExp.Match(FInput).Groups['name'].Value = 'PFI_CREATED');
  Check(FRegExp.Match(FInput).Groups['type'].Value = 'date');
  { Access to non-existent group doesn't allowed!
  Check(FRegExp.Match(FInput).Groups['length'].Value = '');}

  FInput := '    FEATURE_QUALITY_ID char(20)';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput), 'char(20) match fails');
  Check(FRegExp.Match(FInput).Groups['name'].Value = 'FEATURE_QUALITY_ID');
  Check(FRegExp.Match(FInput).Groups['type'].Value = 'char');
  Check(FRegExp.Match(FInput).Groups['length'].Value = '20');

  FInput := '    UFI decimal(12,0)';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput), 'decimal(12,0) match fails');
  Check(FRegExp.Match(FInput).Groups['name'].Value = 'UFI');
  Check(FRegExp.Match(FInput).Groups['type'].Value = 'decimal');
  Check(FRegExp.Match(FInput).Groups['length'].Value = '12');
  Check(FRegExp.Match(FInput).Groups['precision'].Value = '0');
end;

procedure TRegExpTest.TestVersionMatch;
begin
  FPattern := '^\s*VERSION\s+(?P<version>\d{3})';

  FInput := 'VERSION 300';
  FRegExp.Create(FPattern, [roIgnoreCase]);
  Check(FRegExp.IsMatch(FInput));
  Check(FRegExp.Match(FInput).Groups['version'].Value = '300');

  FInput := 'Version 300';
  FRegExp.Create(FPattern, [roIgnoreCase]);
  Check(FRegExp.IsMatch(FInput));
  Check(FRegExp.Match(FInput).Groups['version'].Value = '300');
end;

procedure TRegExpTest.TestExtractGroupValueByName;
begin
  FPattern := '^\s*(?P<name>\w+)\s+(?P<type>\w+)\s*\((?P<length>\d+)\)';
  FInput := '  NAME_UKR Char(64)';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput));
  Check(FRegExp.Match(FInput).Groups['name'].Value = 'NAME_UKR');
  Check(FRegExp.Match(FInput).Groups['type'].Value = 'Char');
  Check(FRegExp.Match(FInput).Groups['length'].Value = '64');
end;

procedure TRegExpTest.TestExtractGroupValueByNumber;
begin
  FPattern := '^\s*(\w+)\s+(\w+)\s*\((\d+)\)';
  FInput := '  NAME_UKR Char(64)';
  FRegExp.Create(FPattern);
  Check(FRegExp.IsMatch(FInput));
  Check(FRegExp.Match(FInput).Groups[1].Value = 'NAME_UKR');
  Check(FRegExp.Match(FInput).Groups[2].Value = 'Char');
  Check(FRegExp.Match(FInput).Groups[3].Value = '64');
end;

procedure TRegExpTest.TestPairOfXYCoords;
begin
  FPattern := '^\s*(?P<x>[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+))\s+(?P<y>[-+]?([0-9]+(\.[0-9]*)?|\.[0-9]+))';

  FInput := '2467897.94083642 2450415.94219368';
  FRegExp.Create(FPattern, [roIgnoreCase]);
  Check(FRegExp.IsMatch(FInput), '0.00 fail');
  Check(FRegExp.Match(FInput).Groups['x'].Value = '2467897.94083642');
  Check(FRegExp.Match(FInput).Groups['y'].Value = '2450415.94219368');

  FInput := '24 94';
  FRegExp.Create(FPattern, [roIgnoreCase]);
  Check(FRegExp.IsMatch(FInput), '0 fail');
  Check(FRegExp.Match(FInput).Groups['x'].Value = '24');
  Check(FRegExp.Match(FInput).Groups['y'].Value = '94');

  FInput := '24. 94.';
  FRegExp.Create(FPattern, [roIgnoreCase]);
  Check(FRegExp.IsMatch(FInput), '0. fail');
  Check(FRegExp.Match(FInput).Groups['x'].Value = '24.');
  Check(FRegExp.Match(FInput).Groups['y'].Value = '94.');

  FInput := '.24 .94';
  FRegExp.Create(FPattern, [roIgnoreCase]);
  Check(FRegExp.IsMatch(FInput), '.00 fail');
  Check(FRegExp.Match(FInput).Groups['x'].Value = '.24');
  Check(FRegExp.Match(FInput).Groups['y'].Value = '.94');
end;

procedure TRegExpTest.TestStartWithCoordSys;
begin
  FPattern := '^\s*COORDSYS';

  FInput := ' CoordSys Earth Projection 3, 116, "m", 145, -37, -36, -38, 2500000, 2500000 Bounds (1500000,1500000) (3500000,3500000)';
  FRegExp.Create(FPattern, [roIgnoreCase]);
  Check(FRegExp.IsMatch(FInput));
end;

initialization

  RegisterTest(TRegExpTest.Suite);

end.
