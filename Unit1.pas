unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, PerlRegEx, pcre, StdCtrls;

type
  TForm1 = class(TForm)
    mmoInput: TMemo;
    mmoOutput: TMemo;
    btnRun: TButton;
    procedure btnRunClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
  arrString = array[1..50] of string;
  arrInteger = array[1..50] of integer;

const
  coeffP = 1;
  coeffM = 2;
  coeffC = 3;
  coeffT = 0.5;
  empStr = '';

var
  Form1: TForm1;


implementation

{$R *.dfm}

/////////////////////// Additional Routines \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
procedure deleteComments1(var CodeString: string);
var
  LengthDeleteRow : integer;
  RegExp : TPerlRegEx;
begin
  RegExp := TPerlRegEx.Create;
  RegExp.Options := [preMultiLine];
  RegExp.RegEx := '\/\*.*?\*\/|\/\/.*?$';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  LengthDeleteRow := 0;
  if RegExp.Match then
  begin
    repeat
      delete(CodeString, RegExp.MatchedOffset - LengthDeleteRow, RegExp.MatchedLength);
      LengthDeleteRow := LengthDeleteRow + RegExp.MatchedLength;
    until not RegExp.MatchAgain;
  end;
end;

procedure deleteComments2(var CodeString: string);
var
  LengthDeleteRow: integer;
  RegExp : TPerlRegEx;
begin
  RegExp := TPerlRegEx.Create;
  RegExp.Options := [preMultiLine];
  RegExp.RegEx := '\/\*.*?\*\/';                            
  RegExp.Subject := CodeString;
  RegExp.Compile;
  LengthDeleteRow := 0;
  if RegExp.Match then
  begin
    repeat
      delete(CodeString, RegExp.MatchedOffset - LengthDeleteRow, RegExp.MatchedLength);
      LengthDeleteRow := LengthDeleteRow + RegExp.MatchedLength;
    until not RegExp.MatchAgain;
  end;
end;

procedure deleteString(var CodeString: string);
var
  LengthDeleteRow: integer;
  RegExp : TPerlRegEx;
begin
  RegExp := TPerlRegEx.Create;
  RegExp.Options := [preMultiLine];
  RegExp.RegEx := '\".*?\"';                            
  RegExp.Subject := CodeString;
  RegExp.Compile;
  LengthDeleteRow := 0;
  if RegExp.Match then
  begin
    repeat
      delete(CodeString, RegExp.MatchedOffset - LengthDeleteRow, RegExp.MatchedLength);
      LengthDeleteRow := LengthDeleteRow + RegExp.MatchedLength;
    until not RegExp.MatchAgain;
  end;
end;

procedure readFromFile(var CodeString: string);
var
  FlagInput: boolean;
  File1Name: string;
  OpenDialog: TOpenDialog;
begin
  FlagInput:= True;
  OpenDialog := TOpenDialog.Create(OpenDialog);
  OpenDialog.Title:= 'Выберите файл для открытия';
  OpenDialog.InitialDir := GetCurrentDir;
  OpenDialog.Options := [ofFileMustExist];
  OpenDialog.Filter := 'Text file|*.txt';
  OpenDialog.FilterIndex := 1;
  if OpenDialog.Execute then
  begin
    File1Name:= OpenDialog.FileName;
  end
  else
    begin
      Application.MessageBox('Выбор файла для открытия остановлен!', 'Предупреждение!');
      FlagInput:=False;
    end;
  if FlagInput then
  begin
    AssignFile(input, File1Name);
    reset(input);
    while not Eof do
    begin
      readln(CodeString);
      Form1.mmoInput.Text := Form1.mmoInput.Text + CodeString + #13 + #10;
    end;
    CloseFile(input);
  end;
  OpenDialog.Free;
  CodeString := Form1.mmoInput.Text;
end;                              //'((void|int|float|bool|short|unsigned\s+int)\s+[a-zA-Z_][a-zA-Z_\d]*\s*\(.*?)(?=(?:void|int|float|bool|short|unsigned\s+int)\s+[a-zA-Z_][a-zA-Z_\d]*\s*\(|$)';

procedure breakingSubroutines(CodeString : string; var arraySubroutines: arrString; var Quantity : integer);
var
  RegExp : TPerlRegEx;
