# GrpcExample

Programa de console que serve e chama um serviço gRPC com o PascalRAL 2.0 (pacotes `RALModuleProtobufPackage` e `RALModuleGrpcPackage`). Servidor e cliente rodam no mesmo programa, que sai ao terminar.

## O que ele faz

1. Sobe um `TRALGrpcModule` no motor fpHTTP (Lazarus), na porta 8000, com o serviço `TGreeter` (uma subclasse do `TGreeterServiceBase` gerado), ligado por `Module.AddService`.
2. Chama `SayHello` (unário) com o `TGreeterClient` gerado sobre um `TRALClient`, protocolo `gpWeb` (gRPC-Web).
3. Chama `SayHellos` (fluxo do servidor); cada resposta é mostrada quando chega.
4. Para o servidor.

## Gerar o Greeter.pas de novo

O `Greeter.pas` é escrito pelo `ralprotoc` a partir do `greeter.proto` e fica ao lado do exemplo. Depois de mudar o `.proto`, rode nesta pasta:

    ralprotoc greeter.proto

O `ralprotoc` é o `tools/ralprotoc/ralprotoc.dpr` do PascalRAL 2.0 (compile com Delphi ou Free Pascal).

## Como rodar

Instale/compile `PascalRAL`, `RALModuleProtobufPackage` e `RALModuleGrpcPackage` (e o pacote do motor, `fpHTTPRAL`), compile o projeto e execute.
