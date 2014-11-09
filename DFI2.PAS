Program Data_File_Include;
{

MZ...
....
(Exe soubor)
....
HLAVICKA          Informace o datech          [OFFSET je na [-4]]
DATA_1            Ulozena data                [OFFSET je v tabulce dat]
DATA_2
.....
.....
TABULKA DAT       Seznam dat                  [OFFSET je na [-8]]
OFFS [Tabulky]    Offset tabulky dat          [-8]
OFFS [Hlavicky]   Offset hlavicky             [-4]


Hlavicka:
 Byty      Obsah            Delka[B]         Vysvetlivky

 0..3       DFI_             [4]               Signatura hlavicky
 4..6       1.3              [3]               Verze programu
 7..13     NUCLEAR           [7]               Inicialy autora
 14..17    1.1.1999          [4]               Datum posledni zmeny souboru
 18..21    1.1.1998          [4]               Datum posledni zmeny programu
 22..23      1000            [2]               Aktualni pocet dat. slozek
 24..25     65535            [2]               Max. pocet dat. slozek
 26..27       28             [2]               Delka hlavicky (v Bytech)
 28..31       200            [4]               Delka tabulky dat (v Bytech)


Tabulka dat:
           Nazev         OFFSET Zacatku   OFFSET Konce

           [12]               [4]             [4]

Napr.:   [EGAVGA.BGI ]       0BCDh           0DA1h
         [Driver Mysi]       A012h           B012h

}




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
  I:Byte;
  Nr,Nw:Integer;
  Attr,Attr2:Word;



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
  FileMode:=2;
  Assign(F,S);
  GetFAttr(F,Attr);
  SetFAttr(F,0);
  GetFAttr(F,Attr2);
  {$I-}Reset(F,1);{$I+}If IOResult<>0 then
  begin
    {$I-}Rewrite(F,1);{$I+}ErrorMessage;
  end;
  If (IORes=0)and(Attr2<>0) then IORes:=1 else IORes:=0;
end;


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

  H.FoldersMax:=FoldersMax;
  H.HeaderLength:=HeaderLength;

  H.SizeOfTab:=0;
end;


Procedure CreateNewHeader;
begin
  S:='DFI ';For I:=0 to 3 do H.SIGNATURE[I]:=ord(S[I+1]);
  S:=Ver;For I:=0 to 2 do H.Ver[I]:=ord(S[I+1]);
  S:='NUCLEAR';For I:=0 to 6 do H.Creator[I]:=ord(S[I+1]);

  {H.Folders:=;}
  UpgradeHeader;
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


Procedure IncludeFile;
Var
  FI:File;
  Buffer:Array[1..2048] of Byte;
  Nr,Nw,Nwc:Word;
  R:Real;
  Size:LongInt;

begin
  If H.Folders>=FoldersMax then
  begin
    OkMessage('Slozku nelze doplnit. Seznam je jiz plny !');
    Exit;
  end;
  Nwc:=0;
  S:=ChooseFile('*.*');
  If Scan=1 then Konec;
  TextInput(12,'Nazev dat','');
  TabBuf^[H.Folders].Nazev:=Vstup;
  Assign(FI,S);
  {$I-}Reset(FI,1);{$I+}ErrorMessage;
  If IORes=0 then
  begin
    WriteDownMessage('Kopiruje se...');
    Seek(FI,0);
    Seek(F,OfsTab);
    Size:=FileSize(FI);
    TabBuf^[H.Folders].StartOffset:=OfsTab;
    Repeat
      {$I-}
      BlockRead(FI,Buffer,SizeOf(Buffer),Nr);
      BlockWrite(F,Buffer,Nr,Nw);
      {$I+}
      Inc(Nwc,Nr);
      ErrorMessage;
      R:=(Nwc+1)/(Size+1) * 100;
      GotoXY(18,25);Write(R:2:0,'%     ');
    until (Nr<>SizeOf(Buffer))or(Nw<>Nr)or(IORes<>0);
    TabBuf^[H.Folders].EndOffset:=OfsTab+Size;{FilePos(F);}
    ClearDownMessage;
  end;

  Inc(H.Folders);
  H.SizeOfTab:=(H.Folders+1) * 20;
  Close(FI);

  OfsTab:=FilePos(F);
  {$I-}Seek(F,OfsHead);{$I+}ErrorMessage;
  {$I-}BlockWrite(F,H,H.HeaderLength,Nr);{$I+}ErrorMessage;

  {$I-}Seek(F,OfsTab);{$I+}ErrorMessage;
  {$I-}BlockWrite(F,TabBuf^,H.SizeOfTab);{$I+}ErrorMessage;
  {$I-}BlockWrite(F,OfsTab,4);{$I+}ErrorMessage;
  {$I-}BlockWrite(F,OfsHead,4);{$I+}ErrorMessage;
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



Begin
  If TabBuf=nil then New(TabBuf);
  InitStandardScreen('±',1,8,2);
  FileIn:='';
  Repeat
    FileIn:=ChooseFile('*.*');If Scan=1 then Konec;
    OpenFile(FileIn);
    If Attr2<>0 then
    begin
      GetScreen;
      OkMessage('Soubor nelze otevrit pro zapis !');
      SetScreen;
    end;
  until (IORes=0)and(Attr2=0);
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
  end
  else
  begin
    CreateNewHeader;
    OfsHead:=FileSize(F);
    OfsTab:=OfsHead+HeaderLength;
    TabBuf^[0].StartOffset:=OfsTab;
    TabBuf^[0].EndOffset:=OfsTab;
    H.HeaderLength:=HeaderLength;
    H.SizeOfTab:=0;
    H.Folders:=0;
    {$I-}Seek(F,OfsHead);{$I+}ErrorMessage;
    {$I-}BlockWrite(F,H,HeaderLength,Nr);{$I+}ErrorMessage;
    {$I-}BlockWrite(F,OfsTab,4);{$I+}ErrorMessage;
    {$I-}BlockWrite(F,OfsHead,4);{$I+}ErrorMessage;
  end;
  UpgradeHeader;
  {$I-}Seek(F,OfsHead);{$I+}ErrorMessage;
  {$I-}BlockWrite(F,H,HeaderLength,Nr);{$I+}ErrorMessage;
  If Nr<>HeaderLength then
  begin
    GetScreen;
    OkMessage('Chyba pri zapisu hlavicky !');
    SetScreen;
  end;
  IncludeFile;
  {$I-}Close(F);{$I+}ErrorMessage;

  Info;
  If TabBuf<>nil then Dispose(TabBuf);
end.


{ Open(F);
  Head:=TestSignature;
  If Head then
  begin
    Read(OfsTab); Read(TabToBuf);
  end else Create New Header;
  Copy DatFile to EXE; Inc(Folders);
  OfsTab:=FilePos(F):
  Upgrade(Header);
  Upgrade(TabToBuf);
  Seek(F,OfsHead); Write(Header);
  Seek(F,OfsTab); Write(HeadToTab);
  Write(OfsHead);
  Write(OfsTab);

  Close(F);
}