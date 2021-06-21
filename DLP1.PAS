var pdl:real;

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

overlay procedure endbatch;
var try:integer; bfr:array[0..127] of byte; c:integer;

  procedure sb;
  var bp:real; numbt,c:integer;
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

overlay procedure send(fn:str; var dok:boolean; batch:boolean; tpb:real);
var filv:file; try,mb,bn,ers,lbn:integer; done,abort:boolean; st,start:real; c:char;
    x,y:integer; bfr:array [0..1023] of byte; numbt,numba:integer;

  procedure erm(i:str);
  begin
    gotoxy(5,7);
    writeln(i);
  end;

  procedure sb(bn:integer);
  var bp:real; onumbt,c:integer;

    procedure mb0;
    var i:str;
        r:regs;
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
      i:=stripname(i)+#0+cstrr(longfilesize(filv),10);
      filename:=fn+#0;
      r.ds:=seg(filename[1]);
      r.dx:=ofs(filename[1]);
      r.ax:=$3D00;
      msdos(r);
      handle:=r.ax;
      r.ax:=$5700;
      r.bx:=handle;
      msdos(r);
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
      msdos(r);
      i:=i+' '+cstrr(ctim1,8);
      for c:=1 to length(i) do bfr[c-1]:=ord(i[c]);
      for c:=length(i) to 127 do bfr[c]:=0;
      bfr[127]:=hi(mb); bfr[126]:=lo(mb);
      numbt:=128; numba:=128;
    end;

  begin
    crc:=0; chksum:=0; onumbt:=numbt;
    if bn=0 then mb0 else begin
      bp:=(lbn*1.0-1.0)*128.0;
      longseek(filv,bp);
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
      read(kbd,c); if c=#27 then begin abort:=true; done:=true;
      erm('ABORTED FROM KEYBOARD'); end;
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
        read(kbd,c);
        if c=#27 then begin
          erm('ABORTED FROM KEYBOARD');
          abort:=true;
        end;
      end;
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
    mb:=trunc((longfilesize(filv)+127.0)/128.0);
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

overlay procedure receive(fn:str; var dok:boolean; tpb:real);
var f:file; r1:array[0..1023] of byte;
    nbts,x,y,terr,xx,t1,csum,try,block,lblk,len,tblk:integer;
    b,b1,b2:byte; c:char;
    oneb,bn0,start,abort,error,done,timeo,kba,sav:boolean;
    rl,rl1,rfl:real; da,ti:integer;

const nak=#21;
      ack=#06;
      can=#24;
      soh=#01;

  procedure erm(i:str);
  begin
    gotoxy(5,6);
    write(i);
    clreol;
  end;

  function valuer(i:str; base:integer):real;
  var rl:real; c:integer;
  begin
    rl:=0;
    c:=1;
    while (c<length(i)) do begin
      if not (i[c] in ['0'..'9']) then i:=copy(i,1,c-1);
      c:=c+1;
    end;
    while (i<>'') do begin
      c:=ord(i[1])-ord('0');
      rl:=rl*1.0*base+c;
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
    if keypressed then begin read(kbd,c); if c=#27 then begin
      done:=true; abort:=true; erm('ABORTED FROM KEYBOARD'); kba:=true; end;
    end;
  end;

  procedure rb0;
  var i:str;
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
    rfl:=valuer(i,10); if rfl<0.0 then rfl:=0.0;
    if rfl>0.0 then tblk:=trunc(rfl/128.0);
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
  var filename:str; r:regs; handle:integer;
  begin
    filename:=fn+#0;
    r.ds:=seg(filename[1]);
    r.dx:=ofs(filename[1]);
    r.ax:=$3D00;
    msdos(r);
    handle:=r.ax;
    r.ax:=$5701;
    r.bx:=handle;
    r.cx:=ti;
    r.dx:=da;
    msdos(r);
    r.bx:=handle;
    r.ax:=$3E00;
    msdos(r);
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
  assign(f,fn); rl1:=timer; rfl:=0.0; tblk:=0;
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
          longseek(f,(lblk-1.0)*128.0);{$I-} blockwrite(f,r1,nbts); {$I+} if ioresult<>0 then begin
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
  if (rfl>0.1) and (rfl<=longfilesize(f)) then begin
    longseek(f,rfl);
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
var c:char; s:str; done:boolean;
begin
  if dl then s:='012345Q?' else s:='0234Q?';
  done:=false;
  repeat
    nl;
    prompt('Protocol (?=list) : '); onek(c,s);
    if c='?' then begin
      nl;
      print('Q) abort transfer');
      print('0) don''t transfer');
      if dl then print('1) ASCII');
      print('2) XMODEM');
      print('3) XMODEM-CRC');
      print('4) YMODEM');
      if dl then print('5) YMODEM Batch');
    end else done:=true;
  until done or hangup;
  if c='Q' then gtp:=-1 else gtp:=value(c+'');
end;

procedure sendascii(fn:str);
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

procedure send1(fn:str; var dok,abort:boolean);
var i:integer;
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
    5:ymbadd(fn);
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

procedure receive1(fn:str; var dok:boolean);
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
  end;
  if not useron then begin incom:=false; outcom:=false; end;
end;
