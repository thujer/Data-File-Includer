Program Data_Include;
{
MZ...
....
(Exe soubor)
....
HLAVICKA          Informace o datech          [OFFSET je na [-18]]
DATA_1            Ulozena data                [OFFSET je v tabulce dat]
DATA_2
.....
.....
TABULKA DAT       Seznam dat                  [OFFSET je na [-14]]
OFFS [Hlavicky]   Offset hlavicky             [-18]
OFFS [Tabulky]    Offset tabulky dat          [-14]



Hlavicka:
 Byty      Obsah            Delka[B]         Vysvetlivky

 0..7     INCLUDER           [8]               Signatura hlavicky
 8..10      1.3              [3]               Verze programu
 11..17    NUCLEAR           [7]               Inicialy autora
 18..21    1.1.1999          [4]               Datum posledni zmeny souboru
 22..25    1.1.1998          [4]               Datum posledni zmeny programu
 26..27      1000            [2]               Aktualni pocet dat. slozek
 28..29     65535            [2]               Max. pocet dat. slozek
 30..31        32            [2]               Delka hlavicky (v Bytech)



Tabulka dat:
           Nazev             OFFSET          Delka

           [11]               [4]             [4]

Napr.:   [EGAVGA.BGI ]       0BCDh            100h
         [LOGO.PCX   ]       A012h            212h

}

Uses Crt,Dos;
Var
  SCAN,ASCII:Byte;

Procedure GetKey;Assembler;
asm
  MOV AH,10h
  INT 16h
  MOV ASCII,AL
  MOV SCAN,AH
end;



Function ReadDataOffset(IncludeFile:String):LongInt;
Var
  F:File of Byte;
  Test: String[6];
  OfsTab,TestOfs:LongInt;
  B,I:Byte;
  W:Word;
begin
  Assign(F,IncludeFile);
  {$I-}Reset(F);{$I+}
  If IOResult<>0 then
  begin
    Writeln('Soubor ',IncludeFile,' nelze otevrit !');
  end;

  Seek(F,FileSize(F)-10);
  Test[0]:=#6;{Nacteni testovaciho retezce}
  For I:=1 to 6 do
  begin
    Read(F,B);Test[I]:=Chr(B);
    {INCLUD}
  end;

  Seek(F,FileSize(F)-4);
  TestOfs:=0;
  {Nacteni test. offsetu (Na nem ma byt stejna hodnota jako je tento offset)}
  {$I-}
  Read(F,B);Mem[Seg(TestOfs):Ofs(TestOfs)+0]:=B;
  Read(F,B);Mem[Seg(TestOfs):Ofs(TestOfs)+1]:=B;
  Read(F,B);Mem[Seg(TestOfs):Ofs(TestOfs)+2]:=B;
  Read(F,B);Mem[Seg(TestOfs):Ofs(TestOfs)+3]:=B;
  {$I+}
  If IOResult<>0 then
  begin
    Writeln('Chyba pri cteni tabulky dat !');
    Halt(1);
  end;

  If (TestOfs>FileSize(F))or(TestOfs<0) then
  begin{Kontrola rozsahu offsetu}
    Writeln('Tabulka dat chybi nebo je poskozena !');
    Close(F);
    Halt(1);
  end;

  If TestOfs<>FileSize(F)-4 then
  begin{Kontrola testovaciho offsetu}
    Writeln('Neplatny testovaci OFFSET !');
    Close(F);
    Halt(1);
  end;

  If Test<>'INCLUD' then
  begin{Kontrola identifikacniho retezce}
    Writeln('Neplatny testovaci RETEZEC !');
    Halt(1);
  end;

  OfsTab:=0;
  Seek(F,FileSize(F)-14);{Nacteni offsetu zacatku tabulky}
  Read(F,Mem[Seg(OfsTab):Ofs(OfsTab)+0]);
  Read(F,Mem[Seg(OfsTab):Ofs(OfsTab)+1]);
  Read(F,Mem[Seg(OfsTab):Ofs(OfsTab)+2]);
  Read(F,Mem[Seg(OfsTab):Ofs(OfsTab)+3]);
end;


Procedure WriteDataOffset(IncludeTo:String);
Var
  F:File of Byte;
  Test: String[6];
  OfsTab,TestOfs,L:LongInt;
  B,I:Byte;

begin
  Assign(F,IncludeTo);
  {$I-}Reset(F);{$I+}
  If IOResult<>0 then
  begin
    Writeln('Soubor ',IncludeTo,' nelze otevrit !');
  end;
  OfsTab:=FileSize(F);

  Seek(F,FileSize(F)-10);
  Test[0]:=#6;{Nacteni testovaciho retezce}
  For I:=1 to 6 do
  begin
    Read(F,B);Test[I]:=Chr(B);
    {INCLUD}
  end;

  Seek(F,FileSize(F)-4);
  TestOfs:=0;
  {Nacteni test. offsetu (Na nem ma byt stejna hodnota jako je tento offset)}
  {$I-}
  Read(F,B);Mem[Seg(TestOfs):Ofs(TestOfs)+0]:=B;
  Read(F,B);Mem[Seg(TestOfs):Ofs(TestOfs)+1]:=B;
  Read(F,B);Mem[Seg(TestOfs):Ofs(TestOfs)+2]:=B;
  Read(F,B);Mem[Seg(TestOfs):Ofs(TestOfs)+3]:=B;
  {$I+}
  If IOResult<>0 then
  begin
    Writeln('Chyba pri cteni tabulky dat !');
    Halt(1);
  end;

  OfsTab:=0;
  Seek(F,FileSize(F));
end;

Begin
end.