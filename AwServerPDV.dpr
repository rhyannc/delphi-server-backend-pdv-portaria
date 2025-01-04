program AwServerPDV;

uses
  Vcl.Forms,
  UnitPrincipal in 'UnitPrincipal.pas' {FrmPrincipal},
  DM in 'DM.pas' {Dtm: TDataModule},
  Controllers.Product in 'Controller\Controllers.Product.pas',
  Controllers.Order in 'Controller\Controllers.Order.pas',
  Controllers.Relatorios in 'Controller\Controllers.Relatorios.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.CreateForm(TDtm, Dtm);
  Application.Run;
end.
