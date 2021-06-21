Program dloads;

                      {*****************************}
                      {Copyright (c) 1986 Wayne Bell}
                      {*****************************}

{$V-} {$C-}
{$I COMMON.PAS}

var ulff:file of ulfrec;
    crc,culb:integer;
    sortbd,doneft:boolean;
    ldat:str;
    ymodem,ucrc,bnp:boolean;
    chksum:byte;
    lrn:integer;
    lfn:str;
    ft:byte;
    ymbtt:real;
    ymbindx:integer;
    ymbary:array[1..20] of record
      fn:string[80];
      tt:real;
    end;

function dcs:boolean;
begin
  dcs:=cs or (thisuser.dsl>=100);
end;

function ratio:real;
begin
  if thisuser.uk=0 then
    ratio:=0
  else
    if thisuser.dk=0 then
      ratio:=100.0
    else
      ratio:=1.0*thisuser.uk/thisuser.dk;
end;

function ratios:str;
var s:str;
begin
  s:=cstrr(ratio*10000,10);
  while length(s)<5 do s:='0'+s;
  s:=copy(s,1,length(s)-4)+'.'+copy(s,length(s)-3,4);
  ratios:=s;
end;

function stripname(i:str):str;
var i1:str; n:integer;
  function nextn:integer;
  var n:integer;
  begin
    n:=pos(':',i1);
    if n=0 then
      n:=pos('\',i1);
    if n=0 then
      n:=pos('/',i1);
    nextn:=n;
  end;
begin
  i1:=i;
  while nextn<>0 do
    i1:=copy(i1,nextn+1,80);
  stripname:=i1;
end;

function tcheck(s:real; i:integer):boolean;
var r:real;
begin
  r:=timer-s;
  if r<0.0 then r:=r+86400.0;
  if (r<0.0) or (r>32760.0) then r:=32766.0;
  if trunc(r)>i then tcheck:=false else tcheck:=true;
end;

function tchk(s:real; i:real):boolean;
var r:real;
begin
  r:=timer;
  if r<s then r:=r+86400.0;
  if (r-s)>i then tchk:=false else tchk:=true;
end;

function uc(s:str):str;
var x:str; i:integer;
begin
  x:=s;
  for i:=1 to length(s) do
    x[i]:=upcase(x[i]);
  uc:=x;
end;

procedure ymbadd(fn:str);
var t1,t2:real; f:file; inte:integer;
begin
  nl;
  assign(f,fn); {$I-} reset(f,1024); {$I+}
  if ioresult<>0 then
    print('File doesn''t exist')
  else begin
    inte:=value(spd); if inte=0 then inte:=1200;
    t1:=(filesize(f))*12960.0/inte;
    close(f);
    t2:=ymbtt+t1;
    if t2>nsl then
      print('Not enough time left in queue.')
    else
      if ymbindx=20 then
        print('Too many files in queue.')
      else begin
        ymbindx:=ymbindx+1;
        ymbary[ymbindx].fn:=fn;
        ymbary[ymbindx].tt:=t1;
        ymbtt:=t2;
        print('File added to batch queue.');
        print('Batch - Files: '+cstr(ymbindx)+'  Time: '+ctim(ymbtt));
      end;
  end;
  nl;
end;

procedure ymbdel(n:integer);
var c:integer;
begin
  if (n<=ymbindx) and (n>0) then begin
    ymbtt:=ymbtt-ymbary[n].tt;
    if n=ymbindx then
      ymbindx:=ymbindx-1
    else begin
      for c:=n to ymbindx-1 do begin
        ymbary[c].fn:=ymbary[c+1].fn;
        ymbary[c].tt:=ymbary[c+1].tt;
      end;
      ymbindx:=ymbindx-1;
    end;
  end;
end;

{$I DLP1.PAS}

procedure i1;
begin
  culb:=1;
  ldat:=thisuser.laston;
  ymbtt:=0.0;
  ymbindx:=0;
end;

function exist(fn:str):boolean;
var f:file;
begin
  assign(f,fn);
  {$I-} reset(f); {$I+}
  if ioresult=0 then begin close(f); exist:=true end else exist:=false;
end;

function align(fn:str):str;
var f,e,t:str; c,c1:integer;
begin
  c:=pos('.',fn);
  if c=0 then begin
    f:=fn; e:='   ';
  end else begin
    f:=copy(fn,1,c-1); e:=copy(fn,c+1,3);
  end;
  while length(f)<8 do f:=f+' ';
  while length(e)<3 do e:=e+' ';
  if length(f)>8 then f:=copy(f,1,8);
  if length(e)>3 then e:=copy(e,1,3);
  c:=pos('*',f); if c<>0 then for c1:=c to 8 do f[c1]:='?';
  c:=pos('*',e); if c<>0 then for c1:=c to 3 do e[c1]:='?';
  c:=pos(' ',f); if c<>0 then for c1:=c to 8 do f[c1]:=' ';
  c:=pos(' ',e); if c<>0 then for c1:=c to 3 do e[c1]:=' ';
  align:=f+'.'+e;
end;

function fit(f1,f2:str):boolean;
var tf:boolean; c:integer;
begin
  tf:=true;
  for c:=1 to 12 do
    if (f1[c]<>f2[c]) and (f1[c]<>'?') then tf:=false;
  fit:=tf;
end;

procedure iscan(var pl:integer);
var f:ulfrec;
begin
  assign(ulff,'gfiles\'+uboards[culb].filename+'.DIR');
  {$I-} reset(ulff); {$I+}
  if ioresult<>0 then begin
    rewrite(ulff);
    f.blocks:=0;
    write(ulff,f);
  end;
  seek(ulff,0);
  read(ulff,f);
  pl:=f.blocks;
  bnp:=false;
end;

procedure recno(fn:str; var pl,rn:integer);
var c:integer;
    f:ulfrec;
begin
  fn:=align(fn);
  iscan(pl); rn:=0; c:=1;
  while (c<=pl) and (rn=0) do begin
    seek(ulff,c); read(ulff,f);
    if pos('.',f.filename)<>9 then begin
      f.filename:=align(f.filename);
      seek(ulff,c); write(ulff,f);
    end;
    if fit(fn,f.filename) then rn:=c;
    c:=c+1;
  end;
  lrn:=rn;
  lfn:=fn;
end;

procedure nrecno(fn:str; var pl,rn:integer);
var c:integer;
    f:ulfrec;
begin
  rn:=0;
  if (lrn<pl) and (lrn>=0) then begin
    c:=lrn+1;
    while (c<=pl) and (rn=0) do begin
      seek(ulff,c); read(ulff,f);
      if pos('.',f.filename)<>9 then begin
        f.filename:=align(f.filename);
        seek(ulff,c); write(ulff,f);
      end;
      if fit(lfn,f.filename) then rn:=c;
      c:=c+1;
    end;
    lrn:=rn;
  end;
end;

procedure return;
var f:file;
begin
  assign(f,'bbs.com');
  print('Returning to BBS...');
  remove_port;
  if hangup then term_ready(false);
  execute(f);
end;

procedure pbn(var abort:boolean);
var i,i1:str; next:boolean;
begin
  if not bnp then begin
    nl;
    i:=uboards[culb].name+' #'+cstr(culb);
    i1:='---'; while length(i1)<length(i) do i1:=i1+'-';
    nl; nl;
    printacr(i,abort,next);
    printacr(i1,abort,next);
    nl;
  end;
  bnp:=true;
end;

procedure dlx(f1:ulfrec; rn:integer; var abort:boolean);
var inte,pl,c:integer; ok,tl:boolean; u:userrec; rl:real; i,ii:str;
begin
    nl; nl;
    print('Filename : "'+f1.filename+'"');
    print('Desc.    : '+f1.description);
    print('# blocks : '+cstr(f1.blocks)+'-'+cstr((f1.blocks+7)div 8));
    print('Apx. time: '+ctim(rte*f1.blocks));
    reset(uf); seek(uf,f1.owner); read(uf,u); close(uf);
    print('U/L by   : '+u.name+' #'+cstr(f1.owner));
    print('U/L on   : '+f1.date);
    print('Times D/L: '+cstr(f1.nacc));
    ft:=f1.ft;
    if ft<>255 then print('File type: '+cstr(ft));
    if timer<timeon then timeon:=timeon-24.0*60*60;
    tl:=(nsl>f1.blocks*rte);
    if tl or (copy(f1.filename,1,4)='WWIV') then begin
      if exist(systat.dloadpath+f1.filename) then begin
        send1(systat.dloadpath+f1.filename,ok,abort);
        if ok then begin
          f1.nacc:=f1.nacc+1;
          seek(ulff,rn);
          write(ulff,f1);
          print('Your upload/download ratio is now : '+ratios);
        end;
      end else print('File isn''t really there!');
    end else print('Not enough time left to D/L');
end;

procedure dl(fn:str);
var pl,rn:integer; f:ulfrec; abort:boolean;
begin
  recno(fn,pl,rn); abort:=false;
  if rn=0 then print('File not found.') else begin
    while (rn<>0) and (not abort) and (not hangup) do begin
      seek(ulff,rn); read(ulff,f); dlx(f,rn,abort);
      nrecno(fn,pl,rn);
    end;
  end;
  close(ulff);
end;

procedure dl1(n:integer);
var f1:ulfrec; abort:boolean;
begin
  nl; nl;
  seek(ulff,n); read(ulff,f1);
  dlx(f1,n,abort);
  nl;
end;

procedure ul(fn:str);
var x,pl,c,cc,ob,np:integer; f,f1:ulfrec; uls,ok:boolean; fi:file of byte;
begin
 if freek(ord(systat.dloadpath[1])-ord('@'))>100 then begin
  uls:=incom;
  ob:=culb;
  ok:=true; fn:=align(fn);
  if (fn[1]=' ') or (fn[10]=' ') then ok:=false;
  for x:=1 to length(fn) do
    if not (fn[x] in ['0'..'9','A'..'Z','.',' ','-']) then ok:=false;
  np:=0; for x:=1 to length(fn) do if fn[x]='.' then np:=np+1;
  if np<>1 then ok:=false;
  if ok then
    if incom then
      if exist(systat.dloadpath+fn) then
        if dcs then begin
          print('There already is one.');
          ynq('Do it anyways? ');
          ok:=yn;
          uls:=false;
        end else
          ok:=false
      else
        ok:=true
    else
      ok:=exist(systat.dloadpath+fn)
  else print('Illegal filename.');
  if (not incom) then
    if ok then print('Am using the file in '+systat.dloadpath)
    else begin print('To put in a file from keyboard, it must already be');
               print('present in the dloads directory.'); end;
  nl; nl;
  if ok and incom and uls then begin
    assign(fi,systat.dloadpath+fn); {$I-} rewrite(fi); {$I+}
    if ioresult<>0 then begin
      {$I-} close(fi); {$I+} cc:=ioresult;
      ok:=false;
    end else begin close(fi); erase(fi); end;
  end;
  if not ok then print('Can''t use that filename, sorry.') else begin
    iscan(pl);
    if pl>=uboards[culb].maxfiles then print('This directory is full.') else begin
      ynq('Upload "'+fn+'" ? ');
      if yn then begin ok:=true;
        nl; print('Please enter a one line description.'); prt(':');
        inputl(f.description,60);
        if (f.description[1]='\') or (rvalidate in thisuser.ac) then begin
          culb:=0;
          close(ulff);
          iscan(pl);
        end;
        if f.description[1]='\' then f.description:=copy(f.description,2,80);
        ok:=true; ft:=255;
        if uls then receive1(systat.dloadpath+fn,ok);
        nl; nl;
        if not ok then print('Not saved.') else begin
          f.filename:=fn;
          f.owner:=usernum;
          f.date:=date;
          f.daten:=daynum(date);
          for x:=1 to 17 do f.res[x]:=0;
          f.ft:=ft;
          f.nacc:=0;
          assign(fi,systat.dloadpath+fn);
          {$I-} reset(fi); {$I+}
          if ioresult=0 then begin
            f.blocks:=trunc((longfilesize(fi)+127.0)/128.0);
            close(fi);
            for x:=pl downto 1 do begin
              seek(ulff,x); read(ulff,f1);
              seek(ulff,x+1); write(ulff,f1);
            end;
            seek(ulff,1);
            write(ulff,f);
            seek(ulff,0); read(ulff,f); f.blocks:=pl+1;
            seek(ulff,0); write(ulff,f);
            sysoplog('Uploaded "'+fn+'" on '+uboards[culb].name);
            print('File successfully uploaded.');
            print('Your upload/download ratio is now : '+ratios);
          end else begin
            print('Oops, system error.  Not saved.');
            sysoplog('Error uploading "'+fn+'"');
          end;
        end;
      end;
    end;
    close(ulff); culb:=ob;
  end;
  nl; nl;
  end else begin
    nl; nl; print('Sorry, not enough disk space.');
    nl;
  end;
end;

procedure idl;
var i:str;
begin
  helpl:='X';
  nl; print('Download -'); nl; prt('Enter filename: '); mpl(12); input(i,12);
  dl(i);
  nl; nl;
end;

procedure iul;
var i:str;
begin
  helpl:='U';
  nl; nl; print('Upload -'); nl; prt('Enter filename: '); mpl(12); input(i,12);
  ul(i);
  nl; nl;
end;

procedure gfn(var fn:str);
begin
  nl; helpl:='L';
  prt('File mask: '); input(fn,12);
  if fn='' then fn:='*.*';
  fn:=align(fn);
end;

function aln(i:str; n:integer):str;
begin
  while length(i)<n do i:=' '+i;
  aln:=i;
end;

procedure pfn(f:ulfrec; var abort,next:boolean);
begin
  printacr(f.filename+':'+aln(cstr(f.blocks),4)+' :'+f.description,abort,next);
end;

procedure searchb(b:integer; fn:str; var abort:boolean);
var oldboard,pl,rn:integer; f:ulfrec;
begin
  oldboard:=culb; culb:=b;
  recno(fn,pl,rn);
  while (rn<=pl) and (not abort) and (not hangup) and (rn<>0) do begin
    seek(ulff,rn); read(ulff,f);
    pbn(abort);
    pfn(f,abort,next);
    nrecno(fn,pl,rn);
  end;
  close(ulff);
  culb:=oldboard;
end;

procedure searchbd(b:integer; ts:str; var abort:boolean);
var oldboard,pl,rn:integer; f:ulfrec; next:boolean;
begin
  oldboard:=culb; culb:=b; iscan(pl);
  rn:=1;
  while (rn<=pl) and (not abort) and (not hangup) do begin
    seek(ulff,rn); read(ulff,f);
    if pos(ts,uc(f.description))<>0 then begin
      pbn(abort);
      pfn(f,abort,next);
    end;
    rn:=rn+1;
  end;
  close(ulff);
  culb:=oldboard;
end;

procedure search;
var fn:str; bn:integer; abort:boolean;
begin
  nl; nl; print('Search all directories.');
  gfn(fn);
  if dcs then bn:=0 else bn:=1; abort:=false;
  while (not abort) and (bn<=maxulb) and (not hangup) do begin
    if uboards[bn].dsl<=thisuser.dsl then searchb(bn,fn,abort);
    bn:=bn+1;
  end;
end;

procedure searchd;
var fn:str; bn:integer; abort:boolean;
begin
  nl; nl; print('Find a description -'); nl;
  print('Enter what to search description for.');
  helpl:='Y'; abort:=false;
  prt(': '); input(fn,20);
  if fn<>'' then begin
    nl; print('Searching for "'+fn+'"'); nl;
    ynq('Search all directories? ');
    if yn then begin
      if dcs then bn:=0 else bn:=1;
      while (not abort) and (bn<=maxulb) and (not hangup) do begin
        if uboards[bn].dsl<=thisuser.dsl then searchbd(bn,fn,abort);
        bn:=bn+1;
      end;
    end else searchbd(culb,fn,abort);
  end;
end;

procedure newfiles(b:integer; var abort:boolean);
var oldboard,pl,rn,ldn:integer; f:ulfrec; next:boolean;
begin
  oldboard:=culb; culb:=b; iscan(pl);
  ldn:=daynum(ldat);
  rn:=1;
  while (rn<=pl) and (not abort) and (not hangup) do begin
    seek(ulff,rn); read(ulff,f);
    if f.daten>=ldn then begin
      pbn(abort);
      pfn(f,abort,next);
    end;
    rn:=rn+1;
  end;
  close(ulff);
  culb:=oldboard;
end;

procedure nf;
var bn:integer; abort:boolean;
begin
  nl; print('Search for new files.'); nl;
  ynq('Search all directories? ');
  if yn then begin
    if dcs then bn:=0 else bn:=1; abort:=false;
    while (not abort) and (bn<=maxulb) and (not hangup) do begin
      if (uboards[bn].dsl<=thisuser.dsl) and
         (bn in thisuser.dlnscn) then newfiles(bn,abort);
      bn:=bn+1;
    end;
  end else newfiles(culb,abort);
end;

procedure delete(rn:integer; var pl:integer);
var f:ulfrec; i:integer;
begin
  if (rn<=pl) and (rn>0) then begin
    pl:=pl-1;
    for i:=rn to pl do begin
      seek(ulff,i+1); read(ulff,f);
      seek(ulff,i); write(ulff,f);
    end;
    seek(ulff,0); f.blocks:=pl; write(ulff,f);
  end;
end;

function gtr(f,f1:ulfrec):boolean;
begin
  if sortbd and (f1.daten<>f.daten) then
    if f1.daten<f.daten then
      gtr:=false
    else
      gtr:=true
  else
    if f1.filename>f.filename then
      gtr:=false
    else
      gtr:=true;
end;

procedure sortd(c:integer);
var oldboard,trn,srn,i,i1,pl:integer; f,f1:ulfrec;
begin
  oldboard:=culb; culb:=c; iscan(pl);
  nl; print('Sorting '+uboards[culb].name);
  for i:=1 to pl-1 do begin
    seek(ulff,i); read(ulff,f); trn:=i;
    for i1:=i+1 to pl do begin
      seek(ulff,i1); read(ulff,f1);
      if gtr(f,f1) then begin
        f:=f1; trn:=i1;
      end;
    end;
    seek(ulff,i); read(ulff,f1); seek(ulff,i);
    write(ulff,f); seek(ulff,trn); write(ulff,f1);
  end;
  close(ulff);
  culb:=oldboard;
end;

procedure sort;
var bn:integer;
begin
  nl; nl; ynq('Sort by date? '); if yn then sortbd:=true else sortbd:=false;
  nl; ynq('Sort all boards? ');
  if yn then
    for bn:=0 to maxulb do
      sortd(bn)
  else
    sortd(culb);
end;

procedure listfiles;
var abort:boolean; fn:str;
begin
  nl; nl; print('List files.');
  gfn(fn); abort:=false;
  searchb(culb,fn,abort);
end;

procedure listf(n:integer; var abort:boolean);
var f:ulfrec; i,i1:str; next:boolean;
begin
  seek(ulff,n); read(ulff,f);
  i:=cstr(n); while length(i)<3 do i:=' '+i;
  i:=i+': '+f.filename;
  while length(i)<20 do i:=i+' ';
  i1:=cstr(f.blocks); while length(i1)<5 do i1:=' '+i1; i:=i+i1;
  i:=i+'  '+f.date+'  '; i1:=cstr(f.owner); while length(i1)<3 do i1:=' '+i1;
  i:=i+i1;
  printacr(i,abort,next);
end;


{$I DLP2.PAS}

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

procedure reqchat;
begin
  nl;nl; if (not sysop) or (rchat in thisuser.ac)
  then begin
    print('Sysop not available.');
  end else begin
    if not chatcall then begin
      helpl:='C'; prt('Reason: '); inputl(i,70);
      if i<>'' then begin
        sysoplog('Chat: '+i);
        print('Chat call now on.');
        sound(440); delay(500); nosound;
        chatr:=i; chatcall:=true;
      end else chatr:='';
    end else
      begin chatcall:=false; print('Chat call turned off.'); chatr:='';end;
  end;
  nl;nl; topscr;
end;

procedure lfi(fn:str; var abort:boolean);
var next:boolean; i1,i2:str;
begin
  if exist(systat.dloadpath+fn) and (not abort) then
    if (pos('.ARC',fn)<>0) or (pos('.LBR',fn)<>0) then begin
      nl;
      i1:=align(fn); i2:=''; while length(i1)>length(i2) do i2:=i2+'-';
      printacr(i1,abort,next);
      printacr(i2,abort,next);
      nl;
      if not abort then begin
        if pos('.ARC',fn)<>0 then arcl(systat.dloadpath+fn,abort);
        if pos('.LBR',fn)<>0 then lbrl(systat.dloadpath+fn,abort);
      end;
      nl;
    end;
end;

procedure lfin(rn:integer; var abort:boolean);
var f:ulfrec;
begin
  seek(ulff,rn); read(ulff,f); lfi(f.filename,abort);
end;

procedure lfii;
var fn:str; pl,rn:integer; abort:boolean;
begin
  helpl:='[';
  nl; print('Enter file to list interior files of');
  prt(': '); mpl(12); input(fn,12);
  recno(fn,pl,rn);
  abort:=false;
  if rn=0 then print('File not found.') else begin
    while (rn<>0) and (not abort) do begin
      lfin(rn,abort);
      nrecno(fn,pl,rn);
    end;
  end;
  close(ulff);
end;

procedure yourinfo;
begin
  nl; nl;
  print('Your name : '+nam);
  print('Your SL   : '+cstr(thisuser.sl));
  print('Your DSL  : '+cstr(thisuser.dsl));
  print('You D/L''d : '+cstr(thisuser.dk)+'K in '+cstr(thisuser.downloads)+' files');
  print('You U/L''d : '+cstr(thisuser.uk)+'K in '+cstr(thisuser.uploads)+' files');
  print('Your ratio: '+ratios);
end;

procedure ftmainmenu;
var ii,i:str; int:integer;
begin
  dump; tleft; nl; nl;
  print('T - '+tlef);
  i:='('+cstr(culb)+')-('+uboards[culb].name+')  :';
  prt(i);
  helpl:='T';
  mmkey(i);
  helpl:=#0;
  if length(i)=1 then case i[1] of
    '?':printfile('gfiles\dlmenu.msg');
    'A':setdirs;
    'Q':doneft:=true;
    'B':browsefiles;
    'U':iul;
    'D':idl;
    'L':listfiles;
    'S':search;
    'F':searchd;
    'C':reqchat;
    'O':begin
          nl;nl; ynq('Hangup?  Sure? '); helpl:='O';
          if yn then begin
            cls;
            printfile('gfiles\logoff.msg');
            hangup:=true;
            hungup:=false;
          end;
        end;
    '*':listboards;
    'P':pointdate;
    'N':nf;
    'R':remove;
    'M':if dcs then move;
    'V':lfii;
    'X':dlbatch;
    'Y':yourinfo;
  end;
  if i='/O' then hangup:=true;
  if (i='SORT') and dcs then sort;
  if (i='REN') and dcs then ren;
  if (i='0') and dcs then culb:=0;
  int:=value(i); if (int>0) and (int<=maxulb) then
    if thisuser.dsl>=uboards[int].dsl then
      if (uboards[int].password='') or dcs then culb:=int else begin
        prt('Password? '); input(i,10);
        if i<>uboards[int].password then
          print('Wrong.')
        else
          culb:=int;
       end;
end;

begin
  iport; i1; doneft:=false;
  while (not doneft) and (not hangup) do
    ftmainmenu;
  return;
end.