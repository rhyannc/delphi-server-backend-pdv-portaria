unit DM;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.VCLUI.Wait, Data.DB,
  DataSet.Serialize.Config, DataSet.Serialize, System.JSON,
  FireDAC.Comp.Client, Vcl.Dialogs, Vcl.Forms, System.IniFiles;

type
  TDtm = class(TDataModule)
    Conn: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
    procedure ConnBeforeConnect(Sender: TObject);
  private
  procedure CarregarConfigDB(Connection: TFDConnection);
    { Private declarations }
  public
    { Public declarations }
    function ListarProduct(): TJsonArray;
    function InsertProduct(product: string; value: Currency): TJsonObject;

    function ListarOrder(): TJsonArray;
    function InsertOrder(value: Currency; totalItems:integer; items: TJSONArray): TJsonObject;
    function ReportOrder(const firstdate, lastdate: TDateTime): TJSONObject;

    function StatusBD: string;  // Função que retorna o texto
  end;

var
  Dtm: TDtm;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

//Configuracao de conexao com BD
procedure TDtm.CarregarConfigDB(Connection: TFDConnection);
var
  IniFile: TIniFile;
  database: string;
  db: string;
begin

  // Lê o arquivo .ini para obter o caminho do banco de dados
  IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'config.ini');
  try
    // Lê o valor da chave 'Path' na seção 'Database'
    database:= IniFile.ReadString('API', 'BD', '');

    if database = '' then
    begin
      ShowMessage('Caminho do banco de dados não encontrado no arquivo .ini');
      Exit;
    end;

    db:= database;

    Connection.DriverName := 'SQLite';
    with Connection.Params do
    begin
        Clear;
        Add('DriverID=SQLite');

        Add('Database=' + db);
       //  Add('Database=C:\MONITOR REDE\BACKEND\DB\banco.db');
        Add('LockingMode=Normal'); // Parâmetro opcional
        Add('Synchronous=Full');   // Parâmetro opcional

    end;

  finally
    IniFile.Free;
  end;
end;

procedure TDtm.ConnBeforeConnect(Sender: TObject);
begin
CarregarConfigDB(Conn);
end;

procedure TDtm.DataModuleCreate(Sender: TObject);
begin
    TDataSetSerializeConfig.GetInstance.CaseNameDefinition := cndLower;
    TDataSetSerializeConfig.GetInstance.Import.DecimalSeparator := '.';


    try
    Conn.Connected := true;
    except
    on E: Exception do
        begin
            // Trate o erro aqui
            ShowMessage('Verifique o caminho do servidor!');
            // Opcional: encerrar a aplicação ou redirecionar o usuário
            Application.Terminate; // Ou você pode usar um exit para sair da rotina
        end;
    end;

end;

function TDtm.StatusBD: string;
begin
  //Se ele chegar ate aqui a Conexao com BD esta ok
  Result := 'CONECTADO';
end;


///////PRODUCTS  (PRODUTOS)
function TDtm.ListarProduct(): TJsonArray;
var
    qry: TFDQuery;
begin
    try

        qry := TFDQuery.Create(nil);
        qry.Connection := Conn;

        qry.SQL.Add('SELECT * FROM tbl_product');
        qry.Open;

        Result := qry.ToJSONArray

    finally
        FreeAndNil(qry);
    end;
end;


function TDtm.InsertProduct(product: string; value: Currency): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    // Iniciar uma transação
    Conn.StartTransaction;

    // Inserir os dados na tabela tbl_trips
    qry.SQL.Text := 'INSERT INTO tbl_product (product, value, status) ' +
                    'VALUES (:product, :value, :status)';

    qry.ParamByName('value').Value := value; // O valor monetário em Real
    qry.ParamByName('product').Value := product;
    qry.ParamByName('status').Value := 'Ativo';


    qry.ExecSQL;

    // Commit da transação
    Conn.Commit;

    // Retorna um JSON com o status de sucesso
    Result := TJsonObject.Create;
    Result.AddPair('status', 'success');
    Result.AddPair('message', 'Produto registrada com sucesso');
  except
    on E: Exception do
    begin
      // Caso ocorra um erro, faz o rollback e retorna a mensagem de erro
      Conn.Rollback;
      Result := TJsonObject.Create;
      Result.AddPair('status', 'error');
      Result.AddPair('message', 'Erro ao registrar Produto: ' + E.Message);
    end;
  end;
