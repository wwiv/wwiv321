program dos;


                      {*****************************}
                      {Copyright (c) 1986 Wayne Bell}
                      {*****************************}

{$C-} {$V-}
{$I COMMON.PAS}

var topheap:^byte;
    i1:str;
    ix:array[1..9] of string[79];
    found,donedos,dld,d1,d2,done,abort:boolean;
    c1,c2,c3:integer;
    f,f1:file of byte;
    x:byte;
    cd:str;
    filenamef,s1,s2,s3:str;
    all:boolean;
    chksum:byte;
    crc:integer;
    ucrc,ymodem:boolean;
    dta:string[44];
    ft:byte;
    lastvar:byte;


function checkpw:boolean;
var i:str;
begin
  prompt('PW? ');
  echo:=false;
  input(i,8);
  echo:=true;
  checkpw:=(i=systat.sysoppw);
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
  r:=timer;
  if r<s then r:=r+86400.0;
  if trunc(r-s)>i then tcheck:=false else tcheck:=true;
end;

function tchk(s:real; i:real):boolean;
var r:real;
begin
  r:=timer;
  if r<s then r:=r+86400.0;
  if (r-s)>i then tchk:=false else tchk:=true;
end;

procedure ymbadd(i:str);
begin
end;

{$I DLP1.PAS}

function okfile(fn:str):boolean;
begin
  okfile:=(pos('.LST',FN)=0) and (pos('.DAT',fn)=0) and (pos('.BRD',fn)=0)
          and (pos('.DIR',fn)=0) and (pos('.LOG',fn)=0);
  if (not so) and (pos('.TXT',fn)=0) and (pos('.MSG',fn)=0)and (pos('.???',FN)=0)
    then okfile:=false;
end;

procedure parse(i1:str);
var c,lp,cp:integer;
begin
  for c:=1 to 9 do ix[c]:='';
  c:=1; lp:=1; cp:=1;
  if length(i1)=1 then ix[1]:=i1;
  while cp<length(i1) do begin
    cp:=cp+1;
    if (i1[cp]=' ') or (cp=length(i1)) then begin
      if cp=length(i1) then cp:=cp+1;
      ix[c]:=copy(i1,lp,(cp-lp));
      lp:=cp+1;
      c:=c+1;
    end;
  end;
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
  c:=pos('*',f); if c<>0 then for c1:=c to 8 do f[c1]:='?';
  c:=pos('*',e); if c<>0 then for c1:=c to 3 do e[c1]:='?';
  align:=f+'.'+e;
end;

function vdir(var d:str):boolean;
var x:boolean;
begin
  if d[length(d)]='\' then d:=copy(d,1,length(d)-1);
  if (d='DLOADS') or (d='GFILES') then x:=true else x:=false;
  if (d='.') and so then x:=true;
  vdir:=x;
end;

