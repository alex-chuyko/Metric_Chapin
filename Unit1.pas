unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, PerlRegEx, pcre, StdCtrls;

type
  TForm1 = class(TForm)
    mmo1: TMemo;
    mmo3: TMemo;
    btn1: TButton;
    procedure btn1Click(Sender: TObject);
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
procedure deleteComments1(var str: string);
var
  i: integer;
  RegExp : TPerlRegEx;
begin
  RegExp := TPerlRegEx.Create;
  RegExp.Options := [preMultiLine];
  RegExp.RegEx := '\/\*.*?\*\/|\/\/.*?$';                            //
  RegExp.Subject := str;
  RegExp.Compile;
  i := 0;
  if RegExp.Match then
  begin
    repeat
      delete(str, RegExp.MatchedOffset - i, RegExp.MatchedLength);
      i := i + RegExp.MatchedLength;
    until not RegExp.MatchAgain;
  end;
end;

procedure deleteComments2(var str: string);
var
  i: integer;
  RegExp : TPerlRegEx;
begin
  RegExp := TPerlRegEx.Create;
  RegExp.Options := [preMultiLine];
  RegExp.RegEx := '\/\*.*?\*\/';                            
  RegExp.Subject := str;
  RegExp.Compile;
  i := 0;
  if RegExp.Match then
  begin
    repeat
      delete(str, RegExp.MatchedOffset - i, RegExp.MatchedLength);
      i := i + RegExp.MatchedLength;
    until not RegExp.MatchAgain;
  end;
end;

procedure readFromFile(var str: string);
var
  flagInput: boolean;
  File1Name: string;
  openDialog: TOpenDialog;
begin
  flagInput:= True;
  openDialog := TOpenDialog.Create(openDialog);
  openDialog.Title:= 'Выберите файл для открытия';
  openDialog.InitialDir := GetCurrentDir;
  openDialog.Options := [ofFileMustExist];
  openDialog.Filter := 'Text file|*.txt';
  openDialog.FilterIndex := 1;
  if openDialog.Execute then
  begin
    File1Name:= openDialog.FileName;
  end
  else
    begin
      Application.MessageBox('Выбор файла для открытия остановлен!', 'Предупреждение!');
      flagInput:=False;
    end;
  if flagInput then
  begin
    AssignFile(input, File1Name);
    reset(input);
    while not Eof do
    begin
      readln(str);
      Form1.mmo1.Text := Form1.mmo1.Text + str + #13 + #10;
    end;
    CloseFile(input);
  end;
  openDialog.Free;
  str := Form1.mmo1.Text;
end;                              //'((void|int|float|bool|short|unsigned\s+int)\s+[a-zA-Z_][a-zA-Z_\d]*\s*\(.*?)(?=(?:void|int|float|bool|short|unsigned\s+int)\s+[a-zA-Z_][a-zA-Z_\d]*\s*\(|$)';

procedure breakingSubroutines(str : string; var arr: arrString; var count : integer);
var
  RegExp : TPerlRegEx;
begin
  count := 0;
  RegExp := TPerlRegEx.Create;
  RegExp.Options := [preMultiLine];
  RegExp.RegEx := '((void|int|float|bool|short|unsigned\s+int|char|double|\s)\s+[a-zA-Z_][a-zA-Z_\d]*\s*\(.*?)(?=(?:void|int|float|bool|short|unsigned\s+int)\s+[a-zA-Z_][a-zA-Z_\d]*\s*\(|$)';
  RegExp.Subject := str;
  RegExp.Compile;
  if RegExp.Match then
  begin
    repeat
      inc(count);
      arr[count] := RegExp.MatchedText;
    until not RegExp.MatchAgain;
  end;
end;
///////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



/////////////////// search Mod. Variable \\\\\\\\\\\\\\\\\\\
function checkArr(arr: arrString; count : integer; s : string): boolean;
var
  flag : boolean;
  i: integer;
begin
  flag := true;
  for i:= 1 to count do
    if s = arr[i] then
      flag := false;
  checkArr := flag;
end;

function searchModVariable(str: string; var arr: arrString; var count: integer): integer;
var
  RegExp: TPerlRegEx;
  s : string;