begin
  Quantity := 0;
  RegExp := TPerlRegEx.Create;
  RegExp.Options := [preMultiLine];
  RegExp.RegEx := '((void|int|float|bool|short|unsigned\s+int|char|double|\s)\s+[a-zA-Z_][a-zA-Z_\d]*\s*\(.*?)(?=(?:void|int|float|bool|short|unsigned\s+int)\s+[a-zA-Z_][a-zA-Z_\d]*\s*\(|$)';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  if RegExp.Match then
  begin
    repeat
      inc(Quantity);
      arraySubroutines[Quantity] := RegExp.MatchedText;
    until not RegExp.MatchAgain;
  end;
end;
///////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



/////////////////// search Mod. Variable \\\\\\\\\\\\\\\\\\\
function checkRepeatVariables(arrayVariable: arrString; Quantity : integer; nameVariables : string): boolean;
var
  flag : boolean;
  i: integer;
begin
  flag := true;
  for i:= 1 to Quantity do
    if nameVariables = arrayVariable[i] then
      flag := false;
  checkRepeatVariables := flag;
end;

function searchModVariable(CodeString: string; var arrayModVariable: arrString; var Quantity: integer): integer;
var
  RegExp: TPerlRegEx;
  nameVariables : string;
begin
  Quantity := 0;
  RegExp := TPerlRegEx.Create;
  RegExp.RegEx := '\b[a-zA-Z_]\w*(?=\s\=[\s\w]*)|[a-zA-Z_]\w*(?=\+\+|\-\-)|(?<=\+\+|\-\-)[a-zA-Z_]\w*|[a-zA-Z_]\w*(?=\s\+\=|\s\-\=|\s\*\=|\s\/\=)|\b[a-zA-Z_]\w*(?=\[{1}.{2,20}\=)';//'(?<=\s)[a-zA-Z_]\w*(?=\s\=[\s\w]*)|[a-zA-Z_]\w*(?=\+\+|\-\-)|(?<=\+\+|\-\-)[a-zA-Z_]\w*|[a-zA-Z_]\w*(?=\s\+\=|\s\-\=|\s\*\=|\s\/\=)';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  if RegExp.Match then
  begin
    repeat
      nameVariables := RegExp.MatchedText;
      if checkRepeatVariables(arrayModVariable, Quantity, nameVariables) then
      begin
        inc(Quantity);
        arrayModVariable[Quantity] := nameVariables;
      end;
    until not RegExp.MatchAgain;
  end;
  searchModVariable := Quantity;
end;
///////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



/////////////////// search Control Variable \\\\\\\\\\\\\\\\\\\
function searchControlVariable(CodeString : string): integer;
var
  RegExp, RegExp1 : TPerlRegEx;
  arrayControlVariables: arrString;
  Quantity, i, numberOpeningBrackets, numberClosingBrackets : integer;
  tempString : string;
begin
  Quantity := 0;
  i := 0;
  numberOpeningBrackets := 0;
  numberClosingBrackets := 0;
  RegExp := TPerlRegEx.Create;

//////////////// SWITCH \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '(?<=\bswitch\b\()\s*[a-zA-Z_]\w*\s*(?=\))';//'(?<=\sfor\s\()\s*(int|float|short|unsigned|unsigned\s+int)?\s*\w+';//\s*for\s*\(\s*(int|float|short|unsigned)?\s*\w+';//'[\s]*for[\s]*\((int|float|short|unsigned\s+int)?[\s]+[\w]+';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  if RegExp.Match then
  begin
    RegExp1 := TPerlRegEx.Create;
    RegExp1.RegEx := '\b[a-zA-Z_]\w*\b';
    RegExp1.Compile;
    repeat
      RegExp1.Subject := RegExp.MatchedText;
      if RegExp1.Match then
      begin
        repeat
          tempString := RegExp1.MatchedText;
          if checkRepeatVariables(arrayControlVariables, Quantity, tempString) then
          begin
            inc(Quantity);
            arrayControlVariables[Quantity] := tempString;
          end;
        until not RegExp1.MatchAgain;
      end;
    until not RegExp.MatchAgain;
  end;
//////////////// SWITCH \\\\\\\\\\\\\\\\\\\\\\\\\\\

