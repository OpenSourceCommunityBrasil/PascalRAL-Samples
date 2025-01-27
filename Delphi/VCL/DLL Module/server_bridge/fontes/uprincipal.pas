unit uprincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RALCustomObjects, RALServer,
  RALSynopseServer, RALAuthentication, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Buttons,
  Data.DB, Vcl.Grids, Vcl.DBGrids, Vcl.ExtCtrls, RALSwaggerModule, RALToken,
  Vcl.Imaging.pngimage, Vcl.Menus, System.ImageList, Vcl.ImgList, RALRequest,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, RALResponse,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, FireDAC.Stan.Async, FireDAC.DApt,
  RALTypes, Themes;

type
  Tfprincipal = class(TForm)
    pooler: TRALSynopseServer;
    jwt: TRALServerJWTAuth;
    basic: TRALServerBasicAuth;
    pgPrincipal: TPageControl;
    TabSheet1: TTabSheet;
    Label1: TLabel;
    eServerPorta: TEdit;
    bIniciarServer: TSpeedButton;
    Label2: TLabel;
    rbAuthJWT: TRadioButton;
    rbAuthBasic: TRadioButton;
    TabSheet2: TTabSheet;
    Panel1: TPanel;
    dbgUsuarios: TDBGrid;
    Label3: TLabel;
    eUserUsuario: TEdit;
    Label4: TLabel;
    ePassUsuario: TEdit;
    bGravarUsuario: TSpeedButton;
    rbAuthNenhuma: TRadioButton;
    Panel2: TPanel;
    swagger: TRALSwaggerModule;
    Image1: TImage;
    ckSwagger: TCheckBox;
    iconTray: TTrayIcon;
    memPop: TPopupMenu;
    Abrir1: TMenuItem;
    N1: TMenuItem;
    Encerrar1: TMenuItem;
    imgList: TImageList;
    ckAutoStart: TCheckBox;
    TabSheet3: TTabSheet;
    imgIniciar: TImage;
    imgParar: TImage;
    DBGrid2: TDBGrid;
    memModulos: TFDMemTable;
    dsModulos: TDataSource;
    memModulosmod_handle: TLargeintField;
    memModulosmod_name: TStringField;
    memModulosmod_file: TStringField;
    qUsuarios: TFDQuery;
    dsUsuarios: TDataSource;
    qUsuariosCODIGO: TIntegerField;
    qUsuariosUSUARIO: TStringField;
    qUsuariosSENHA: TStringField;
    qUsuariosATIVO: TStringField;
    procedure bIniciarServerClick(Sender: TObject);
    procedure Abrir1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure DBGrid2DblClick(Sender: TObject);
    procedure eServerPortaChange(Sender: TObject);
    procedure Encerrar1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bGravarUsuarioClick(Sender: TObject);
    procedure dbgUsuariosCellClick(Column: TColumn);
    procedure dbgUsuariosDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure basicValidate(ARequest: TRALRequest; AResponse: TRALResponse;
      var AResult: Boolean);
    procedure jwtGetToken(ARequest: TRALRequest; AResponse: TRALResponse;
      AParams: TRALJWTParams; var AResult: Boolean);
    procedure jwtValidate(ARequest: TRALRequest; AResponse: TRALResponse;
      AParams: TRALJWTParams; var AResult: Boolean);
    procedure iconTrayDblClick(Sender: TObject);
  private
    { Private declarations }
    FCanClose : boolean;
    FCodUsuario : integer;
    FProcessando : boolean;
    procedure carregaSubModules;
    procedure imageButton(AButton : TSpeedButton; AImage : TImage);
    procedure startServer;
    procedure novoUsuario;
    procedure proximoUsuario;
    function drawCheckBox(canv : TCanvas; rct : TRect; sel : boolean = True) : boolean; overload;
    function drawCheckBox(hwd : THandle; rct : TRect; sel : boolean = True) : boolean; overload;
  public
    { Public declarations }
  end;

