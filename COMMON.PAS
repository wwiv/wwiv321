{$I-,R-,S-,V-,B+,N-}

Unit Common;

                      {*****************************}
                      {Copyright (c) 1986 Wayne Bell}
                      {*****************************}

Interface

Uses Crt,Dos;

type
  astr = String[160];  { generic string type for parameters      }
                       { note the change from Waynes str => Astr }
const
  buffer_max = 5120;

var
  Async_OriginalVector : pointer;
  buffer       : Array[0..buffer_max] of char;

  Async_Open_Flag    : Boolean;   { true if Open but no Close }
  Async_Port         : Integer;   { current Open port number (1 or 2) }
  base               : Integer;   { base for current open port }
  Async_Irq          : Integer;   { irq for current open port }

  Async_Buffer_Overflow : Boolean;  { True if buffer overflow has happened }
  Async_Buffer_Used     : Integer;
  Async_MaxBufferUsed   : Integer;

                 { buffer is empty if Head = Tail }
  Buffer_head  : Integer;   { Locn in buffer to put next char }
  Buffer_tail  : Integer;   { Locn in buffer to get next char }
  Buffer_newtail : Integer;

CONST strlen=160;
      maxusers=100;
      comptyp:array[1..8] of string[14]=
        ('IBM           ','Apple         ','TRS-80        ','Z-80 CP/M     ',
         'Commodore     ','Atari         ','Dumb Terminal ','Other         ');

TYPE
     restrictions=(rlogon,rchat,rvalidate,rbackspace,ramsg,rpostan,
                   rpost,remail,rvoting,rmsg);
     acrq='@'..'G';
     newtyp=(rp,lt,rm);
     deflts=(spcsr,onekey,wordwrap,pause,mmnu,ansi,color,music);
     pnr=record name:string[40]; number:string[14]; hs:byte; end;
     anontyp=(no,yes,forced,dearabby);
     ansttype=(postn,emailn,pana,sanm,cosysop,lcosysop);
     opts=(alert,smw,nomail);
     dlnscan=set of 0..39;
     emary=array[1..20] of integer;
     clrs=array[false..true,1..8] of byte;
     slr=record
           ttime:byte;
           mallowed:integer;
           emails,posts:byte;
           anst:set of ansttype;
         end;
     messages=record
                ltr:char;
                number:integer;
                ext:byte;
              end;
     smalrec=record
               name:string[25];
               number:integer;
             end;
     userrec=record
               name:string[25];
               realname:string[14];
               deleted:boolean;
               pw:string[8];
               ph:string[12];
               waiting:byte;
               laston:string[10];
               loggedon:integer;
               msgpost:integer;
               emailsent:integer;
               feedback:integer;
               linelen:byte;
               pagelen:byte;
               defaults:set of deflts;
               ontoday:byte;
               illegal:byte;
               ttimeon:real;
               dlnscn:dlnscan;
               sl:byte;
               ac:set of restrictions;
               ar:set of acrq;
               qscan:array[1..19] of messages;
               qscn:array[1..19] of boolean;
               macro:array[1..2] of string[79];
               comptype:byte;
               option:set of opts;
               vote:array[1..9] of byte;
               sbn:byte;
               dsl:byte;
               uploads,downloads:integer;
               uk,dk:integer;
               age:byte;
               sex:char;
               note:string[39];
               forusr:integer;
               cols:clrs;
               res:array[1..72] of byte;
             end;
      boardrec=record
                 name:string[30];
                 filename:string[12];
                 sl:byte;
                 maxmsgs:byte;
                 pw:string[10];
                 anonymous:anontyp;
                 ar:acrq;
                 key:char;
                 postsl:byte;
               end;
      msgstat=(validated,unvalidated,deleted);
      messagerec=record
                   title:string[60];
                   messagestat:msgstat;
                   message:messages;
                   owner:integer;
                   date:integer;
                   mage:byte;
                 end;
      systatrec=record
                  boardpw:string[8];
                  sysoppw:string[8];
                  hmsg:messages;
                  users:integer;
                  lastdate:string[8];
                  callernum:integer;
                  activetoday:integer;
                  callstoday:integer;
                  msgposttoday:integer;
                  emailtoday:integer;
                  fbacktoday:integer;
                  uptoday:integer;
                  closedsystem:boolean;
                  comport:byte;
                  maxbaud:integer;
                  dloadpath:string[79];
                  gfiledate:string[8];
                  lowtime,hitime:integer;
                  res:array[1..200] of byte;
                end;
      blk=array[1..255] of byte;
      mailrec=record
                title:string[60];
                from,destin:integer;
                msg:messages;
                date:integer;
                mage:byte;
              end;
      gft=record
            num:integer;
            title:string[40];
            filen:string[12];
          end;
      smr=record
            msg:astr;
            destin:integer;
          end;
      vdatar=record
               question:string[79];
               numa:integer;
               answ:array[0..9] of record
                      ans:string[25];
                      numres:integer;
                    end;
             end;
      ulrec=record
              name:string[25];
              filename:string[12];
              password:string[10];
              dsl:byte;
              maxfiles:integer;
            end;
      ulfrec=record
               filename:string[12];
               description:string[60];
               res:array[1..17] of byte;
               nacc:integer;
               ft:byte;
               blocks:integer;
               owner:integer;
               date:string[8];
               daten:integer;
             end;
      strptr=^strrec;
      strrec=record
               i:astr;
               next,last:strptr;
             end;
      zlogt=record
              date:string[8];
              active,calls,post,email,fback,up:integer;
            end;
      Str255=String[255];
      Str66=String[66];

CONST dcols:clrs=((7,7,15,15,15,112,15,143),(7,7,11,14,5,31,2,140));

var sf:file of smalrec;
    uf:file of userrec;
    bf:file of boardrec;
    mailfile:file of mailrec;
    ulf:file of ulrec;
    uboards:array[0..19] of ulrec;
    maxulb:integer;
    helpl:char;
    helpi:array['0'..'~'] of integer;
    ihelp,nofile:boolean;
    sysopf:text{[1024]};
    slf:file of slr;
    seclev:array[0..255] of slr;
    systatf:file of systatrec;
    systat:systatrec;
    sr:smalrec;
    thisline,chatr,buf,spd,irt,lastname,ll,i:astr;
    thisuser,user:userrec;
    boards:array[1..19] of boardrec;
    fw,extramsgs,mread,board,numboards,t,usernum:integer;
    pap,lil,realsl,ftoday,ptoday,etoday:integer;
    c,ID:char;
    hungup,useron,next,chatcall,doneday,echo,hangup,incom,outcom:boolean;
    extratime,chattime,timeon:real;
    mailread,smread,macok,lan,enddayf,ch,quit,beepend:boolean;
    smf:file of smr;
    srl:array[0..maxusers] of smalrec;
    vqu:array[1..9] of boolean;
    ldate:integer;
    cmd:char;
    bread:byte;
    bchanged:boolean;
    mary:array[0..200] of messagerec;
    cf:text; cfo,okt:boolean;
    elevel:byte;
    curco:byte;
    sll:astr;
    andwith:byte;
    checkit,comd:boolean;

