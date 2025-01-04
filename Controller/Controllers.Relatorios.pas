unit Controllers.Relatorios;

interface

uses Horse,
     System.JSON,
     System.SysUtils,
     DM;

     procedure RegistrarRotas;
     procedure ReportOrder(Req: THorseRequest; Res: THorseResponse; Next: Tproc);

implementation

procedure RegistrarRotas;
begin
    // Configurações de endpoints do Horse
    THorse.Post('/reportorder',  ReportOrder);


end;

procedure ReportOrder(Req: THorseRequest; Res: THorseResponse; Next: Tproc);
var
  dm:TDtm;
  body: TJSONObject;
  dt1, dt2: string;
  firstdate, lastdate: TDateTime;
begin
      try
        try
            dm          := TDtm.Create(nil);
            body        := Req.Body<TJSONObject>;

            dt1 := body.GetValue<string>('firstdt', '');
            dt2 := body.GetValue<string>('lastdt', '');

            firstdate       := StrToDate(dt1) ;
            lastdate        := StrToDate(dt2) ;

            Res.Send(dm.ReportOrder(firstdate, lastdate)).Status(201);

        except
          on ex:exception do
            Res.Send('Houve  um erro:' + ex.Message).Status(502);     //DEU ERRO
        end;
      finally
          FreeAndNil(dm);
      end;
end;

end.