var
  fprincipal: Tfprincipal;

implementation

{$R *.dfm}

uses
  uglobal_vars, udm, udm_rest;

var
  start_module: function(server : TRALServer): Boolean; stdcall;
  desc_module : function : string; stdcall;
  config_module : procedure; stdcall;

procedure Tfprincipal.Abrir1Click(Sender: TObject);
begin
  Self.Show;
end;

procedure Tfprincipal.basicValidate(ARequest: TRALRequest;
  AResponse: TRALResponse; var AResult: Boolean);
var
  dm_rest : Tdm_rest;
begin
  dm_rest := Tdm_rest.Create(nil);
  try
    dm_rest.validBasicAuth(ARequest, AResponse, AResult);
  finally
    FreeAndNil(dm_rest);
  end;
end;

procedure Tfprincipal.bGravarUsuarioClick(Sender: TObject);
var
  q1 : TFDQuery;
  bErro : boolean;
begin
  bErro := False;

  q1 := TFDQuery.Create(nil);
  try
    q1.Connection := dm.conexao;
    q1.Close;
    q1.SQL.Clear;
    q1.SQL.Add('select count(*) from usuarios');
    q1.SQL.Add('where usuario = :usuario');
    if FCodUsuario = -1 then begin
      q1.SQL.Add('  and codigo <> :codigo');
      q1.ParamByName('codigo').AsInteger := FCodUsuario;
    end;
    q1.ParamByName('usuario').AsString := eUserUsuario.Text;
    q1.Open;

    if q1.Fields[0].AsInteger > 0 then begin
      ShowMessage('Usuário já existe');
      bErro := True;
    end;
  finally
    FreeAndNil(q1);
  end;

  if bErro then
    Exit;

  q1 := TFDQuery.Create(nil);
  try
    q1.Connection := dm.conexao;
    q1.Close;
    q1.SQL.Clear;
    if FCodUsuario = -1 then begin
      proximoUsuario;
      q1.SQL.Add('insert into usuarios(codigo, usuario, senha)');
      q1.SQL.Add('values(:codigo, :usuario, :senha)');
    end
    else begin
      q1.SQL.Add('update usuarios');
      q1.SQL.Add('set usuario = :usuario,');
      q1.SQL.Add('    senha = :senha');
      q1.SQL.Add('where codigo = :codigo');
    end;
    q1.ParamByName('codigo').AsInteger := FCodUsuario;
    q1.ParamByName('usuario').AsString := eUserUsuario.Text;
    q1.ParamByName('senha').AsString := ePassUsuario.Text;
    q1.ExecSQL;

    novoUsuario;

    qUsuarios.Close;
    qUsuarios.Open;
  finally
    FreeAndNil(q1);
  end;
end;

procedure Tfprincipal.bIniciarServerClick(Sender: TObject);
begin
  if bIniciarServer.Tag = 0 then begin
    startServer;
    iconTray.IconIndex := 1;
    bIniciarServer.Tag := 1;
    imageButton(bIniciarServer, imgParar);
    bIniciarServer.Caption := 'Parar';
  end
  else begin
    pooler.Stop;
    iconTray.IconIndex := 0;
    bIniciarServer.Tag := 0;
    imageButton(bIniciarServer, imgIniciar);
    bIniciarServer.Caption := 'Iniciar';
  end;
end;

procedure Tfprincipal.carregaSubModules;
var
  F: TSearchRec;
  Ret : Integer;

  procedure carregaBiblioteca(ADLL : string);
  var
    vDLL : THandle;
    vDesc : string;
  begin
    vDLL := SafeLoadLibrary(ADLL);

    if vDLL <> HMODULE(0) then begin
      try
        start_module := GetProcAddress(vDLL, 'start_module');
        if Assigned(start_module) then
          start_module(pooler);

        vDesc := '';
        desc_module := GetProcAddress(vDLL, 'desc_module');
        if Assigned(desc_module) then begin
          vDesc := desc_module();

          memModulos.Append;
          memModulosmod_handle.AsInteger := vDLL;
          memModulosmod_file.AsString := ExtractFileName(ADLL);
          memModulosmod_name.AsString := vDesc;
          memModulos.Post;
        end;
      except

      end;
    end;
  end;

