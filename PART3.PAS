overlay procedure chuser;
var n:integer;
begin
  if checkpw then begin
    prt('Which user? ');
    finduser(n);
    if n>0 then begin
      thisuser.sl:=realsl;
      reset(uf);
      seek(uf,usernum);
      write(uf,thisuser);
      seek(uf,n);
      read(uf,thisuser);
      close(uf);
      realsl:=thisuser.sl;
      usernum:=n;
      sysoplog('#*#*#*# Changed to '+nam);
      topscr;
    end;
  end;
end;

overlay procedure chchains;
var i,i1:str; n,c1,c2:integer; f:file of chnft; c:chnft; ch,ch1:char; done:boolean;
    f1:file;
begin
  assign(f,'gfiles\chains.dat');
  if checkpw then
    repeat
      cls; done:=false;
      print('N  Filename  Description                               SL   AR ANSI');
      print('=  --------  ========================================  ---  == ----');
      for c1:=1 to numchns do begin
        prompt(mn(c1,1)+'  '+mln(chns[c1].filen,8)+'  '+mln(chns[c1].descr,40)+'  '+
              mn(chns[c1].sl,3)+'  ');
        if chns[c1].ar='@' then prompt('   ') else prompt(chns[c1].ar+'  ');
        if chns[c1].ansir then print('RQD') else nl;
      end;
      nl; nl;
      prt('I:nsert, D:elete, Q:uit : ');
      onek(ch,'QID');
      case ch of
        'Q':done:=true;
        'I':if numchns=9 then begin
              print('Can only have 9.');
              prompt('Press return.');
              input(i,3);
            end else chcha;
        'D':if n>0 then begin
              prt('Delete which? '); mpl(1); input(i,1); c1:=value(i);
              if (c1>0) and (c1<=numchns) then begin
                nl;
                print('Filename: '+chns[c1].filen);
                print('Description: '+chns[c1].descr);
                nl;
                ynq('Delete it? ');
                if yn then begin
                  numchns:=numchns-1;
                  for c2:=c1 to numchns do
                    chns[c2]:=chns[c2+1];
                  rewrite(f); for c1:=1 to numchns do write(f,chns[c1]);
                  close(f);
                end;
              end;
            end;
      end;
    until done or hangup;
end;

overlay procedure oldusers;
type n=record
         name:string[25];
         number:integer;
         laston:string[10];
         lastonn:integer;
       end;

var c1,c2,c3:integer; u:userrec;
    x:array[1..maxusers] of n;
    x1,x2:n;
    abort,next:boolean;
    i:str;
begin
  prompt('Sorting ');
  reset(uf); c1:=0;
  for c2:=1 to filesize(uf)-1 do begin
    seek(uf,c2); read(uf,u);
    if not u.deleted then begin
      c1:=c1+1;
      with x[c1] do begin
        name:=u.name;
        number:=c2;
        laston:=u.laston;
        lastonn:=daynum(u.laston);
      end;
    end;
  end;
  print(cstr(c1)+' users...'); nl; nl;
  for c2:=1 to c1-1 do
    for c3:=c2+1 to c1 do
      if (x[c2].lastonn>x[c3].lastonn) or
        ((x[c2].lastonn=x[c3].lastonn) and (x[c2].name>x[c3].name)) then begin
        x1:=x[c2];
        x[c2]:=x[c3];
        x[c3]:=x1;
      end;
  abort:=false; c2:=1; c3:=daynum(date);
  while (c2<=c1) and (not abort) do begin
    i:=cstr(c3-x[c2].lastonn); while length(i)<4 do i:=' '+i;
    i:=mln(mln(x[c2].name+' #'+cstr(x[c2].number),34)+x[c2].laston,45)+i;
    printacr(i,abort,next);
    c2:=c2+1;
  end;
  close(uf);
end;

