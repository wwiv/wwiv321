{$O+,V-}

Unit dloads;

                      {*****************************}
                      {Copyright (c) 1986 Wayne Bell}
                      {*****************************}

Interface

Uses Crt,Dos,Common;

var ulff:file of ulfrec;
    crc,culb:integer;
    sortbd,doneft:boolean;
    ldat:astr;
    ymodem,ucrc,bnp:boolean;
    chksum:byte;
    lrn:integer;
    lfn:astr;
    ft:byte;
    ymbtt:real;
    ymbindx:integer;
    ymbary:array[1..20] of record
      fn:string[80];
      tt:real;
    end;

procedure loads; var pdl:real;

Implementation

Procedure loads;

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

function ratios:astr;
var s:astr;
begin
  s:=cstrr(ratio*10000,10);
  while length(s)<5 do s:='0'+s;
  s:=copy(s,1,length(s)-4)+'.'+copy(s,length(s)-3,4);
  ratios:=s;
end;

function stripname(i:astr):astr;
var i1:astr; n:integer;
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

function uc(s:astr):astr;
var x:astr; i:integer;
begin
  x:=s;
  for i:=1 to length(s) do
    x[i]:=upcase(x[i]);
  uc:=x;
end;

procedure ymbadd(fn:astr);
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

function rte:real;
var i:integer;
begin
  i:=value(spd); if i=0 then i:=systat.maxbaud;
  rte:=1620.0/i;
end;

procedure calcCRC(data:byte);
var
  i: byte;
begin
  chksum := lo(chksum + data);
  if ucrc then begin
    crc:=crc xor (data shl 8);
    for i := 0 to 7 do begin
      if (crc<0) then
        crc:=(crc shl 1) xor $1021
      else
        crc:=crc shl 1;
    end;
  end;
end;

