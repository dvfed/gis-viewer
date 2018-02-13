unit Loader;

interface

uses
  Generics.Collections,
  SimpleXML,
  MapTypes;

type
  TProject = class(TObject)
  private
  type
    TSourcesTable = TObjectDictionary<Integer,TModel>;
  private
    FFileName: string;
    FProjectPath: string;
    FDataSources: TSourcesTable;
    FLayoutSources: TSourcesTable;
    FModelWin: TWorkWindow;
    FLayoutWin: TWorkWindow;
    FResolution: Double;
    procedure LoadLayerGroup(AFeatureNode: IXmlNode; AFeature: TBaseViewPort;
      ASourcesTable: TSourcesTable);
    procedure LoadStylesIfAny(AFeatureNode: IXmlNode; AFeature: TLayer);
    procedure LoadPropertiesIfAny(AFeatureNode: IXmlNode; AFeature: TPropertyEnabledFeature);
    procedure LoadLinearFeature(AFeatureNode: IXmlNode; AModel: TModel);
    function LoadWorkWindow(AFeatureNode: IXmlNode; ASourcesTable: TSourcesTable): TWorkWindow;
    procedure LoadViewPort(AFeatureNode: IXmlNode; AModel: TModel);
    procedure LoadViewPortParameters(AFeatureNode: IXmlNode; AFeature: TBaseViewPort);
    procedure LoadModelFromXML(ASourceNode: IXmlNode; AModel: TModel);
    procedure LoadModelFromFile(const AFileName: string; AModel: TModel);
    procedure InitDataSources(ADatasourceNode: IXmlNode);
    procedure InitLayoutSources(ALayoutsourcesNode: IXmlNode);
    procedure InitModels(AModelsNode: IXmlNode);
    procedure InitLayout(ALayoutsNode: IXmlNode);
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    procedure Load;
    property ModelWin: TWorkWindow read FModelWin write FModelWin;
    property LayoutWin: TWorkWindow read FLayoutWin write FLayoutWin;
  end;

implementation

uses
  Vcl.Forms,
  System.SysUtils,
  System.Types,
  System.StrUtils,
  GDIPAPI,
  CommonGeometry,
  GeosGeometry,
  Features,
  Storages,
  Properties;

{ TProject }

constructor TProject.Create(const AFileName: string);
begin
  FFileName := AFileName;
  FProjectPath := IncludeTrailingBackslash(ExtractFilePath(ExpandFileName(FFileName)));
  FResolution := Screen.PixelsPerInch;
  FDataSources := TSourcesTable.Create([doOwnsValues]);
  FLayoutSources := TSourcesTable.Create([doOwnsValues]);
end;

destructor TProject.Destroy;
begin
  { Object that depends on the others has to be destroyed first.
    See "Objects" UML diagram. }
  FModelWin.Free;
  FLayoutWin.Free;
  FLayoutSources.Free;
  FDataSources.Free;
  inherited;
end;

procedure TProject.InitDataSources(ADatasourceNode: IXmlNode);
var
  nodeList: IXmlNodeList;
  filesourceNode: IXmlNode;
  I, fileID: Integer;
  filesourceName: string;
  model: TModel;
begin
  nodeList := ADatasourceNode.ChildNodes;
  for I := 0 to nodeList.Count - 1 do begin
    filesourceNode := nodeList.Item[i];
    if filesourceNode.NodeName = 'file' then begin
      fileID := StrToInt(filesourceNode.NeedAttr('id'));
      filesourceName := FProjectPath + filesourceNode.NeedAttr('name');

      model := TModel.Create(nil);
      model.TopoScale := 500;
      FDataSources.Add(fileID, model);
      LoadModelFromFile(filesourceName, FDataSources[fileID]);
    end;
  end;
end;

procedure TProject.InitLayout(ALayoutsNode: IXmlNode);
var
  workwinNode: IXMLNode;
begin
  workwinNode := ALayoutsNode.SelectSingleNode('workwindow');
  FLayoutWin := LoadWorkWindow(workwinNode, FLayoutSources);
end;

procedure TProject.InitLayoutSources(ALayoutsourcesNode: IXmlNode);
var
  layout: TLayout;
  nodeList: IXmlNodeList;
  sourceNode: IXmlNode;
  I, sourceID: Integer;