//////////////// FOR \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '((?<=\sfor\s\()|(?<=\sfor\())\s*(int|float|short|unsigned|unsigned\s+int)?\s*\w+';
  RegExp.Compile;
  if RegExp.Match then
  begin
    RegExp1 := TPerlRegEx.Create;
    RegExp1.RegEx := '\s*(int|float|short|unsigned|unsigned\s+int)\s+';//'\b[a-zA-Z_]\w*\b';
    RegExp1.Compile;
    repeat
      RegExp1.Subject := RegExp.MatchedText;
      if RegExp1.Match then
      begin
        repeat
          tempString := RegExp1.Subject;
          delete(tempString, RegExp1.MatchedOffset, RegExp1.MatchedLength);
          if checkRepeatVariables(arrayControlVariables, Quantity, tempString) then
          begin
            inc(Quantity);
            arrayControlVariables[Quantity] := tempString;
          end;
        until not RegExp1.MatchAgain;
      end;
    until not RegExp.MatchAgain;
  end;
//////////////// FOR \\\\\\\\\\\\\\\\\\\\\\\\\\\

//////////////// IF \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '\bif\s*';      //'\bif\s*'; //'((?<=\bif\s\()|(?<=\bif\()).*?(?=\).*?)';
  RegExp.Subject := CodeString;
  tempString := '';
  RegExp.Compile;
  if RegExp.Match then
  begin
    repeat
      i := RegExp.MatchedOffset + RegExp.MatchedLength;
      while (numberOpeningBrackets <> numberClosingBrackets) or ((numberOpeningBrackets = 0) and (numberClosingBrackets = 0)) do
      begin
        if CodeString[i] = '(' then
          inc(numberOpeningBrackets);
        if CodeString[i] = ')' then
          inc(numberClosingBrackets);
        tempString := tempString + CodeString[i];
        inc(i);
      end;
      numberOpeningBrackets := 0;
      numberClosingBrackets := 0;
    until not RegExp.MatchAgain;

    RegExp1.RegEx := '\b[a-zA-Z_]\w*\s*\(.*?\)';
    RegExp1.Subject := tempString;
    if RegExp1.Match then
    begin
      repeat
        tempString := RegExp1.Subject;
        delete(tempString, RegExp1.MatchedOffset, RegExp1.MatchedLength);
        RegExp1.Subject := tempString;
      until not RegExp1.MatchAgain;
    end;

    RegExp1.RegEx := '(?<!\[)[a-zA-Z_]\w*(?!\])';
    RegExp1.Subject := tempString;
    if RegExp1.Match then
    begin
      repeat
        tempString := RegExp1.MatchedText;
        if checkRepeatVariables(arrayControlVariables, Quantity, tempString) then
        begin
          inc(Quantity);
          arrayControlVariables[Quantity] := tempString;
        end;
      until not RegExp1.MatchAgain;
    end;
  end;
//////////////// IF \\\\\\\\\\\\\\\\\\\\\\\\\\\

//////////////// WHILE \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '\bwhile\s*';//'((?<=\swhile\s\()|(?<=\swhile\()).*?(?=\))';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  tempString := '';
  numberOpeningBrackets := 0;
  numberClosingBrackets := 0;
  if RegExp.Match then
  begin
    repeat
      i := RegExp.MatchedOffset + RegExp.MatchedLength;
      while (numberOpeningBrackets <> numberClosingBrackets) or ((numberOpeningBrackets = 0) and (numberClosingBrackets = 0)) do
      begin
        if CodeString[i] = '(' then
          inc(numberOpeningBrackets);
        if CodeString[i] = ')' then
          inc(numberClosingBrackets);
        tempString := tempString + CodeString[i];
        inc(i);
      end;
      numberOpeningBrackets := 0;
      numberClosingBrackets := 0;
    until not RegExp.MatchAgain;

    RegExp1.RegEx := '\b[a-zA-Z_]\w*\s*\(.*?\)';
    RegExp1.Subject := tempString;
    if RegExp1.Match then
    begin
      repeat
        tempString := RegExp1.Subject;
        delete(tempString, RegExp1.MatchedOffset, RegExp1.MatchedLength);
        RegExp1.Subject := tempString;
      until not RegExp1.MatchAgain;
    end;

    RegExp1.RegEx := '(?<!\[)[a-zA-Z_]\w*(?!\])';
    RegExp1.Subject := tempString;
    if RegExp1.Match then
    begin
      repeat
        tempString := RegExp1.MatchedText;
        if checkRepeatVariables(arrayControlVariables, Quantity, tempString) then
        begin
          inc(Quantity);
          arrayControlVariables[Quantity] := tempString;
        end;
      until not RegExp1.MatchAgain;
    end;
  end; 
