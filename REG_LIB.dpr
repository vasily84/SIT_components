library REG_LIB;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

 //**************************************************************************//


uses
  simmm,
  Classes,
  Info in 'Info.pas';

{$R *.res}

  //Эта функция возвращает адрес структуры DllInfo
function  GetEntry:Pointer;
begin
  Result:=@DllInfo;
end;

exports
  GetEntry name 'GetEntry',         //Функция получения адреса структуры DllInfo
  CreateObject name 'CreateObject'; //Функция создания объекта

begin
end.
