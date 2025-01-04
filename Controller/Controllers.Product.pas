unit Controllers.Product;

interface

uses Horse,
     System.JSON,
     System.SysUtils,
     DM;

     procedure RegistrarRotas;
     procedure ListarProduct(Req: THorseRequest; Res: THorseResponse; Next: Tproc);
     procedure InsertProduct(Req: THorseRequest; Res: THorseResponse; Next: Tproc);

implementation

procedure RegistrarRotas;
begin
    // Configurações de endpoints do Horse
    THorse.Get('/listarproduct',  ListarProduct);
    THorse.Post('/postproduct',  InsertProduct);

end;

procedure ListarProduct(Req: THorseRequest; Res: THorseResponse; Next: Tproc);
var
  dm:TDtm;
begin
      try
          dm  := TDtm.Create(nil);
          Res.Send(dm.ListarProduct()).Status(200);
      finally
          FreeAndNil(dm);
      end;
end;

procedure InsertProduct(Req: THorseRequest; Res: THorseResponse; Next: Tproc);
var
  dm:TDtm;
  body: TJSONObject;
  product: string;
  value: Currency;
begin
      try
        try
            dm          := TDtm.Create(nil);
            body        := Req.Body<TJSONObject>;

            product     := body.GetValue<string>('product', '');
            value       := body.GetValue<Currency>('value', 0);


            Res.Send(dm.InsertProduct(product, value)).Status(201);

        except
          on ex:exception do
            Res.Send('Houve  um erro:' + ex.Message).Status(502);     //DEU ERRO
        end;
      finally
          FreeAndNil(dm);
      end;
end;

end.
