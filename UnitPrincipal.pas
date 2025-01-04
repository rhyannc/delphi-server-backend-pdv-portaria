unit UnitPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  DM, System.IniFiles,FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  Vcl.ExtCtrls, IdBaseComponent, IdComponent, IdIPWatch;

type
  TFrmPrincipal = class(TForm)
    Panel1: TPanel;
    lblIP: TLabel;
    lblPorta: TLabel;
    Label1: TLabel;
    Image1: TImage;
    edtip: TEdit;
    edtporta: TEdit;
    edtbanco: TEdit;
    pnl_status: TPanel;
    idp: TIdIPWatch;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    PORTA:integer;
    DB:string;
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.dfm}

uses Horse,
  Horse.Jhonson,
  Horse.CORS,
  Registry,
  Controllers.Order,
  Controllers.Product,
  Controllers.Relatorios;


//CONSULTA O DM PARA INICIAR UM CONEXAO COM BD E SABER SE ESTA FUNCIONANDO
function ObterStatusBD: string;
var
  dm: TDtm;
begin
  dm := TDtm.Create(nil);
  try
    Result := dm.StatusBD;  // Retorna o texto do StatusBD
  finally
    FreeAndNil(dm);  // Libera o DataModule
  end;
end;

procedure Status(Req: THorseRequest; Res: THorseResponse; Next: Tproc);
var
  dm:TDtm;
begin
  Res.Send('SERVIDOR ONLINE').Status(200);
end;

procedure TFrmPrincipal.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini');
  try
    // Ler o valor de IdLocal da seção [LOCAL] no arquivo INI
    PORTA := IniFile.ReadInteger('API', 'Port', 3060);  // Valor padrão 0 caso não exista
    DB:= IniFile.ReadString('API', 'BD', '');
  finally
    IniFile.Free;
  end;

  if PORTA = 0 then
  begin
    ShowMessage('Porta não encontrado no arquivo INI.');
    Application.Terminate;  // Fechar a aplicação
    end;

end;

procedure TFrmPrincipal.FormShow(Sender: TObject);
var
EnvValue: string;
PortStr: string;
Port: Integer;
Textostatudm: string;
begin


    // Capturando a variável de ambiente "API_PORTS"  PORTA PARA API FUNCIONAR
    PortStr := inttostr(PORTA);

    // Iniciando o Horse
    THorse.Use(Jhonson());
    THorse.Use(CORS);


    // Configurações de endpoints do Horse
    THorse.Get('/status', Status);
    Controllers.Order.RegistrarRotas;
    Controllers.Product.RegistrarRotas;
    Controllers.Relatorios.RegistrarRotas;



    // Verifica
    if DB <> '' then
     begin
      pnl_status.Color := RGB(254, 144, 62);
      pnl_status.caption := 'BD NÃO CONECTADO';
      //SE ELE JA TEMAS VARIAVEIS DE AMBIENTE COM O CAMNIHO DO DB
       Textostatudm := ObterStatusBD;
       pnl_status.caption :=    Textostatudm;
    end
    else
    begin
      pnl_status.caption := 'BD NÃO INFORMADO';
      pnl_status.Color := RGB(228, 124, 124);
    end;


    // Configurações de Porta do Horse
    // Verifica se a variável foi encontrada e se é um número válido
     if PortStr <> '' then
     begin
      Port := StrToIntDef(PortStr, 3050); // Se falhar, usa a porta 3002 por padrão
     end
     else
     begin
      Port := 3050; // Porta padrão se a variável não estiver configurada
     end;
     Thorse.Listen(Port);


     // Pega e Exibe dados dos EDIT
     edtip.Constraints.MinHeight := 30;
     edtporta.Constraints.MinHeight := 30;
     edtbanco.Constraints.MinHeight := 30;
     edtip.Text := idp.LocalIP;
     edtPorta.Text := inttostr(Port);
     edtbanco.Text := DB;

end;

end.