overlay procedure pstat;
var c:char;
begin
  outkey(chr(12));
  with systat do begin
    print('New User Pass   : '+boardpw);
    prompt('Board is        : '); if closedsystem then print('Closed') else print('Open');
    print('Number Users    : '+cstr(users));
    print('Number calls    : '+cstr(callernum));
    print('Date            : '+lastdate);
    print('Time            : '+time);
    print('Active today    : '+cstr(activetoday));
    print('Calls today     : '+cstr(callstoday));
    print('M posted today  : '+cstr(msgposttoday));
    print('E sent today    : '+cstr(emailtoday));
    print('F sent today    : '+cstr(fbacktoday));
    print('U today         : '+cstr(uptoday));
    prompt('Sysop           : '); if sysop then print('Available')
      else print('NOT Available');
    print('F waiting       : '+cstr(fw));
    print('Disk free space : '+cstr(freek(0))+'k');
    prompt('Sysop hours     : ');
    if lowtime=hitime then
      print('None')
    else
      print(tch(cstr(lowtime div 60))+':'+tch(cstr(lowtime mod 60))+' to '+
                tch(cstr(hitime div 60))+':'+tch(cstr(hitime mod 60)));

  end;
  if not useron then begin
    nl;nl;print('Hit any key');
    getkey(c);
  end;
end;

overlay procedure initvotes;
var vdata:file of vdatar; cv,tv,ii:integer; i,i1,i2:str; vd:vdatar; t1,tf:boolean;
    u1:userrec;
begin
  begin
    assign(vdata,'gfiles\voting.dat'); {$I-} reset(vdata); {$I+}
    if ioresult<>0 then begin
      rewrite(vdata); vd.question:='<< NO QUESTION >>'; vd.numa:=0;
      for cv:=0 to 8 do write(vdata,vd);
    end;
    repeat
      cls;
      for cv:=1 to 9 do begin
        seek(vdata,cv-1); read(vdata,vd);
        print(cstr(cv)+': '+vd.question);
      end;
      prt('Which? '); input(i,2);
      ii:=value(i); t1:=false;
      if (ii>0) and (ii<10) then begin
        cv:=1; t1:=true;
        print('Enter new question:'); prt(':');
        inputl(vd.question,79);
        if vd.question='' then begin vd.numa:=0; vd.question:='<< NO QUESTION >>';
        end else begin
          vd.answ[0].ans:='No Comment';
          vd.answ[0].numres:=0;
          nl; print('Enter blank line for last answer,');
          print('max 9 answers, 25 chars/answer');
          tf:=false;
          repeat
            prt(cstr(cv)+':'); inputl(vd.answ[cv].ans,25); vd.answ[cv].numres:=0;
            if vd.answ[cv].ans='' then begin
              tf:=true;
              if cv=1 then vd.question:='<< NO QUESTION >>'
            end else cv:=cv+1;
          until hangup or (cv=10) or tf;
          vd.numa:=cv-1;
        end;
        seek(vdata,ii-1); write(vdata,vd);
        vqu[ii]:= vd.numa<>0;
        reset(uf); for cv:=1 to filesize(uf)-1 do begin
          seek(uf,cv); read(uf,u1); u1.vote[ii]:=0; seek(uf,cv); write(uf,u1);
        end;
        close(uf);
        thisuser.vote[ii]:=0;
      end;
    until (not t1) or hangup;
    close(vdata);
  end;
end;

overlay procedure boardedit;
var i1,i2,ii:integer; c:char; ij:str; abort,next:boolean; st:str;
begin
 if checkpw then
 repeat
  cls; abort:=false;
  printacr('NN K Name                           Filename     RSL PSL MaxM Password   AR An',abort,next);
  printacr('-- = ------------------------------ ============ --- === ---- ========== -- ==',abort,next);
  ii:=1;
  while (ii<=numboards) and (not abort) do
    with boards[ii] do begin
      st:=mn(ii,2)+' '+key+' '+mln(name,30)+' '+mln(filename,12)+' '+mn(sl,3)+' '+mn(postsl,3)+' ';
      st:=st+mn(maxmsgs,3)+'  '+mln(pw,10)+' ';
      if ar='@' then st:=st+'   ' else st:=st+ar+'  ';
      case anonymous of
        yes:st:=st+'Y';
        no:st:=st+'N';
        forced:st:=st+'F';
        dearabby:st:=st+'DA';
      end;
      printacr(st,abort,next);
      ii:=ii+1;
    end;
  nl; prt('D)elete, I)nsert, M)odify, Q)uit  :'); onek(c,'QDIM');
  case c of
    'D':bed;
    'M':bem;
    'I':bei;
  end;
 until (c='Q') or hangup;
end;