procedure fix(var fn:str);
var i,i1:str; c1,c2:integer; ok:boolean;
begin
  if vdir(fn) then fn:=fn+'\';
  c1:=pos('\',fn); ok:=true;
  if c1<>0 then begin
    i:=copy(fn,1,c1-1);
    fn:=copy(fn,c1+1,15);
    if not vdir(i) then ok:=false;
  end else i:='';
  if i='' then i:=cd;
  if fn='' then fn:='*.*';
  fn:=i+'\'+align(fn);
  if (pos('.MSG',fn)=0) and (pos('.TXT',fn)=0) and (pos('?',fn)=0) and (not so) then ok:=false;
  if not ok then fn:='';
  if not okfile(fn) then fn:='';
end;

function fit(f1,f2:str):boolean;
var tf:boolean; c:integer;
begin
  tf:=true;
  for c:=1 to 12 do
    if (f1[c]<>f2[c]) and (f1[c]<>'?') then tf:=false;
  fit:=tf;
end;

procedure inu(var i:integer);
var s:str;
begin
  input(s,3); i:=value(s);
end;

procedure ini(var i:byte);
var s:str;
begin
  input(s,3); i:=value(s);
end;

{$I DOSP1.PAS}

procedure setdta;
var r:regs;
begin
  r.ds:=seg(dta[1]);
  r.dx:=ofs(dta[1]);
  r.ax:=$1a00;
  msdos(r);
end;

procedure ffile(fn:str);
var r:regs; c:integer;
begin
  for c:=0 to 80 do dta[c]:=#0;
  setdta;
  filenamef:=fn+#0;
  r.ds := seg(filenamef[1]);
  r.dx := ofs(filenamef[1]);
  r.ax := $4e00;
  r.cx := 0;
  msdos(r);
  if r.ax=0 then found:=true else found:=false;
end;

procedure nfile;
var r:regs;
begin
  r.ax:=$4f00;
  msdos(r);
  if r.ax=0 then found:=true else found:=false;
end;

function fname:str;
var i1:str; c1:integer;
begin
  i1:=''; c1:=31;
  while (dta[c1]<>#0) and (c1<44) do begin i1:=i1+dta[c1]; c1:=c1+1; end;
  fname:=i1;
end;

function ti(i:integer):str;
var i1:str;
begin
  str(i,i1);
  if length(i1)=1 then i1:='0'+i1;
  ti:=i1;
end;

function info:str;
var res,i1,f,e:str; c1,c2:integer; rl:real;
begin
  i1:=fname;
  if (ord(dta[22]) and $10)=$10 then begin
    res:=i1;
    while length(res)<13 do res:=res+' ';
    res:=res+'<DIR>   ';
    e:='';
  end else begin
    c1:=pos('.',i1);
    if c1=0 then begin
      res:=i1;
      while length(res)<12 do res:=res+' ';
    end else begin
      f:=copy(i1,1,c1-1); e:=copy(i1,c1+1,3);
      while length(f)<8 do f:=f+' ';
      while length(e)<3 do e:=e+' ';
      res:=f+' '+e;
    end;
    rl:=0;
    for c1:=30 downto 27 do
      rl:=(rl*$100)+ord(dta[c1]);
    i1:=cstrr(rl,10);
    while length(i1)<9 do i1:=' '+i1;
    res:=res+i1;
  end;
  c1:=ord(dta[26])*$100+ord(dta[25]);
  i1:=cstr((c1 shr 5) mod 16); if i1[0]=#1 then i1:=' '+i1;
  i1:=i1+'-'+ti(c1 mod 32)+'-'+ti(80+(c1 shr 9));
  res:=res+'  '+i1+'  ';
  c1:=ord(dta[24])*$100+ord(dta[23]);
  c2:=(c1 shr 11);
  if (c2<12) then f:='a' else begin f:='p'; c2:=c2-12; end;
  if c2=0 then c2:=12;
  i1:=cstr(c2); if i1[0]=#1 then i1:=' '+i1;
  res:=res+i1+':'+ti((c1 shr 5) mod 64)+f;
  info:=res;
end;

procedure dir(cd,x:str; all,tf:boolean);
var
  abort,next:boolean;
  x1:str; dfs:integer;
begin
  if cd='DLOADS' then cd:=systat.dloadpath else cd:=cd+'\';
  ffile(cd+x);
  nl; abort:=false;
  while found and not abort do begin
    x1:=align(fname);
    if ((copy(x1,10,3)='MSG') or (copy(x1,10,3)='TXT') or all) and okfile(x1) then
      if tf then
        printacr(info,abort,next)
      else
        printacr(x1,abort,next);
    nfile;
  end;
  if cd[2]=':' then dfs:=freek(ord(cd[1])-ord('@')) else dfs:=freek(0);
  nl; printacr('  Free space = '+cstr(dfs)+'k',abort,next);
end;

procedure delfil;
begin
  nl;
  fix(ix[2]);
  if (not so) and (pos('.TXT',ix[2])=0) then begin
    ix[2]:='';
  end;
  if ix[2]<>'' then begin
    assign(f,ix[2]);
    {$I-} erase(f); {$I+}
    if ioresult=0 then print('Deleted.') else print('File not found.');
  end else print('Illegal filename.');
end;

procedure copyf;
begin
  fix(ix[2]); fix(ix[3]); nl;
  if (pos('????????.???',ix[3])<>0) then begin
    s1:=copy(ix[3],1,pos('\',ix[3])-1);
    s2:=copy(ix[2],pos('\',ix[2])+1,12);
    ix[3]:=s1+'\'+s2;
  end;
  if (ix[2]='') or (ix[3]='') then print('Illegal filename.') else begin
    assign(f,ix[2]); assign(f1,ix[3]);
    {$I-} reset(f); {$I+}
    if ioresult<>0 then print('File not found.') else begin
      close(f);
      {$I-} reset(f1); {$I+}
      if ioresult=0 then begin
        print('File already exists.');
        close(f1);
      end else begin
        {$I-} rewrite(f1); {$I+}
        if ioresult<>0 then begin close(f); print('Illegal filename.'); end else begin
          close(f1);
          copyfile(ix[2],ix[3]);
        end;
      end;
    end;
  end;
end;

procedure dirf(tf:boolean);
begin
  all:=false;
  if not (vdir(ix[2]) or (ix[2]='')) and so then all:=true;
  fix(ix[2]);
  c1:=pos('\',ix[2]);
  s1:=copy(ix[2],1,c1-1);
  s2:=copy(ix[2],c1+1,12);
  if s1='' then s1:=cd;
  nl; dir(s1,s2,all,tf);
end;

procedure typef;
begin
  nl;
  fix(ix[2]);
  if ix[2]<>'' then printfile(ix[2]) else print('Illegal filename.');
end;

procedure dosfc;
begin
  nl; prompt(cd+': ');
  input(i1,35); parse(i1);
  if ix[1]='?' then begin
    nl; nl; printfile('gfiles\dosmnu.msg');
  end;
  if ix[1]='EDIT' then tedit;
  if ix[1]='VOTEPRINT' then voteprint;
  if ix[1]='LOADHELP' then loadhelp;
  if ix[1]='GFILE' then gfileedit;
  if ix[1]='QUIT' then donedos:=true;
  if ix[1]='DEL' then delfil;
  if ix[1]='TYPE' then typef;
  if ix[1]='REN' then ren;
  if ix[1]='DIR' then dirf(false);
  if ix[1]='XDIR' then dirf(true);
  if ix[1]='CD' then if vdir(ix[2]) then cd:=ix[2];
  if ix[1]='COPY' then copyf;
  if ix[1]='CLS' then cls;
end;

begin
  iport; cd:='GFILES';
  topheap:=ptr(seg(lastvar),ofs(lastvar));
  release(topheap);
  case upcase(cmd) of
    'D':begin
          donedos:=false;
          print('Now in Mini-DOS.  "?" for help');
          if not so then print('Only .TXT or .MSG files can be accessed.');
          nl; nl;
          while (not hangup) and (not donedos) do
            dosfc;
        end;
    'T':term;
    'G':gfileedit;
    'U':uedit(usernum);
    'E':begin
          prompt('Filename: ');
          mpl(12);
          input(ix[2],12);
          tedit;
        end;
    'S':chsldata;
  end;
  return;
end.