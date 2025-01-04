unit Controllers.Order;

interface

uses Horse,
     System.JSON,
     System.SysUtils,
     DM;

     procedure RegistrarRotas;
     procedure ListarOrder(Req: THorseRequest; Res: THorseResponse; Next: Tproc);
     procedure InsertOrder(Req: THorseRequest; Res: THorseResponse; Next: Tproc);

implementation

procedure RegistrarRotas;
begin
    // Configurações de endpoints do Horse
    THorse.Get('/listarorder',  ListarOrder);
    THorse.Post('/postorder',  InsertOrder);
end;

procedure ListarOrder(Req: THorseRequest; Res: THorseResponse; Next: Tproc);
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

procedure InsertOrder(Req: THorseRequest; Res: THorseResponse; Next: Tproc);
var
  dm:TDtm;
  body: TJSONObject;
   items: TJSONArray;
  value, totalAmount: Currency;
  totalItems: integer;
   resultJson: TJSONObject;
begin
      try
        try
            // Inicializa a conexão com o banco e o objeto JSON recebido
            dm          := TDtm.Create(nil);
            body        := Req.Body<TJSONObject>;

            // Obtém o valor total da ordem
            totalAmount := body.GetValue<Currency>('totalAmount', 0);

            // Obtém o valor total de itens da order
            totalItems := body.GetValue<Integer>('totalItems', 0);

            // Obtém os itens da ordem
            items := body.GetValue<TJSONArray>('items');

            // Chama o método InsertOrder com os valores extraídos
            resultJson := dm.InsertOrder(totalAmount, totalItems, items);

            // Retorna o resultado do método InsertOrder
            Res.Send(resultJson).Status(201);

        except
          on ex:exception do
            Res.Send('Houve  um erro:' + ex.Message).Status(502);     //DEU ERRO
        end;
      finally
          FreeAndNil(dm);
      end;
end;

end.