overlay procedure mailr;
var ii:integer; mr:mailrec; abort,a:boolean; c:char; u:userrec; is:str;
begin
  {$I-} reset(mailfile); {$I+} c:=' ';
  if ioresult=0 then begin
    reset(uf);
    ii:=filesize(mailfile)-1; c:=' ';
    while (ii>=0) and (c<>'Q') and (not hangup) do begin
      seek(mailfile,ii); read(mailfile,mr);
      if mr.destin<>-1 then begin
        repeat
          seek(uf,mr.destin); read(uf,u);
          print('To '+u.name+' #'+cstr(mr.destin)); a:=true;
          print('Title: '+mr.title);
          readmsg(mr.msg,a,next);
          prt('R,D,Q,<space>  : ');
          if next then c:=' ' else getkey(c); c:=upcase(c); print(c);
          if c='D' then begin
            close(uf); is:=rmail(ii); reset(uf);
            if usernum=mr.destin then thisuser.waiting:=thisuser.waiting-1;
          end;
          nl;nl;
        until (c<>'R') or hangup;
      end;
      ii:=ii-1;
    end;
    close(mailfile);
    close(uf);
  end;
end;

overlay procedure changestuff;
var i,i1:str; c:char; b1,b2:boolean; c1,c2,c3:integer;

  procedure po;
  begin
    clrscr;
    writeln('A. Sysop Password    : "'+systat.sysoppw+'"');
    writeln('B. New User Password : "'+systat.boardpw+'"');
    write('C. System            : ');
    if systat.closedsystem then writeln('Closed') else writeln('Open');
    writeln('D. Com Port Number   : '+cstr(systat.comport));
    writeln('E. Modem Speed       : '+cstr(systat.maxbaud));
    writeln('F. Download Path     : "'+systat.dloadpath+'"');
    write  ('G. Sysop hours       : ');
    if systat.lowtime=systat.hitime then
      writeln('None')
    else
      with systat do
        writeln(tch(cstr(lowtime div 60))+':'+tch(cstr(lowtime mod 60))+' to '+
                tch(cstr(hitime div 60))+':'+tch(cstr(hitime mod 60)));
    writeln; writeln; writeln; writeln;
  end;