begin
  memModulos.Close;
  memModulos.Open;

  Ret := FindFirst('*.dll', faAnyFile, F);
  try
    repeat
      if F.Name <> '' then
        carregaBiblioteca(F.Name);
      Ret := FindNext(F);
    until Ret <> 0;
  finally
    FindClose(F);
  end;
end;

procedure Tfprincipal.dbgUsuariosCellClick(Column: TColumn);
var
  q1 : TFDQuery;
  ativo : string;
begin
  if Column.Index = 2 then begin

    if qUsuariosATIVO.AsString = 'S' then
      ativo := 'N'
    else
      ativo := 'S';

    q1 := TFDQuery.Create(nil);
    try
      q1.Connection := dm.conexao;
      q1.Close;
      q1.SQL.Clear;
      q1.SQL.Add('update usuarios');
      q1.SQL.Add('set ativo = :ativo');
      q1.SQL.Add('where codigo = :codigo');
      q1.ParamByName('codigo').AsInteger := qUsuariosCODIGO.AsInteger;
      q1.ParamByName('ativo').AsString := ativo;
      q1.ExecSQL;

      novoUsuario;

      qUsuarios.Close;
      qUsuarios.Open;
    finally
      FreeAndNil(q1);
    end;
  end;
end;

procedure Tfprincipal.dbgUsuariosDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  dbgUsuarios.Canvas.Brush.Color := clWhite;
  dbgUsuarios.Canvas.Brush.Style := bsSolid;
  dbgUsuarios.Canvas.FillRect(Rect);

  if (DataCol = 2) then
    dbgUsuarios.Canvas.Font.Color := clWhite;
  dbgUsuarios.DefaultDrawColumnCell(Rect, DataCol, Column, State);

  if (DataCol = 2) and (qUsuarios.Active) then
    drawCheckBox(dbgUsuarios.Canvas, Rect, qUsuariosATIVO.AsString = 'S');
end;

function Tfprincipal.drawCheckBox(hwd: THandle; rct: TRect;
sel: boolean): boolean;
var
  det : TThemedElementDetails;
  x,y : integer;
begin
  Result := ThemeServices.ThemesEnabled;
  if ThemeServices.ThemesEnabled then begin
    if sel then
      det := ThemeServices.GetElementDetails(tbCheckBoxCheckedNormal)
    else
      det := ThemeServices.GetElementDetails(tbCheckBoxUncheckedNormal);
    ThemeServices.DrawElement(hwd,det,rct);
  end
  else begin
    Result := False;
    x := Trunc(rct.Left + ((rct.Right-rct.Left) / 2) - 6.5);
    y := Trunc(rct.Top + ((rct.Bottom-rct.Top) / 2) - 6.5);

    rct.Left := x;
    rct.Top := y;
    rct.Right := x + 13;
    rct.Bottom := y + 13;

    if sel then
      DrawFrameControl(hwd, rct, DFC_BUTTON, DFCS_BUTTONCHECK or DFCS_CHECKED)
    else
      DrawFrameControl(hwd, rct, DFC_BUTTON, DFCS_BUTTONCHECK);
  end;
end;

function Tfprincipal.drawCheckBox(canv: TCanvas; rct: TRect;
  sel: boolean): boolean;
begin
  Result := drawCheckBox(canv.Handle,rct,sel);
end;

procedure Tfprincipal.DBGrid2DblClick(Sender: TObject);
begin
  config_module := GetProcAddress(memModulosmod_handle.AsInteger, 'config_module');
  if Assigned(config_module) then
    config_module();
end;

procedure Tfprincipal.Encerrar1Click(Sender: TObject);
begin
  FCanClose := True;
  Close;
