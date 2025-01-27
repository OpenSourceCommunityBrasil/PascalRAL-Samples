unit uglobal_vars;

interface

uses
  Classes, SysUtils, IniFiles;

var
  gb_defaultdir : string;
  gb_serverport : integer;
  gb_authtype : integer;
  gb_modswager : boolean;
  gb_autostart : boolean;

  gb_database : string;
  gb_hostname : string;
  gb_dbport : integer;

procedure salvarConfiguracoes;

implementation

procedure salvarConfiguracoes;
var
  fIni : TIniFile;
begin
  fIni := TIniFile.Create(gb_defaultdir + 'config.ini');
  try
    fIni.WriteInteger('config', 'serverport', gb_serverport);
    fIni.WriteInteger('config', 'authtype', gb_authtype);
    fIni.WriteBool('config', 'modswager', gb_modswager);
    fIni.WriteBool('config', 'autostart', gb_autostart);
  finally
    FreeAndNil(fIni);
  end;
end;

procedure carregaConfiguracoes;
var
  fIni : TIniFile;
begin
  fIni := TIniFile.Create(gb_defaultdir + 'config.ini');
  try
    gb_serverport := fIni.ReadInteger('config', 'serverport', 8000);
    gb_authtype := fIni.ReadInteger('config', 'authtype', 3);
    gb_modswager := fIni.ReadBool('config', 'modswager', False);
    gb_autostart := fIni.ReadBool('config', 'autostart', False);

    gb_database := fIni.ReadString('conexao', 'database', gb_defaultdir + 'bridge_bd.dat');
    gb_hostname := fIni.ReadString('conexao', 'hostname', 'localhost');
    gb_dbport := fIni.ReadInteger('conexao', 'port', 3050);
  finally
    FreeAndNil(fIni);
  end;
end;

initialization
  gb_defaultdir := ExtractFilePath(ParamStr(0));
  carregaConfiguracoes;

end.
