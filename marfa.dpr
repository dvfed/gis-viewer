program marfa;

uses
  Vcl.Forms,
  GDIPOBJ in 'src\GDIPlus\GDIPOBJ.pas',
  GDIPAPI in 'src\GDIPlus\GDIPAPI.pas',
  Geos_c in 'src\Geos_c.pas',
  GeosGeometry in 'src\GeosGeometry.pas',
  CommonGeometry in 'src\CommonGeometry.pas',
  Storages in 'src\Storages.pas',
  Features in 'src\Features.pas',
  MapTypes in 'src\MapTypes.pas',
  Matrices in 'src\Matrices.pas',
  Properties in 'src\Properties.pas',
  Renderers in 'src\Renderers.pas',
  Main in 'src\Main.pas' {Form1},
  MapControl in 'src\MapControl.pas',
  Loader in 'src\Loader.pas',
  SimpleXML in 'src\SimpleXML\SimpleXML.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
