{$M 32150,0,0}
PROGRAM BBS;

                      {*****************************}
                      {Copyright (c) 1986 Wayne Bell}
                      {*****************************}

(*****************************************************************************)
(*                                                                           *)
(*  This code is for the most part Copyright (c) 1986 Wayne Bell but is used *)
(*  with premission from the author.  The Code has been changed from Turbo   *)
(*  Pascal Ver 3.0 (c) Borland INT 1983 to Turbo Pascal Ver 7.0 (c) Borland  *)
(*  INT 1992.  This code was modified by James Fielden and know copyright    *)
(*  is placed on my work to this code.  Any and or All this code my be used  *)
(*  by anyone as long as due credit is giving to Wayne Bell for his work on  *)
(*  the World War Four BBS.  If you want you can give me credit also but none*)
(*  to me is required.  Wayne Bell, Borland INT and or James Fielden can not *)
(*  be made responsible for any damage, loss of Profit or any other problems *)
(*  from the use or misuse of this code.  You use this code at your own risk *)
(*  No support is available of any kind.                                     *)
(*                                                                           *)
(*          James E. Fielden                                                 *)
(*                                                                           *)
(*****************************************************************************)
Uses
  Crt,Dos,Overlay,Common,Dloads,Unit0,Unit1,Unit2,Minios,ExecSwap;

{$O Dloads}
{$O Unit1}
{$O Minios}

procedure pver;
begin
   nl;nl;
   print('WWIV Version 3.21d-TP70');
   print('by: Wayne Bell & James Fielden');
   print('WWIV 3.21d-TP70 is writing in Turbo Pascal Ver 7.0');
   print('Last Compiled June 29, 1993 by: James Fielden');
   nl;nl;
   print('REGISTERED To: Edweird Strange  # 00-02');
   nl;nl;
end;

procedure dropto(s:astr; swaping:boolean);
var CurDir:Astr; Status:Word;
begin
  GetDir(0, CurDir);
  ClrScr; if s='' then  Writeln('Type "EXIT" to Return to BBS');
  SwapVectors;
  if swaping then begin
  if not InitExecSwap(HeapPtr, 'SWAP.$$$') then
    Writeln('Unable to allocate swap space') else
    Status := ExecWithSwap(GetEnv('COMSPEC'),s);
  end else
   Exec(GetEnv('COMSPEC'),s); SwapVectors;
   ChDir(CurDIR); nl; nl; print('Please Wait ReLoading BBS.'); nl; nl;
   if swaping then ShutdownExecSwap;
end;

Function TimeStr:Astr;
Var I:Astr;
Begin
  Str(Nsl/60:7:2,i);
  i:=copy(i,2,length(i));
  i:=copy(i,1,pos('.',i)-1);
  timestr:=i;
end;

procedure write_dor;
var filvar:text; first,last:astr; dum:astr;
begin
  assign(filvar,'dorinfo1.def');
  rewrite(filvar); writeln(filvar,'MX Communications');
  writeln(filvar,'Edweird'); writeln(filvar,'Strange');
  if spd='KB' then writeln(filvar,'COM0') else
  writeln(filvar,'COM'+cstr(systat.comport));
  if spd='KB' then dum:='0' else dum:=spd;
  writeln(filvar,dum+' BAUD,N,8,1');
  writeln(filvar,'0');
  first:=copy(thisuser.name,1,pos(' ',thisuser.name));
  last:=copy(thisuser.name,length(first)+1,length(thisuser.name));
  if first='' then first:='THE';
  writeln(filvar,first); writeln(filvar,last);
  writeln(filvar,'Knoxville, TN'); if okansi then writeln(filvar,'1') else
  writeln(filvar,'0'); writeln(filvar,thisuser.sl); writeln(filvar,timestr);
  close(filvar);
end;

procedure run_door;
var b:dorrec; f:file of dorrec; i:astr; t,c:integer; deep,exit:boolean;
    dftit:array[1..25] of record tit:string[80]; arn:integer; dorfile:boolean;end;
    lgftn,lgftnt,numgft:integer; titl:astr;

