program ralnetloopexample;

{ delphi}{+}

uses
  { UNIX}cthreads,{}
  SysUtils,
  RALSocket,
  Eco.Servidor;

var
  vServidor: TEcoServidor;
  vCliente: TRALSocket;
  vCanal: TRALSocketChannel;
  vTexto: AnsiString;
  vBuffer: array[0..255] of AnsiChar;
  vLidos: Integer;
begin
  vServidor := TEcoServidor.Create;
  try
    vServidor.Iniciar(7000);
    WriteLn('eco na porta 7000 (teste: telnet localhost 7000; "sair" encerra)');

    // um cliente na mesma rede propria: conecta, manda uma linha, le a resposta
    vCliente := TRALSocket.Create;
    vCanal := TRALSocketChannel.Create(vCliente);
    try
      vCliente.Connect('127.0.0.1', 7000, 3000, mifIPv4);
      vTexto := 'ola, rede propria'#10;
      vCanal.WriteAll(Pointer(vTexto)^, Length(vTexto), 3000);
      vLidos := vCanal.ReadWait(vBuffer, SizeOf(vBuffer), 3000);
      if vLidos > 0 then
      begin
        SetString(vTexto, PAnsiChar(@vBuffer[0]), vLidos);
        Write('o servidor respondeu: ', string(vTexto));
      end;
    finally
      vCanal.Free; // fecha o socket tambem
    end;

    WriteLn('Enter para terminar...');
    ReadLn;
  finally
    vServidor.Free;
  end;
end.