begin
  nodeList := ALayoutsourcesNode.ChildNodes;
  for I := 0 to nodeList.Count - 1 do begin
    sourceNode := nodeList.Item[i];
    if sourceNode.NodeName = 'embedded' then begin
      sourceID := StrToInt(sourceNode.NeedAttr('id'));
      layout := TLayout.Create(nil);
      layout.Scale := 1;
      FLayoutSources.Add(sourceID, layout);
      LoadModelFromXML(sourceNode, layout);
    end;
  end;
end;

procedure TProject.InitModels(AModelsNode: IXmlNode);
var
  workwinNode: IXMLNode;
begin
  workwinNode := AModelsNode.SelectSingleNode('workwindow');
  FModelWin := LoadWorkWindow(workwinNode, FDataSources);
end;

procedure TProject.Load;
var
  doc: IXmlDocument;
  datasourceNode: IXmlNode;
  layoutsourceNode: IXmlNode;
  modelsNode, layoutsNode: IXmlNode;
begin
  doc := LoadXmlDocument(FFileName);
  datasourceNode := doc.DocumentElement.SelectSingleNode('datasources');
  InitDatasources(datasourceNode);
  layoutsourceNode := doc.DocumentElement.SelectSingleNode('layoutsources');
  InitLayoutSources(layoutsourceNode);
  modelsNode := doc.DocumentElement.SelectSingleNode('models');
  InitModels(modelsNode);
  layoutsNode := doc.DocumentElement.SelectSingleNode('layouts');
  InitLayout(layoutsNode);
end;

procedure TProject.LoadLayerGroup(AFeatureNode: IXmlNode;
  AFeature: TBaseViewPort; ASourcesTable: TSourcesTable);
var
  I, sourceID: Integer;
  layNode, layGroupNode, dataNode: IXmlNode;
  nodeList: IXmlNodeList;
  layGroupScale: Double;
  layer: TLayer;
  layGroup: TLayerGroup;
begin
  layGroupNode := AFeatureNode.SelectSingleNode('layergroup');
  if not Assigned(layGroupNode) then
    Exit;
  layGroupScale := StrTofloat(layGroupNode.NeedAttr('scale'));
  layGroup := TLayerGroup.Create(AFeature);
  AFeature.Add(layGroup);
  layGroup.Scale := layGroupScale;
  nodeList := layGroupNode.ChildNodes;
  for I := 0 to nodeList.Count - 1 do begin
    layNode := nodeList.Item[I];
    if layNode.NodeName = 'layer' then begin
      dataNode := layNode.SelectSingleNode('data');
      sourceID := StrToInt(dataNode.NeedAttr('sourceid'));
      layer := TLayer.Create(layGroup, ASourcesTable[sourceID]);
      layGroup.Add(layer);
      LoadStylesIfAny(layNode, layer);
    end;
  end;
end;

procedure TProject.LoadLinearFeature(AFeatureNode: IXmlNode; AModel: TModel);
var
  geomNode: IXMLNode;
  wkt: string;
  geom: TGeosGeometryWrapper;
  feature: TLinearFeature;
begin
  geomNode := AFeatureNode.SelectSingleNode('geometry');
  wkt := geomNode.NeedAttr('wkt');
  geom := TGeosGeometryWrapper.MakeFromWKT(wkt);
  feature := TLinearFeature.Create(AModel, geom);
  AModel.Add(feature);
  LoadPropertiesIfAny(AFeatureNode, feature);
end;

procedure TProject.LoadModelFromFile(const AFileName: string; AModel: TModel);
var
  storage: TStorage;
begin
  storage := TMifStorage.Create(AFileName);
  try
    AModel.Load(storage);
  finally
    storage.Free;
  end;
end;

procedure TProject.LoadModelFromXML(ASourceNode: IXmlNode; AModel: TModel);
var
  nodeList: IXmlNodeList;
  featureNode: IXmlNode;
  I: Integer;
begin
  nodeList := ASourceNode.ChildNodes;
  for I := 0 to nodeList.Count - 1 do begin
    featureNode := nodeList.Item[I];
    if featureNode.NodeName = 'linearfeature' then begin
      LoadLinearFeature(featureNode, AModel);
    end
    else if featureNode.NodeName = 'viewport' then begin
      LoadViewPort(featureNode, AModel);
    end;
  end;