function freek(d:integer):integer;
function cs:boolean;
function so:boolean;
function lcs:boolean;
function nma:integer;
function okansi:boolean;
function commpressed : boolean;
procedure dump;
procedure remove_port;
procedure term_ready(s:Boolean);
procedure set_baud(r:integer);
procedure iport;
function cinkey1:char;
function cinkey:char;
procedure o1(c:char);
procedure o(c:char);
function timer:real;
function nsl:real;
function sysop1:boolean;
function sysop:boolean;
procedure sl1(i:astr);
procedure sysoplog(i:astr);
function tch(i:astr):astr;
function time:astr;
function date:astr;
function value(I:astr):integer;
function cstr(i:integer):astr;
function nam:astr;
function leapyear(yr:integer):boolean;
function days(mo,yr:integer):integer;
function daycount(mo,yr:integer):integer;
function daynum(dt:astr):integer;
function dat:astr;
function cdet:boolean;
procedure checkhangup;
procedure getkey(var c:char);
procedure pr1(i:astr);
procedure pr(i:astr);
procedure sdc;
procedure stsc;
function xclr(c:integer):astr;
procedure setc(cl:byte);
procedure ansic(c:integer);
procedure prompt(i:astr);
procedure pausescr;
procedure print(i:astr);
procedure nl;
procedure prt(i:astr);
procedure ynq(i:astr);
procedure mpl(c:integer);
procedure tleft;
procedure prestrict(u:userrec);
procedure ff(i:integer);
procedure topscr;
function empty:boolean;
procedure skey1(var c:char);
function inkey:char;
procedure oc(c:char);
procedure outkey(c:char);
procedure ptime;
procedure skey(var c:char);
procedure dm(i:astr; var c:char);
procedure cls;
procedure wait(b:boolean);
procedure chsl;
procedure swac(var u:userrec;r:restrictions);
procedure acch(c:char; var u:userrec);
procedure chac(var thisuser:userrec);
procedure chbac;
procedure chdsl;
procedure tfile;
procedure inli1(var i:astr);
procedure chat;
function yn:boolean;
procedure input1(var i:astr; ml:integer; tf:boolean);
procedure input(var i:astr; ml:integer);
procedure inputl(var i:astr; ml:integer);
procedure onek(var c:char; ch:astr);
procedure onek2(var c:char; ch:astr); {Added because I use a Modified}
procedure centre(var i:astr);
procedure wkey(var abort,next:boolean);
procedure printa1(i:astr; var abort,next:boolean);
procedure printa(i:astr; var abort,next:boolean);
procedure printacr(i:astr; var abort,next:boolean);
function ctim(rl:real):astr;
function tlef:astr;
function cstrr(rl:real; base:integer):astr;
procedure savesystat;
procedure pfl(fn:astr; var abort:boolean; cr:boolean);
procedure printfile(fn:astr);
Procedure Print_File (fn:astr);  {Another Addiitional Mod}
procedure printf(fn:astr);
procedure Async_Init;
procedure Async_Close;
function Async_Open(ComPort:Integer; BaudRate:Integer;Parity:Char;
                    WordSize:Integer; StopBits:Integer):Boolean;

IMPLEMENTATION

const
  UART_THR = $00;    { offset from base of UART Registers for IBM PC }
  UART_RBR = $00;
  UART_IER = $01;
  UART_IIR = $02;
  UART_LCR = $03;
  UART_MCR = $04;
  UART_LSR = $05;
  UART_MSR = $06;
  I8088_IMR = $21;   { port address of the Interrupt Mask Register }