end;

procedure Tfprincipal.eServerPortaChange(Sender: TObject);
begin
  if FProcessando then
    Exit;

  gb_serverport := StrToIntDef(eServerPorta.Text, 8000);

  gb_authtype := 3;
  if rbAuthJWT.Checked then
    gb_authtype := 1
  else if rbAuthBasic.Checked then
    gb_authtype := 2;

  gb_modswager := ckSwagger.Checked;
  gb_autostart := ckAutoStart.Checked;

  salvarConfiguracoes;

  if pooler.Active then
    startServer;
end;

procedure Tfprincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caNone;
  if FCanClose then begin
    Action := caFree;
    Application.Terminate;
  end;
end;

procedure Tfprincipal.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FCanClose;
  Self.Hide;
end;

procedure Tfprincipal.FormCreate(Sender: TObject);
begin
  carregaSubModules;

  FCanClose := False;

  qUsuarios.Close;
  qUsuarios.Open;

  novoUsuario;

  imageButton(bIniciarServer, imgIniciar);

  FProcessando := True;

  eServerPorta.Text := IntToStr(gb_serverport);

  rbAuthJWT.Checked := gb_authtype = 1;
  rbAuthBasic.Checked := gb_authtype = 2;
  rbAuthNenhuma.Checked := gb_authtype = 3;

  ckSwagger.Checked := gb_modswager;
  ckAutoStart.Checked := gb_autostart;

  FProcessando := False;
  pgPrincipal.ActivePageIndex := 0;

  Application.ProcessMessages;

  if gb_autostart then
    bIniciarServer.Click
  else
    Self.Show;
end;

procedure Tfprincipal.iconTrayDblClick(Sender: TObject);
begin
  Self.Show;
end;

procedure Tfprincipal.imageButton(AButton: TSpeedButton; AImage: TImage);
begin
  bIniciarServer.Glyph.Assign(AImage.Picture.Graphic);
end;

procedure Tfprincipal.jwtGetToken(ARequest: TRALRequest;
  AResponse: TRALResponse; AParams: TRALJWTParams; var AResult: Boolean);
var
  dm_rest : Tdm_rest;
begin
  dm_rest := Tdm_rest.Create(nil);
  try
    dm_rest.getJWTToken(ARequest, AResponse, AParams, AResult);
  finally
    FreeAndNil(dm_rest);
  end;
end;

procedure Tfprincipal.jwtValidate(ARequest: TRALRequest;
  AResponse: TRALResponse; AParams: TRALJWTParams; var AResult: Boolean);
var
  dm_rest : Tdm_rest;
begin
  dm_rest := Tdm_rest.Create(nil);
  try
    dm_rest.validJWToken(ARequest, AResponse, AParams, AResult);
  finally
    FreeAndNil(dm_rest);
  end;
end;

procedure Tfprincipal.novoUsuario;
begin
  FCodUsuario := -1;
  eUserUsuario.Text := '';
  ePassUsuario.Text := '';
end;

procedure Tfprincipal.proximoUsuario;
var
  q1 : TFDQuery;
begin
  q1 := TFDQuery.Create(nil);
  try
    q1.Connection := dm.conexao;
    q1.Close;
    q1.SQL.Clear;
    q1.SQL.Add('select max(codigo) from usuarios');
    q1.Open;

    FCodUsuario := q1.Fields[0].AsInteger + 1;
  finally
    FreeAndNil(q1);
  end;
end;

procedure Tfprincipal.startServer;
begin
  pooler.Stop;

  pooler.Port := StrToIntDef(eServerPorta.Text, 8000);

  swagger.Server := nil;
  if gb_modswager then
    swagger.Server := pooler;

  case gb_authtype of
    1 : pooler.Authentication := jwt;
    2 : pooler.Authentication := basic;
    3 : pooler.Authentication := nil;
  end;

  pooler.Start;
end;

end.
