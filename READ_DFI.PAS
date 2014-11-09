Program Reader_DFI;
Uses Crt,Dos,THApp,THOpen,CZ,THString,THGS;
Const
  OEM='Data File Includer';
  Ver='1.2';
  FoldersMax=128;
  HeaderLength=32;
Type
  THeader=Record
            SIGNATURE:Array[0..3] of Byte;
            Ver:Array[0..2] of Byte;
            Creator:Array[0..6] of Byte;
            DateOfLastChange:Array[0..3] of Byte;
            Created:Array[0..3] of Byte;
            Folders:Word;
            FoldersMax:Word;
            HeaderLength:Word;
            SizeOfTab:LongInt;
          end;
  TTabBuf=Array[0..FoldersMax-1] of Record
                              Nazev:String[12];
                              StartOffset:LongInt;
                              EndOffset:LongInt;
                            end;

Var
  H:THeader;
  TabBuf:^TTabBuf;
  F:File;
  FileIn:String[80];
  Head:Boolean;
  S:String[80];
  OfsHead,OfsTab:LongInt;
  I:LongInt;
  Nr,L:Word;
  Ch:Char;
  Buf:Array[0..10000] of Byte;


Function TestSignature:Boolean;
Var
  I:Byte;
begin
  TestSignature:=False;
  {$I-}
  If FileSize(F)>=HeaderLength then
  begin
    Seek(F,FileSize(F)-4);
    BlockRead(F,OfsHead,4);

    Seek(F,OfsHead);
    If (OfsHead<FileSize(F)) then BlockRead(F,H,HeaderLength);
    S[0]:=#4;
    For I:=0 to 3 do S[I+1]:=chr(Mem[Seg(H):Ofs(H)+I]);
    If S='DFI ' then TestSignature:=True else TestSignature:=False;
  end;
  {$I+}ErrorMessage;
end;


Procedure OpenFile(S:String);
begin
  Assign(F,S);
  {$I-}Reset(F,1);{$I+}ErrorMessage;
end;


Procedure Info;
begin
  TextCursor(True);
  TextColor(7);TextBackground(0);
  ClrScr;
  Write('Signatura souboru: ');For I:=0 to 3 do Write(Chr(H.Signature[I]));Writeln;
  Write('Verze editoru: ');For I:=0 to 2 do Write(Chr(H.Ver[I]));Writeln;
  Writeln('Ofset Hlavicky: ',OfsHead);
  Writeln('Ofset Tabulky: ',OfsTab);
  Write('Creator: ');For I:=0 to 6 do Write(Chr(H.Creator[I]));Writeln;
  {Writeln('Datum posledni zmeny souboru: ',H.DateOfLastChange[1],'/',H.DateOfLastChange[2],'/',H.DateOfLastChange[3]);}
  {Writeln('Created: ',H.Created[0]);}
  Writeln('Pocet slozek: ',H.Folders);
  Writeln('Maximalni pocet slozek: ',H.FoldersMax);
  Writeln('Delka hlavicky: ',H.HeaderLength);
  Writeln('Delka tabulky: ',H.SizeOfTab);
end;



Procedure Konec;
begin
  SetFAttr(F,$20);
  TextCursor(True);
  TextColor(7);TextBackground(0);
  ClrScr;
  Writeln(#10#10#13'Copyright (C) 1999  Tomas Hujer');
  Halt(1);
end;



Begin
  If TabBuf=nil then New(TabBuf);
  InitStandardScreen('±',1,8,2);
  FileIn:='';
  FileIn:=ChooseFile('*.*');If Scan=1 then Konec;
  OpenFile(FileIn);
  Head:=TestSignature;

  If Head then
  begin
    {$I-}
    Seek(F,FileSize(F)-8);
    BlockRead(F,OfsTab,4);
    Seek(F,OfsTab);
    BlockRead(F,TabBuf^,H.SizeOfTab);
    {$I+}
    ErrorMessage;
  end;

  TextColor(15);TextBackground(0);

  if(H.Folders>0) then
    For L:=0 to H.Folders-1 do
    begin
      ClrScr;
      {Info;}
      Seek(F,TabBuf^[L].StartOffset);
      I:=0;

      {Repeat
        Inc(I);
        BlockRead(F,Ch,1,Nr);
        Write(Ch);
      until (Nr<>1)or(I>=TabBuf^[L].EndOffset-TabBuf^[L].StartOffset);}
      Nr:=TabBuf^[L].EndOffset-TabBuf^[L].StartOffset;
      {$I-}BlockRead(F,Buf,Nr);{$I+}ErrorMessage;
      If IORes<>0 then Konec;
      For I:=0 to Nr do Write(Chr(Buf[I]));
      Writeln(#10#13'Bytes: ',I);
      GetKey;
    end;


  If TabBuf<>nil then Dispose(TabBuf);
end.