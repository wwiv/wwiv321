overlay procedure arcl(fn:str; var abort:boolean);
type ei=record l,h:integer; end;
     archead=record
               name:array[1..13] of char;
               size:ei;
               date,time,crc:integer;
               len:ei;
             end;
var f:file; b:byte;
    head:archead;
    done,next:boolean;

  function unsigned(i:integer):real;
  begin
    if i>=0 then
      unsigned:=int(i)
    else
      unsigned:=65536.0+int(i);
  end;

  function valueei(x:ei):real;
  var rl:real;
  begin
    rl:=unsigned(x.h)*65536.0+unsigned(x.l);
    if rl>=32768.0*65536.0 then
      rl:=65536.0*65536.0-rl+1;
    valueei:=rl;
  end;

  procedure pfn;
  var i,i1:str; try:byte;
  begin
    b:=0; try:=0;
    while not eof(f) and (b<>26) and (try<5) do begin
      blockread(f,b,1);
      try:=try+1;
    end;
    if try>=5 then longseek(f,filesize(f)-2.0);
    if longfilepos(f)+27<longfilesize(f) then begin
      blockread(f,b,1);
      if b<>0 then begin
          if b=1 then begin
          blockread(f,head,sizeof(head)-sizeof(ei));
          head.len:=head.size;
        end else blockread(f,head,sizeof(head));
        i:=''; b:=1;
        while (head.name[b]<>#0) and (b<=13) do begin
          i:=i+head.name[b];
          b:=b+1;
        end;
        i:=align(i)+' ';
        i1:=cstrr(valueei(head.len),10);
        while length(i1)<7 do i1:=' '+i1;
        i:=i+i1;
        printacr(i,abort,next);
      end else done:=true;
      longseek(f,longfilepos(f)+valueei(head.size));
    end;
  end;

begin
  assign(f,fn);
  reset(f,1); done:=false;
  while (longfilepos(f)+27.0<longfilesize(f)) and not (abort or done) do
    pfn;
  close(f);
end;

overlay procedure lbrl(fn:str; var abort:boolean);
var f:file;
    c,n,n1:integer;
    x:record
        st:byte;
        name:array[1..8] of char;
        ext:array[1..3] of char;
        index,len:integer;
        fil:array[1..16] of byte;
      end;
    next:boolean;
    i,i1:str;

begin
  assign(f,fn);
  reset(f,32);
  blockread(f,x,1);
  c:=x.len*4-1;
  for n:=1 to c do begin
    blockread(f,x,1); i:='';
    if (x.st=0) and not abort then begin
      for n1:=1 to 8 do i:=i+x.name[n1];
      i:=i+'.';
      for n1:=1 to 3 do i:=i+x.ext[n1];
      i:=align(i)+' ';
      i1:=cstrr(x.len*128.0,10);
      while length(i1)<7 do i1:=' '+i1;
      i:=i+i1;
      printacr(i,abort,next);
    end;
  end;
  close(f);
end;

overlay procedure remove;
var pl,c,rn:integer; f:ulfrec; fn:str; ff:file; u:userrec; tf:boolean; ch:char;
begin
  print('Enter filename to remove.'); prt(': '); mpl(12);
  input(fn,12);
  if fn<>'' then begin
    recno(fn,pl,rn); ch:=' ';
    while (rn<>0) and (not hangup) and (ch<>'Q') do begin
      seek(ulff,rn); read(ulff,f);
      if (usernum=f.owner) or dcs then begin
        nl; nl;
        print('Filename: "'+f.filename+'"');
        print('Desc.   : '+f.description);
        print('# blocks: '+cstr(f.blocks));
        reset(uf); seek(uf,f.owner); read(uf,u); close(uf);
        print('U/L by  : '+u.name+' #'+cstr(f.owner));
        print('U/L on  : '+f.date);
        ynq('Delete this (Y/N/Q) ? ');
        ansic(3); onek(ch,'QYN');
        if ch='Y' then begin
          delete(rn,pl);
          lrn:=lrn-1;
          sysoplog('Deleted "'+f.filename+'"');
          if dcs then begin
            ynq('Erase file too? ');
            tf:=yn;
          end else tf:=true;
          if tf then begin
            assign(ff,systat.dloadpath+f.filename);
            {$I-} erase(ff); {$I+}
            c:=ioresult;
          end;
        end;
      end;
      nrecno(fn,pl,rn);
    end;
    close(ulff);
  end;
  nl; nl;
end;

overlay procedure move;
var x,pl,c,rn,int,dbn:integer; f,f1:ulfrec; fn:str; ff:file; i:str;
    abort,next:boolean;
begin
  print('Enter filename to move.'); prt(': '); mpl(12);
  input(fn,12);
  if fn<>'' then begin
    recno(fn,pl,rn);
    if rn<>0 then begin
      seek(ulff,rn); read(ulff,f);
      abort:=false; nl; pfn(f,abort,next); nl; nl;
      ynq('Move this? ');
      if yn then begin
        nl;
        for int:=0 to maxulb do
          print(cstr(int)+' : '+uboards[int].name);
        nl; nl;
        prompt('To which directory? '); input(i,3);
        dbn:=value(i); if (dbn=0) and (i<>'0') then dbn:=-1;
        if (dbn<0) or (dbn>maxulb) then print('Can''t move it there.')
        else begin
          delete(rn,pl);
          close(ulff);
          int:=culb; culb:=dbn; iscan(pl);
          for x:=pl downto 1 do begin
            seek(ulff,x); read(ulff,f1);
            seek(ulff,x+1); write(ulff,f1);
          end;
          seek(ulff,1);
          write(ulff,f);
          f.blocks:=pl+1;
          seek(ulff,0); write(ulff,f);
          culb:=int;
          sysoplog('Moved "'+f.filename+'"');
        end;
      end;
    end;
    close(ulff);
  end;
end;

overlay procedure ren;
var pl,c,rn,int,dbn,x:integer; f:ulfrec; fn,fd:str; ff:file; i:str;
begin
  print('Enter filename to rename.'); prt(': '); mpl(12);
  input(fn,12); nl; nl;
  if fn<>'' then begin
    recno(fn,pl,rn);
    if rn<>0 then begin
      seek(ulff,rn); read(ulff,f);
      print(f.filename+' : '+f.description); nl; nl;
      ynq('Rename this stuff? ');
      if yn then begin
        prt('New filename? '); mpl(12); input(fn,12);
        if fn<>'' then begin
          if exist(systat.dloadpath+fn) then print('Can''t use that filename.') else begin
            assign(ff,systat.dloadpath+f.filename);
            {$I-} rename(ff,systat.dloadpath+fn); {$I+} x:=ioresult;
            f.filename:=align(fn);
          end;
        end;
        print('New description -'); prt(': '); inputl(fd,60);
        if fd<>'' then f.description:=fd;
        seek(ulff,rn); write(ulff,f);
      end;
    end;
    close(ulff);
  end;
end;

overlay procedure browsefiles;
var pl,n,nfl,cn:integer; f:ulfrec; i,i1:str; abort,next,list,done:boolean;
begin
  iscan(pl); nl; nl; helpl:='B';
    print('('+uboards[culb].name+') - '+cstr(pl)+' files');
    if pl<>0 then begin
    nl; abort:=false; done:=false;
    prompt('Start at? '); input(i,3); cn:=value(i); if cn=0 then cn:=1;
    if i='Q' then cn:=0; if cn>pl then cn:=0;
    if cn>0 then begin list:=true;
      repeat
        tleft;
        if list then begin
          if cn>pl then cn:=1;
          nfl:=0;
          print(' NN: filename.ext   blcks  mm/dd/yy  frm');
          while (not hangup) and (nfl<10) and (not abort) and (cn<=pl) do begin
            listf(cn,abort); cn:=cn+1; nfl:=nfl+1;
          end;
          list:=false;
        end;
        nl; prt('Browse: (1-'+cstr(pl)+',^'+cstr(cn)+'),U,D,Q,L,? :');
        input(i,3); n:=0;
        if (i='') and (cn>pl) then i:='Q';
        n:=value(i); if (n>0) and (n<=pl) then begin cn:=n; i:='D'; end;
        if i='?' then begin print('U:pload     D:ownload');
                            print('Q:uit       L:ist files'); end;
        if i='Q' then done:=true;
        if i='L' then list:=true;
        if i='U' then begin close(ulff); iul; iscan(pl); end;
        if i='D' then begin
          if n=0 then begin print('Download -'); nl; prt('Which number? ');
            input(i1,3); n:=value(i1); end;
          if (n>0) and (n<=pl) then dl1(n);
        end;
      until done or hangup;
    end;
  end;
  close(ulff);
end;

overlay procedure setdirs;
var i:str; c1,c2:integer; done:boolean;

  procedure listit;
  var c:integer; abort,next:boolean; i:str;
  begin
    nl; print('Dir''s to scan marked with "*"'); nl;
    if dcs then c:=0 else c:=1;
    abort:=false;
    while (c<=maxulb) and (not abort) and (not hangup) do begin
      if c in thisuser.dlnscn then
        i:='* '
      else
        i:='  ';
      if c<10 then i:=i+' ';
      i:=i+cstr(c)+'. '+uboards[c].name;
      if (thisuser.dsl>=uboards[c].dsl) then printacr(i,abort,next);
      c:=c+1;
    end;
    nl;
  end;

begin
  listit; done:=false;
  repeat
    nl; prt('Enter number, Q, ? : ');
    input(i,3);
    if i='Q' then done:=true;
    if i='?' then listit;
    c1:=value(i);
    if not (i[1] in ['0'..'9']) then c1:=-1;
    if (c1<0) or ((c1<1) and (not dcs)) then c1:=-1;
    if (c1>maxulb) then c1:=-1;
    if c1<>-1 then
      if thisuser.dsl>=uboards[c1].dsl then begin
        nl;
        if c1 in thisuser.dlnscn then begin
          print(uboards[c1].name+' will NOT be scanned.');
          thisuser.dlnscn:=thisuser.dlnscn-[c1];
        end else begin
          print(uboards[c1].name+' WILL be scanned.');
          thisuser.dlnscn:=thisuser.dlnscn+[c1];
        end;
      end;
  until done or hangup;
end;

overlay procedure pointdate;
var i:str; n:integer;
begin
  nl; nl; nl; helpl:='P';
  print('Enter limiting date for new files -');
  print('Date is currently set to '+ldat);
  print(' mm/dd/yy');
  prt(':'); mpl(8); input(i,8);
  nl; nl;
  n:=daynum(i);
  if n=0 then
    print('Illegal date.')
  else
    ldat:=i;
  nl; print('Current limiting date is '+ldat);
end;

overlay procedure listboards;
var b:integer; i:str; abort,next:boolean;
begin
  nl;nl; print('Directories available to you:'); nl; nl;
  if dcs then b:=0 else b:=1; abort:=false;
  while (b<=maxulb) and (not abort) and (not hangup) do begin
    if uboards[b].dsl<=thisuser.dsl then begin
       i:=cstr(b);
       if length(i)=1 then i:=' '+i;
       i:=i+' : '+uboards[b].name;
       printacr(i,abort,next);
    end;
    b:=b+1;
  end;
  nl;nl;
end;

overlay procedure dlbatch;
var ch:char; n:integer; hua,done:boolean; dok,abort,next:boolean; i:str;

  function info(n:integer):str;
  var i,i1:str;
  begin
    i:=cstr(n)+'. '; if length(i)=3 then i:=' '+i;
    i:=i+stripname(ymbary[n].fn);
    while length(i)<20 do i:=i+' ';
    i:=i+ctim(ymbary[n].tt);
    info:=i;
  end;

begin
  done:=false; helpl:=']';
  if ymbindx=0 then
    print('Batch queue empty.')
  else
    repeat
      nl;
      prt('Batch: Q,L,D,R,C,? : ');
      onek(ch,'QLDRC?');
      case ch of
        'Q':done:=true;
        '?':begin
              print('Q:uit to D/L Menu   L:ist files in queue');
              print('D:ownload queue     R:emove file from queue');
              print('C:lear queue');
            end;
        'R':begin
              prt('Number to remove (1-'+cstr(ymbindx)+') ? ');
              input(i,2); n:=value(i);
              if (n>0) and (n<=ymbindx) then begin
                ymbdel(n);
                print('Deleted out of queue.');
              end;
              if ymbindx=0 then begin
                done:=true;
                print('Queue empty.');
              end;
            end;
        'D':if incom and (ymbindx>0) then begin
              nl; nl; ynq('Hang up after transfer? ');
              hua:=yn; ymodem:=true; ucrc:=true;
              nl; nl; print('Transmitting batch - Files: '+cstr(ymbindx)+
                            '  Time: '+ctim(ymbtt));
              nl;
              repeat
                if nsl>=ymbary[1].tt then begin
                  send(ymbary[1].fn,dok,true,rte);
                  if dok then
                    sysoplog('Downloaded "'+stripname(ymbary[1].fn)+'"')
                  else
                    sysoplog('Tried D/L "'+stripname(ymbary[1].fn)+'"');
                end;
                ymbdel(1);
              until (not dok) or hangup or (ymbindx<1);
              if dok then
                endbatch;
              done:=true;
              if hua then hangup:=true;
            end;
        'L':begin
              abort:=false; n:=1;
              while (not abort) and (not hangup) and (n<=ymbindx) do begin
                printacr(info(n),abort,next);
                n:=n+1;
              end;
            end;
        'C':begin
              ynq('Clear queue? ');
              if yn then begin
                ymbindx:=0;
                ymbtt:=0.0;
                done:=true;
              end;
            end;
      end;
    until done or hangup;
end;