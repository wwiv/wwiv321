program convert;

TYPE str=string[180];
     restrictions=(rlogon,rchat,rvalidate,rbackspace,ramsg,rpostan,
                   rpost,remail,rvoting,rmsg);
     acrq='@'..'G';
     deflts=(spcsr,onekey,wordwrap,pause,mmnu);
     anontyp=(no,yes,forced,dearabby);
     ansttype=(postn,emailn,pana,sanm,cosysop,lcosysop);
     opts=(alert,smw,nomail);
     pnr=record name:string[40]; number:string[14]; hs:byte; end;
     clrs=array[false..true,1..8] of byte;
     messages=record
                ltr:char;
                number:integer;
                ext:byte;
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
               cursor:string[10];
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
             end;
      boardrec=record
                 name:string[25];
                 filename:string[12];
                 sl:byte;
                 maxmsgs:byte;
                 pw:string[10];
                 anonymous:anontyp;
                 ar:acrq;
                 key:char;
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
                end;
      userrec1=record
                 u:userrec;
                 age:byte;
                 sex:char;
                 note:string[39];
                 forusr:integer;
                 cols:clrs;
                 res:array[1..72] of byte;
               end;
      systat1=record
                 s:systatrec;
                 comport:byte;
                 maxspd:integer;
                 dloadpath:string[79];
                 gfiledate:string[8];
                 lowtime,hitime:integer;
                 res:array[1..100] of byte;
              end;
      boardrec1=record
                 name:string[30];
                 filename:string[12];
                 sl:byte;
                 maxmsgs:byte;
                 pw:string[10];
                 anonymous:anontyp;
                 ar:acrq;
                 key:char;
                 psl:byte;
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
               ft:array[1..3] of byte;
               blocks:integer;
               owner:integer;
               date:string[8];
               daten:integer;
             end;

CONST dcols:clrs=((7,7,15,15,15,112,15,143),(7,7,11,2,14,48,4,132));

var
    uf:file of userrec;
    bf:file of boardrec;
    systatf:file of systatrec;
    uf1:file of userrec1;
    bf1:file of boardrec1;
    systatf1:file of systat1;
    u:userrec;
    u1:userrec1;
    b:boardrec;
    b1:boardrec1;
    s:systatrec;
    s1:systat1;
    asc,maxulb,n,n1,n2,n3,culb,pl:integer;
    fi:text;
    fil:file of pnr;
    i:str;
    ns:pnr;
    fx:file;
    ulf:file of ulrec;
    ulff:file of ulfrec;
    uboards:array[0..25] of ulrec;
    f1:ulfrec;

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
  c:=pos(' ',f); if c<>0 then for c1:=c to 8 do f[c1]:=' ';
  c:=pos(' ',e); if c<>0 then for c1:=c to 3 do e[c1]:=' ';
  align:=f+'.'+e;
end;

function upper(i:str):str;
var c:integer;
begin
  for c:=1 to length(i) do
    i[c]:=upcase(i[c]);
  upper:=i;
end;