//////////////// WHILE \\\\\\\\\\\\\\\\\\\\\\\\\\\


//////////////// ? : \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '\?';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  tempString := '';
  numberOpeningBrackets := 0;
  numberClosingBrackets := 0;
  if RegExp.Match then
  begin
    repeat
      i := RegExp.MatchedOffset - RegExp.MatchedLength;
      while (numberOpeningBrackets <> numberClosingBrackets) or ((numberOpeningBrackets = 0) and (numberClosingBrackets = 0)) do
      begin
        if CodeString[i] = '(' then
          inc(numberOpeningBrackets);
        if CodeString[i] = ')' then
          inc(numberClosingBrackets);
        tempString := CodeString[i] + tempString;
        dec(i);
      end;
      numberOpeningBrackets := 0;
      numberClosingBrackets := 0;
    until not RegExp.MatchAgain;

    RegExp1.RegEx := '\b[a-zA-Z_]\w*\s*\(.*?\)';
    RegExp1.Subject := tempString;
    if RegExp1.Match then
    begin
      repeat
        tempString := RegExp1.Subject;
        delete(tempString, RegExp1.MatchedOffset, RegExp1.MatchedLength);
        RegExp1.Subject := tempString;
      until not RegExp1.MatchAgain;
    end;

    RegExp1.RegEx := '(?<!\[)[a-zA-Z_]\w*(?!\])';
    RegExp1.Subject := tempString;
    if RegExp1.Match then
    begin
      repeat
        tempString := RegExp1.MatchedText;
        if checkRepeatVariables(arrayControlVariables, Quantity, tempString) then
        begin
          inc(Quantity);
          arrayControlVariables[Quantity] := tempString;
        end;
      until not RegExp1.MatchAgain;
    end;
  end;
//////////////// ? : \\\\\\\\\\\\\\\\\\\\\\\\\\\

  searchControlVariable := Quantity;
end;
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



/////////////////// search Parazit Variables \\\\\\\\\\\\\\\\\\\\
procedure checkNumberOfMeetingsVariables(arrayParazitVariables: arrString; Quantity: integer; CodeString : string; var variableNumberMeetings : arrInteger);
var
  RegEx : TPerlRegEx;
  i : integer;
begin
  RegEx := TPerlRegEx.Create;
  RegEx.Subject := CodeString;
  for i:=1 to Quantity do
  begin
    variableNumberMeetings[i] := 0;
    RegEx.RegEx := '\b' + arrayParazitVariables[i] + '\b';
    RegEx.Compile;
    if RegEx.Match then
    begin
      repeat
        inc(variableNumberMeetings[i]);
      until not RegEx.MatchAgain;
      dec(variableNumberMeetings[i]);
    end;
  end;
end;

function searchParazitVariable(CodeString : string): integer;
var
  RegExp, RegExp2, RegExp3: TPerlRegEx;
  i, Quantity, NumberParazitVariables, LengthDeleteRow: integer;
  tempString : string;
  arrayParazitVariables : arrString;
  variableNumberMeetings : arrInteger;
