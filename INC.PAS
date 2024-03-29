Program Data_Include;
Uses Crt,Dos,CZ,THString;
Const
  OEM='Data File Includer';
  Ver='1.2';

Type
  THeader=Record
            SIGNATURE:Array[0..7] of Byte;
            Verze:Array[0..2] of Byte;
            Inicialy:Array[0..6] of Byte;
            DateOfLastChange:Array[0..3] of Byte;
            Created:Array[0..3] of Byte;
            Folders:Word;
            FoldersMax:Word;
            LongOfHeader:Word;
          end;

Var
  Header:Array[0..31] of Byte;
  H:THeader;
  I:Byte;
  FileIn,S:String[80];
  OfsTab,OfsHead:LongInt;
  Head:Boolean;
  F:File of Byte;
  B:Byte;



Procedure UpgradeHeader;
Var
  Year        :Word;
  Month,Day   :Byte;
begin
  Asm
  MOV AH,2Ah
  INT 21h
  MOV Year,CX
  MOV Month,DH
  MOV Day,DL
  end;                  {01.12.1999}
  H.DateOfLastChange[0]:=Day;
  H.DateOfLastChange[1]:=Month;
  H.DateOfLastChange[2]:=Lo(Year);
  H.DateOfLastChange[3]:=Hi(Year);

  H.Created[0]:=27;
  H.Created[1]:=4;
  H.Created[2]:=99;
  H.Created[3]:=19;

  {H.Folders:=;}

  H.FoldersMax:=65535;
  H.LongOfHeader:=32;

  For I:=0 to 31 do Header[I]:=Mem[Seg(H):Ofs(H)+I];

end;



Procedure BuildHeader;
begin
  S:='INCLUDER';For I:=0 to 7 do H.SIGNATURE[I]:=ord(S[I+1]);
  S:=Ver;For I:=0 to 2 do H.Verze[I]:=ord(S[I+1]);
  S:='NUCLEAR';For I:=0 to 6 do H.Inicialy[I]:=ord(S[I+1]);
  UpgradeHeader;
end;


{$I-}
Procedure ReadHeader;
begin
  {Nacteni hlavicky}
  Seek(F,OfsHead);
  For I:=0 to 31 do Read(F,Header[I]);
  For I:=0 to 31 do Mem[Seg(H):Ofs(H)+I]:=Header[I];
end;
{$I+}


Procedure WriteHeader;
begin
  {Zapis hlavicky}
  If not Head then
  begin
    OfsHead:=FileSize(F);
    BuildHeader;
  end
  else UpgradeHeader;

  Seek(F,OfsHead);
  For I:=0 to 31 do Header[I]:=Mem[Seg(H):Ofs(H)+I];
  For I:=0 to 31 do Write(F,Header[I]);
end;


Procedure WriteOfsHead;
begin
  If Head then Seek(F,FileSize(F)-4) else Seek(F,FileSize(F));
  Write(F,Mem[Seg(OfsHead):Ofs(OfsHead)+0]);
  Write(F,Mem[Seg(OfsHead):Ofs(OfsHead)+1]);
  Write(F,Mem[Seg(OfsHead):Ofs(OfsHead)+2]);
  Write(F,Mem[Seg(OfsHead):Ofs(OfsHead)+3]);
end;


Procedure WriteOfsTab;
begin
  If Head then Seek(F,FileSize(F)-8) else Seek(F,FileSize(F));
  Write(F,Mem[Seg(OfsTab):Ofs(OfsTab)+0]);
  Write(F,Mem[Seg(OfsTab):Ofs(OfsTab)+1]);
  Write(F,Mem[Seg(OfsTab):Ofs(OfsTab)+2]);
  Write(F,Mem[Seg(OfsTab):Ofs(OfsTab)+3]);
end;


Function ReadDataOffset(IncludeFile:String):LongInt;
Var
  Test: String[6];