begin
  if checkpw then begin
    repeat
      b1:=false;
      repeat
        po;
        gotoxy(1,10);
        write('Which (A-F,Q=Quit) ? ');
        clreol;
        read(kbd,c);
        c:=upcase(c);
      until (c in ['A'..'G','Q']) or hangup;
      writeln(c);
      case c of
        'Q':b1:=true;
        'A':chsta;
        'B':chstb;
        'C':chstc;
        'D':chstd;
        'E':chste;
        'F':begin
              pmsg(1);
              write('Do you want to do this? ');
              if yn then begin
                pmsg(2);
                writeln('Current path: '+systat.dloadpath);
                writeln('Just hit enter for no change.'); writeln;
                write('Path: ');
                input(i,79);
                if (not (i[1] in ['A'..'E'])) or (i[2]<>':') or
                   (i[length(i)]<>'\') then i:='';
                if i<>'' then begin
                  writeln; writeln; writeln('Path: '+i);
                  writeln; write('Is this what you want? ');
                  if yn then systat.dloadpath:=i;
                end;
              end;
            end;
        'G':chstg;
      end;
    until b1;
    savesystat;
  end;
end;

overlay procedure dlboardedit;
var i1,ii,culb,i2:integer;
    c:char; abort,next,done:boolean;
    ij:str;
    d:dlnscan;
begin
 if checkpw then
 repeat
  cls; done:=false; abort:=false;
  printacr('NN Directory Name            Filename     DSL MaxF  Password',abort,next);
  printacr('-- ========================= ------------ === ----  ========',abort,next);
  ii:=0;
  while (ii<=maxulb) and (not abort) do
    with uboards[ii] do begin
      printacr(mn(ii,2)+' '+mln(name,25)+' '+mln(filename,12)+' '+mn(dsl,3)+' '+mn(maxfiles,3)+'   '+
         mln(password,10),abort,next);
      ii:=ii+1;
    end;
  nl; prt('D)elete, I)nsert, M)odify, Q)uit  :'); onek(c,'QDIM');
  case c of
    'Q':done:=true;
    'D':dlbed;
    'M':dlbem;
    'I':dlbei;
  end;
 until done or hangup;
end;

overlay procedure init;
var a,b,c:integer;
    vdf:file of vdatar;
    vd:vdatar;
    fi:text;
    i:str;
    f:file;
    ch1:char;
    help:array[0..32000] of char;
    f1:file of chnft;
begin
  if daynum(date)=0 then begin
    clrscr;
    writeln('You need to set the date & time first.');
    halt;
  end;
  initp1;
  assign(f1,'gfiles\chains.dat');
  numchns:=0;
  {$I-} reset(f1); {$I+}
  if ioresult=0 then begin
    while not eof(f1) do begin
      numchns:=numchns+1;
      read(f1,chns[numchns]);
    end;
    close(f1);
  end;
  assign(f,'gfiles\help.msg');
  for ch1:='0' to '^' do helpi[ch1]:=0;
  {$I-} reset(f,1); {$I+}
  if ioresult=0 then begin
    blockread(f,help[1],32000,a);
    close(f);
    b:=0;
    while (b<a) do begin
      if help[b]='|' then begin
        ch1:=help[b+1];
        if ch1 in ['0'..'^'] then begin
          c:=b;
          while (help[c]<>#10) and (abs(c-b)<80) do c:=c+1;
          c:=c+1;
          if c<a then helpi[ch1]:=c;
        end;
      end;
      b:=b+1;
    end;
  end;
  assign(vdf,'gfiles\voting.dat');
  {$I-} reset(vdf); {$I+}
  if ioresult=0 then begin
    for a:=1 to 9 do begin
      read(vdf,vd);
      vqu[a]:=vd.numa<>0;
    end;
    close(vdf);
  end else for a:=1 to 9 do vqu[a]:=false;
  a:=freek(0);
  errorptr:=ofs(erhnd);
end;

overlay procedure movemsg(var cn:integer);
var mr:messagerec; i:str; c1,c2,c3,ob:integer; done:boolean;
begin
  nl; nl; if (cn>0) and (cn<=tnum) then begin
    print('Move message'); c1:=0; done:=false;
    repeat
      prt('To which board (1-'+cstr(numboards)+') ?=list, Q=Quit :');
      input(i,3);
      if (i='') or (i='Q') then done:=true;
      if i='?' then begin
        nl;
        for c2:=1 to numboards do
          print(cstr(c2)+': '+boards[c2].name);
        nl;
      end;
      c1:=value(i);
      if (c1>0) and (c1<=numboards) then done:=true;
    until done or hangup;
    if (c1>0) and (c1<=numboards) then begin
      mr:=mary[cn];
      mary[0].message.number:=tnum-1;
      for c2:=cn+1 to tnum+1 do
        mary[c2-1]:=mary[c2];
      bchanged:=true;
      savebase;
      ob:=board;
      board:=c1;
      iscan;
      if tnum>=boards[board].maxmsgs then deletem(1);
      mary[0].message.number:=tnum+1;
      mary[tnum]:=mr;
      bchanged:=true;
      savebase;
      board:=ob;
      iscan;
      if cn>tnum then cn:=tnum;
      print('Moved.');
    end;
  end;
end;

overlay procedure hangupphone;
var rl:real; try:integer;
  procedure dely(r:real);
  var r1:real;
  begin
    r1:=timer;
    while abs(timer-r1)<r do;
  end;

begin
  try:=0;
  term_ready(false);
  while (try<2) and cdet do begin
    dely(2.0);
    pr1(#1#1#1);
    rl:=timer;
    while (cinkey<>'0') and (abs(timer-rl)<2.0) do;
    dely(0.8);
    pr('ATH');
    try:=try+1;
    dely(0.3);
  end;
end;

overlay procedure zlog;
var d1:zlogt; n:integer; i:str; zf:file of zlogt; abort,next:boolean;

  function f(x,n:integer):str;
  var i:str;
  begin
    i:=cstr(x);
    while length(i)<n do
      i:=' '+i;
    f:=i;
  end;

begin
  assign(zf,'gfiles\zlog.dat');
  {$I-} reset(zf); {$I+}
  if ioresult=0 then begin
    abort:=false;
    read(zf,d1);
    printacr(
      '  Date     Calls  Active   Posts   Email   Fback     U/L    %Act   T/user',abort,next);
    printacr(
      '--------   -----  ------   -----   -----   -----     ---    ----   ------',abort,next);
    while (not abort) and (d1.date<>'') do begin
      i:=d1.date+f(d1.calls,8)+f(d1.active,8)+f(d1.post,8)+f(d1.email,8)+
         f(d1.fback,8)+f(d1.up,8)+f(trunc(100.0*d1.active/1440.0),8);
      if d1.calls>0 then i:=i+f(d1.active div d1.calls,9);
      printacr(i,abort,next);
      if eof(zf) then
        abort:=true
      else
        read(zf,d1);
    end;
  end;
  close(zf);
end;