begin
  count := 0;
  RegExp := TPerlRegEx.Create;
  RegExp.RegEx := '\b[a-zA-Z_]\w*(?=\s\=[\s\w]*)|[a-zA-Z_]\w*(?=\+\+|\-\-)|(?<=\+\+|\-\-)[a-zA-Z_]\w*|[a-zA-Z_]\w*(?=\s\+\=|\s\-\=|\s\*\=|\s\/\=)|\b[a-zA-Z_]\w*(?=\[{1}.{2,20}\=)';//'(?<=\s)[a-zA-Z_]\w*(?=\s\=[\s\w]*)|[a-zA-Z_]\w*(?=\+\+|\-\-)|(?<=\+\+|\-\-)[a-zA-Z_]\w*|[a-zA-Z_]\w*(?=\s\+\=|\s\-\=|\s\*\=|\s\/\=)';
  RegExp.Subject := str;
  RegExp.Compile;
  if RegExp.Match then
  begin
    repeat
      s := RegExp.MatchedText;
      if checkArr(arr, count, s) then
      begin
        inc(count);
        arr[count] := s;
      end;
    until not RegExp.MatchAgain;
  end;
  searchModVariable := count;
end;
///////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



/////////////////// search Control Variable \\\\\\\\\\\\\\\\\\\
function searchControlVariable(str : string): integer;
var
  RegExp, RegExp1 : TPerlRegEx;
  arr: arrString;
  count, i, k1, k2 : integer;
  s : string;
begin
  count := 0;
  i := 0;
  k1 := 0;
  k2 := 0;
  RegExp := TPerlRegEx.Create;

//////////////// SWITCH \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '(?<=\bswitch\b\()\s*[a-zA-Z_]\w*\s*(?=\))';//'(?<=\sfor\s\()\s*(int|float|short|unsigned|unsigned\s+int)?\s*\w+';//\s*for\s*\(\s*(int|float|short|unsigned)?\s*\w+';//'[\s]*for[\s]*\((int|float|short|unsigned\s+int)?[\s]+[\w]+';
  RegExp.Subject := str;
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
          s := RegExp1.MatchedText;
          if checkArr(arr, count, s) then
          begin
            inc(count);
            arr[count] := s;
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
          s := RegExp1.Subject;
          delete(s, RegExp1.MatchedOffset, RegExp1.MatchedLength);
          if checkArr(arr, count, s) then
          begin
            inc(count);
            arr[count] := s;
          end;
        until not RegExp1.MatchAgain;
      end;
    until not RegExp.MatchAgain;
  end;
//////////////// FOR \\\\\\\\\\\\\\\\\\\\\\\\\\\

//////////////// IF \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '\bif\s*';      //'\bif\s*'; //'((?<=\bif\s\()|(?<=\bif\()).*?(?=\).*?)';
  RegExp.Subject := str;
  s := '';
  RegExp.Compile;
  if RegExp.Match then
  begin
    repeat
      i := RegExp.MatchedOffset + RegExp.MatchedLength;
      while (k1 <> k2) or ((k1 = 0) and (k2 = 0)) do
      begin
        if str[i] = '(' then
          inc(k1);
        if str[i] = ')' then
          inc(k2);
        s := s + str[i];
        inc(i);
      end;
      k1 := 0;
      k2 := 0;
    until not RegExp.MatchAgain;

    RegExp1.RegEx := '\b[a-zA-Z_]\w*\s*\(.*?\)';
    RegExp1.Subject := s;
    if RegExp1.Match then
    begin
      repeat
        s := RegExp1.Subject;
        delete(s, RegExp1.MatchedOffset, RegExp1.MatchedLength);
        RegExp1.Subject := s;
      until not RegExp1.MatchAgain;
    end;

    RegExp1.RegEx := '(?<!\[)[a-zA-Z_]\w*(?!\])';
    RegExp1.Subject := s;
    if RegExp1.Match then
    begin
      repeat
        s := RegExp1.MatchedText;
        if checkArr(arr, count, s) then
        begin
          inc(count);
          arr[count] := s;
        end;
      until not RegExp1.MatchAgain;
    end;
  end;