var
  Async_BIOS_Port_Table : Array[1..2] of Integer absolute $40:0;
               { This table is initialized by BIOS equipment determination
                 code at boot time to contain the base addresses for the
                 installed async adapters.  A value of 0 means "not in-
                 stalled." }

const
  Async_Num_Bauds = 8;
  Async_Baud_Table : array [1..Async_Num_Bauds] of record
                                                     Baud, Bits : integer
                                                   end
                   = ((Baud:110;  Bits:$00),
                      (Baud:150;  Bits:$20),
                      (Baud:300;  Bits:$40),
                      (Baud:600;  Bits:$60),
                      (Baud:1200; Bits:$80),
                      (Baud:2400; Bits:$A0),
                      (Baud:4800; Bits:$C0),
                      (Baud:9600; Bits:$E0));

PROCEDURE DisableInterrupts; inline($FA {cli} );     {MACROS}
PROCEDURE EnableInterrupts;  inline($FB {sti} );

procedure BIOS_RS232_Init(ComPort, ComParm : Integer);
{ Issue Interrupt $14 to initialize the UART }
{ See the IBM PC Technical Reference Manual for the format of ComParm }
var
  Regs : registers;
begin
  with Regs do
    begin
      ax := ComParm and $00FF;  { AH=0; AL=ComParm }
      dx := ComPort;
      Intr($14, Regs)
    end
end; { BIOS_RS232_Init }

procedure Async_Isr;  INTERRUPT;
{ Interrupt Service Routine }
{ Invoked when the UART has received a byte of data from the
  communication line }
{ re-written 9/10/84 to be entirely in machine language; original source
  left as comments }
begin
  Inline(
    $FB/                           { STI }
      { get the incomming character }
      { buffer[Buffer_head] := Chr(Port[UART_RBR + base]); }
    $8B/$16/base/                  { MOV DX,base }
    $EC/                           { IN AL,DX }
    $8B/$1E/Buffer_head/           { MOV BX,Buffer_head }
    $88/$87/buffer/                { MOV buffer[BX],AL }
      { Async_Buffer_NewHead := Buffer_head + 1; }
    $43/                           { INC BX }
      { if Async_Buffer_NewHead > buffer_max then
          Async_Buffer_NewHead := 0; }
    $81/$FB/buffer_max/            { CMP BX,buffer_max }
    $7E/$02/                       { JLE L001 }
    $33/$DB/                       { XOR BX,BX }
      { if Async_Buffer_NewHead = Buffer_tail then
          Async_Buffer_Overflow := TRUE
        else }
{L001:}
    $3B/$1E/Buffer_tail/     { CMP BX,Buffer_tail }
    $75/$08/                       { JNE L002 }
    $C6/$06/Async_Buffer_Overflow/$01/ { MOV Async_Buffer_Overflow,1 }
    $90/                           { NOP generated by assembler for some reason }
    $EB/$16/                       { JMP SHORT L003 }
      { begin
          Buffer_head := Async_Buffer_NewHead;
          Async_Buffer_Used := Async_Buffer_Used + 1;
          if Async_Buffer_Used > Async_MaxBufferUsed then
            Async_MaxBufferUsed := Async_Buffer_Used
        end; }
{L002:}
    $89/$1E/Buffer_head/           { MOV Buffer_head,BX }
    $FF/$06/Async_Buffer_Used/     { INC Async_Buffer_Used }
    $8B/$1E/Async_Buffer_Used/     { MOV BX,Async_Buffer_Used }
    $3B/$1E/Async_MaxBufferUsed/   { CMP BX,Async_MaxBufferUsed }
    $7E/$04/                       { JLE L003 }
    $89/$1E/Async_MaxBufferUsed/   { MOV Async_MaxBufferUsed,BX }
{L003:}
      { disable interrupts }
    $FA/                           { CLI }
      { Port[$20] := $20; }        { use non-specific EOI }
    $B0/$20/                       { MOV AL,20h }
    $E6/$20                        { OUT 20h,AL }
       )
end; { Async_Isr }

procedure Async_Init;
{ initialize variables }
begin
  Async_Open_Flag := FALSE;
  Async_Buffer_Overflow := FALSE;
  Async_Buffer_Used := 0;
  Async_MaxBufferUsed := 0;
end; { Async_Init }

procedure Async_Close;
{ reset the interrupt system when UART interrupts no longer needed }
var
  i, m : Integer;
begin
  if Async_Open_Flag then
    begin

      { disable the IRQ on the 8259 }
      DisableInterrupts;
      i := Port[I8088_IMR];        { get the interrupt mask register }
      m := 1 shl Async_Irq;        { set mask to turn off interrupt }
      Port[I8088_IMR] := i or m;

      { disable the 8250 data ready interrupt }
      Port[UART_IER + base] := 0;

      { disable OUT2 on the 8250 }
      Port[UART_MCR + base] := 0;
      EnableInterrupts;

      SetIntVec(Async_Irq + 8,Async_OriginalVector);

      { re-initialize our data areas so we know the port is closed }
      Async_Open_Flag := FALSE

    end
end; { Async_Close }

function Async_Open(ComPort       : Integer;
                    BaudRate      : Integer;
                    Parity        : Char;
                    WordSize      : Integer;
                    StopBits      : Integer) : Boolean;
{ open a communications port }
var
  ComParm : Integer;
  i, m : Integer;
begin
  if Async_Open_Flag then Async_Close;

  if (ComPort = 2) and (Async_BIOS_Port_Table[2] <> 0) then
    Async_Port := 2
  else
    Async_Port := 1;  { default to COM1 }
  base := Async_BIOS_Port_Table[Async_Port];
  Async_Irq := Hi(base) + 1;

  if (Port[UART_IIR + base] and $00F8) <> 0 then
    Async_Open := FALSE
  else
    begin
      Buffer_head := 0;
      Buffer_tail := 0;
      Async_Buffer_Overflow := FALSE;

  { Build the ComParm for RS232_Init }
  { See Technical Reference Manual for description }

      ComParm := $0000;

  { Set up the bits for the baud rate }
      i := 0;
      repeat
        i := i + 1
      until (Async_Baud_Table[i].Baud = BaudRate) or (i = Async_Num_Bauds);
      ComParm := ComParm or Async_Baud_Table[i].Bits;

      if Parity in ['E', 'e'] then ComParm := ComParm or $0018
      else if Parity in ['O', 'o'] then ComParm := ComParm or $0008
      else ComParm := ComParm or $0000;  { default to No parity }

      if WordSize = 7 then ComParm := ComParm or $0002
      else ComParm := ComParm or $0003;  { default to 8 data bits }

      if StopBits = 2 then ComParm := ComParm or $0004
      else ComParm := ComParm or $0000;  { default to 1 stop bit }

  { use the BIOS COM port initialization routine to save typing the code }
      BIOS_RS232_Init(Async_Port - 1, ComParm);

      GetIntVec(Async_Irq + 8, Async_OriginalVector);
      SetIntVec(Async_Irq + 8, @Async_Isr);

  { read the RBR and reset any possible pending error conditions }
  { first turn off the Divisor Access Latch Bit to allow access to RBR, etc. }

      DisableInterrupts;

      Port[UART_LCR + base] := Port[UART_LCR + base] and $7F;
  { read the Line Status Register to reset any errors it indicates }
      i := Port[UART_LSR + base];
  { read the Receiver Buffer Register in case it contains a character }
      i := Port[UART_RBR + base];

  { enable the irq on the 8259 controller }
      i := Port[I8088_IMR];  { get the interrupt mask register }
      m := (1 shl Async_Irq) xor $00FF;
      Port[I8088_IMR] := i and m;

  { enable the data ready interrupt on the 8250 }
      Port[UART_IER + base] := $01; { enable data ready interrupt }

  { enable OUT2 on 8250 }
      i := Port[UART_MCR + base];
      Port[UART_MCR + base] := i or $08;

      EnableInterrupts;
      Async_Open_Flag := TRUE;  { bug fix by Scott Herr }
      Async_Open := TRUE
    end
end; { Async_Open }

{End of Async Routines}

function freek(d:integer):integer;
var r:registers;
begin
  r.ax:=$3600;
  r.dx:=d;
  msdos(r);
  freek:=trunc(1.0*r.bx*r.ax*r.cx/1024.0);
end;

function cs:boolean;
begin
  cs:=cosysop in seclev[thisuser.sl].anst;
end;

function so:boolean;
begin
  so:=thisuser.sl=255;
end;

function lcs:boolean;
begin
  lcs:=cs or ((lcosysop in seclev[thisuser.sl].anst) and ((board=thisuser.sbn) or (thisuser.sbn=0)));
end;

function nma:integer;
begin
  nma:=seclev[thisuser.sl].ttime;
end;

function okansi:boolean;
begin
  okansi:=ansi in thisuser.defaults;
end;

function commpressed : boolean;
begin
 commpressed := (buffer_tail<>buffer_head);
end;

procedure dump;
Begin
  disableinterrupts;  {Replaces the old inline $FA}
  buffer_head:=0;
  buffer_tail:=buffer_head;
  enableinterrupts;   {Replaces the old inline $FB}
end;

procedure remove_port;
{This routes all WWIV 3 calls to the new Close Port routine}
Begin
  Async_Close;
end;

procedure term_ready(s:Boolean);
var x:byte;
begin
  x := port[4+base] and $FE;
  if s then x:=x+1;
  port[4+base] := x;
end;

procedure set_baud(r:integer);
var rl:real; a:byte;
begin
  if (r>=300) and (r<=9600) then begin
    rl:=115200.0/r;
    r:=trunc(rl);
    a:=port[3+base] or 128;
    port[base+3]:=a;
    port[base]:=lo(r);
    port[1+base]:=hi(r);
    port[3+base]:=a and 127;
  end;
end;

procedure iport;
{This routes all WWIV 3 calls to the new Intialize Port routine}
Begin
  Async_init;
  Write(Async_open(1,2400,'N',8,1));
end;

function cinkey1:char;
var t:char;
begin
  if buffer_Head = buffer_Tail Then
    t:=#0
  else begin
    disableinterrupts;
    t:=buffer[buffer_Tail];
    buffer_Tail:=(buffer_Tail+1) mod (buffer_max+1);
    enableinterrupts;
  end;
  cinkey1:=t;
end;

function cinkey:char;
var t:char;
begin
  t:=cinkey1;
  cinkey:=chr(ord(t) and andwith);
end;

procedure o1(c:char);
begin
  while (port[base+5] and 32)=0 do;
  port[base]:=ord(c);
end;

procedure o(c:char);
begin
  if outcom and (c<>#1) then
    o1(c);
end;

function timer:real;
var reg:registers;
    h,m,s,t:real;
begin
  reg.ax:=44*256;
  msdos(Dos.Registers(reg));
  h:=(reg.cx div 256);
  m:=(reg.cx mod 256);
  s:=(reg.dx div 256);
  t:=(reg.dx mod 256);
  timer:=h*3600+m*60+s+t/100;
end;

function nsl:real;
begin
  nsl:=(nma*60.0+extratime+chattime+timeon-timer);
end;

function sysop1:boolean;
begin
  if (mem[0:1047] and 16)=0 then sysop1:=false else sysop1:=true;
end;

function sysop:boolean;
begin
  sysop:=sysop1;
  if rchat in thisuser.ac then sysop:=false;
  if systat.lowtime<>systat.hitime then begin
    if systat.hitime>systat.lowtime then begin
      if (timer<=(systat.lowtime*60.0)) or (timer>=(systat.hitime*60.0))
        then sysop:=false;
    end else begin
      if (timer<=(systat.lowtime*60.0)) and (timer>=(systat.hitime*60.0))
        then sysop:=false;
    end;
  end;
end;

procedure sl1(i:astr);
begin
  writeln(sysopf,i);
end;

procedure sysoplog(i:astr);
begin
  if (realsl<>255) or incom then
    sl1('   '+i);
end;

function tch(i:astr):astr;
begin
  if length(i)>2 then i:=copy(i,length(i)-1,2) else
    if length(i)=1 then i:='0'+i;
  tch:=i;
end;

function time:astr;
var reg:registers;
    h,m,s:string[4];
begin
  reg.ax:=$2c00; intr($21,Dos.Registers(reg));
  str(reg.cx shr 8,h); str(reg.cx mod 256,m); str(reg.dx shr 8,s);
  time:=tch(h)+':'+tch(m)+':'+tch(s);
end;

function date:astr;
var reg:registers;
    m,d,y:string[4];
begin
  reg.ax:=$2a00; msdos(Dos.Registers(reg)); str(reg.cx,y); str(reg.dx mod 256,d);
  str(reg.dx shr 8,m);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
end;

function value(I:astr):integer;
var n,n1:integer;
begin
  val(i,n,n1);
  if n1<>0 then begin
    i:=copy(i,1,n1-1);
    val(i,n,n1)
  end;
  value:=n;
  if i='' then value:=0;
end;

function cstr(i:integer):astr;
var c:astr;
begin
  str(i,c); cstr:=c;
end;

function nam:astr;
var s:astr; i:integer; tf:boolean;
begin
  s:=thisuser.name;
  tf:=true;
  for i:=1 to length(s) do
    if s[i]<'A' then
      tf:=true
    else begin
      if (s[i]<='Z') and not tf then
        s[i]:=chr(ord(s[i])+32);
      tf:=false;
    end;
  nam:=s+' #'+cstr(usernum);
end;

function leapyear(yr:integer):boolean;
begin
  leapyear:=(yr mod 4=0) and ((yr mod 100<>0) or (yr mod 400=0));
end;

function days(mo,yr:integer):integer;
var d:integer;
begin
  d:=value(copy('312831303130313130313031',1+(mo-1)*2,2));
  if (mo=2) and leapyear(yr) then d:=d+1;
  days:=d;
end;

function daycount(mo,yr:integer):integer;
var m,t:integer;
begin
  t:=0;
  for m:=1 to (mo-1) do t:=t+days(m,yr);
  daycount:=t;
end;

function daynum(dt:astr):integer;
var d,m,y,t,c:integer;
begin
  t:=0;
  m:=value(copy(dt,1,2));
  d:=value(copy(dt,4,2));
  y:=value(copy(dt,7,2))+1900;
  for c:=1985 to y-1 do
    if leapyear(c) then t:=t+366 else t:=t+365;
  t:=t+daycount(m,y)+(d-1);
  daynum:=t;
  if y<1985 then daynum:=0;
end;

function dat:astr;
var ap,x,y:astr; i:integer;
begin
  case daynum(date) mod 7 of
    0:x:='Tue';
    1:x:='Wed';
    2:x:='Thu';
    3:x:='Fri';
    4:x:='Sat';
    5:x:='Sun';
    6:x:='Mon';
  end;
  case value(copy(date,1,2)) of
    1:y:='Jan';
    2:y:='Feb';
    3:y:='Mar';
    4:y:='Apr';
    5:y:='May';
    6:y:='Jun';
    7:y:='Jul';
    8:y:='Aug';
    9:y:='Sep';
    10:y:='Oct';
    11:y:='Nov';
    12:y:='Dec';
  end;
  x:=x+' '+y+' '+copy(date,4,2)+', '+cstr(1900+value(copy(date,7,2)));
  y:=time; i:=value(copy(y,1,2));
  if i>11 then ap:='pm' else ap:='am';
  if i>12 then i:=i-12;
  if i=0 then i:=12;
  dat:=cstr(i)+copy(y,3,3)+' '+ap+'  '+x;
end;

function cdet:boolean;
begin
  cdet:=(port[base+6] and 128)<>0;
end;

procedure checkhangup;
begin
  if outcom and not cdet and (not hangup) then begin
    hangup:=true; hungup:=true;
  end;
end;

procedure ptime;
var i:astr;
begin
  if useron then begin
    i:=thisline;
    nl; nl; print(dat);
    print('Time left: '+tlef);
    print('Time on  : '+ctim(timer-timeon));
    nl; prompt(i);
  end;
end;

procedure skey(var c:char);
begin
  case ord(c) of
      6:if macok and (buf='') then dm(thisuser.macro[2],c);
      4:if macok and (buf='') then dm(thisuser.macro[1],c);
     20:ptime;
    127:c:=#8;
   end;
end;

procedure getkey(var c:char);
var t:real; b,tf,t1:boolean;
begin
  lil:=0;
  if buf<>'' then begin
    c:=buf[1]; buf:=copy(buf,2,length(buf)-1);
  end else
    if not empty then c:=inkey
    else begin
      t:=timer; t1:=false; tf:=false;
      c:=#0;
      while (c=#0) and not hangup do begin
        c:=inkey;
        if ((timer-t)>180) and (c=#0) then begin nl;
          print('Call back later when you are there.');hangup:=true;
          sysoplog('!-! Timeout !-!');
        end;
        if ((timer-t)>90) and (not tf) and (c=#0) then begin tf:=true; outkey(chr(7)); end;
        checkhangup;
      end;
    end;
    if checkit then
      if (ord(c) and 128)>0 then begin
        checkit:=false;
        andwith:=127;
        c:=chr(ord(c) and andwith);
      end;
  skey(c);
end;

procedure pr1(i:astr);
var c:integer;
begin
  for c:=1 to length(i) do o1(i[c]);
end;

procedure pr(i:astr);
begin
  pr1(i+#13);
end;

procedure sdc;
var f:integer;
begin
  f:=curco and 7;
  if (curco and 8)<>0 then f:=f+8;
  if (curco and 128)<>0 then f:=f+16;
  textcolor(f);
  textbackground((curco shr 4) and 7);
end;

procedure stsc;
begin
  textcolor(14); textbackground(0);
end;

function xclr(c:integer):astr;
begin
  case c of
    0:xclr:='0';
    1:xclr:='4';
    2:xclr:='2';
    3:xclr:='6';
    4:xclr:='1';
    5:xclr:='5';
    6:xclr:='3';
    7:xclr:='7';
  end;
end;

procedure setc(cl:byte);
var i:astr;
  procedure adto(ii:astr);
  begin
    if (i[length(i)]<>';') and (i[length(i)]<>'[') then i:=i+';';
    i:=i+ii;
  end;
begin
  if cl<>curco then begin
    if ((curco and (not cl)) and $88)<>0 then begin
      i:=#27+'[0';
      curco:=$07;
    end else i:=#27+'[';
    if (cl and 7)<>(curco and 7) then adto('3'+xclr(cl and 7));
    if (cl and $70)<>(curco and $70) then adto('4'+xclr((cl shr 4) and 7));
    if (cl and 128)<>0 then adto('5');
    if (cl and 8)<>0 then adto('1');
    i:=i+'m';
    curco:=cl;
    if okansi and outcom then pr1(i);
    sdc;
  end;
end;

procedure ansic(c:integer);
begin
  if c=0 then c:=1;
  if okansi then
    if color in thisuser.defaults then
      setc(thisuser.cols[true,c])
    else
      setc(thisuser.cols[false,c]);
end;

procedure prompt(i:astr);
var c:integer; cc:char;
begin
 checkhangup;
 if not hangup then begin
  for c:=1 to length(i) do begin
    if i[c]=#10 then
      if okansi then
        if (curco<>thisuser.cols[color in thisuser.defaults,1]) then
          ansic(0);
    if (not ((i[c]=chr(7)) and (incom))) and (i[c]<>chr(12)) and (i<>#1) then write(i[c]);
    o(i[c]);
    if i[c]>#31 then thisline:=thisline+i[c];
    if i[c]=#8 then if length(thisline)>0 then thisline:=copy(thisline,1,length(thisline)-1);
    if i[c]=chr(12) then begin lil:=0; clrscr; end;
    if i[c]=chr(13) then begin pap:=0; thisline:=''; end;
    if i[c]=chr(10) then begin
      lil:=lil+1;
      if (lil>=thisuser.pagelen-1) then begin
        lil:=0;
        if pause in thisuser.defaults then pausescr;
      end;
    end;
  end;
 end;
end;

procedure pausescr;
var i:integer; cc:char;
begin
  ansic(5); prompt('(-More-)'); ansic(0);
  getkey(cc);
  for i:=1 to 8 do
    prompt(#8+' '+#8);
end;

procedure print(i:astr);
begin
  prompt(i+chr(13)+chr(10))
end;

procedure nl;
begin
  prompt(chr(13)+chr(10))
end;

procedure prt(i:astr);
begin
  ansic(4); prompt(i); ansic(0);
end;

procedure ynq(i:astr);
begin
  ansic(7); prompt(i);
end;

procedure mpl(c:integer);
var n:integer; i:astr;
begin
 if okansi then begin
  ansic(6);
  i:='';
  for n:=1 to c do i:=i+' ';
  n:=wherex;
  prompt(i);
  gotoxy(n,wherey);
  if outcom then
    pr1(#27+'['+cstr(c)+'D');
 end;
 thisline:=copy(thisline,1,length(thisline)-c);
end;

procedure tleft;
var x,y:integer;
begin
 if okt then begin
  stsc;
  x:=wherex; y:=wherey; window(1,1,80,4);
  gotoxy(72,3);if chatcall then begin
    write('CHAT ON');
    if alert in thisuser.option then begin
      gotoxy(72,3);
      write('ALERT  ');
    end;
  end else write('       ');
  gotoxy(56,3); if sysop1 then write('Sysop Available') else
    write('----- ---------');
  if useron then begin
    gotoxy(35,3); if thisuser.ontoday<>1 then write('ML=',extramsgs+seclev[thisuser.sl].mallowed-mread,'   ');
    gotoxy(45,3); write('TL=',(nsl/60):7:2,' ');
  end;
  if hangup then begin
    gotoxy(72,3);
    write('HANG UP');
  end;
  gotoxy(74,1);
  if beepend then write('(-*-)') else write('     ');
  window(1,5,80,25);gotoxy(x,y);
  if timer<timeon then timeon:=timeon-24.0*60*60;
  if not ch and (nsl<0) and useron then
  begin nl; print('Time expired.'); hangup:=true; end;
  checkhangup;
  sdc;
 end;
end;

procedure prestrict(u:userrec);
var r:restrictions;
begin
  for r:=rlogon to rmsg do
    if r in u.ac then write(copy('LCVBA*PEKM',ORD(R)+1,1)) else write(' ');
  writeln;
end;

procedure ff(i:integer);
begin
  while wherex<i do write(' ');
end;

procedure topscr;
var c:char; x,y,i:integer;
begin
 if (usernum<>0) and okt then begin
  stsc;
  x:=wherex; y:=wherey;
  window(1,1,80,5);
  for i:=1 to 4 do
   begin
    gotoxy(1,i);
    clreol;
   End;
  gotoxy(1,1);
  write(chr(186),' ',nam); ff(35);
  with thisuser do begin
    write(realname);ff(50);write(ph);ff(65);
    if laston<>date then write(laston) else write(ontoday,'       ');
    ff(79); write(' ',chr(186));gotoxy(1,2);
    write(chr(186),' SL=',sl);ff(10);write('AR=');
    for c:='A' to 'G' do if c in ar then write(c) else write(' ');
    write(' LO=',loggedon);
    ff(28);write('P=',msgpost);ff(35);write('E=',emailsent);
    ff(42);write('F=',feedback);ff(48);
    write('W=',waiting);ff(53);
    if not useron then write('"',pw,'"') else write('SC=',thisuser.linelen,'X',
      thisuser.pagelen,' ',thisuser.sex,' ',thisuser.age);
    ff(68);write('FW=',fw); ff(74); write('D=',thisuser.dsl);
    gotoxy(80,2);write(#186);
    gotoxy(1,3);write(#186,' AC='); prestrict(thisuser);
    gotoxy(17,3);write('C=',comptyp[thisuser.comptype]);
    gotoxy(80,3);write(chr(186));
    gotoxy(1,4);write(chr(200));
    for i:=2 to 79 do
      write(chr(205));
    write(chr(188));
  end;
  window(1,5,80,25);
  gotoxy(x,y);
  tleft;
  sdc;
 end;
end;

function empty:boolean;
begin
  if incom then empty:=not commpressed else empty:=true;
  if keypressed then empty:=false;
  if hangup then begin dump; empty:=true; end;
end;

procedure skey1(var c:char);
var b:boolean;
begin
  case ord(c) of
    59:chsl;
    60:chac(thisuser);
    61:begin
         if outcom then incom:=not incom;
         writeln; if incom then writeln('<INPUT ENABLED>')
           else writeln('<COM DISABLED>');
         writeln;dump;
         write(thisline);
       end;
    62:begin chatcall:=false; thisuser.option:=thisuser.option-[alert]; end;
    63:hangup:=true;
    64:tleft;
    65:begin b:=ch; ch:=true; extratime:=extratime-5*60; tleft; ch:=b;end;
    66:begin b:=ch; ch:=true; extratime:=extratime+5*60; tleft; ch:=b;end;
    67:begin
          if thisuser.sl=255 then if realsl<>255 then begin
            thisuser.sl:=realsl; writeln;writeln;writeln('<SECLEV RESTORED>');
            writeln; write(thisline); end
          else else begin
            thisuser.sl:=255; writeln;writeln;writeln('<TEMP SYSOP GRANTED>');
            writeln; write(thisline);
          end; topscr;
        end;
    68:if ch then
         ch:=false
       else begin
         chat;
       end;
    71:if ch then tfile;
    84:chdsl;
    85:chbac;
    90:begin b:=ch; ch:=true; extramsgs:=extramsgs-10; tleft; ch:=b;  end;
    91:begin b:=ch; ch:=true; extramsgs:=extramsgs+10; tleft; ch:=b;  end;
    93:begin beepend:=not beepend; b:=ch; ch:=true; tleft; ch:=b; end;
  end;
end;

function inkey:char;
var c:char;
begin
  c:=chr(0); inkey:=chr(0);
  if keypressed then begin
    c := readkey; if c=#0 then
{    read(kbd,c); if c=chr(27) then}
      if keypressed then begin
       { read(kbd,c);}
        c:=readkey;
        skey1(c);
        if c=#68 then
          c:=#1
        else
          c:=#0;
      end;
    inkey:=c;
  end else begin
    if commpressed and incom then begin
      inkey:=cinkey;
    end;
  end;
end;

procedure oc(c:char);
begin
  if c<>#0 then write(c);
  o(c);
end;

procedure outkey(c:char);
begin
  if (c<>chr(12)) and (not ((c=chr(7)) and (incom))) then if c<>#0 then write(c);
  if (not echo) and (c>=' ') then c:='X';
  o(c);
  if c=chr(12) then begin clrscr; lil:=0; end;
  if c=#7 then begin o(#0); o(#0); o(#0); o(#0); end;
end;

procedure dm(i:astr; var c:char);
begin
  buf:=i;
  if buf<>'' then begin
    c:=buf[1];
    buf:=copy(buf,2,length(buf)-1);
  end;
end;

procedure cls;
begin
  outkey(chr(12));
end;

procedure wait(b:boolean);
var c:integer;
begin
  if b then begin
    prompt('[WAIT]');
    sll:=thisline;
    writeln; writeln;
  end else begin
    writeln; thisline:=sll; write(sll);
    sll:=''; for c:=1 to 6 do sll:=sll+chr(8)+' '+chr(8);
    topscr;
    prompt(sll);
  end;
end;

procedure chsl;
var ij,i:astr; c:integer;
begin
 wait(true);
 write('Enter new SL: ');
 readln(i); if i<>'' then thisuser.sl:=value(i); writeln;
 if thisuser.sl=99 then begin
   write('Board #? '); thisuser.sbn:=0;
   readln(i); thisuser.sbn:=value(i);
   writeln;
 end;
 realsl:=thisuser.sl;
 wait(false);
end;

procedure swac(var u:userrec;r:restrictions);
begin
  if r in u.ac then u.ac:=u.ac-[r] else u.ac:=u.ac+[r];
end;

procedure acch(c:char; var u:userrec);
begin
  case c of
    'L':swac(u,rlogon);
    'C':SWAC(u,RCHAT);
    'V':SWAC(u,RVALIDATE);
    'B':SWAC(u,RBACKSPACE);
    'A':SWAC(u,RAMSG);
    '*':SWAC(u,RPOSTAN);
    'P':SWAC(u,RPOST);
    'E':SWAC(u,REMAIL);
    'K':SWAC(u,RVOTING);
    'M':swac(u,rmsg);
  END;
end;

procedure chac(var thisuser:userrec);
var c:char; ij,i:astr; cc:integer;
begin
  wait(true);
  writeln('LCVBA*PEKM');writeln;write('Which? ');
  c:=readkey; c:=upcase(c); writeln(c); writeln;
  acch(c,thisuser);
  wait(false);
end;

procedure chbac;
var c:char; ij,i:astr; cc:integer;
begin
  wait(true);
  write('Which board? '); c:=readkey; c:=upcase(c); writeln(c);
  if c in ['A'..'G'] then
    if c in thisuser.ar then
      thisuser.ar:=thisuser.ar-[c]
    else
      thisuser.ar:=thisuser.ar+[c];
  wait(false);
end;

procedure chdsl;
var ij,i:astr; c:integer;
begin
 wait(true);
 writeln('UL=',thisuser.uploads,'-',thisuser.uk,'K   DL=',thisuser.downloads,'-',thisuser.dk,'K');
 write('Enter new DSL: ');
 readln(i); if i<>'' then thisuser.dsl:=value(i); writeln;
 wait(false);
end;

procedure tfile;
var i:astr; ii:integer;
bf:file of byte; cr:boolean;
begin
  if cfo then begin
    cfo:=false;
    close(cf);
    write('<CLOSED>');
  end else begin
    assign(cf,'gfiles\chat.msg');
    assign(bf,'gfiles\chat.msg'); cr:=false;
    {$I-} reset(bf); {$I+}
    if ioresult<>0 then cr:=true
    else begin
      if filesize(bf)=0 then cr:=true;
      close(bf);
    end;
    if cr then rewrite(cf) else append(cf);
    cfo:=true;
    i:=#13+#10+#13+#10+dat+#13+#10+'==============='+#13+#10;
    writeln(cf,i);
    write('<OPEN>');
  end;
end;

procedure inli1(var i:astr);
var cp:integer; c:char; cv,cc:integer;
begin
  cp:=1;
  i:='';
  if ll<>'' then begin prompt(ll); i:=ll; ll:=''; cp:=length(i)+1;end;
  repeat
    getkey(c); checkhangup;
    case ord(c) of
      32..255:if (cp<79) then begin
                i[cp]:=c; cp:=cp+1; outkey(c);
              end;
      8:if cp>1 then begin c:=chr(8);
               prompt(c+' '+c); cp:=cp-1;
            end;
      24:begin
           for cv:=1 to cp-1 do prompt(chr(8)+' '+chr(8)); cp:=1;
         end;
       7:o(#7);
      23:if cp>1 then repeat
           prompt(chr(8)+' '+chr(8)); cp:=cp-1;
         until (cp=1) or (i[cp]=' ');
       9:begin
           cv:=5-(cp mod 5); if (cp+cv<79)  then
             for cc:=1 to cv do begin
               prompt(' ');
               i[cp]:=' '; cp:=cp+1;
             end;
         end;
  end;
  until (c=#13) or (cp=79) or hangup or (not ch);
  if not ch then begin c:=#13; ch:=false; end;
  i[0]:=chr(cp-1);
  if c<>chr(13) then begin
    cv:=cp-1;
    while (cv>0) and (i[cv]<>' ') and (i[cv]<>chr(8))do cv:=cv-1;
    if (cv>(cp div 2)) and (cv<>cp-1) then begin
      ll:=copy(i,cv+1,cp-cv); for cc:=cp-2 downto cv do prompt(chr(8));
      for cc:=cp-2 downto cv do prompt(' ');
      i[0]:=chr(cv-1);
    end;
  end;
  nl;
end;

procedure chat;
var c:char; tf:boolean; sp,xx:astr; x:integer; t,t1:real;
begin
  sp:=thisline; ch:=true; chatcall:=false; tf:=echo; echo:=true;nl;nl; t:=timer;
  thisuser.option:=thisuser.option-[alert];
  if chatr<>'' then
    begin
      writeln('                    *** Reason for Chat: ',chatr,' ***');
      chatr:='';
    end;
  ansic(5); print('Sysop''s here, go ahead '+ thisuser.realname + ' ...'); nl;
  repeat
    inli1(xx);
    if (xx='/quitchat') or (xx='/QUITCHAT') then begin
      t1:=timer; while (abs(t1-timer)<4.0) and (not keypressed) do;
      if not keypressed then ch:=false;
    end else if cfo then writeln(cf,xx);
  until (not ch) or hangup;
  nl; ansic(5); print('Chat mode completed, standby for return ...'); nl;
  chattime:=chattime+timer-t; ch:=false; echo:=tf;
  if hangup and cfo then begin
    writeln(cf); writeln(cf,'<HANGUP>');
  end;
  prompt(sp); thisline:=sp;
  if cfo then begin cfo:=false; close(cf); end;
end;

function yn:boolean;
var c:char;
begin
  if not hangup then begin
    ansic(3);
    repeat
      getkey(c);
      c:=upcase(c);
    until (c='Y') or (c='N') or (c=chr(13)) or hangup;
    if c='Y' then begin print('Yes'); yn:=true; end else begin print('No'); yn:=false; end;
    if hangup then yn:=false;
  end;
end;

procedure input1(var i:astr; ml:integer; tf:boolean);
var cp:integer;
    c:char;
    r:real;
begin
 checkhangup;
 if not hangup then begin
  r:=timer;
  cp:=1;
  repeat
    getkey(c);
    if c=#1 then r:=timer;
    if not tf then c:=upcase(c);
    if (c>=' ') and (c<chr(127)) then
      if cp<=ml then begin
      i[cp]:=c;
      cp:=cp+1;
      outkey(c);
      thisline:=thisline+c;
    end else else case ord(c) of
      8:if cp>1 then begin
               c:=chr(8);
               outkey(c);outkey(' '); outkey(c);
               cp:=cp-1;
               if length(thisline)>0 then thisline:=copy(thisline,1,length(thisline)-1);
             end;
      21,24:while cp<>1 do begin
               cp:=cp-1;
               outkey(#8);outkey(' '); outkey(#8);
               if length(thisline)>0 then thisline:=copy(thisline,1,length(thisline)-1);
             end;
    end;
    if (timer-r)>300.0 then hangup:=true;
  until (c=#13) or (c=#14) or hangup;
  i[0]:=chr(cp-1);
  nl;
 end;
end;

procedure input(var i:astr; ml:integer);
begin
  input1(i,ml,false);
end;

procedure inputl(var i:astr; ml:integer);
begin
  input1(i,ml,true);
end;

procedure onek(var c:char; ch:astr);
var i1,i:astr; tf:boolean;
begin
  i1:=thisline; tf:=false;
  repeat
    if not(onekey in thisuser.defaults) then begin
      if tf then prompt(i1);
      input(i,3);
      if length(i)=1 then c:=i[1] else c:=' ';
    end else begin
      getkey(c);
      c:=upcase(c);
    end;
    tf:=true;
  until (pos(c,ch)>0) or hangup;
  if hangup then c:=ch[1];
  if onekey in thisuser.defaults then print(''+c);
end;

procedure onek2(var c:char; ch:astr);
var i1,i:astr; tf:boolean;
begin
  i1:=thisline; tf:=false;
  repeat
    getkey(c);
    c:=upcase(c);
    tf:=true;
  until (pos(c,ch)>0) or hangup;
  if hangup then c:=ch[1];
  prt(''+c);
end;

procedure centre(var i:astr);
var n,n1:integer;
begin
  if pap<>0 then nl;
  if i[1]=#2 then i:=copy(i,2,length(i)-1);
  n:=length(i); n1:=1;
  while (n1<=length(i)) do begin
    if i[n1]=#3 then begin
      n:=n-2;
      n1:=n1+1;
    end;
    n1:=n1+1;
  end;
  if n<thisuser.linelen then
    i:=copy('                                               ',1,
      (thisuser.linelen-n) div 2)+i;
end;

procedure wkey(var abort,next:boolean);
var cc:char;
 begin
    while not (empty or hangup or abort) do begin
      getkey(cc);
      if (cc=' ') or (cc=chr(3)) or (cc=chr(24)) or (cc=chr(11)) then
        abort:=true;
      if (cc=chr(14)) then begin abort:=true; next:=true; end;
      if (cc=chr(19)) or (cc='P') or (cc='p') then begin
        getkey(cc);
      end;
    end;
 end;

procedure printa1(i:astr; var abort,next:boolean);
var c:integer;
begin
 checkhangup;
 if not hangup then begin
  abort:=false; next:=false; c:=1;
  if not empty then wkey(abort,next);
  while (not abort) and (c-1<length(i)) and (not hangup) do begin
    checkhangup;
    if i[c]=chr(8) then pap:=pap-1 else
      if i[c]=#3 then begin
        if i[c+1] in [#0..#8] then
          if okansi then
            ansic(ord(i[c+1]));
      end else
        if i[c]<>chr(10) then pap:=pap+1;
    if not empty then wkey(abort,next);
    if i[c]=#3 then
      c:=c+1
    else
      outkey(i[c]);
    c:=c+1;
  end;
 end else abort:=true;
end;

procedure printa(i:astr; var abort,next:boolean);
var s:astr; p,op,rp,rop,nca:integer; crend:boolean;
begin
  abort:=false;
  crend:=(i[length(i)]=#1) and (i[length(i)-1]<>#3);
  if crend then i:=copy(i,1,length(i)-1);
  if i[1]=#2 then begin
    centre(i);
    printa1(i,abort,next);
    nl;
  end else begin
    wkey(abort,next);
    if i='' then nl;
    while (i<>'') and (not abort) and (not hangup) do begin
      rp:=0; nca:=thisuser.linelen-pap-1; p:=0;
      while (rp<nca) and (p<length(i)) do begin
        if i[p+1]=#8 then rp:=rp-1 else
          if i[p+1]=#3 then
            p:=p+1
          else
            if (i[p+1]<>#10) then rp:=rp+1;
        p:=p+1;
      end;
      op:=p; rop:=rp;
      if (rp>=nca) and (p<length(i)) then begin
        while ((not (i[p] in [' ',#8,#10])) or (i[p-1]=#3)) and (p>1) do begin
          rp:=rp-1; p:=p-1;
        end;
        if p=1 then
          if not (i[1] in [' ',#8,#10]) then begin rp:=rp-1; p:=p-1; end;
      end;
      if abs(rop-rp)>=(thisuser.linelen div 2) then p:=op;
      s:=copy(i,1,p); delete(i,1,p);
      if (s[length(s)]=' ') then s[0]:=pred(s[0]);
      printa1(s,abort,next);
      if ((i='') and crend) or (i<>'') or abort then
        nl
      else
        printa1(' ',abort,next);
    end;
  end;
end;

procedure printacr(i:astr; var abort,next:boolean);
begin
 if not abort then
  if i[length(i)]=#1 then
    printa(i,abort,next)
  else
    printa(i+#1,abort,next);
end;

function ctim(rl:real):astr;
var h,m,s:astr;
begin
  s:=tch(cstr(trunc(rl-int(rl/60.0)*60.0)));
  m:=tch(cstr(trunc(int(rl/60.0)-int(rl/3600.0)*60.0)));
  h:=cstr(trunc(rl/3600.0));
  if length(h)=1 then h:='0'+h;
  ctim:=h+':'+m+':'+s;
end;

function tlef:astr;
begin
  tlef:=ctim(nsl);
end;

function cstrr(rl:real; base:integer):astr;
var c1,c2,c3:integer; i:astr; r1,r2:real;
begin
 if rl<=0.0 then cstrr:='0' else begin
  r1:=ln(rl)/ln(1.0*base);
  r2:=exp(ln(1.0*base)*(trunc(r1)));
  i:='';
  while (r2>0.999) do begin
    c1:=trunc(rl/r2);
    i:=i+copy('0123456789ABCDEF',c1+1,1);
    rl:=rl-c1*r2;
    r2:=r2/(1.0*base);
  end;
  cstrr:=i;
 end;
end;

procedure savesystat;
begin
  reset(systatf); write(systatf,systat); close(systatf);
end;

procedure pfl(fn:astr; var abort:boolean; cr:boolean);
var fil:text;
    i:astr;
    next:boolean;
begin
    if not hangup then begin
      assign(fil,fn);
      {$I-} reset(fil); {$I+}
      if ioresult<>0 then print('File not found.') else begin
        abort:=false;
        while not eof(fil) and (not abort) and (not hangup) do begin
          readln(fil,i);
          if cr then
            printacr(i,abort,next)
          else
            printa(i,abort,next);
        end;
        close(fil);
      end;
      nl;nl;
    end;
end;

procedure printfile(fn:astr);
var abort:boolean;
begin
  pfl(fn,abort,true);
end;

procedure print_file (fn:astr);
Var  fil:Text; i:char; abort,next:boolean; c:Integer; r:registers;
begin
 if not hangup then begin
   assign(fil,fn);
   {$I-} reset(fil); {$I+}
   if ioresult<>0 then print('File not found.') else begin
     abort:=false;
     while ((not eof(fil)) and (not abort) and (not hangup)) do begin
       checkhangup;
       if (not empty) then wkey(abort,next);
       read(fil,i);
          If outcom then o1(i);
          With r Do Begin
             DX := Ord(i);
             AX := $0200;
             MsDos (r);
          End;
     end;
     close(fil);
   end;
   nl;nl;
 end;
 topscr;
end;

procedure printf(fn:astr);      (* See if an *.ans file is available *)
var fil:text;                  (* if you have ansi graphics invoked *)
begin
  if okansi then begin
    assign(fil,fn+'.ans');
    {$I-} reset(fil); {$I+}
    if ioresult<>0 then nofile:=true else begin nofile:=false; close(fil); end;
    if nofile then printfile(fn+'.msg') else print_file(fn+'.ans');
  end else printfile(fn+'.msg');
end;
end.
