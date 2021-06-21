PROGRAM BBS;

                      {*****************************}
                      {Copyright (c) 1986 Wayne Bell}
                      {*****************************}

{$V-} {$C-}
{$I COMMON.PAS}
{$I PART1.PAS}

function greater(mrec:messages):boolean;
begin
 if mrec.ext>thisuser.qscan[board].ext then greater:=true else
  if mrec.ltr>thisuser.qscan[board].ltr then greater:=true else
    if (mrec.ltr=thisuser.qscan[board].ltr) and (mrec.number>thisuser.qscan[board].number) then
      greater:=true
    else greater:=false;
end;

function maxage(x:integer):integer;
begin
  maxage:=255;
  if x<20 then
    maxage:=5
  else if x<30 then
    maxage:=14
  else if x<40 then
    maxage:=90
  else if x<60 then
    maxage:=120;
end;

function boardacpw(nb:integer):boolean;
var i:str;
begin
  boardacpw:=false;
  if cs then boardacpw:=true else
    if (thisuser.sl>=boards[nb].sl) and
    ((boards[nb].ar='@') or (boards[nb].ar in thisuser.ar)) then
    if boards[nb].pw='' then boardacpw:=true else begin
      prt('Password? '); mpl(10); input(i,10);
      if i=boards[nb].pw then boardacpw:=true else print('Wrong.');
    end;
end;

function boardac(nb:integer):boolean;
begin
  boardac:=false;
  if cs then boardac:=true else
    if (thisuser.sl>=boards[nb].sl) and
    ((boards[nb].ar='@') or (boards[nb].ar in thisuser.ar)) then boardac:=true;
end;

procedure isr(uname:str;usernum:integer);
var t,i,ii:integer; sr:smalrec;
begin
 ii:=systat.users; i:=0;
 while (ii-i)>1 do begin
   t:=(ii+i) div 2;
   if uname<srl[t].name then
     ii:=t
   else
     i:=t;
 end;
 if srl[ii].name<uname then i:=ii;
 for ii:=systat.users downto i+1 do
   srl[ii+1]:=srl[ii];
 sr.name:=uname; sr.number:=usernum;
 srl[i+1]:=sr;
 systat.users:=systat.users+1;
 savesystat;
 rewrite(sf); for ii:=0 to systat.users do write(sf,srl[ii]); close(sf);
end;

function ctp(t,b:integer):str;
var i,i1:str; n:real;
begin
  i:=cstr((t*100) div b); if length(i)=1 then i:=' '+i; i:=i+'.';
  if length(i)=3 then i:=' '+i;
  n:=t/b+0.0005;
  i1:=cstr(trunc(n*1000) mod 10);
  ctp:=i+i1+'%';
end;

procedure vali(un:integer);
var i:integer; c:char; ii:str; r:restrictions;
begin
  reset(uf); seek(uf,un); read(uf,user);
  print('Name: '+user.name+' #'+cstr(un));
  print('RN  : '+user.realname);
  print('PH  : '+user.ph);
  print('AGE : '+cstr(user.age)+' '+user.sex);
  print('COMP: '+comptyp[user.comptype]);
  print('SL  : '+cstr(user.sl));
  if (user.sl=99) or (lcosysop in seclev[user.sl].anst) then
    print('SBN : '+cstr(user.sbn));
  if user.sl<>255 then begin
    prt('Enter new sl : '); input(ii,3);
    if ii<>'' then begin
      i:=value(ii); if (i<255) and (i>-1) then user.sl:=i;
    end;
  end;
  if (lcosysop in seclev[user.sl].anst) or (user.sl=99) then begin
    prt('Which board #? '); input(ii,2);
    if ii<>'' then user.sbn:=value(ii);
  end;
  print('      LCVBA*PEKM');
  repeat
    prt('AC  : ');
    for r:=rlogon to rmsg do
    if r in user.ac then prompt(copy('LCVBA*PEKM',ORD(R)+1,1)) else prompt(' '); nl;
    prt('Which? ');
    getkey(c); c:=upcase(c); print(c);acch(c,user);
  until (c=chr(13)) or hangup;
  print('DSL : '+cstr(user.dsl));
  prt('Enter new dsl : '); input(ii,3);
  if ii<>'' then user.dsl:=value(ii);
  seek(uf,un); write(uf,user); close(uf);
end;

procedure vallastuser;
var i:integer;
begin
  if lastname='' then print('Can''t validate anyone.') else begin
    i:=length(lastname);
    while (lastname[i]<>'#') and (i>1) do i:=i-1;
    i:=value(copy(lastname,i+1,5));
    if i=0 then print('Oops, there''s a problem.') else vali(i);
  end;
end;

