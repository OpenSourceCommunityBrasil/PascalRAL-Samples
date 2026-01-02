unit uFunctions;

interface

function SomenteNumero(str: String ): String;

Const
  //URL_SERVER_FOTO = 'http://localhost:3003/';
  URL_SERVER_FOTO = 'http://192.168.0.103:3003/';


implementation

function SomenteNumero(str: String ): String;
var
    i: Integer ;
begin
    Result := '' ;
    for i := 1 to length(str) do
    begin
        if str[i] in ['0'..'9'] then
        Result := Result + str[i] ;
    end;
end;

end.
