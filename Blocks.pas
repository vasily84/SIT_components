
 //**************************************************************************//
 // Данный исходный код является составной частью системы МВТУ-4             //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit Blocks;

 //***************************************************************************//
 //                Блоки для моделирования гидроавтоматики                    //
 //***************************************************************************//

interface

uses Classes, DataTypes, SysUtils, abstract_im_interface, RunObjts, uExtMath,
  RealArrays; // RealArrays for inlines


type

  //Модель PID
  TPID1 = class(TRunObject)
  public
    kp: TExtArray;
    ki: TExtArray;
    i0: TExtArray;
    kd: TExtArray;
    td: TExtArray;
    d0: TExtArray;
    // перемещены из тела модуля
    xdif1,xdif2,fdif1,fdif2:TExtArray;

    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;

    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
  end;



implementation

uses math;



{*******************************************************************************
                              TPID1
*******************************************************************************}
//var xdif1,xdif2,fdif1,fdif2:TExtArray;
// использование глобальных переменных делает невозможным расчет несколькими экземплярами объекта


constructor TPID1.Create(Owner: TObject);
begin
  inherited;
  // переменные из блока SimInTech
  kp := TExtArray.Create(1);
  ki := TExtArray.Create(1);
  i0 := TExtArray.Create(1);
  kd := TExtArray.Create(1);
  td := TExtArray.Create(1);
  d0 := TExtArray.Create(1);

  // внутренние переменные SimInTech
  xdif1 := TExtArray.Create(1);
  xdif2 := TExtArray.Create(1);
  fdif1 := TExtArray.Create(1);
  fdif2 := TExtArray.Create(1);
end;

//--------------------------------------------------------------------------

function    TPID1.GetParamID;
begin
  Result:=inherited GetParamId(ParamName,DataType,IsConst);
  if Result = -1 then begin
    if StrEqu(ParamName,'kp') then begin
      Result:=NativeInt(kp);
      DataType:=dtDoubleArray;
      exit;
    end;

    if StrEqu(ParamName,'ki') then begin
      Result:=NativeInt(ki);
      DataType:=dtDoubleArray;
      exit;
    end;

    if StrEqu(ParamName,'i0') then begin
      Result:=NativeInt(i0);
      DataType:=dtDoubleArray;
      exit;
    end;

    if StrEqu(ParamName,'kd') then begin
      Result:=NativeInt(kd);
      DataType:=dtDoubleArray;
      exit;
    end;

    if StrEqu(ParamName,'td') then begin
      Result:=NativeInt(td);
      DataType:=dtDoubleArray;
      exit;
    end;

    if StrEqu(ParamName,'d0') then begin
      Result:=NativeInt(d0);
      DataType:=dtDoubleArray;
      exit;
    end;

  end
end;

//------------------------------------------------------------------------
function TPID1.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;

begin
  Result:=0;
  case Action of
    // число выходов
    i_GetCount:     begin
                      cY[0].Dim[0] := cU[0].Dim[0];
                      //cY[0].Dim[0] := cU[0].Dim[0]+1;    //- будет на 1 график больше, но не упадет? Почему?
                      //cY[0] := cU[0];  // тоже работает, почему?
                      xdif1.Count := cU[0].Dim[0];
                      xdif2.Count := cU[0].Dim[0];
                      fdif1.Count := cU[0].Dim[0];
                      fdif2.Count := cU[0].Dim[0];
                    end;

    // число производных
    i_GetDifCount:  begin
                      Result:=cU[0].Dim[0]*2;
                      //Result:=cU[0].Dim[0]*2+5; // почему не падает при неправильном числе производных?
                    end;

    //
    i_GetInit:      begin
                      Result:=1;  // рабочая, как в примере
                      //Result := t_none; // почему работает?
                      //Result := t_dst; // почему работает?
                    end;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end
end;
//--------------------------------------------------------------------------
function TPID1.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var i,j,k :Integer;

function Check0:Boolean;     // проверка и останов по необходимости
begin
  Result:=False;
  begin
    if (kp[i]=0)or(ki[i]=0)or(kd[i]=0)or(td[i]=0) then begin
      ErrorEvent('Ошибка',msError,VisualObject);
      RunFunc := r_Fail;
      Result := True;
    end;
  end;
end;

begin // сама RunFunction
  Result:=0;
  case Action of
    f_InitState:  begin
                    // начальные значения
                    for i:=0 to Y[0].Count-1 do begin
                      if Check0 then exit;
                      xdif1[i] := i0[i];
                      xdif2[i] := -td[i]/kd[i]*d0[i];
                      Y[0][i] := i0[i]+(U[0][i]-U[1][i])*kp[i]+d0[i]+(U[0][i]-U[1][i])*kd[i]/td[i];
                    end;
                    // переменные состояния
                    for j:=0 to Y[0].Count-1 do begin
                      xdif[j]:=xdif1[j];
                    end;
                    for k:= Y[0].Count to 2*Y[0].Count-1  do begin
                      xdif[k]:=xdif2[k-Y[0].Count];
                    end;
                  end;

    f_UpdateOuts,
    f_GoodStep:   begin
    // обратно распределяем переменные состояния по локальным массивам
                for j:=0 to Y[0].Count-1 do begin
                  xdif1[j]:=xdif[j];
                end;
                for k:=Y[0].Count to 2*Y[0].Count-1 do begin
                  xdif2[k-Y[0].Count]:=xdif[k];
                end;
    // вычисляем выход блока
                for i:=0 to Y[0].Count-1 do begin
                  if Check0 then exit;
                  Y[0][i]:=xdif1[i]+kp[i]*(U[0][i]-U[1][i])+kd[i]*(U[0][i]-U[1][i]-Xdif2[i])/td[i];
                end;
              end;

    f_GetDeri: begin
    // высчитываем значения производных локальных переменных состояния
                for i:=0 to Y[0].Count-1 do begin
                  if Check0 then exit;
                  fdif1[i]:=ki[i]*(U[0][i]-U[1][i]);
                  fdif2[i]:=(U[0][i]-U[1][i]-xdif2[i])/td[i];
                end;
    // записываем их в один массив для передачи решателю
                for j:=0 to Y[0].Count-1 do begin
                  fdif[j]:=fdif1[j];
                end;

                for k:=Y[0].Count to 2*Y[0].Count-1 do begin
                  fdif[k]:=fdif2[k-Y[0].Count];
                end;
                end;

end;
end;

//----------------------------------------------------------------------------
end.