begin
  assign(uf,'gfiles\user.lst');
  assign(bf,'gfiles\boards.dat');
  assign(systatf,'gfiles\status');
  assign(ulf,'gfiles\uploads.dat');
  assign(uf1,'gfiles\user1.lst');
  assign(bf1,'gfiles\boards1.dat');
  assign(systatf1,'gfiles\status1');
  assign(fx,'gfiles\status');
  reset(fx,1);
  n:=filesize(fx);
  close(fx);
  if n=sizeof(s1) then begin
    writeln('Already converted.');
    halt;
  end;
  reset(systatf);
  read(systatf,s);
  s1.s:=s;
  close(systatf);
  s1.comport:=0;
  s1.maxspd:=0;
  getdir(0,i);
  s1.dloadpath:=i[1]+':DLOADS\';
  s1.gfiledate:='01/01/85';
  s1.lowtime:=0; s1.hitime:=0;
  for n:=1 to 100 do s1.res[n]:=0;
  while (not (s1.comport in [1,2])) or
   ((s1.maxspd<>300) and (s1.maxspd<>1200) and (s1.maxspd<>2400)) do begin
    write('Which com port (1-2) ? ');
    readln(s1.comport);
    write('Modem speed (300,1200,2400) ? ');
    readln(s1.maxspd);
  end;
  writeln('Working (this could take a while)...');
  reset(uf);
  rewrite(uf1);
  u1.age:=0;
  u1.sex:=' ';
  u1.note:='';
  u1.forusr:=0;
  u1.cols:=dcols;
  for n:=1 to 72 do
    u1.res[n]:=0;
  while not eof(uf) do begin
    read(uf,u);
    u1.u:=u;
    for n:=0 to 5 do u1.u.cursor[n]:=#0;
    for n:=6 to 10 do u1.u.cursor[n]:=#255;
    write(uf1,u1);
  end;
  close(uf1);
  close(uf);
  reset(bf);
  rewrite(bf1);
  while not eof(bf) do begin
    read(bf,b);
    b1.name:=b.name;
    i:=b.filename;
    assign(fil,'gfiles\'+i);
    if pos('.',i)>0 then
      i:=copy(i,1,pos('.',i)-1);
    if pos('.BRD',upper(b.filename))=0 then
      {$I-} rename(fil,'gfiles\'+i+'.BRD'); {$I+}
    asc:=ioresult;
    b1.filename:=i;
    b1.sl:=b.sl;
    b1.maxmsgs:=b.maxmsgs;
    b1.pw:=b.pw;
    b1.anonymous:=b.anonymous;
    b1.ar:=b.ar;
    b1.key:=b.key;
    b1.psl:=b.sl;
    write(bf1,b1);
  end;
  close(bf1);
  close(bf);
  rewrite(systatf1);
  write(systatf1,s1);
  close(systatf1);
  erase(bf);
  erase(uf);
  erase(systatf);
  rename(bf1,'gfiles\boards.dat');
  rename(uf1,'gfiles\user.lst');
  rename(systatf1,'gfiles\status.dat');
  assign(fi,'gfiles\trashcan.txt'); {$I-} reset(fi); {$I+}
  if ioresult<>0 then begin
    rewrite(fi); i:='FUCK'; writeln(fi,i); i:='SID VICIOUS'; writeln(fi,i);
    i:='SYSOP'; writeln(fi,i); i:='JEFF THE RIPPER'; writeln(fi,i);
  end;
  close(fi);
  assign(fil,'gfiles\numbers.trm');
  {$I-} reset(fil); {$I+}
  if ioresult<>0 then begin
    rewrite(fil);
    ns.name:='========================================';
    ns.number:='- --- --- ----';
    ns.hs:=1;
    for n:=1 to 9 do write(fil,ns);
  end;
  close(fil);
  rename(fil,'gfiles\numbers.dat');
  assign(fil,'gfiles\laston.fil'); rename(fil,'gfiles\laston.dat');
  reset(ulf); maxulb:=-1;
  while not eof(ulf) do begin maxulb:=maxulb+1; read(ulf,uboards[maxulb]); end;
  close(ulf);
  for culb:=0 to maxulb do begin
    i:=uboards[culb].filename;
    assign(fil,'gfiles\'+i);
    if pos('.',i)>0 then
      i:=copy(i,1,pos('.',i)-1);
    if pos('.DIR',upper(uboards[culb].filename))=0 then
      {$I-} rename(fil,'gfiles\'+i+'.DIR'); {$I+}
    asc:=ioresult;
    uboards[culb].filename:=i;
    iscan(pl);
    for n:=1 to pl do begin
      seek(ulff,n);
      read(ulff,f1);
      f1.filename:=align(f1.filename);
      if ord(f1.description[0])>60 then f1.description[0]:=#60;
      for n1:=1 to 17 do
        f1.res[n1]:=0;
      if (f1.ft[1]<>$81) or (f1.ft[2]<>$F4) then f1.ft[3]:=255;
      f1.ft[1]:=0; f1.ft[2]:=0;
      seek(ulff,n);
      write(ulff,f1);
    end;
    close(ulff);
  end;
  rewrite(ulf);
  for n:=0 to maxulb do write(ulf,uboards[n]);
  close(ulf);
  close(fil);
    writeln('WWIV v3.20 conversion complete.');
    writeln; writeln;
    writeln('Thank you for using WWIV software.  A $25 donation is requested for using');
    writeln('this software.  Please address any correspondences to:');
    writeln;
    writeln('             Wayne Bell');
    writeln('             Box 636');
    writeln('             904 Silver Spur Road');
    writeln('             Rolling Hills Estates, CA  90274');
end.