end;

procedure TProject.LoadPropertiesIfAny(AFeatureNode: IXmlNode;
  AFeature: TPropertyEnabledFeature);
var
  I: Integer;
  propertyNode, propertiesNode: IXmlNode;
  nodeList: IXmlNodeList;
  name, value: string;
begin
  propertiesNode := AFeatureNode.SelectSingleNode('properties');
  if not Assigned(propertiesNode) then
    Exit;
  nodeList := propertiesNode.ChildNodes;
  for I := 0 to nodeList.Count - 1 do begin
    propertyNode := nodeList.Item[I];
    if propertyNode.NodeName = 'property' then begin
      name := propertyNode.NeedAttr('name');
      value := propertyNode.NeedAttr('value');
      AFeature.PropertyByName[name] := value;
    end;
  end;
end;

procedure TProject.LoadStylesIfAny(AFeatureNode: IXmlNode; AFeature: TLayer);
var
  I: Integer;
  styleNode, stylesNode,
  propertyNode, penNode, brushNode: IXmlNode;
  nodeList: IXmlNodeList;
  isDefault: Boolean;
  style: TDrawStyle;
  name, value: string;
begin
  stylesNode := AFeatureNode.SelectSingleNode('styles');
  if not Assigned(stylesNode) then
    Exit;
  nodeList := stylesNode.ChildNodes;
  for I := 0 to nodeList.Count - 1 do begin
    styleNode := nodeList.Item[I];
    if styleNode.NodeName = 'style' then begin
      isDefault := styleNode.GetAttr('default') = 'true';
      penNode := styleNode.SelectSingleNode('pen');
      if Assigned(penNode) then
        style.PenColor := ARGB(penNode.GetHexAttr('color'));
      brushNode := styleNode.SelectSingleNode('brush');
      if Assigned(brushNode) then
        style.BrushColor := ARGB(brushNode.GetHexAttr('color'));
      if isDefault then
        AFeature.SetDefaultStyle(style)
      else begin
        propertyNode := styleNode.SelectSingleNode('property');
        if Assigned(propertyNode) then begin
          name := propertyNode.NeedAttr('name');
          value := propertyNode.NeedAttr('value');
          AFeature.AddStyle(name, value, style);
        end;
      end;
    end;
  end;
end;

procedure TProject.LoadViewPort(AFeatureNode: IXmlNode; AModel: TModel);
var
  geomNode: IXMLNode;
  wkt: string;
  clipperGeom: TGeosGeometryWrapper;
  viewport: TViewPort;
begin
  viewport := TViewPort.Create(AModel);
  geomNode := AFeatureNode.SelectSingleNode('clipper');
  wkt := geomNode.NeedAttr('wkt');
  clipperGeom := TGeosGeometryWrapper.MakeFromWKT(wkt);
  viewport.Clipper := clipperGeom;
  AModel.Add(viewport);
  LoadLayerGroup(AFeatureNode, viewport, FDataSources);
  LoadPropertiesIfAny(AFeatureNode, viewport);
  LoadViewPortParameters(AFeatureNode, viewport);
end;

procedure TProject.LoadViewPortParameters(AFeatureNode: IXmlNode;
  AFeature: TBaseViewPort);
var
  scale, x, y: Double;
  panTo: string;
  panToStrArray: TStringDynArray;
begin
  scale := StrToFloat(AFeatureNode.NeedAttr('scale'));
  AFeature.Scale := scale;
  panTo := AFeatureNode.NeedAttr('panto');
  panToStrArray := SplitString(panTo, ' ');
  Assert(Length(panToStrArray) = 2);
  x := StrToFloat(panToStrArray[0]);
  y := StrToFloat(panToStrArray[1]);
  AFeature.PanTo(MakeVertex(x, y));
end;

function TProject.LoadWorkWindow(AFeatureNode: IXmlNode;
  ASourcesTable: TSourcesTable): TWorkWindow;
begin
  Result := TWorkWindow.Create(nil, FResolution);
  LoadLayerGroup(AFeatureNode, Result, ASourcesTable);
  LoadViewPortParameters(AFeatureNode, Result);
end;

end.