end;


///////ORDER  (VENDAS)
function TDtm.ListarOrder(): TJsonArray;
var
    qry: TFDQuery;
begin
    try

        qry := TFDQuery.Create(nil);
        qry.Connection := Conn;

        qry.SQL.Add('SELECT * FROM tbl_order');
        qry.Open;

        Result := qry.ToJSONArray

    finally
        FreeAndNil(qry);
    end;
end;




function TDtm.InsertOrder(value: Currency; totalItems:integer; items: TJSONArray): TJSONObject;
var
  qryOrder, qryItem: TFDQuery;
  orderId: Integer;
  item: TJSONObject;
  i: Integer;
begin
  qryOrder := nil;
  qryItem := nil;
  try
    // Início do primeiro bloco TRY para criação dos objetos
    try
      qryOrder := TFDQuery.Create(nil);
      qryItem := TFDQuery.Create(nil);
      qryOrder.Connection := Conn;
      qryItem.Connection := Conn;

      // Inicia uma transação
      Conn.StartTransaction;

      // Inserir os dados na tabela tbl_order
      qryOrder.SQL.Text := 'INSERT INTO tbl_order (value, totalitems, date) VALUES (:value, :totalitems, :date)';
      qryOrder.ParamByName('value').AsCurrency := value;
      qryOrder.ParamByName('totalitems').AsCurrency := totalItems;

      qryOrder.ParamByName('date').Value := FormatDateTime('yyyy-mm-dd HH:nn:ss', now);
      qryOrder.ExecSQL;

      // Obter o ID da última inserção
      qryOrder.SQL.Text := 'SELECT last_insert_rowid() AS id';
      qryOrder.Open;
      orderId := qryOrder.FieldByName('id').AsInteger;

      // Inserir os itens na tabela tbl_order_items
      qryItem.SQL.Text :=
        'INSERT INTO tbl_itens_order (id_order, id_product, value, qtd, total) ' +
        'VALUES (:id_order, :id_product, :value, :qtd, :total)';

      for i := 0 to items.Count - 1 do
      begin
        item := items.Items[i] as TJSONObject;

        qryItem.ParamByName('id_order').AsInteger := orderId;
        qryItem.ParamByName('id_product').AsInteger := item.GetValue<Integer>('id_product');
        qryItem.ParamByName('value').AsCurrency := item.GetValue<Currency>('total') / item.GetValue<Integer>('quantity');
        qryItem.ParamByName('qtd').AsInteger := item.GetValue<Integer>('quantity');
        qryItem.ParamByName('total').AsCurrency := item.GetValue<Currency>('total');

        qryItem.ExecSQL;
      end;

      // Commit da transação
      Conn.Commit;

      // Retorna um JSON com o ID da ordem e status de sucesso
      Result := TJSONObject.Create;
      Result.AddPair('status', 'success');
      Result.AddPair('message', 'Ordem registrada com sucesso');
      Result.AddPair('orderId', TJSONNumber.Create(orderId));

    except
      on E: Exception do
      begin
        // Rollback em caso de erro
        Conn.Rollback;
        raise; // Relança a exceção para ser tratada fora do bloco interno
      end;
    end;
  finally
    if Assigned(qryOrder) then
    begin
      qryOrder.Close;
      FreeAndNil(qryOrder);
    end;
    if Assigned(qryItem) then
    begin
      qryItem.Close;
      FreeAndNil(qryItem);
    end;
  end;
end;

function TDtm.ReportOrder(const firstdate, lastdate: TDateTime): TJSONObject;
var
  qryOrder, qryItem: TFDQuery;
  DataFirst, DataLast: string;
  jsonOrderObj, jsonItemObj: TJSONObject;
  jsonOrdersArray, jsonItemsArray: TJSONArray;
  finalJson: TJSONObject;
  orderId: Integer;