procedure gettit(n:integer);
var r:integer; b:dorrec;
begin
  numgft:=0;
  if n>0 then begin
    seek(f,n); read(f,b); titl:='[ '+b.title+' ]';
  end else titl:='[ Doors ]';
  r:=n+1;
  if r<=t then begin
    seek(f,r); read(f,b);
    while (r<=t) and (b.filen[1]<>#1) do begin
      if b.num<=thisuser.sl then begin
        numgft:=numgft+1;
        dftit[numgft].tit:=b.title;
        dftit[numgft].arn:=r;
        dftit[numgft].dorfile:=true;
      end;
    r:=r+1; if (r<=t) then begin seek(f,r); read(f,b); end; end;
  end;
  if n=0 then while (r<=t) do begin seek(f,r); read(f,b);
  if (b.filen[1]=#1) and (b.num<=thisuser.sl) then begin
    numgft:=numgft+1; dftit[numgft].tit:='[ '+b.title+' ]';
    dftit[numgft].arn:=r; dftit[numgft].dorfile:=false; end;
  r:=r+1; end;
end;

  procedure lgft;
  var abort,next:boolean; c:integer;
  begin
    nl; print(titl); nl;
    if numgft=0 then print('No Onliners Yet.') else begin
      abort:=false; next:=false; c:=1;
      while (c<=numgft) and (not abort) do begin
        printacr(cstr(c)+': '+dftit[c].tit,abort,next);
        c:=c+1;
      end;
    end;
  end;

begin
  nl; assign(f,'gfiles\door.dat'); {$i-} reset(f); {$i+}
  if ioresult <> 0 then begin
    rewrite(f); b.num:=0; write(f,b);
  end;
  seek(f,0); read(f,b); t:=b.num; if t=0 then print('No Doors yet.') else
  begin gettit(0); exit:=false; lgft; lgftn:=0; deep:=false; lgftnt:=0;
  repeat
    nl; nl; prompt('Doors: (1-'+cstr(numgft)+', ^'+cstr(lgftn)+'),?,Q : ');
    input(i,3); if i='' then if lgftn=numgft then i:='Q' else i:=cstr(lgftn+1);
    if i='?' then lgft; if i='Q' then if deep then begin
      deep:=false; gettit(0); lgft; lgftn:=lgftnt; end else exit:=true;
    c:=value(i); if (c>0) and (c<=numgft) then begin
      if dftit[c].dorfile=true then begin 
      seek(f,dftit[c].arn); read(f,b); nl; nl; nl; sysoplog('Ran '+b.title);
      print('Please wait while door is Loading');
      dropto('/C '+b.filen,false); topscr; lgftn:=c;
      end else begin
        gettit(dftit[c].arn); lgftn:=c; if numgft>0 then begin
          lgft; lgftnt:=c; lgftn:=0; deep:=true; end else begin
          gettit(0); nl; print('No Door there.');
        end;
      end;
    end;
  until exit or hangup;
  end;
  close(f); nl; nl;
end;

procedure getcaller;
var c:char; x:smr; chkcom:boolean; rl,rl1,rl2:real; i:Astr;

  procedure init1;
  begin
    set_baud(systat.maxbaud);
    if systat.maxbaud=300 then pr('ATS0=0Q0V0E0M0S2=1');
    if systat.maxbaud=1200 then pr('ATS0=0Q0V0E0M0S2=1X1');
    if systat.maxbaud=2400 then pr('ATS0=0Q0V0E0M0S2=1X1');
    dump;
  end;

  procedure i1;
  begin
    init1; c:=#0; write('Waiting...'); rl:=timer;
    repeat
      c:=cinkey;if abs(timer-rl)>4.0 then begin init1; rl:=timer; end;
    until c=#13; delay(50);
  end;

begin
  buf:=''; enddayf:=false; delay(50); close(sysopf); append(sysopf);
  dump; mailread:=false; smread:=false; andwith:=255; checkit:=false;
  curco:=7; sdc; window(1,1,80,25); clrscr; beepend:=false;
  outcom:=false; useron:=false; ll:=''; chatr:='';
  hangup:=false; usernum:=0; chatcall:=false; hungup:=false;
  term_ready(true); i1; clrscr; thisline:=''; okt:=false;
  if systat.users>0 then
    begin reset(uf); seek(uf,1); read(uf,thisuser); close(uf); usernum:=1; end
  else with thisuser do begin
    linelen:=80; pagelen:=25; defaults:=[]; option:=[];
  end;
  repeat
    if daynum(date)<>ldate then
      if (daynum(date)-ldate)=1 then
        ldate:=ldate+1
      else begin
        writeln('Date corrupted.');
        halt(1);
      end;
    randomize; incom:=false; outcom:=false; ihelp:=false; helpl:=#0;
    hangup:=false; hungup:=false; irt:=''; lastname:=''; macok:=true; cfo:=false;
    spd:='KB'; c:=#0; chkcom:=false;chattime:=0.0; extratime:=0.0;
    sdc; bread:=0; lil:=0;
    c:=inkey;
    if c<>#0 then begin
      c:=upcase(c);
      ansic(0);
      case c of
        'V':if usernum=1 Then uedit(usernum);
        ' ':begin
              write('Log on? '); rl2:=timer;
              while (not keypressed) and (abs(timer-rl2)<60.0) do;
              if keypressed then c:=readkey else c:='N'; c:=upcase(c);
              writeln(c); if c='Y' then c:=' ' else c:='@';
            end;
        'Q':begin elevel:=0; hangup:=true; doneday:=true; end;
        'L':begin close(sysopf); printfile('gfiles\sysop.log');
              pausescr; append(sysopf);
            end;
        'Y':begin printfile('gfiles\ysysop.log'); pausescr; end;
        'A':chkcom:=true;
        'S':pstat;
        'M':mailr;
        'B':boardedit;
        'I':initvotes;
        'T':begin term_ready(false); DropTo('/C Term',false); term_ready(true);
              pr('ATS0=0Q0V0E0M0S2=1X1'); dump; end;
        'E':dropto('/C list',true);
        'G':gfileedit;
        '.':dorfileedit;
        'P':changestuff;
        'D':dlboardedit;
        'C':DropTo('',false);
        'Z':begin zlog; pausescr; end;
        '=':chsldata;
        'R':if (systat.users>0) and (thisuser.waiting>0) then begin
              print('Feedback: '); nl; nl;
              macok:=true; readmail; macok:=false;
              reset(uf); seek(uf,1); write(uf,thisuser); close(uf);
            end;
        'F':dosfc;
        '?':begin printfile('gfiles\wfcmenu.msg'); pausescr; end;
      end;
      curco:=7; sdc; window(1,1,80,25); clrscr; dump;
    end;
    if c<>' ' then c:=#0;
    if (c<>#0) or commpressed or chkcom then begin
      getcallera(c,chkcom);
      if c='X' then i1;
    end;
  until incom or (c=' ') or doneday;
  etoday:=0; ptoday:=0; ftoday:=0; if not doneday then
    writeln('Logging on at '+spd+'...');
  curco:=7; sdc;
  if incom then begin
    outcom:=true;
    set_baud(value(spd));
    delay(700);
  end else begin term_ready(false); incom:=false; outcom:=false; end;
  timeon:=timer; ftoday:=0;
  dump;
  window(1,5,80,25); lil:=0; okt:=true;
  thisuser.defaults:=thisuser.defaults-[ansi];
  thisuser.cols:=dcols; curco:=$07;
  andwith:=255; checkit:=true; beepend:=false;
end;

procedure titles(var cn:integer);
var abort,next:boolean; nl:integer; i:Astr;
begin
  nl:=0;
  abort:=false;
  while (not hangup) and (not abort) and (nl<10) and (cn<=tnum) do begin
    if mary[cn].owner=usernum then i:='['+cstr(cn)+']' else i:='('+cstr(cn)+')';
    while length(i)<8 do i:=' '+i; i:=i+' '+mary[cn].title;
    if greater(mary[cn].message) then i[1]:='*';
    if mary[cn].messagestat<>validated then if lcs
      then begin
        i[1]:='N'; i[2]:='V';
      end else
        i:=copy(i,1,9)+'<<< NOT VALIDATED YET >>>';
    printacr(i,abort,next);
    nl:=nl+1;cn:=cn+1;
  end;
  cn:=cn-1;
end;

procedure scan2(var cn:integer; iread:newtyp; var quit:boolean);
var unvali,uv,pq,donescan,abort,next:boolean; i:Astr; t:integer;
 b:messagerec;
begin
  quit:=false;pq:=false; unvali:=false; helpl:='S';
  donescan:=false;
  repeat
    if iread=lt then begin cn:=cn+1; titles(cn); iread:=rp; end;
    if iread=rp then begin
      tleft;
      prt('Read:(1-'+cstr(tnum)+',^'+cstr(cn)+'),? :');
      input(i,4); t:=value(i);
      if i='R' then begin t:=cn; i:=cstr(t); end;
      if (i<>'') and (t=0) then case i[1] of
        'P':post;
        'T':iread:=lt;
        'Q':begin quit:=true; donescan:=true; end;
        'B':donescan:=true;
        'D':if lcs and (cn>0) and (cn<=tnum) then begin
              deletem(cn); cn:=cn-1;
            end;
        'A':autoreply;
        'V':if cs then vallastuser;
        'M':if cs then movemsg(cn);
        '?':begin
              print('Read:number');
              print('<CR>=next');
              print('T:itles     Q:uit');
              print('P:ost       A:uto-reply');
              print('R:e-read    B:next board in N-scan');
            end;
      end else begin
        if (t>0) and (t<=tnum) then begin
          cn:=t;
          iread:=rm;
        end else if i='' then begin
          t:=cn+1;
          if t<=tnum then begin
            cn:=t;
            iread:=rm;
          end else begin donescan:=true; pq:=true; end;
        end;
      end;
    end;
    if (iread=rm) and (cn>0) and (cn<=tnum) then begin
      readm(cn,next,uv); if uv then unvali:=true;
      if next then cn:=cn+1 else iread:=rp;
      mread:=mread+1; tleft;
      if (mread>=extramsgs+seclev[thisuser.sl].mallowed)
      and (thisuser.sl<>255) and (thisuser.ontoday<>1) then begin
        print('You have read all your messages.');
        hangup:=true;
      end;
      if (mread+5=extramsgs+seclev[thisuser.sl].mallowed) and (thisuser.ontoday<>1) then
        print('5 messages left until forced logoff');
    end else if iread=rm then iread:=rp;
    if (iread=rm) and (cn=tnum+1) then begin donescan:=true; pq:=true; end;
  until donescan or hangup;
  if unvali and lcs then begin
    ynq(chr(7)+'Validate messages here? ');
    if yn then for t:=1 to tnum do
      if mary[t].messagestat<>validated then
        mary[t].messagestat:=validated;
    bchanged:=true;
  end;
  if pq and (thisuser.sl>=boards[board].postsl) and not (rpost in thisuser.ac)
        and ((ptoday<seclev[thisuser.sl].posts) or (thisuser.sl>55)) then begin
    nl; ynq('Post on '+boards[board].name+'? ');
    if yn then post;
  end;
  nl;
end;

procedure scan1;
var cn:integer; i:Astr; quit:boolean;
begin
  iscan; helpl:='N';
  print(cstr(tnum)+' msgs on '+boards[board].name);
  if tnum<>0 then begin
    prt('Start listing at? ');
    input(i,4);
    cn:=value(i); if cn<=0 then cn:=0 else if cn>tnum then cn:=tnum else cn:=cn-1;
    if i='S' then scan2(cn,rp,quit) else
      if (i<>'Q') then
        if i='N' then begin
          cn:=1;
          while (not greater(mary[cn].message)) and (cn<tnum) do
            cn:=cn+1;
          cn:=cn-1;
          if greater(mary[cn].message) then scan2(cn,lt,quit);
        end else scan2(cn,lt,quit);
  end;
  savebase;
end;

procedure qscan(var quit:boolean; tf:boolean);
var cn:integer; i:Astr;
begin
  iscan;
  if boards[board].key=' ' then i:='#'+cstr(board) else i:=boards[board].key;
  cn:=1; nl;
  ansic(3); print('< Q-scan '+boards[board].name+' '+i+' - '+cstr(tnum)+' msgs >');
  if (tnum<>0) then begin
    if not tf then tf:=boardacpw(board);
    if tf then begin
      while (not greater(mary[cn].message)) and (cn<tnum) do
        cn:=cn+1;
      if greater(mary[cn].message) then scan2(cn,rm,quit) else quit:=false;
    end;
  end;
  ansic(3); print('< '+boards[board].name+' Q-scan done >');
  savebase;
end;

procedure nscan;
var quit:boolean;
begin
  nl;nl; ansic(5); print('<< Q-scan all >>');
  board:=1; quit:=false;
  while (board<=numboards) and (not quit) and (not hangup) do begin
   if thisuser.qscn[board] then
     if boardac(board) then qscan(quit,false);
   board:=board+1;
  end;
  nl; ansic(5); print('<<Global Q-scan done>>'); nl;
  board:=1;
end;

procedure mmkey(var i:Astr);
var c:char;
begin
  repeat
    repeat
      getkey(c);
    until (((c>=' ') and (c<chr(127))) or (c=chr(13))) or hangup;
    c:=upcase(c);
    outkey(c);
    thisline:=thisline+c;
    if (c='/') or (c='1') then begin
      i:=c;
      repeat
        getkey(c);
      until ((c>=' ')and(c<=chr(127))) or (c=chr(13)) or (c=chr(8)) or hangup;
      c:=upcase(c);
      if c<>chr(13) then begin outkey(c); thisline:=thisline+c; end;
      if (c=chr(8)) or (c=chr(127)) then prompt(' '+c);
      if c='/' then input(i,20) else if c<>chr(13) then i:=i+c;
    end else i:=c;
  until (c<>chr(8)) and (c<>chr(127)) or hangup;
  nl;
end;

procedure msgmenu;
var camel:boolean; nb,inte:integer; abort,next:boolean; ii:astr; rl:real; mr:mailrec;
begin
  camel:=false;
  repeat
   tleft;nl;nl;
   if mmnu in thisuser.defaults then printf('gfiles\msgmenu');
   print('T - '+tlef);
   if boards[board].key=' ' then i:='['+cstr(board)+'] ' else
   i:='['+boards[board].key+'] ';
   i:=i+'['+boards[board].name+'] :';
   prt(i); helpl:='M';
   if onekey in thisuser.defaults then mmkey(i) else input(i,20);
   if length(i)=1 then case i[1] of
     '+','>':begin nb := board; inc(nb); if nb >numboards then nb := 1;
         board := nb; end;
     '-','<':begin nb := board; dec(nb); if nb <1 then nb := numboards;
         board := nb; end;
     '?':if not (mmnu in thisuser.defaults) then begin
         nl;nl; printf('gfiles\msgmenu'); end;
     'O':begin
            helpl:='O';nl;nl; ynq('Log Off ? ');
            if yn then begin
            cls; printf('gfiles\logoff');
            hangup:=true; hungup:=false; end; end;
     '*':boardlist;
     'X':if mmnu in thisuser.defaults then
         thisuser.defaults:=thisuser.defaults-[mmnu]
         else thisuser.defaults:=thisuser.defaults+[mmnu];
     'C':reqchat;
     'R':removem;
     'E':smail(false);
     'F':begin irt:='Feedback'; imail(1); end;
     'S':scan1;
     'P':begin post; savebase; end;
     'T':loads;
     'M':readmail;
     'W':qscan(next,true);
     'N':nscan;
     'K':delmail;
     'J':prg(false);
     'Z':prg(true);
     'Q':camel:=true;
end else
  begin
    if copy(i,1,2)='//' then i:=copy(i,3,length(i)-2);
    if i='/O' then hangup:=true;
    if i='/E' then smail(true);
    if (i='BOARDEDIT') and so then begin sysoplog('Boardedit'); boardedit; end;
    if (i='VER') then pver;
  end;
  nb:=value(i);
  if nb>0 then
    if nb<=numboards then
      if (boards[nb].key=' ') and boardacpw(nb) then board:=nb
     else
   else
 else begin
   nb:=0;
   for inte:=1 to numboards do if boards[inte].key=i then nb:=inte;
   if (nb<>0) and (i<>' ') then if boardacpw(nb) then board:=nb;
 end;
 until camel or hangup;
end;

procedure mainmenu;
var nb,inte:integer; abort,next:boolean; ii:Astr; rl:real; mr:mailrec;
begin
  dump;tleft;nl;nl; macok:=true;
  if mmnu in thisuser.defaults then printf('gfiles\mainmenu');
  print('T - '+tlef);
  i:='Main Menu: ';
  prt(i); helpl:='@';
  if onekey in thisuser.defaults then mmkey(i) else input(i,20);
  helpl:=#0;
  if length(i)=1 then case i[1] of
    '?':if not (mmnu in thisuser.defaults) then
          begin nl;nl; printf('gfiles\mainmenu'); end;
    'O':begin
          helpl:='O';nl;nl; ynq('Hangup?  Sure? ');
          if yn then begin
            cls; printf('gfiles\logoff');
            hangup:=true;
            hungup:=false;
          end;
        end;
    'X':if mmnu in thisuser.defaults then
          thisuser.defaults:=thisuser.defaults-[mmnu]
        else
          thisuser.defaults:=thisuser.defaults+[mmnu];
    'D':default;
    'Y':yourinfo;
    'I':begin pver; printf('gfiles\logon'); printf('gfiles\system'); end;
    'C':reqchat;
    '$':chpw;
    'U':ulist;
    'F':begin irt:='Feedback'; imail(1); end;
    'T':loads;
    'M':msgmenu;
    'G':gfiles;
    'P':gallery;
    'N':jukebox;
    'R':bulletins;
    'W':wamsg;
    'V':vote;
    'L':printfile('gfiles\user.log');
    'A':abbs;
    'H':mmacro;
    '.':begin nl;nl; write_dor; run_door; cls; dump; topscr; end;
    'B':printfile('gfiles\bbslist.msg');
    '!':if cs then begin
          print('Enter name or number of person.'); prt(':');
          finduser(inte); if inte>0 then vali(inte);
        end;
 end else
  begin
    if copy(i,1,2)='//' then i:=copy(i,3,length(i)-2);
    if i='/O' then hangup:=true;
    if i='/K' then if onekey in thisuser.defaults then thisuser.defaults:=
      thisuser.defaults-[onekey] else thisuser.defaults:=thisuser.defaults+[onekey];
    if (i='UEDIT') and cs then uedit(usernum);
    if (i='STATUS') and cs then pstat;
    if (i='IVOTES') AND cs then begin sysoplog('Init Votes'); initvotes; end;
    if (i='LOG') and cs then begin
      close(sysopf);
      printfile('gfiles\sysop.log');
      append(sysopf);
    end;
    if (i='YLOG') and cs then printfile('gfiles\ysysop.log');
    if (i='TEDIT') and cs then tedit;
    if (i='/?') and cs then printfile('gfiles\sysopmnu.msg');
    if (i='DOS') and cs then dosfc;
    if (i='VER') then pver;
    if (i='STAT') and cs then begin Writeln(MemAvail, ' bytes available');
       Writeln('Largest free block is ',MaxAvail, ' bytes');
       Writeln('This is DOS Version ',Lo(DosVersion),'.',Hi(DosVersion));
       Writeln(DiskFree(0) div 1024,' Kbytes free');
       Writeln(DiskSize(0) div 1024, ' Kbytes capacity'); end;
    if (i='OLDUSERS') and cs then oldusers;
    if (i='ZLOG') and cs then zlog;
    if (i='QUIT') and so then
      if checkpw then
        begin doneday:=true; hangup:=true; elevel:=1; end;
    if (i='DOORWAY') and so then if checkpw then begin if spd = 'KB' then
      dropto('',true) else dropto('/C doorway.bat',true); end;
    if (i='BOARDEDIT') and so then begin sysoplog('Boardedit'); boardedit; end;
    if (i='DLBOARDEDIT') and so then begin sysoplog('DLBoardedit'); dlboardedit; end;
    if (i='MAILR') and so then
      if checkpw then begin sysoplog('Mailr'); mailr; end;
    if (i='CHUSER') and so then chuser;
  end;
end;

begin
  OvrInit(ParamStr(0));          (* Use "copy/b bbs.exe + bbs.ovr" *)
  if OvrResult<>ovrOk then
  begin
    Writeln('Overlay manager initialization failed.');
    Halt(1);
  end;
  OvrInitEMS;
  case OvrResult of
    ovrIOError: Writeln('Overlay file I/O error.');
    ovrNoEMSDriver: Writeln('No EMS.  Using Disk for Overlay.');
    ovrNoEMSMemory: Writeln('Not enough EMS.  Using Disk for Overlay.');
    else Writeln('Using EMS for faster Overlay swapping.');
  end;
  checkbreak:=false;
  UseEmsIfAvailable := True;
  getdir(0,i);
  async_init;
  init;
  repeat
    getcaller;
    if not doneday then begin
      if getuser then newuser;
      macok:=true;
      if not hangup then
        if logon then
          readmail;
        bulletins;
    end;
    flush(sysopf);
    if thisuser.age=0 then getnewinfo;
    while not hangup do
      mainmenu;
    term_ready(false); delay(500);
    if useron then logoff;
    if cdet and (not doneday) then hangupphone;
    if enddayf then endday;
    enddayf:=false;
  until doneday;
  close(sysopf);
  term_ready(true); delay(100); pr('ATZ');
  remove_port;
  halt(elevel);
end.