procedure iscan;
var f:file; n:integer;
begin
  if bread<>board then begin
    assign(f,'gfiles\'+boards[board].filename+'.BRD');
    {$I-} reset(f,sizeof(messagerec)); {$I+}
    if (ioresult=0) then begin
      blockread(f,mary[0],1);
      blockread(f,mary[1],mary[0].message.number);
    end else begin
      rewrite(f);
      mary[0].message.number:=0;
      blockwrite(f,mary[0],1);
    end;
    close(f);
    bread:=board;
    bchanged:=false;
  end;
end;

procedure savebase;
var f:file;
begin
  if (bread>0) and bchanged then begin
    assign(f,'gfiles\'+boards[bread].filename+'.BRD');
    reset(f,sizeof(messagerec));
    blockwrite(f,mary[0],mary[0].message.number+1);
    truncate(f);
    close(f);
    bchanged:=false;
  end;
end;

function tnum:integer;
begin
  tnum:=mary[0].message.number;
end;

procedure deletem(ntd:integer);
var filvar:file; t:integer;
begin
  assign(filvar,filename(mary[ntd].message));
  {$I-} erase(filvar); {$I+} t:=ioresult;
  for t:=ntd+1 to tnum do begin
    mary[t-1]:=mary[t];
  end;
  mary[0].message.number:=tnum-1;
  bchanged:=true;
end;

procedure readm(cn:integer; var next:boolean; var unvali:boolean);
var i:str; ratall,rname:boolean;
begin
  nl;nl;
  ratall:=true; next:=false;unvali:=false;
  if mary[cn].messagestat<>validated then begin  unvali:=true;
    print(cstr(cn)+'/'+cstr(tnum)+': <<< NOT VALIDATED YET >>>');
    lastname:='';
    if not lcs then ratall:=false;
  end;
  if ratall then begin
    print(cstr(cn)+'/'+cstr(tnum)+': '+mary[cn].title); irt:=mary[cn].title;
    if postn in seclev[thisuser.sl].anst then rname:=true else rname:=false;
    if so and (not hangup) then writeln('Days left: '+
      cstr(mary[cn].date-daynum(date)+mary[cn].mage));
    readmsg(mary[cn].message,rname,next); tleft;
    if greater(mary[cn].message) then thisuser.qscan[board]:=mary[cn].message;
  end;
end;

function mln(i:str; l:integer):str;
begin
  while length(i)<l do i:=i+' ';
  mln:=i;
end;

function mn(i,l:integer):str;
begin
  mn:=mln(cstr(i),l);
end;

procedure inu(var i:integer);
var s:str;
begin
  input(s,5); i:=value(s);
end;

procedure ini(var i:byte);
var s:str;
begin
  input(s,3); i:=value(s);
end;

{$I PARTX.PAS}

procedure imail(i:integer);
var user:userrec; ori:integer;
begin
  ori:=i;
  if i>0 then begin
    reset(uf); seek(uf,i); read(uf,user);
    if user.deleted then begin
      print('That user is deleted.');
      close(uf);
    end else begin
      if user.forusr<>0 then begin
        i:=forwardm(i);
        if i>0 then begin
          seek(uf,i); read(uf,user); close(uf);
          print('Mail forwarded.');
          ynq('E-mail '+user.name+' #'+cstr(i)+'? ');
          if yn then
            if ori=1 then
              email(i,true)
            else
              email(i,false);
        end else begin
          print('Can''t E-mail that user.');
          close(uf);
        end;
      end else begin
        close(uf);
        ynq('E-mail '+user.name+' #'+cstr(i)+'? ');
        if yn then email(i,false);
      end;
    end;
  end;
end;

procedure autoreply;
var i:integer; c:char;
begin
  if lastname='' then print('Can''t Auto-reply now.') else begin
    i:=length(lastname);
    while (lastname[i]<>'#') and (i>1) do i:=i-1;
    i:=value(copy(lastname,i+1,5));
    if i=0 then print('It seems I can''t do that now.') else imail(i);
  end;
end;

{$I PART2.PAS}
{$I PART3.PAS}

procedure getcaller;
var c:char; x:smr; chkcom:boolean; rl,rl1,rl2:real; i:str;

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
    randomize; incom:=false; outcom:=false; ihelp:=false; helpl:=#0; ret:=201;
    hangup:=false; hungup:=false; irt:=''; lastname:=''; macok:=true; cfo:=false;
    spd:='KB'; c:=#0; chkcom:=false;chattime:=0.0; extratime:=0.0;
    sdc; bread:=0; lil:=0;
    c:=inkey;
    if c<>#0 then begin
      c:=upcase(c);
      ansic(0);
      case c of
        'V':if usernum=1 then dos('U');
        ' ':begin
              write('Log on? '); rl2:=timer;
              while (not keypressed) and (abs(timer-rl2)<60.0) do;
              if keypressed then read(kbd,c) else c:='N'; c:=upcase(c); writeln(c);
              if c='Y' then c:=' ' else c:='@';
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
        'T':dos('T');
        'E':dos('E');
        'G':dos('G');
        'P':changestuff;
        'D':dlboardedit;
        'C':chchains;
        'Z':begin zlog; pausescr; end;
        '=':dos('S');
        'R':if (systat.users>0) and (thisuser.waiting>0) then begin
              print('Feedback: '); nl; nl;
              macok:=true; readmail; macok:=false;
              reset(uf); seek(uf,1); write(uf,thisuser); close(uf);
            end;
        'F':dos('D');
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
var abort,next:boolean; nl:integer; i:str;
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
var unvali,uv,pq,donescan,abort,next:boolean; i:str; t:integer;
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
var cn:integer; i:str; quit:boolean;
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
var cn:integer; i:str;
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

procedure mmkey(var i:str);
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

procedure mainmenu;
var nb,inte:integer; abort,next:boolean; ii:str; rl:real; mr:mailrec;
begin
  dump;tleft;nl;nl; macok:=true; ret:=200;
  if mmnu in thisuser.defaults then printfile('gfiles\mainmenu.msg');
  print('T - '+tlef);
  if boards[board].key=' ' then i:='['+cstr(board)+'] ' else
    i:='['+boards[board].key+'] ';
  i:=i+'['+boards[board].name+'] :';
  prt(i); helpl:='@';
  if onekey in thisuser.defaults then mmkey(i) else input(i,20);
  helpl:=#0;
  if length(i)=1 then case i[1] of
    '?':if not (mmnu in thisuser.defaults) then
          begin nl;nl; printfile('gfiles\mainmenu.msg'); end;
    'O':begin
          helpl:='O';nl;nl; ynq('Hangup?  Sure? ');
          if yn then begin
            cls;
            printfile('gfiles\logoff.msg');
            hangup:=true;
            hungup:=false;
          end;
        end;
    '*':boardlist;
    'X':if mmnu in thisuser.defaults then
          thisuser.defaults:=thisuser.defaults-[mmnu]
        else
          thisuser.defaults:=thisuser.defaults+[mmnu];
    'D':default;
    'Y':yourinfo;
    'I':begin pver; printfile('gfiles\logon.msg'); printfile('gfiles\system.msg'); end;
    'C':reqchat;
    '$':chpw;
    'R':removem;
    'U':ulist;
    'E':smail(false);
    'F':begin irt:='Feedback'; imail(1); end;
    'S':scan1;
    'P':begin post; savebase; end;
    'T':dloads;
    'M':readmail;
    'Q':qscan(next,true);
    'G':gfiles;
    'N':nscan;
    'W':wamsg;
    'V':vote;
    'L':printfile('gfiles\user.log');
    'A':abbs;
    'H':mmacro;
    'K':delmail;
    'J':prg(false);
    'Z':prg(true);
    '.':chains;
    'B':printfile('gfiles\bbslist.msg');
    '!':if cs then begin
          print('Enter name or number of person.'); prt(':');
          finduser(inte); if inte>0 then vali(inte);
        end;
 end else
  begin
    if copy(i,1,2)='//' then i:=copy(i,3,length(i)-2);
    if i='/O' then hangup:=true;
    if i='/E' then smail(true);
    if i='/K' then if onekey in thisuser.defaults then thisuser.defaults:=
      thisuser.defaults-[onekey] else thisuser.defaults:=thisuser.defaults+[onekey];
    if (i='UEDIT') and cs then dos('U');
    if (i='STATUS') and cs then pstat;
    if (i='IVOTES') AND cs then begin sysoplog('Init Votes'); initvotes; end;
    if (i='LOG') and cs then begin
      close(sysopf);
      printfile('gfiles\sysop.log');
      append(sysopf);
    end;
    if (i='YLOG') and cs then printfile('gfiles\ysysop.log');
    if (i='TEDIT') and cs then dos('E');
    if (i='/?') and cs then printfile('gfiles\sysopmnu.msg');
    if (i='DOS') and cs then dos('D');
    if (i='VER') then pver;
    if (i='OLDUSERS') and cs then oldusers;
    if (i='ZLOG') and cs then zlog;
    if (i='QUIT') and so then
      if checkpw then
        begin doneday:=true; hangup:=true; elevel:=1; end;
    if (i='BOARDEDIT') and so then begin sysoplog('Boardedit'); boardedit; end;
    if (i='DLBOARDEDIT') and so then begin sysoplog('DLBoardedit'); dlboardedit; end;
    if (i='MAILR') and so then
      if checkpw then begin sysoplog('Mailr'); mailr; end;
    if (i='CHAINS') and so then begin sysoplog('Change Chains'); chchains; end;
    if (i='CHUSER') and so then chuser;
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
end;

label reent,reent1;

begin
  getdir(0,i); ovrpath(i);
  errorptr:=ofs(erhnd);
  if ret>127 then begin
    iport;
    if ret=200 then
      goto reent;
    if ret=201 then
      goto reent1;
  end;
  ret:=ret+128;
  init;
  repeat
    reent1: getcaller;
    if not doneday then begin
      if getuser then newuser;
      macok:=true;
      if not hangup then
        if logon then
          readmail;
    end;
    flush(sysopf);
    if thisuser.age=0 then getnewinfo;
    while not hangup do
      reent: mainmenu;
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
end.