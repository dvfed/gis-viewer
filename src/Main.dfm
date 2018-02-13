object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'MaRFA project'
  ClientHeight = 505
  ClientWidth = 753
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 753
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object ZoommingButton: TSpeedButton
      Left = 696
      Top = 8
      Width = 23
      Height = 22
      AllowAllUp = True
      GroupIndex = 1
      Caption = '+'
      OnClick = ZoommingButtonClick
    end
    object PanningButton: TSpeedButton
      Left = 725
      Top = 8
      Width = 23
      Height = 22
      AllowAllUp = True
      GroupIndex = 1
      Caption = '>'
      OnClick = PanningButtonClick
    end
    object ZoomInButton: TButton
      Left = 448
      Top = 8
      Width = 25
      Height = 25
      Caption = '+'
      TabOrder = 0
      OnClick = ZoomInButtonClick
    end
    object PanDownButton: TButton
      Left = 665
      Top = 8
      Width = 25
      Height = 25
      Caption = '\/'
      TabOrder = 1
      OnClick = PanDownButtonClick
    end
    object PanUpButton: TButton
      Left = 634
      Top = 8
      Width = 25
      Height = 25
      Caption = '/\'
      TabOrder = 2
      OnClick = PanUpButtonClick
    end
    object PanRightButton: TButton
      Left = 603
      Top = 8
      Width = 25
      Height = 25
      Caption = '>'
      TabOrder = 3
      OnClick = PanRightButtonClick
    end
    object PanLeftButton: TButton
      Left = 572
      Top = 8
      Width = 25
      Height = 25
      Caption = '<'
      TabOrder = 4
      OnClick = PanLeftButtonClick
    end
    object ZoomAllButton: TButton
      Left = 510
      Top = 8
      Width = 25
      Height = 25
      Caption = 'ALL'
      TabOrder = 5
      OnClick = ZoomAllButtonClick
    end
    object ZoomOutButton: TButton
      Left = 479
      Top = 8
      Width = 25
      Height = 25
      Caption = '-'
      TabOrder = 6
      OnClick = ZoomOutButtonClick
    end
    object comboPropertyValues: TComboBox
      Left = 296
      Top = 10
      Width = 146
      Height = 21
      Hint = #1047#1085#1072#1095#1077#1085#1080#1103' '#1072#1090#1088#1080#1073#1091#1090#1086#1074
      ParentShowHint = False
      ShowHint = True
      TabOrder = 7
      OnChange = comboPropertyValuesChange
    end
    object LoadButton: TButton
      Left = 8
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Open'
      TabOrder = 8
      OnClick = LoadButtonClick
    end
    object Zoom1x1: TButton
      Left = 541
      Top = 8
      Width = 25
      Height = 25
      Caption = '1=1'
      TabOrder = 9
      OnClick = Zoom1x1Click
    end
    object comboPropertyNames: TComboBox
      Left = 145
      Top = 10
      Width = 145
      Height = 21
      Hint = #1048#1084#1077#1085#1072' '#1072#1090#1088#1080#1073#1091#1090#1086#1074
      ParentShowHint = False
      ShowHint = True
      TabOrder = 10
      OnChange = comboPropertyNamesChange
    end
    object comboLayers: TComboBox
      Left = 89
      Top = 10
      Width = 50
      Height = 21
      Hint = #1057#1083#1086#1080
      ParentShowHint = False
      ShowHint = True
      TabOrder = 11
      OnChange = comboLayersChange
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 486
    Width = 753
    Height = 19
    Panels = <
      item
        Width = 50
      end
      item
        Width = 150
      end
      item
        Width = 50
      end>
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 41
    Width = 753
    Height = 445
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 2
    Visible = False
    OnChange = PageControl1Change
    object TabSheet1: TTabSheet
      Caption = 'Model'
      object Panel2: TPanel
        Left = 0
        Top = 0
        Width = 745
        Height = 417
        Align = alClient
        BevelOuter = bvLowered
        Caption = 'Panel2'
        TabOrder = 0
        object MapControl1: TMapControl
          Left = 1
          Top = 1
          Width = 743
          Height = 415
          Align = alClient
          Color = clWhite
          OnMouseMove = MapControlMouseMove
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Layout'
      ImageIndex = 1
      object Panel3: TPanel
        Left = 0
        Top = 0
        Width = 745
        Height = 417
        Align = alClient
        BevelOuter = bvLowered
        Caption = 'Panel3'
        TabOrder = 0
        object MapControl2: TMapControl
          Left = 1
          Top = 1
          Width = 743
          Height = 415
          Align = alClient
          Color = clWhite
          OnMouseMove = MapControlMouseMove
        end
      end
    end
  end
  object dialogOpenProject: TOpenDialog
    Filter = 'Project XML files|*.xml'
    InitialDir = '..\..\demodata'
    Left = 680
    Top = 416
  end
end
