unit Main;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Vcl.Buttons,
  Vcl.Dialogs,
  MapTypes,
  MapControl,
  Loader;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    ZoomInButton: TButton;
    PanDownButton: TButton;
    PanUpButton: TButton;
    PanRightButton: TButton;
    PanLeftButton: TButton;
    ZoomAllButton: TButton;
    ZoomOutButton: TButton;
    comboPropertyValues: TComboBox;
    LoadButton: TButton;
    MapControl1: TMapControl;
    Zoom1x1: TButton;
    StatusBar1: TStatusBar;
    ZoommingButton: TSpeedButton;
    PanningButton: TSpeedButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    MapControl2: TMapControl;
    Panel2: TPanel;
    Panel3: TPanel;
    comboPropertyNames: TComboBox;
    comboLayers: TComboBox;
    dialogOpenProject: TOpenDialog;
    procedure LoadButtonClick(Sender: TObject);
    procedure ZoomInButtonClick(Sender: TObject);
    procedure ZoomOutButtonClick(Sender: TObject);
    procedure ZoomAllButtonClick(Sender: TObject);
    procedure comboPropertyValuesChange(Sender: TObject);
    procedure PanDownButtonClick(Sender: TObject);
    procedure PanLeftButtonClick(Sender: TObject);
    procedure PanRightButtonClick(Sender: TObject);
    procedure PanUpButtonClick(Sender: TObject);
    procedure Zoom1x1Click(Sender: TObject);
    // used by both MapControls
    procedure MapControlMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ZoommingButtonClick(Sender: TObject);
    procedure PanningButtonClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure comboPropertyNamesChange(Sender: TObject);
    procedure comboLayersChange(Sender: TObject);
  private
    { Private declarations }
    FProject: TProject;
    procedure ActivateModel;
    function IsModelActive: boolean;
    function CurrentMapControl: TMapControl;
    procedure UpdateGUI;
    procedure UpdateLayersCombo;
    procedure UpdatePropertyNamesCombo;
    procedure UpdatePropertyValuesCombo(const APropertyName: string);
  end;

var
  Form1: TForm1;

implementation

uses
  GDIPAPI,
  Properties;

{$R *.dfm}

procedure TForm1.LoadButtonClick(Sender: TObject);
begin
  if dialogOpenProject.Execute then begin
    LoadButton.Enabled := False;
    FProject := TProject.Create(dialogOpenProject.FileName);
    PageControl1.Visible := True;
    Screen.Cursor := crHourglass;
    try
      FProject.Load;
      MapControl1.Win := FProject.ModelWin;
      MapControl1.ZoomAll;
      MapControl2.Win := FProject.LayoutWin;
      MapControl2.ZoomAll;
      ActivateModel;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TForm1.MapControlMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if not (CurrentMapControl.HasData) then
    Exit;
  StatusBar1.Panels[0].Text := {'PixelXY: ' + }IntToStr(X) + ',' + IntToStr(Y);
  StatusBar1.Panels[1].Text := {' WorldXY: ' +}
    FloatToStrF(CurrentMapControl.WorldPos.Y, ffFixed, 10, 3) + ','
    + FloatToStrF(CurrentMapControl.WorldPos.X, ffFixed, 10, 3);
end;

procedure TForm1.ZoomInButtonClick(Sender: TObject);
begin
  CurrentMapControl.ZoomIn;
end;

procedure TForm1.ZoomOutButtonClick(Sender: TObject);
begin
  CurrentMapControl.ZoomOut;
end;

procedure TForm1.Zoom1x1Click(Sender: TObject);
begin
  CurrentMapControl.Zoom1x1;
end;

procedure TForm1.ZoomAllButtonClick(Sender: TObject);
begin
  CurrentMapControl.ZoomAll;
end;

procedure TForm1.ActivateModel;
begin
  PageControl1.ActivePageIndex := 0;
  UpdateGUI;
end;

procedure TForm1.comboPropertyValuesChange(Sender: TObject);
var
  propName, propValue: string;
  Style: TDrawStyle;
  layIndex: Integer;
begin
  layIndex := comboLayers.ItemIndex;
  propName := comboPropertyNames.Text;
  propValue := comboPropertyValues.Text;

  // populate style manager by rules Layer == Color, but first clear
  with CurrentMapControl do begin
    (Data.Features[layIndex] as TLayer).ClearStyles;
    Style.PenColor := aclRed;
    Style.BrushColor := aclLightCoral;
    (Data.Features[layIndex] as TLayer).AddStyle(propName, propValue, style);
  end;
  CurrentMapControl.Repaint;
end;

procedure TForm1.comboLayersChange(Sender: TObject);
begin
  UpdatePropertyNamesCombo;
end;

procedure TForm1.comboPropertyNamesChange(Sender: TObject);
begin
  UpdatePropertyValuesCombo(comboPropertyNames.Text);
end;

function TForm1.CurrentMapControl: TMapControl;
begin
  if IsModelActive then
    Result := MapControl1
  else
    Result := MapControl2;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FProject.Free;
end;

procedure TForm1.UpdateGUI;
begin
  UpdateLayersCombo;
  comboPropertyNames.Clear;
  comboPropertyValues.Clear;
  // tools
  ZoommingButton.Down := mcsZooming in CurrentMapControl.Tool;
  PanningButton.Down := mcsPanning in CurrentMapControl.Tool;
end;

procedure TForm1.UpdateLayersCombo;
var
  count: Integer;
  F: TFeature;
begin
  count := 1;
  comboLayers.Clear;
  for F in CurrentMapControl.Data.Features do  begin
    comboLayers.Items.Add('L' + IntToStr(count));
    count := count + 1;
  end;
end;

procedure TForm1.UpdatePropertyNamesCombo;
var
  layIndex: Integer;
begin
  layIndex := comboLayers.ItemIndex;
  comboPropertyNames.Clear;
  comboPropertyValues.Clear;
  comboPropertyNames.Items.Assign(
    (CurrentMapControl.Data.Features[layIndex] as TLayer).Model.GetPropertyNames);
end;

procedure TForm1.UpdatePropertyValuesCombo(const APropertyName: string);
var
  layIndex: Integer;
begin
  layIndex := comboLayers.ItemIndex;
  comboPropertyValues.Clear;
  comboPropertyValues.Items.Assign(
    (CurrentMapControl.Data.Features[layIndex] as TLayer).Model.GetPropertyValues(APropertyName));
end;

function TForm1.IsModelActive: boolean;
begin
  Result := PageControl1.ActivePageIndex = 0;
end;

procedure TForm1.PageControl1Change(Sender: TObject);
begin
  UpdateGUI;
end;

procedure TForm1.PanDownButtonClick(Sender: TObject);
begin
  CurrentMapControl.PanDown;
end;

procedure TForm1.PanLeftButtonClick(Sender: TObject);
begin
  CurrentMapControl.PanLeft;
end;

procedure TForm1.PanningButtonClick(Sender: TObject);
begin
  PanningButton.Down := True;
  CurrentMapControl.Tool := [mcsPanning];
end;

procedure TForm1.PanRightButtonClick(Sender: TObject);
begin
  CurrentMapControl.PanRight;
end;

procedure TForm1.PanUpButtonClick(Sender: TObject);
begin
  CurrentMapControl.PanUp;
end;

procedure TForm1.ZoommingButtonClick(Sender: TObject);
begin
  ZoommingButton.Down := True;
  CurrentMapControl.Tool := [mcsZooming];
end;

end.