//////////////// IF \\\\\\\\\\\\\\\\\\\\\\\\\\\

//////////////// WHILE \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '\bwhile\s*';//'((?<=\swhile\s\()|(?<=\swhile\()).*?(?=\))';
  RegExp.Subject := str;
  RegExp.Compile;
  s := '';
  k1 := 0;
  k2 := 0;
  if RegExp.Match then
  begin
    repeat
    i := RegExp.MatchedOffset + RegExp.MatchedLength;
    while (k1 <> k2) or ((k1 = 0) and (k2 = 0)) do
    begin
      if str[i] = '(' then
        inc(k1);
      if str[i] = ')' then
        inc(k2);
      s := s + str[i];
      inc(i);
    end;
    k1 := 0;
    k2 := 0;
    until not RegExp.MatchAgain;

    RegExp1.RegEx := '\b[a-zA-Z_]\w*\s*\(.*?\)';
    RegExp1.Subject := s;
    if RegExp1.Match then
    begin
      repeat
        s := RegExp1.Subject;
        delete(s, RegExp1.MatchedOffset, RegExp1.MatchedLength);
        RegExp1.Subject := s;
      until not RegExp1.MatchAgain;
    end;

    RegExp1.RegEx := '(?<!\[)[a-zA-Z_]\w*(?!\])';
    RegExp1.Subject := s;
    if RegExp1.Match then
    begin
      repeat
        s := RegExp1.MatchedText;
        if checkArr(arr, count, s) then
        begin
          inc(count);
          arr[count] := s;
        end;
      until not RegExp1.MatchAgain;
    end;
  end; 
//////////////// WHILE \\\\\\\\\\\\\\\\\\\\\\\\\\\


//////////////// ? : \\\\\\\\\\\\\\\\\\\\\\\\\\\
  RegExp.RegEx := '\?';
  RegExp.Subject := str;
  RegExp.Compile;
  s := '';
  k1 := 0;
  k2 := 0;
  if RegExp.Match then
  begin
    repeat
    i := RegExp.MatchedOffset - RegExp.MatchedLength;
    while (k1 <> k2) or ((k1 = 0) and (k2 = 0)) do
    begin
      if str[i] = '(' then
        inc(k1);
      if str[i] = ')' then
        inc(k2);
      s := str[i] + s;
      dec(i);
    end;
    k1 := 0;
    k2 := 0;
    until not RegExp.MatchAgain;

    RegExp1.RegEx := '\b[a-zA-Z_]\w*\s*\(.*?\)';
    RegExp1.Subject := s;
    if RegExp1.Match then
    begin
      repeat
        s := RegExp1.Subject;
        delete(s, RegExp1.MatchedOffset, RegExp1.MatchedLength);
        RegExp1.Subject := s;
      until not RegExp1.MatchAgain;
    end;

    RegExp1.RegEx := '(?<!\[)[a-zA-Z_]\w*(?!\])';
    RegExp1.Subject := s;
    if RegExp1.Match then
    begin
      repeat
        s := RegExp1.MatchedText;
        if checkArr(arr, count, s) then
        begin
          inc(count);
          arr[count] := s;
        end;
      until not RegExp1.MatchAgain;
    end;
  end;
//////////////// ? : \\\\\\\\\\\\\\\\\\\\\\\\\\\

  searchControlVariable := count;
end;
/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



/////////////////// search Parazit Variables \\\\\\\\\\\\\\\\\\\\
procedure check(arr: arrString; count: integer; str : string; var num : arrInteger);
var
  RegEx : TPerlRegEx;
  i : integer;
begin
  RegEx := TPerlRegEx.Create;
  RegEx.Subject := str;
  for i:=1 to count do
  begin
    num[i] := 0;
    RegEx.RegEx := '\b' + arr[i] + '\b';
    RegEx.Compile;
    if RegEx.Match then
    begin
      repeat
        inc(num[i]);
      until not RegEx.MatchAgain;
      dec(num[i]);
    end;
  end;
end;