begin
  Quantity := 0;
  NumberParazitVariables := 0;
  RegExp := TPerlRegEx.Create;
  RegExp.RegEx := '(?<=\sint|float|short|unsigned|unsigned\sint|char|bool|double)[\w\,\s=\+\-\/\*\[\]]+\;';  //'\s(?:int|float|short|unsigned|unsigned\s+int|char|bool|double)\s[\w\,\s=\+\-\/\*\[\]]+\;';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  if RegExp.Match then
  begin
    RegExp2 := TPerlRegEx.Create;
    RegExp2.RegEx := '\s*\=\s*[\w\+\*\-\/\(\)]+';
    RegExp2.Compile;
    repeat
      RegExp2.Subject := RegExp.MatchedText;
      tempString := RegExp.MatchedText;
      LengthDeleteRow := 0;
      if RegExp2.Match then
      begin
        repeat
          delete(tempString, RegExp2.MatchedOffset - LengthDeleteRow, RegExp2.MatchedLength);
          LengthDeleteRow := LengthDeleteRow + RegExp2.MatchedLength;
        until not RegExp2.MatchAgain;
      end;
        RegExp3 := TPerlRegEx.Create;
        RegExp3.RegEx := '\b[a-zA-Z_]\w*\b';
        RegExp3.Subject := tempString;
        RegExp3.Compile;
        if RegExp3.Match then
        begin
          repeat
            inc(Quantity);
            arrayParazitVariables[Quantity] := RegExp3.MatchedText;
          until not RegExp3.MatchAgain;
        end;
    until not RegExp.MatchAgain;
  end;
  checkNumberOfMeetingsVariables(arrayParazitVariables, Quantity, CodeString, variableNumberMeetings);
  for i:= 1 to Quantity do
    if variableNumberMeetings[i] = 0 then
      inc(NumberParazitVariables);
  searchParazitVariable := NumberParazitVariables;
end;
////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


/////////////////// search Variables To Output and Calc. \\\\\\\\\\\\\\\\\\\\
function searchVariableForOutput(CodeString: string; arrayModVariable : arrString; countArrayModVariable : integer): integer;
var
  RegExp, RegExp1 : TPerlRegEx;
  nameVariable : string;
  Quantity : integer;
  arrayVariableForOutput : arrString;
begin
  Quantity := 0;
  RegExp := TPerlRegEx.Create;
  RegExp.RegEx := '\s*(\=|\+\=|\*\=|\-\=|\/\=)[\w\s\\\/\*\+\*\-\(\)]*\;';
  RegExp.Subject := CodeString;
  RegExp.Compile;
  if RegExp.Match then
  begin
    RegExp1 := TPerlRegEx.Create;
    RegExp1.RegEx := '\b[a-zA-z_]\w*\b';
    RegExp1.Compile;
    repeat
      RegExp1.Subject := RegExp.MatchedText;
      if RegExp1.Match then
      begin
        repeat
          nameVariable := RegExp1.MatchedText;
          if (checkRepeatVariables(arrayModVariable, countArrayModVariable, nameVariable)) and (checkRepeatVariables(arrayVariableForOutput, Quantity, nameVariable)) then
          begin
            inc(Quantity);
            arrayVariableForOutput[Quantity] := nameVariable;
          end;
        until not RegExp1.MatchAgain;
      end;
    until not RegExp.MatchAgain;
  end;
  searchVariableForOutput := Quantity;
end;
////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



procedure TForm1.btnRunClick(Sender: TObject);
var
  i, countSubroutines, countArrayModVariable: integer;
  CodeString: string;
  arraySubroutines, arrayModVariable: arrString;
  P, M, C, T: integer;
  Q : Extended;
begin
  mmoInput.Clear;
  mmoOutput.Clear;
  P := 0; M := 0; C := 0; T := 0; Q := 0;

  readFromFile(CodeString);
  deleteString(CodeString);
  deleteComments1(CodeString);

  for i:= 1 to length(CodeString) do
    if (CodeString[i] = #13) or (CodeString[i] = #10) then
      CodeString[i] := #0;
  deleteComments2(CodeString);
  breakingSubroutines(CodeString, arraySubroutines, countSubroutines);

  for i:= 1 to countSubroutines do
  begin
    M := M + searchModVariable(arraySubroutines[i], arrayModVariable, countArrayModVariable);
    P := P + searchVariableForOutput(arraySubroutines[i], arrayModVariable, countArrayModVariable);
    T := T + searchParazitVariable(arraySubroutines[i]);
    C := C + searchControlVariable(arraySubroutines[i]);
  end;

  Q := coeffP * P + coeffM * M + coeffC * C + coeffT * T;
  mmoOutput.Text := mmoOutput.Text + 'P = ' + IntToStr(P) + '; ' + 'M = ' + IntToStr(M) + '; ' + 'C = ' + IntToStr(C) + '; ' + 'T = ' + IntToStr(T) + #13 + #10 + 'Q = ' + FloatToStr(Q);
end;

end.
 