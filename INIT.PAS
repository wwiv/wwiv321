{$M 7000,0,60000}
program init;

                      {*****************************}
                      {Copyright (c) 1986 Wayne Bell}
                      {*****************************}

Uses
  Crt,Common;

var x:file of astr;
    vdata:file of vdatar;
    vd:vdatar;
    fx:ulrec;
    fi:text;
    ns:pnr; fil:file of pnr;
    boards1:boardrec;
    slf1:file of slr;
    strng:astr;

function exist(fn:astr):boolean;
var f:file;
begin
  assign(f,fn);
  {$I-} reset(f); {$I+}
  if ioresult <> 0 then exist := false else
  begin
    exist := true;
    close(f);
  end;
end;

procedure move(s:astr);
var s1,i:astr; f,f1:text;
begin
  if not exist(s) then writeln('"',s,'" isn''t here.') else begin
    writeln('  Moving '+s);
    assign(f,s); s1:='gfiles\'+s; assign(f1,s1);
    reset(f); rewrite(f1);
    while not eof(f) do begin
      readln(f,i); writeln(f1,i);
    end;
    close(f1); close(f);
    erase(f);
  end;
end;

procedure make(s:astr);
var f:text;
begin
  if not exist('gfiles\'+s) then begin
    writeln('  Creating: ',s);
    assign(f,'gfiles\'+s);
    rewrite(f);
    writeln(f,'This is "'+s+'"');
    close(f);
  end;
end;

procedure make1(s:astr);
var f:text;
begin
  if not exist('gfiles\'+s) then begin
    writeln('  Creating: ',s);
    assign(f,'gfiles\'+s);
    rewrite(f);
    writeln(f);
    close(f);
  end;
end;

begin
  clrscr;
  if exist('gfiles\user.lst') then writeln('Already installed') else begin
    writeln('WWIV v3.20 Initialization Program.');
    writeln('Now beginning initialization.');
    writeln('  Creating directories..');
    mkdir('gfiles'); mkdir('msgs'); mkdir('dloads');
    writeln('  Creating user files..');
    assign(uf,'gfiles\user.lst'); assign(sf,'gfiles\names.lst');
    assign(systatf,'gfiles\status.dat');
    rewrite(uf); write(uf,user);close(uf); rewrite(sf);
    sr.number:=0; sr.name:='';
    write(sf,sr);write(sf,sr);close(sf); rewrite(systatf);
    systat.comport:=0;
    systat.maxbaud:=0;
    while (not (systat.comport in [1,2])) or
    ((systat.maxbaud<>300) and (systat.maxbaud<>1200) and (systat.maxbaud<>2400)) do begin
      write('Which com port (1-2) ? ');
      readln(systat.comport);
      write('Modem speed (300,1200,2400) ? ');
      readln(systat.maxbaud);
    end;
    getdir(0,strng);
    with systat do begin boardpw:=''; sysoppw:='SYSOP';
      hmsg.number:=-32767; hmsg.ltr:='A'; hmsg.ext:=1; users:=0;
      lastdate:=''; callernum:=0; activetoday:=0; callstoday:=0; msgposttoday:=0;
      emailtoday:=0; fbacktoday:=0; uptoday:=0; closedsystem:=false;
      gfiledate:='01/01/85'; dloadpath:=strng[1]+':DLOADS\';
      lowtime:=0; hitime:=0;
      for t:=1 to 100 do res[t]:=0;
    end;
    write(systatf,systat); close(systatf);
    make('WELCOME.MSG');
    make('LOGON.MSG');
    make('LOGOFF.MSG');
    make('SYSTEM.MSG');
    make('NEWUSER.MSG');
    make1('USER.LOG');
    make1('SYSOP.LOG');
    make1('YSYSOP.LOG');
    make1('BBSLIST.MSG');
    make1('NONEWUSR.MSG');
    writeln('  Creating board files..');
    assign(bf,'gfiles\boards.dat');
    with boards1 do begin
      name:='General';
      filename:='board1';
      sl:=10;
      postsl:=10;
      maxmsgs:=50;
      pw:='';
      anonymous:=no;
      ar:='@';
      key:=' ';
    end;
    rewrite(bf); write(bf,boards1); close(bf);
    assign(ulf,'gfiles\uploads.dat'); rewrite(ulf);
    fx.name:='Sysop'; fx.dsl:=100; fx.filename:='ubsysop'; fx.maxfiles:=50; fx.password:='';
    write(ulf,fx);
    fx.name:='Miscellaneous'; fx.dsl:=0; fx.filename:='ub1'; fx.maxfiles:=50; fx.password:='';
    write(ulf,fx);
    close(ulf);
    assign(x,'gfiles\laston.dat'); rewrite(x);
    i:='';
    for t:=1 to 8 do write(x,i);
    close(x);
    assign(vdata,'gfiles\voting.dat');
    rewrite(vdata);
    vd.question:='<< NO QUESTION >>'; vd.numa:=0;
    for t:=1 to 9 do write(vdata,vd);
    close(vdata);
    assign(mailfile,'gfiles\email.dat');
    rewrite(mailfile);
    close(mailfile);
    assign(fi,'gfiles\trashcan.txt');
    rewrite(fi); i:='FUCK'; writeln(fi,i); i:='SID VICIOUS'; writeln(fi,i);
    i:='SYSOP'; writeln(fi,i); i:='JEFF THE RIPPER'; writeln(fi,i);
    close(fi);
    move('mainmenu.msg');
    move('msgmenu.msg');
    move('sysopmnu.msg');
    move('dlmenu.msg');
    move('dosmnu.msg');
    move('wfcmenu.msg');
    if not exist('seclev.dat') then writeln('"seclev.dat" is missing.') else begin
      writeln('  Moving seclev.dat');
      assign(slf,'seclev.dat'); assign(slf1,'gfiles\seclev.dat');
      reset(slf); rewrite(slf1);
      for fw:=0 to 255 do begin read(slf,seclev[fw]); write(slf1,seclev[fw]); end;
      close(slf1);
      close(slf);
      erase(slf);
    end;
    assign(fil,'gfiles\numbers.dat');
    {$I-} reset(fil); {$I+}
    if ioresult<>0 then begin
      rewrite(fil);
      ns.name:='========================================';
      ns.number:='- --- --- ----';
      ns.hs:=1;
      for fw:=1 to 9 do write(fil,ns);
    end; close(fil);
    writeln('WWIV v3.21-TP70 initialization complete.');
    writeln; writeln;
    writeln('Thank you for using WWIV software.  A $25 donation is requested for using');
    writeln('this software.  Please address any correspondences to:');
    writeln;
    writeln('             Wayne Bell');
    writeln('             Box 636');
    writeln('             904 Silver Spur Road');
    writeln('             Rolling Hills Estates, CA  90274');
  end;
end.