begin
  Assign(F,IncludeFile);
  {$I-}Reset(F);{$I+}
  If IOResult<>0 then
  begin
    Writeln('Soubor ',IncludeFile,' nelze otevrit !');
    Halt(1);
  end;

  If FileSize(F)<8 then Exit;
  OfsHead:=0;
  {$I-}
  Seek(F,FileSize(F)-4);{Nacteni offsetu Hlavicky}
  Read(F,Mem[Seg(OfsHead):Ofs(OfsHead)+0]);
  Read(F,Mem[Seg(OfsHead):Ofs(OfsHead)+1]);
  Read(F,Mem[Seg(OfsHead):Ofs(OfsHead)+2]);
  Read(F,Mem[Seg(OfsHead):Ofs(OfsHead)+3]);
  {$I+}
  If IOResult<>0 then
  begin
    Writeln('Nelze nacist hlavicku !');
  end;

  OfsTab:=0;
  {$I-}
  Seek(F,FileSize(F)-8);{Nacteni offsetu Tabulky}
  Read(F,Mem[Seg(OfsTab):Ofs(OfsTab)+0]);
  Read(F,Mem[Seg(OfsTab):Ofs(OfsTab)+1]);
  Read(F,Mem[Seg(OfsTab):Ofs(OfsTab)+2]);
  Read(F,Mem[Seg(OfsTab):Ofs(OfsTab)+3]);
  {$I+}
  If IOResult<>0 then
  begin
    Writeln('Nelze nacist offset tabulky dat !');
  end;

  If (OfsHead>FileSize(F))or(OfsHead<0) then Head:=False else Head:=True;
  ReadHeader;
  For I:=0 to 7 do S[I+1]:=Chr(H.SIGNATURE[I]);
  If S='INCLUDER' then Head:=True else Head:=False;

  If Head then
  begin
    {$I-}Seek(F,OfsTab);{$I+}
    If (IOResult<>0)or(FilePos(F)>FileSize(F)-37) then
    begin
      Writeln('Nelze najit hlavicku dat !'#7);
      {$I-}Close(F);{$I+}
      Halt(1);
    end;

    ReadHeader;

    If IOResult<>0 then
    begin
      Writeln('Chyba pri cteni hlavicky dat !');
      {$I-}Close(F);{$I+}
      Writeln('Nelze zavrit soubor !'#7);
      Halt(1);
    end;
  end;
end;



Procedure WriteDataOffset(IncludeTo:String);
Var
  Test: String[6];
  OfsTab,TestOfs,L:LongInt;

begin
  Vstup:=IncludeTo;
  Assign(F,IncludeTo);
  {$I-}Reset(F);{$I+}
  If IOResult<>0 then
  begin
    Writeln('Soubor ',IncludeTo,' nelze otevrit !'#7);
    Writeln('Chcete vytvorit novy ?');
    Repeat
      GetKey;
    until (Scan=1)or(Scan=28)or(UpCase(Chr(ASCII))='Y')or(UpCase(Chr(ASCII))='N')or
          (UpCase(Chr(ASCII))='A');
    If (UpCase(Chr(ASCII))='Y')or(UpCase(Chr(ASCII))='A')or(Scan=28) then
    begin
      TextColor(7);TextBackground(0);
      InputLine(0,WhereY,79,'');
      Writeln;
      Assign(F,Vstup);
      {$I-}Rewrite(F);{$I+}
      If IOResult<>0 then
      begin
        Writeln('Soubor "',Vstup,'" nelze vytvorit !'#7);
        Halt(1);
      end;
    end;
  end;
  FileIn:=Vstup;

  {$I-}OfsHead:=ReadDataOffset(Vstup);{$I+}
  If IOResult<>0 then;

  If (OfsHead>FileSize(F)-32)or(OfsHead<0)then Head:=False else Head:=True;
  If Head then ReadHeader;
  For I:=0 to 7 do S[I+1]:=Chr(H.SIGNATURE[I]);
  If S='INCLUDER' then Head:=True else Head:=False;

  If Head then
  begin
    {$I-}
    Seek(F,OfsHead);{Nacteni Signatury Hlavicky}
    For I:=0 to 7 do Read(F,Mem[Seg(H.SIGNATURE):Ofs(H.SIGNATURE)+I]);
    {$I+}
    If IOResult<>0 then
    begin
      Writeln('Chyba pri cteni hlavicky !');
      Halt(1);
    end;
  end
  else
  begin
    OfsHead:=FileSize(F);
    OfsTab:=0;
    WriteHeader;
    WriteOfsTab;
    WriteOfsHead;
  end;

  {$I-}Close(F);{$I+}
  If IOResult<>0 then
  begin
    Writeln('Soubor ',FileIn,' nelze zavrit !');
    Halt(1);
  end;
  If not Head then BuildHeader else ReadHeader;
  UpgradeHeader;

end;


Begin
  TextMode(2);
  ClrScr;
  FileIn:='X.DAT';{ParamStr(0);}
  WriteDataOffset(FileIn);
  Writeln('Verze programu: ',Chr(H.Verze[0]),Chr(H.Verze[1]),Chr(H.Verze[2]));

  Writeln('Offset hlavicky: ',ReadDataOffset(FileIn));
  Write('Signatura hlavicky: ');For I:=0 to 7 do Write(Char(H.Signature[I]));
  Writeln;
  Writeln('Verze programu: ',Chr(H.Verze[0]),Chr(H.Verze[1]),Chr(H.Verze[2]));
  Writeln('Ok');
end.DFI 1.2NUCLEAR�c  �        �:&� �	C�  �     b  