function searchParazitVariable(str : string): integer;
var
  RegExp, RegExp2, RegExp3: TPerlRegEx;
  i, count, number: integer;
  str1 : string;
  arr : arrString;
  num : arrInteger;
begin
  count := 0;
  number := 0;
  RegExp := TPerlRegEx.Create;
  RegExp.RegEx := '(?<=\sint|float|short|unsigned|unsigned\sint|char|bool|double)[\w\,\s=\+\-\/\*\[\]]+\;';  //'\s(?:int|float|short|unsigned|unsigned\s+int|char|bool|double)\s[\w\,\s=\+\-\/\*\[\]]+\;';
  RegExp.Subject := str;
  RegExp.Compile;
  if RegExp.Match then
  begin
    RegExp2 := TPerlRegEx.Create;
    RegExp2.RegEx := '\s*\=\s*[\w\+\*\-\/\(\)]+';
    RegExp2.Compile;
    repeat
      RegExp2.Subject := RegExp.MatchedText;
      str1 := RegExp.MatchedText;
      i := 0;
      if RegExp2.Match then
      begin
        repeat
          delete(str1, RegExp2.MatchedOffset - i, RegExp2.MatchedLength);
          i := i + RegExp2.MatchedLength;
        until not RegExp2.MatchAgain;
      end;
        RegExp3 := TPerlRegEx.Create;
        RegExp3.RegEx := '\b[a-zA-Z_]\w*\b';
        RegExp3.Subject := str1;
        RegExp3.Compile;
        if RegExp3.Match then
        begin
          repeat
            inc(count);
            arr[count] := RegExp3.MatchedText;
          until not RegExp3.MatchAgain;
        end;
    until not RegExp.MatchAgain;
  end;
  check(arr, count, str, num);
  for i:= 1 to count do
    if num[i] = 0 then
      inc(number);
  searchParazitVariable := number;
end;
////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


/////////////////// search Variables To Output and Calc. \\\\\\\\\\\\\\\\\\\\
function searchVariableForOutput(str: string; arrModVar : arrString; countArrModVar : integer): integer;
var
  RegExp, RegExp1 : TPerlRegEx;
  s : string;
  count : integer;
  arr : arrString;
begin
  count := 0;
  RegExp := TPerlRegEx.Create;
  RegExp.RegEx := '\s*(\=|\+\=|\*\=|\-\=|\/\=)[\w\s\\\/\*\+\*\-\(\)]*\;';
  RegExp.Subject := str;
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
          s := RegExp1.MatchedText;
          if (checkArr(arrModVar, countArrModVar, s)) and (checkArr(arr, count, s)) then
          begin
            inc(count);
            arr[count] := s;
          end;
        until not RegExp1.MatchAgain;
      end;
    until not RegExp.MatchAgain;
  end;
  searchVariableForOutput := count;
end;
////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



procedure TForm1.btn1Click(Sender: TObject);
var
  i, count, countArrModVar: integer;
  str: string;
  arr, arrModVar: arrString;
  P, M, C, T: integer;
  Q : Extended;
begin
  mmo1.Clear;
  mmo3.Clear;
  P := 0; M := 0; C := 0; T := 0; Q := 0;

  readFromFile(str);
  deleteComments1(str);

  for i:= 1 to length(str) do
    if (str[i] = #13) or (str[i] = #10) then
      str[i] := #0;
  deleteComments2(str);
  breakingSubroutines(str, arr, count);

  for i:= 1 to count do
  begin
    M := M + searchModVariable(arr[i], arrModVar, countArrModVar);
    P := P + searchVariableForOutput(arr[i], arrModVar, countArrModVar);
    T := T + searchParazitVariable(arr[i]);
    C := C + searchControlVariable(arr[i]);
  end;

  Q := coeffP * P + coeffM * M + coeffC * C + coeffT * T;
  mmo3.Text := mmo3.Text + 'P = ' + IntToStr(P) + '; ' + 'M = ' + IntToStr(M) + '; ' + 'C = ' + IntToStr(C) + '; ' + 'T = ' + IntToStr(T) + #13 + #10 + 'Q = ' + FloatToStr(Q);
end;

end.
 