procedure endbatch;
var try:integer; bfr:array[0..127] of byte; c:integer;

  procedure sb;
  var bp:longint; numbt,c:integer;
  begin
    crc:=0; chksum:=0; numbt:=128;
    for c:=0 to numbt-1 do bfr[c]:=0; c:=0;
    o1(#1); o1(chr(0)); o1(chr(0 xor 255));
    while (c<numbt) do begin
      o1(chr(bfr[c])); calccrc(bfr[c]); c:=c+1;
    end;
    if ucrc then begin o1(chr(hi(crc))); o1(chr(lo(crc))); end else o1(chr(chksum));
    dump;
  end;

  procedure sblock;
  var start:real; done:boolean; b:blk; try,i:integer; c:char;
  begin
    try:=1;
    checkhangup;
    done:=false;
    while (not done) and (not hangup) do begin
      sb;
      start:=timer;
      while tcheck(start,20) and (not commpressed) and (not hangup)
        do checkhangup;
      if commpressed then c:=cinkey1 else c:=#21;
      case c of
        #6:done:=true;
        #24:done:=true;
        else begin
          try:=try+1;
          if try>9 then done:=true;
        end;
      end;
    end;
  end;

  function ok:boolean;
  var start:real; c:char; try:integer; abort,done:boolean;
  begin
    done:=false; start:=timer; abort:=false;
    while tcheck(start,90) and (not done) and (not abort) and (not hangup) do begin
      checkhangup;
      if commpressed then begin
        c:=cinkey1;
        if c=#21 then begin ucrc:=false; done:=true; end;
        if c='C' then begin ucrc:=true; done:=true; end;
        if c=#24 then abort:=true;
      end;
    end;
    if not tcheck(start,90) then
      abort:=true;
    ok:=(not abort) and (not hangup);
  end;

begin
  if ok then sblock;
end;

procedure send(fn:astr; var dok:boolean; batch:boolean; tpb:real);
var filv:file; try,mb,bn,ers,lbn:integer; done,abort:boolean; st,start:real; c:char;
    x,y:integer; bfr:array [0..1023] of byte; numbt,numba:integer;

  procedure erm(i:astr);
  begin
    gotoxy(5,7);
    writeln(i);
  end;

  procedure sb(bn:integer);
  var bp:longint; onumbt,c:integer;

    procedure mb0;
    var i:astr;
        r:registers;
        handle:integer;
        filename:string[80];
        m,d,y,h,mi,s:integer;
        c,t:integer;
        ctim1:real;

    begin
      i:=fn;
      while pos(' ',i)>0 do delete(i,pos(' ',i),1);
      for c:=1 to length(i) do
        if i[c] in ['A'..'Z'] then
          i[c]:=chr(ord(i[c])-ord('A')+ord('a'));
      i:=stripname(i)+#0+cstrr(filesize(filv),10);
      filename:=fn+#0;
      r.ds:=seg(filename[1]);
      r.dx:=ofs(filename[1]);
      r.ax:=$3D00;
      msdos(Dos.Registers(r));
      handle:=r.ax;
      r.ax:=$5700;
      r.bx:=handle;
      msdos(Dos.Registers(r));
      h:=(r.cx shr 11) and 31;
      mi:=(r.cx shr 5) and 63;
      s:=(r.cx and 31)*2;
      y:=((r.dx shr 9) and 255)+1980;
      m:=(r.dx shr 5) and 15;
      d:=(r.dx and 31);
      t:=0;
      for c:=1970 to y-1 do
        if leapyear(c) then t:=t+366 else t:=t+365;
      t:=t+daycount(m,y)+(d-1);
      ctim1:=s+mi*60.0+h*3600.0+(t*24.0*3600.0);
      r.bx:=handle;
      r.ax:=$3E00;
      msdos(Dos.Registers(r));
      i:=i+' '+cstrr(ctim1,8);
      for c:=1 to length(i) do bfr[c-1]:=ord(i[c]);
      for c:=length(i) to 127 do bfr[c]:=0;
      bfr[127]:=hi(mb); bfr[126]:=lo(mb);
      numbt:=128; numba:=128;
    end;

  begin
    crc:=0; chksum:=0; onumbt:=numbt;
    if bn=0 then mb0 else begin
      bp:=(lbn -1)*longint(128);
      seek(filv,bp);
      blockread(filv,bfr[0],numbt,numba);
    end;
    for c:=numba to numbt-1 do bfr[c]:=0; c:=0;
    if numbt=1024 then o1(#2) else o1(#1); o1(chr(lo(bn))); o1(chr(lo(bn) xor 255));
    while (c<numbt) do begin
      o1(chr(bfr[c])); calccrc(bfr[c]); c:=c+1;
    end;
    if ucrc then begin o1(chr(hi(crc))); o1(chr(lo(crc))); end else o1(chr(chksum));
    dump; numbt:=onumbt;
  end;

  procedure sblock(bn:integer; var abort:boolean);
  var start:real; done:boolean; b:blk; try,i:integer; c:char;

  procedure ckbd;
  begin
    if keypressed then begin
      c:=readkey; if c=#0 then begin
      c:=readkey; if c=#27 then begin
      abort:=true; done:=true;
      erm('ABORTED FROM KEYBOARD'); end; end;
    end;
  end;

  begin
    try:=1; abort:=false;
    checkhangup;
    done:=false;
    while (not done) and (not hangup) do begin
      gotoxy(20,3); write(bn); if ymodem then write('-',lbn);
      gotoxy(20,4); write(try-1);
      gotoxy(20,5); write(ers);
      gotoxy( 8,6);
      if ymodem then
        write(ctim(tpb*(((mb-lbn) div 8)+1)*8.0))
      else
        write(ctim(tpb*(mb-lbn+1)));
      sb(bn);
      start:=timer;
      while tcheck(start,20) and (not commpressed) and (not hangup) and (not abort)
        do begin checkhangup; ckbd; end;
      ckbd;
      if commpressed then c:=cinkey1 else c:=#21;
      case c of
        #6:done:=true;
        #24:begin done:=true; abort:=true; erm('ABORTED REMOTELY   '); end;
        else begin try:=try+1; ers:=ers+1; if try>9 then begin
            abort:=true; done:=true;
            erm('EXCESSIVE ERRORS     ');
          end;
        end;
      end;
    end;
  end;

  function ok:boolean;
  var start:real; c:char; try:integer; done:boolean;
  begin
    done:=false; abort:=false; start:=timer;
    while tcheck(start,90) and (not done) and (not abort) and (not hangup) do begin
      checkhangup;
      if keypressed then begin
        c:=readkey; if c=#0 then begin
        c:=readkey; if c=#27 then begin
          erm('ABORTED FROM KEYBOARD');
          abort:=true;
        end;
      end; end;
      if commpressed then begin
        c:=cinkey1;
        if c=#21 then begin ucrc:=false; done:=true; end;
        if c='C' then begin ucrc:=true; done:=true; end;
        if c=#24 then begin abort:=true;
          erm('ABORTED REMOTELY    ');
        end;
      end;
    end;
    if not tcheck(start,90) then begin
      erm('TIMEOUT ERROR    ');
      abort:=true;
    end;
    ok:=(not abort) and (not hangup);
  end;

begin
  assign(filv,fn); ers:=0; if ymodem then numbt:=1024 else numbt:=128;
  {$I-} reset(filv,1); {$I+}
  if ioresult=0 then begin
    mb:=trunc((filesize(filv)+127.0)/128.0);
    if useron and not batch then print('> WAITING FOR START, ^X to abort');
    x:=wherex; y:=wherey; pdl:=0.0;
    for bn:=1 to 8 do begin gotoxy(49,bn); write(#186); end;
    gotoxy(49,9); write(#200); for bn:=1 to 30 do write(#205);
    if useron then window(50,5,80,12) else window(50,1,80,8);
    clrscr; writeln('File: ',stripname(fn));
    writeln('Total blocks     = ',mb);
    writeln('Current block    = 0');
    writeln('# consec. errors = 0');
    writeln('# errors         = 0');
    writeln('Time = ');
    writeln('ER: ');
    write('<ESC> to abort');
    if ok then begin
      bn:=1; lbn:=1; try:=1;
      if ft<>255 then begin
        while (not abort) and (not hangup) do begin
          o1(#$81); o1(chr(ft)); o1(chr(ft xor $ff));
          st:=timer; try:=try+1;
          while tcheck(st,3) and not commpressed do;
          if tcheck(st,6) then c:=cinkey else c:=#0;
          if (c=#6) or (try>4) then abort:=true;
        end;
        abort:=false; try:=1;
      end;
      if ymodem then sblock(0,abort);
      while (not abort) and (not hangup) and (lbn<=mb) do begin
        sblock(bn,abort);
        bn:=bn+1; if ymodem then lbn:=lbn+8 else lbn:=lbn+1;
      end;
      if not abort then begin
        try:=1; done:=false;
        repeat
          start:=timer;
          gotoxy(20,3); write('EOT ');  o1(#4); clreol;
          while tcheck(start,10) and not commpressed and not hangup do checkhangup;
          if commpressed then begin
            c:=cinkey1; if c=#6 then begin
              done:=true;
            end;
          end;
          if not done then try:=try+1;
        until (try>9) or hangup or done;
      end else
        if ((lbn+1)>=mb) or (ymodem and ((lbn+8)>=mb)) then  begin
          abort:=false;
          sysoplog('&&&& Aborted on last block &&&&');
        end;
    end;
    close(filv);
    if useron then window(1,5,80,25) else window(1,1,80,25);
    gotoxy(x,y);
    dok:=not abort;
    if mb<>0 then pdl:=(100.0*lbn)/(1.0*mb);
    if dok then begin
      thisuser.downloads:=thisuser.downloads+1;
      thisuser.dk:=thisuser.dk+((mb+4) div 8);
      if useron and not batch then print('> FILE TRANSMISSION COMPLETE');
    end;
  end else if not batch then print('File not found.');
end;

procedure receive(fn:astr; var dok:boolean; tpb:real);
var f:file; r1:array[0..1023] of byte;
    nbts,x,y,terr,xx,t1,csum,try,block,lblk,len,tblk:integer;
    b,b1,b2:byte; c:char;
    oneb,bn0,start,abort,error,done,timeo,kba,sav:boolean;
    rl,rl1:real; da,ti:integer; rfl:longint;
const nak=#21;
      ack=#06;
      can=#24;
      soh=#01;

  procedure erm(i:astr);
  begin
    gotoxy(5,6);
    write(i);
    clreol;
  end;

  function valuer(i:astr; base:integer):longint;
  var rl:longint; c:integer;
  begin
    rl:=0;
    c:=1;
    while (c<length(i)) do begin
      if not (i[c] in ['0'..'9']) then i:=copy(i,1,c-1);
      c:=c+1;
    end;
    while (i<>'') do begin
      c:=ord(i[1])-ord('0');
      rl:=rl * 1 * base+c;
      i:=copy(i,2,length(i)-1);
    end;
    valuer:=rl;
  end;

  procedure onec(var b:byte);
  var r:real; c:char; i:byte;
  begin
    if buffer_Head<>buffer_Tail then begin
      inline($FA);
      b:=ord(buffer[buffer_Tail]);
      buffer_Tail:=(buffer_Tail+1) mod (buffer_max+1);
      inline($FB);
    end else begin
      r:=timer;
      while (not commpressed) and (not hangup) and tchk(r,1.0) do checkhangup;
      if commpressed then b:=ord(cinkey1) else begin timeo:=true; b:=0; end;
      if timeo then error:=true;
      if hangup then begin error:=true; done:=true; abort:=true; end;
    end;
    if ucrc then begin
      crc:=crc xor (b shl 8);
      for i := 0 to 7 do begin
        if (crc<0) then
          crc:=(crc shl 1) xor $1021
        else
          crc:=crc shl 1;
      end;
    end else chksum := lo(chksum + b);
  end;

  function onec1:byte;
  var r:real; c:char;
  begin
    checkhangup;
    r:=timer;
    while (not commpressed) and tcheck(r,6) and (not hangup) do checkhangup;
    if commpressed then onec1:=ord(cinkey1) else begin timeo:=true; onec1:=0; end;
    if timeo then error:=true;
    if hangup then begin error:=true; done:=true; abort:=true; end;
  end;

  procedure checkkb;
  var c:char;
  begin
    if keypressed then begin
      c:=readkey; if c=#0 then begin c:=readkey; if c=#27 then begin
      done:=true; abort:=true; erm('ABORTED FROM KEYBOARD'); kba:=true; end;
    end; end;
  end;

  procedure rb0;
  var i:astr;
      handle:integer;
      m,d,y,h,mi,s:integer;
      c,t:integer;
      ctim1:real;

    function daysin(y:integer):real;
    begin
      if leapyear(y) then daysin:=366.0 else daysin:=365.0;
    end;

  begin
    c:=0; while (r1[c]<>0) and (c<100) do c:=c+1;
    c:=c+1; i:='';
    while (chr(r1[c]) in ['0'..'9']) and (length(i)<11) do begin
      i:=i+chr(r1[c]);
      c:=c+1;
    end;
    rfl:=valuer(i,10); if rfl<0 then rfl:=0;
    if rfl>0 then tblk:=trunc(rfl/128);
    if chr(r1[c])=' ' then begin
      i:=''; c:=c+1;
      while (chr(r1[c]) in ['0'..'7']) and (length(i)<11) do begin
        i:=i+chr(r1[c]);
        c:=c+1;
      end;
      ctim1:=valuer(i,8);
      y:=1970;
      while (ctim1-daysin(y)*86400.0)>0 do begin
        ctim1:=ctim1-daysin(y)*86400.0;
        y:=y+1;
      end;
      m:=1;
      while (ctim1-daycount(m+1,y)*86400.0)>0 do
        m:=m+1;
      ctim1:=ctim1-daycount(m,y)*86400.0;
      d:=1;
      while (ctim1-d*86400.0)>0 do
        d:=d+1;
      ctim1:=ctim1-(d-1)*86400.0;
      h:=trunc(ctim1/3600.0);
      ctim1:=ctim1-h*3600.0;
      mi:=trunc(ctim1/60.0); ctim1:=ctim1-mi*60.0;
      s:=trunc(ctim1/2.0);
      da:=((y-1980) shl 9)+(m shl 5)+d;
      ti:=(h shl 11)+(mi shl 5)+s;
      if y<1980 then da:=0;
    end else begin
      da:=0; ti:=0;
    end;
  end;

  procedure savedate;
  var filename:astr; r:registers; handle:integer;
  begin
    filename:=fn+#0;
    r.ds:=seg(filename[1]);
    r.dx:=ofs(filename[1]);
    r.ax:=$3D00;
    msdos(Dos.Registers(r));
    handle:=r.ax;
    r.ax:=$5701;
    r.bx:=handle;
    r.cx:=ti;
    r.dx:=da;
    msdos(Dos.Registers(r));
    r.bx:=handle;
    r.ax:=$3E00;
    msdos(Dos.Registers(r));
  end;

  procedure tl;
  begin
    gotoxy(17,2); write(block,'-',lblk);
    gotoxy(17,3); write(try-1);
    gotoxy(17,4); write(terr);
    if rfl>0.0 then begin
      gotoxy(8,5);
      if ymodem then
        write(ctim(tpb*(((tblk-lblk) div 8)+1)*8.0))
      else
        write(ctim(tpb*(tblk-lblk+1)));
    end;
  end;

begin
  abort:=false; done:=false; timeo:=false; kba:=false; oneb:=true;
  block:=1; try:=1; start:=false; lblk:=1; da:=0; ti:=0;
  assign(f,fn); rl1:=timer; rfl:=0; tblk:=0;
  {$I-} rewrite(f,1);{$I+}
  if ioresult<>0 then begin
    print('> DISK ERROR, SORRY CAN''T UPLOAD IT.');
    done:=true; abort:=true;
  end;
  if useron then print('> WAITING FOR START, ^X to abort'); x:=wherex; y:=wherey;
  for terr:=1 to 7 do begin gotoxy(49,terr); write(#186); end;
  gotoxy(49,8); write(#200); for terr:=1 to 30 do write(#205);
  if useron then window(50,5,80,11) else window(50,1,80,7);
  clrscr; writeln('File: '+stripname(fn));
  writeln('Block number  = 0');
  writeln('Consec errors = 0');
  writeln('Total errors  = 0');
  writeln('Time = Unknown');
  writeln('ER:');
  write('<ESC> to abort.');
  error:=true; terr:=0; bn0:=false;
  delay(500);
  while (not done) and (not hangup) do begin
    tl;
    checkkb; if kba then begin done:=true; abort:=true; end;
    if kba then o1(can) else
      if error then begin if (block=1) and ucrc and oneb then o1('C') else o1(nak);
        dump; if block<>1 then terr:=terr+1; try:=try+1; tl;
      end else begin
        o1(ack); dump;
        if bn0 then rb0;
        bn0:=false;
        if sav and (not error) then begin
          try:=1;
          seek(f,(lblk -1) * 128);{$I-}
          blockwrite(f,r1,nbts); {$I+} if ioresult<>0 then begin
            done:=true; abort:=true; erm('DISK ERROR');
            sysoplog('Disk error in upload');
          end;
          block:=block+1; if ymodem then lblk:=lblk+8 else lblk:=lblk+1;
        end else
        begin if block<>1 then erm('Low block number '+cstr(block-1)); end;
      end;
    if (not done) and (not abort) and (not hangup) then begin
      start:=false; t1:=0;
      while (not start) and (not hangup) and (not abort) do begin
        timeo:=false;
        b:=onec1;
        if b=$81 then begin
          b1:=onec1; b2:=onec1;
          if b1=(b2 xor $ff) then begin
            ft:=b1; o1(ack);
          end else o1(nak);
        end;
        if b=ord(soh) then begin start:=true; ymodem:=false; end;
        if b=2 then begin start:=true; ymodem:=true; end;
        if b=ord(can) then begin abort:=true; done:=true; erm('ABORTED REMOTELY'); end;
        if b=04 then begin o1(ack); start:=true; done:=true; erm('EOT RECEIVED'); end;
        if timeo then begin if (block=1) and ucrc and oneb then o1('C') else o1(nak); t1:=t1+1; end;
        if t1>=9 then begin start:=true; abort:=true; done:=true; end;
      end;
      if kba then begin o1(can); erm('ABORTED FROM KEYBOARD'); end;
    if try>9 then begin abort:=true; done:=true; erm('ABORTING - too many errors'); end;
    if t1>=9 then begin abort:=true; done:=true; erm('TIMEOUT'); end;
    error:=false; checkkb; oneb:=false;
    if not done then begin
      tl;
      sav:=true;
      onec(b1); if b1<>lo(block) then
        if (b1+1) mod 256=lo(block) then begin
          sav:=false;
          if (block=1) and (b1=0) then bn0:=true;
        end else begin
          error:=true; erm('bn was '+cstr(b1)+' vs. '+cstr(lo(block)));
        end;
      onec(b); if b xor 255<>b1 then begin error:=true; erm('com was '+cstr(b)+' vs. '+cstr(b1 xor 255)); end
        else if sav and (b1<>lo(block)) then begin abort:=true; done:=true; end;
      len:=0; chksum:=0; crc:=0; if ymodem then nbts:=1024 else nbts:=128;
      while (len<nbts) and (not timeo) do begin
        onec(r1[len]);
        len:=len+1;
      end;
      xx:=crc; csum:=chksum;
      onec(b); if ucrc then onec(b1);
      if not error then begin
        if ((b<>lo(csum)) and (not ucrc)) or
           (((b<>hi(xx)) or (b1<>lo(xx))) and ucrc)
        then begin error:=true; erm('Checksum/CRC error in '+cstr(block)); end;
        end;
      end;
      if abort then o1(can);
    end;
  end;
  if (rfl>0.1) and (rfl<=filesize(f)) then begin
    seek(f,rfl);
    truncate(f);
  end;
  close(f);
  if (da<>0) then savedate;
  if useron then window(1,5,80,25) else window(1,1,80,25);
  gotoxy(x,y);
  if hangup then abort:=true;
  if abort then erase(f) else
  begin
    thisuser.uploads:=thisuser.uploads+1;
    thisuser.uk:=thisuser.uk+((lblk+3) div 8);
    writeln('> TRANSFER COMPLETED');
    if timer<rl1 then rl1:=rl1-24.0*60*60;
    chattime:=chattime+timer-rl1;
    systat.uptoday:=systat.uptoday+1;
  end;
  dok:=not abort;
end;

function gtp(dl:boolean):integer;
var c:char; s:astr; done:boolean;
begin
  if dl then s:='0123456Q?' else s:='02345Q?';
  done:=false;
  repeat
    nl;
    ansic(4); prompt('Protocol (?=list) : '); onek(c,s);
    if c='?' then begin
      nl;
      print('Q) abort transfer');
      print('0) don''t transfer');
      if dl then print('1) ASCII');
      print('2) XMODEM');
      print('3) XMODEM-CRC');
      print('4) YMODEM');
      print('5) ZMODEM');
      if dl then print('6) Batch');
    end else done:=true;
  until done or hangup;
  if c='Q' then gtp:=-1 else gtp:=value(c+'');
end;

procedure sendascii(fn:astr);
var f:file of char; c,c1:char; abort:boolean; i:integer;
  procedure ckey;
  begin
    checkhangup;
    while (not empty) and (not abort) and (not hangup) do begin
      if hangup then abort:=true;
      c1:=inkey;
      if (c1=^X) or (c1=#27) or (c1=' ') then abort:=true;
      if c1=^S then getkey(c1);
    end;
  end;
begin
  assign(f,fn);
  {$I-} reset(f); {$I+}
  if ioresult<>0 then print('File not found.') else begin
    abort:=false;
    clrscr;
    writeln('File: ',fn);
    writeln('<ESC> to abort');
    writeln;
    gotoxy(1,5);
    for i:=1 to 80 do write(#205);
    gotoxy(1,17);
    for i:=1 to 80 do write(#205);
    window(1,10,80,20);
    clrscr;
    print('^X=ABORT');
    print('^S=PAUSE'); nl;
    while (not hangup) and (not abort) and (not eof(f)) do begin
      read(f,c); o(c); if (c<>#7) then write(c); ckey;
    end;
    close(f);
    if useron then window(1,5,80,25) else window(1,1,80,25); gotoxy(1,19);
    nl; nl; print('> FILE TRANSMISSION COMPLETE');
  end;
end;

procedure send1(fn:astr; var dok,abort:boolean);
var i:integer; f:file; g:astr;
begin
  i:=gtp(true); dok:=true; abort:=false;
  if not useron then begin incom:=true; outcom:=true; if i=1 then i:=0; end;
  case i of
   -1:begin dok:=false; abort:=true; end;
    0:dok:=false;
    1:sendascii(fn);
    2:if incom then begin ucrc:=false; ymodem:=false; send(fn,dok,false,rte); end;
    3:if incom then begin ucrc:=true; ymodem:=false; send(fn,dok,false,rte); end;
    4:if incom then begin ucrc:=true; ymodem:=true; send(fn,dok,false,rte); end;
    5:begin
        assign(f, fn);
        {$I-} reset(f); {$I+}
        if (IOResult <> 0) then print('File not found.') else begin
        g:=fn;
        while pos(' ',g)>0 do delete(g,pos(' ',g),1);
        g := copy(g,3,20);
        print('Ctrl-X Many times to Abort Transfer');
        SwapVectors;
        Exec(GetEnv('COMSPEC'),'/C dsz sz -m '+g);
        SwapVectors;
        print('File Transmission Complete');
        sysoplog('Downloaded "'+g+'"');
        thisuser.downloads:=thisuser.downloads+1; topscr;
        end;
      end;
    6:ymbadd(fn);
  end;
  if (i<1) and (not incom) then dok:=false;
  if useron then
    if (i>1) and (i<>5) then
      if dok then
        sysoplog('Downloaded "'+stripname(fn)+'"')
      else
        sysoplog('Tried D/L "'+stripname(fn)+'"   '+cstrr(pdl,10)+'%')
    else
      if i=1 then
        sysoplog('Text D/L "'+stripname(fn)+'"')
      else
  else begin incom:=false; outcom:=false; end;
end;

procedure receive1(fn:astr; var dok:boolean);
var i:integer;
begin
  i:=gtp(false); dok:=true;
  if not useron then begin incom:=true; outcom:=true; end;
  case i of
   -1:dok:=false;
    0:dok:=false;
    2:begin ucrc:=false; ymodem:=false; receive(fn,dok,rte); end;
    3:begin ucrc:=true; ymodem:=false; receive(fn,dok,rte); end;
    4:begin ucrc:=true; ymodem:=true; receive(fn,dok,rte); end;
    5:begin
         print('Ctrl-X Many times to Abort Transfer');
         swapvectors;
         Exec(GetEnv('COMSPEC'),'/C dsz rz -m dloads\');
         swapvectors; topscr;
      end;
  end;
  if not useron then begin incom:=false; outcom:=false; end;
end;

procedure i1;
begin
  culb:=1;
  ldat:=thisuser.laston;
  ymbtt:=0.0;
  ymbindx:=0;
end;

function exist(fn:astr):boolean;
var f:file;
begin
  assign(f,fn);
  {$I-} reset(f); {$I+}
  if ioresult=0 then begin close(f); exist:=true end else exist:=false;
end;

function align(fn:astr):astr;
var f,e,t:astr; c,c1:integer;
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

function fit(f1,f2:astr):boolean;
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

procedure recno(fn:astr; var pl,rn:integer);
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

procedure nrecno(fn:astr; var pl,rn:integer);
var c:integer; f:ulfrec;
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

procedure pbn(var abort:boolean);
var i,i1:astr; next:boolean;
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
var inte,pl,c:integer; ok,tl:boolean; u:userrec; rl:real; i,ii:astr;
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
      end else print('File is on Request');
    end else print('Not enough time left to D/L');
end;

procedure dl(fn:astr);
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

procedure ul(fn:astr);
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
            f.blocks:=trunc((filesize(fi)+127)/128);
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
var i:astr;
begin
  helpl:='X';
  nl; print('Download -'); nl; prt('Enter filename: '); mpl(12); input(i,12);
  dl(i);
  nl; nl;
end;

procedure iul;
var i:astr;
begin
  helpl:='U';
  nl; nl; print('Upload -'); nl; prt('Enter filename: '); mpl(12); input(i,12);
  ul(i);
  nl; nl;
end;

procedure gfn(var fn:astr);
begin
  nl; helpl:='L';
  prt('File mask: '); input(fn,12);
  if fn='' then fn:='*.*';
  fn:=align(fn);
end;

function aln(i:astr; n:integer):astr;
begin
  while length(i)<n do i:=' '+i;
  aln:=i;
end;

procedure pfn(f:ulfrec; var abort,next:boolean);
begin
  printacr(f.filename+':'+aln(cstr(f.blocks),4)+' :'+f.description,abort,next);
end;

procedure searchb(b:integer; fn:astr; var abort:boolean);
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

procedure searchbd(b:integer; ts:astr; var abort:boolean);
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
var fn:astr; bn:integer; abort:boolean;
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
var fn:astr; bn:integer; abort:boolean;
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
var abort:boolean; fn:astr;
begin
  nl; nl; print('List files.');
  gfn(fn); abort:=false;
  searchb(culb,fn,abort);
end;

procedure listf(n:integer; var abort:boolean);
var f:ulfrec; i,i1:astr; next:boolean;
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

procedure arcl(fn:astr; var abort:boolean);
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

  function unsigned(i:integer):longint;
  begin
    if i>=0 then
      unsigned:=longint(i)
    else
      unsigned:=65536 + longint(i);
  end;

  function valueei(x:ei):longint;
  var rl:longint;
  begin
    rl:=unsigned(x.h)*65536 + unsigned(x.l);
    if rl>= {32768 * 65536} 2147483647 then
      rl:=65536 - rl * 65536 + 1;
    valueei:=rl;
  end;

  procedure pfn;
  var i,i1:astr; try:byte;
  begin
    b:=0; try:=0;
    while not eof(f) and (b<>26) and (try<5) do begin
      blockread(f,b,1);
      try:=try+1;
    end;
    if try>=5 then seek(f,filesize(f)-2);
    if filepos(f)+27<filesize(f) then begin
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
      seek(f,filepos(f)+valueei(head.size));
    end;
  end;

begin
  assign(f,fn);
  reset(f,1); done:=false;
  while (filepos(f)+27<filesize(f)) and not (abort or done) do
    pfn;
  close(f);
end;

procedure lbrl(fn:astr; var abort:boolean);
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
    i,i1:astr;
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

procedure remove;
var pl,c,rn:integer; f:ulfrec; fn:astr; ff:file; u:userrec; tf:boolean; ch:char;
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

procedure move;
var x,pl,c,rn,int,dbn:integer; f,f1:ulfrec; fn:astr; ff:file; i:astr;
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

procedure ren;
var pl,c,rn,int,dbn,x:integer; f:ulfrec; fn,fd:astr; ff:file; i:astr;
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

procedure browsefiles;
var pl,n,nfl,cn:integer; f:ulfrec; i,i1:astr; abort,next,list,done:boolean;
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

procedure setdirs;
var i:astr; c1,c2:integer; done:boolean;

  procedure listit;
  var c:integer; abort,next:boolean; i:astr;
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

procedure pointdate;
var i:astr; n:integer;
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

procedure listboards;
var b:integer; i:astr; abort,next:boolean;
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

procedure dlbatch;
var ch:char; n:integer; hua,done:boolean; dok,abort,next:boolean; i:astr;
  function info(n:integer):astr;
  var i,i1:astr;
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
      printfile('gfiles\dlbat.msg '); nl; nl;
      prt('Batch Menu: ');
      onek(ch,'QLDRC?O');
      case ch of
        'Q':done:=true;
        'O':begin
               ynq('Log Off ? ');
               if yn then begin cls; ymbindx:=0; ymbtt:=0.0;
               printf('gfiles\logoff'); hangup:=true; hungup:=false;
              end;
            end;
        '?':begin
              print('Q:uit to D/L Menu   L:ist files in queue');
              print('D:ownload queue     R:emove file from queue');
              print('C:lear queue        O: Log Off');
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
end;

procedure mmkey(var i:astr);
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

procedure lfi(fn:astr; var abort:boolean);
var next:boolean; i1,i2:astr;
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
var pl,rn:integer; abort:boolean;f,ff:file;oldm:text; fn,g,curdir:string;
begin
  abort:=false;
  nl; print('Enter file to list interior files of');
  prt(': '); mpl(12); input(fn,12); GetDir(0,curdir);
  chDir('dloads'); if length(fn)= 0 then fn:='xxxxxxxx';
  assign(f, fn); {$i-} reset(f); {$i+} if (IOResult <> 0) then
  print('File not found.') else begin close(f); g:=fn;
  assign(ff,'archive.txt'); {$i-} reset(ff); {$i+}
  if ioresult<>0 then delay(1) else begin close(ff);
  erase(ff); end; abort := true; swapvectors;
  Exec(GetEnv('comspec'),'/C fv '+g+' >archive.txt'); swapvectors; end;
  chdir(curdir); if abort then printfile('dloads\archive.txt');
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
var ii,i:astr; int:integer;
begin
  dump; tleft; nl; nl;
  if mmnu in thisuser.defaults then
  printf('gfiles\dlmenu');
  print('T - '+tlef);
  i:='('+cstr(culb)+')-('+uboards[culb].name+')  :';
  prt(i); helpl:='T'; mmkey(i); helpl:=#0;
  if length(i)=1 then case i[1] of
    '+','>':begin int := culb; inc(int); if int >maxulb then int := 1;
             if (int>0) and (int<=maxulb) then
             if thisuser.dsl>=uboards[int].dsl then
             if (uboards[int].password='') or dcs then culb:=int else begin
             prt('Password? '); input(i,10);
             if i<>uboards[int].password then
             print('Wrong.')
             else
             culb:=int; end;
           end;
    '-','<':begin int := culb; dec(int); if int <1 then int := maxulb;
             if (int>0) and (int<=maxulb) then
             if thisuser.dsl>=uboards[int].dsl then
             if (uboards[int].password='') or dcs then culb:=int else begin
             prt('Password? '); input(i,10);
             if i<>uboards[int].password then
             print('Wrong.')
             else
             culb:=int; end;
           end;
    '?':if not (mmnu in thisuser.defaults) then begin
        nl; nl; printf('gfiles\dlmenu'); end;
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
          nl;nl; ynq('Log Off? '); helpl:='O';
          if yn then begin
            cls;
            printf('gfiles\logoff');
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
    'E':dlbatch;
    'X':if mmnu in thisuser.defaults then
           thisuser.defaults:=thisuser.defaults-[mmnu] else
           thisuser.defaults:=thisuser.defaults+[mmnu];
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
  doneft:=false;
  while (not doneft) and
  (not hangup) do
  ftmainmenu;
end;
end.