begin
  try
    qryOrder := TFDQuery.Create(nil);
    qryItem := TFDQuery.Create(nil);
    qryOrder.Connection := Conn;
    qryItem.Connection := Conn;

    // Converter as datas para o formato YYYY-MM-DD
    DataFirst := FormatDateTime('yyyy-mm-dd', firstdate);
    DataLast := FormatDateTime('yyyy-mm-dd', lastdate);

    // Inicializa o array JSON e o objeto final
    jsonOrdersArray := TJSONArray.Create;
    finalJson := TJSONObject.Create;

    // Consulta os pedidos
    qryOrder.SQL.Add('SELECT id_order, date, totalitems, value ');
    qryOrder.SQL.Add('FROM tbl_order ');
    qryOrder.SQL.Add('WHERE DATE(date) BETWEEN :data_inicio AND :data_fim');
    qryOrder.SQL.Add('ORDER BY date');

    qryOrder.ParamByName('data_inicio').Value := DataFirst;
    qryOrder.ParamByName('data_fim').Value := DataLast;
    qryOrder.Open;

    // Processa os pedidos
    while not qryOrder.Eof do
    begin
      // Cria o JSON para a ordem atual
      jsonOrderObj := TJSONObject.Create;
      orderId := qryOrder.FieldByName('id_order').AsInteger;

      jsonOrderObj.AddPair('id_order', TJSONNumber.Create(orderId));
      jsonOrderObj.AddPair('date', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', qryOrder.FieldByName('date').AsDateTime));
      jsonOrderObj.AddPair('totalitems', qryOrder.FieldByName('totalitems').AsString);
      jsonOrderObj.AddPair('value', TJSONNumber.Create(qryOrder.FieldByName('value').AsFloat));

      // Consulta os itens da ordem atual
      qryItem.SQL.Text :=
        'SELECT i.id_product, p.product, i.value, i.qtd, i.total ' +
        'FROM tbl_itens_order i ' +
        'INNER JOIN tbl_product p ON i.id_product = p.id_product ' +
        'WHERE i.id_order = :id_order';
      qryItem.ParamByName('id_order').Value := orderId;
      qryItem.Open;

      // Inicializa o array de itens
      jsonItemsArray := TJSONArray.Create;

      while not qryItem.Eof do
      begin
        // Cria o JSON para o item atual
        jsonItemObj := TJSONObject.Create;
        jsonItemObj.AddPair('id_product', TJSONNumber.Create(qryItem.FieldByName('id_product').AsInteger));
        jsonItemObj.AddPair('product', qryItem.FieldByName('product').AsString);
        jsonItemObj.AddPair('value', TJSONNumber.Create(qryItem.FieldByName('value').AsFloat));
        jsonItemObj.AddPair('qtd', TJSONNumber.Create(qryItem.FieldByName('qtd').AsInteger));
        jsonItemObj.AddPair('total', TJSONNumber.Create(qryItem.FieldByName('total').AsFloat));

        // Adiciona o item ao array de itens
        jsonItemsArray.AddElement(jsonItemObj);
        qryItem.Next;
      end;

      // Adiciona os itens ao JSON da ordem
      jsonOrderObj.AddPair('items', jsonItemsArray);

      // Adiciona a ordem ao array de ordens
      jsonOrdersArray.AddElement(jsonOrderObj);

      qryOrder.Next;
    end;

    // Adiciona o array de ordens ao objeto final
    finalJson.AddPair('orders', jsonOrdersArray);

    // Retorna o JSON final
    Result := finalJson;
  finally
    FreeAndNil(qryOrder);
    FreeAndNil(qryItem);
  end;
end;





{function TDtm.InsertOrder(value: Currency): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    // Iniciar uma transação
    Conn.StartTransaction;

    // Inserir os dados na tabela tbl_trips
    qry.SQL.Text := 'INSERT INTO tbl_order (value, date) ' +
                    'VALUES (:value, :date)';

    qry.ParamByName('value').Value := value; // O valor monetário em Real
    qry.ParamByName('date').Value := FormatDateTime('yyyy-mm-dd HH:nn:ss', now);

    qry.ExecSQL;

    // Commit da transação
    Conn.Commit;

    // Retorna um JSON com o status de sucesso
    Result := TJsonObject.Create;
    Result.AddPair('status', 'success');
    Result.AddPair('message', 'Serviço registrada com sucesso');
  except
    on E: Exception do
    begin
      // Caso ocorra um erro, faz o rollback e retorna a mensagem de erro
      Conn.Rollback;
      Result := TJsonObject.Create;
      Result.AddPair('status', 'error');
      Result.AddPair('message', 'Erro ao registrar Serviço: ' + E.Message);
    end;
  end;
end;  }

end.
