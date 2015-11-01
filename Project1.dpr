program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  PerlRegEx in '..\..\..\RegExp\PerlRegEx.pas',
  pcre in '..\..\..\RegExp\pcre.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
