overlay procedure chsldata;
var a,csl:byte; ch:char; done:boolean;

  function inf:str;
    function ml(i:integer):str;
    var s:str;
    begin
      s:=cstr(i); while length(s)<6 do s:=s+' ';
      ml:=s;
    end;
    function yy(a:ansttype):str;
    begin
      if a in seclev[csl].anst then
        yy:='Yes   '
      else
        yy:='No    ';
    end;
  begin
    with seclev[csl] do
      inf:=ml(csl)+ml(ttime)+ml(mallowed)+'  '+ml(emails)+ml(posts)+
         yy(pana)+yy(sanm)+yy(postn)+yy(emailn)+yy(lcosysop)+yy(cosysop);
  end;

  procedure changesldata;
  var c:char; i:str;
    function yn1(x:boolean):boolean;
    var c:char;
    begin
      repeat
        getkey(c);
        c:=upcase(c);
      until (c='Y') or (c='N') or (c=#13);
      if c='Y' then
        x:=true
      else
        if c='N' then
          x:=false;
      if x then
        write('Yes   ')
      else
        write('No    ');
      yn1:=x;
    end;

    procedure chg(a:ansttype);
    begin
      if yn1(a in seclev[csl].anst) then
        seclev[csl].anst:=seclev[csl].anst+[a]
      else
        seclev[csl].anst:=seclev[csl].anst-[a];
    end;

    procedure chbyte(var b:byte);
    var i:str; x,y:integer;
    begin
      x:=wherex; y:=wherey;
      write(cstr(b)); gotoxy(x,y);
      input(i,3);
      if i<>'' then b:=value(i);
      gotoxy(x,y);
      i:=cstr(b);
      while length(i)<6 do
        i:=i+' ';
      write(i);
    end;

    procedure chint(var b:integer);
    var i:str; x,y:integer;
    begin
      x:=wherex; y:=wherey;
      write(cstr(b)); gotoxy(x,y);
      input(i,5);
      if i<>'' then b:=value(i);
      gotoxy(x,y);
      i:=cstr(b);
      while length(i)<8 do
        i:=i+' ';
      write(i);
    end;
  begin
    gotoxy(1,4);
    write(inf);
    gotoxy(7,4);
    with seclev[csl] do begin
      chbyte(ttime);
      chint(mallowed);
      chbyte(emails);
      chbyte(posts);
      chg(pana); chg(sanm); chg(postn); chg(emailn); chg(lcosysop); chg(cosysop);
    end;
  end;

begin
  if checkpw then begin
    cls;
    writeln('                               |Anony write|Anony read |Lt''d| Full|');
    writeln('SL    Time  Msgs    Email Post |Msgs  Email|Msgs  Email|C-SO| C-SO|');
    writeln('-------------------------------------------------------------------');
    csl:=10;
    done:=false;
    gotoxy(1,6);
    writeln('[,] = up/down one SL');
    writeln('{,} = up/down 10 SL');
    writeln('C   = change SL data');
    writeln('S   = save changed data');
    writeln('L   = load old data');
    writeln('Q   = quit to BBS');
    repeat
      gotoxy(1,4);
      writeln(inf);
      read(kbd,ch);
      ch:=upcase(ch);
      case ch of
        'Q':done:=true;
        ']':csl:=csl+1;
        '[':csl:=csl-1;
        '}':csl:=csl+10;
        '{':csl:=csl-10;
        'C':changesldata;
        'S':begin
              assign(slf,'gfiles\seclev.dat'); reset(slf);
              for a:=0 to 255 do write(slf,seclev[a]);
              close(slf);
            end;
        'L':begin
              assign(slf,'gfiles\seclev.dat'); reset(slf);
              for a:=0 to 255 do read(slf,seclev[a]);
              close(slf);
            end;
      end;
    until done or hangup;
    cls;
    end;
end;

overlay procedure return;
var f:file;
begin
  assign(f,'bbs.com');
  print('Returning to BBS...');
  remove_port;
  if hangup then term_ready(false);
  execute(f);
end;


overlay procedure term;
var c:char; done,bac,eco:boolean;
    hs:byte;
    ns:array[1..9] of pnr;
    fil:file of pnr;
    lnd,i:integer;
    maxs:byte;
    rl:real;
    r:regs;

procedure ul;
var dok,abort:boolean; i:str;
f:file;
begin
  writeln; writeln; ft:=255;
  prompt('Send file: ');
  input(i,12);
  i:=systat.dloadpath+i;
  assign(f,i);
  {$I-} reset(f); {$I+}
  if ioresult=0 then begin
    close(f);
    send1(i,dok,abort);
  end else print('File not found.');
  incom:=false;
  hangup:=false;
  outcom:=false;
  writeln;
end;

procedure dl;
var dok:boolean; i:str; f:file;
begin
  writeln; writeln; ft:=255;
  prompt('Receive file: ');
  input(i,12);
  i:=systat.dloadpath+i;
  assign(f,i);
  {$I-} reset(f); {$I+}
  if ioresult<>0 then begin
    {$I-} rewrite(f); {$I+}
    if ioresult=0 then begin
      close(f);
      dok:=true;
    end else begin
      dok:=false;
      print('Illegal filename.');
    end;
  end else begin
    close(f);
    print(#7+'File already exists.');
    prompt('Overwrite? ');
    dok:=yn;
  end;
  if dok then
    receive1(i,dok);
  hangup:=false;
  incom:=false;
  outcom:=false;
end;

  procedure pc(s:str);
  var i:integer;
  begin
    s:=s+chr(13);
    for i:=1 to length(s) do o1(s[i]);
  end;

  procedure cs(hs:byte);
  begin
    writeln;
    case hs of
      0:begin
          set_baud(300);
          writeln('--- 300 BAUD ---');
        end;
      1:begin
          set_baud(1200);
          writeln('=== 1200 BAUD ===');
        end;
      2:begin
          set_baud(2400);
          writeln('=-= 2400 BAUD =-=');
        end;
    end;
    writeln;
  end;

  procedure tab(x:integer);
  begin
    while wherex<x do write(' ');
  end;

  procedure dial;
  var i:integer; done:boolean; c:char; s:str;
  begin
    done:=false;
    repeat
      writeln;
      write('Dial: 1-9,M,Q,? : ');
      repeat
        read(kbd,c); c:=upcase(c);
      until c in ['1'..'9','M','Q','?'];
      writeln(c); writeln;
      if c='Q' then begin done:=true; writeln; writeln('Back in term mode.'); writeln; end;
      if c='?' then begin
        clrscr;
        writeln('N NAME                                      NUMBER         SPD');
        writeln('- ----------------------------------------  -------------  ----');
        for i:=1 to 9 do begin
          write(i,' ',ns[i].name); tab(44); write(ns[i].number); tab(60);
          case ns[i].hs of
            0:writeln(' 300');
            1:writeln('1200');
            2:writeln('2400');
          end;
        end;
      end;
      if c='M' then begin
        write('Which (1-9) ? ');
        repeat
          read(kbd,c);
        until c in ['1'..'9',#13];
        if c in ['1'..'9'] then begin
          i:=value(c);
          clrscr;
          writeln('Number: ',i);
          writeln;
          writeln('Old Name: ',ns[i].name);
          write('New Name: '); inputl(s,40);
          if s<>'' then ns[i].name:=s;
          writeln;
          writeln('Old Number: ',ns[i].number);
          write('New Number: '); input(s,14);
          if s<>'' then ns[i].number:=s;
          writeln;
          write('Old Speed: ');
          case ns[i].hs of
            0:writeln(' 300');
            1:writeln('1200');
            2:writeln('2400');
          end;
          writeln;
          writeln('0 =  300');
          if maxs>0 then writeln('1 = 1200');
          if maxs>1 then writeln('2 = 2400');
          write('New speed? '); read(kbd,c); if (c<'0') or (c>'2') then c:=#0;
          writeln(c); writeln;
          if (value(''+c)<=maxs) and (c<>#0)  then ns[i].hs:=value(''+c);
          reset(fil); seek(fil,i-1); write(fil,ns[i]); close(fil);
          c:=' ';
        end;
      end;
      if c in ['1'..'9'] then begin
        done:=true;
        i:=value(c);
        clrscr; lnd:=i;
        hs:=ns[i].hs; cs(hs);
        writeln('Dialing: ',ns[i].name);
        writeln('At     : ',ns[i].number);
        writeln;
        pc('ATDT'+ns[i].number);
      end;
    until done;
  end;

  function cdet:boolean;
  begin
    cdet:=((port[base+6] and 128)<>0)
  end;

  procedure hang;
  var rl:real;
  begin
    dump;
    term_ready(false); rl:=timer;
    while cdet and (abs(timer-rl)<1.5) do;
    term_ready(true);
  end;

  procedure redial;
  var c:char; done:boolean; try:integer; rl,rl1,rl2:real; int:integer; i,i1:str;
  begin
    clrscr; try:=0;
    hs:=ns[lnd].hs; cs(hs); rl:=timer;
    pc('ATM0Q0V0E0S7=16');
    writeln('Re-Dialing: ',ns[lnd].name);
    writeln('At        : ',ns[lnd].number);
    writeln('Try       : 0');
    writeln('Time      : 00:00');
    writeln; writeln('Hit <ESC> to abort'); done:=false;
    delay(500); dump;
    repeat
      pc('ATDT'+ns[lnd].number);
      try:=try+1;
      gotoxy(13,6); writeln(try);
      rl1:=timer; if rl1<rl then rl:=rl+24.0*3600.0;
      rl2:=abs(rl1-rl); if rl2>32000 then rl2:=32000;
      int:=trunc(rl2);
      i:=cstr(int div 60);
      if length(i)=1 then i:='0'+i;
      i1:=cstr(int mod 60);
      if length(i1)=1 then i1:='0'+i1;
      i:=i+':'+i1;
      gotoxy(13,7); writeln(i); dump;
      while (not done) and (not commpressed) do begin
        if keypressed then begin
          read(kbd,c); if c=#27 then begin done:=true; o1('A'); end;
        end;
      end;
      delay(100);
      if cdet then done:=true else dump;
    until done;
    if cdet then for try:=1 to 6 do begin
      sound(1200); delay(200); nosound; delay(100);
    end else begin
      delay(500); pc('ATM1Q0V1E1S7=30');
    end;
    gotoxy(1,14); writeln; writeln('Back in term mode...');
  end;

  procedure help;
  var x,y,c:integer;
  begin
    x:=wherex; y:=wherey;
    for c:=1 to 10 do begin
      gotoxy(42,c); write(#$b3);
    end;
    gotoxy(42,11); write(#$c0);
    while wherex<>1 do write(#$c4);
    window(43,1,80,10); clrscr;
    window(45,1,80,10); gotoxy(1,1);
    writeln('Alt-B = backspacing toggle');
    writeln('Alt-C = clear screen');
    writeln('Alt-D = dial number');
    writeln('Alt-E = echo toggle');
    writeln('Alt-H = hang up phone');
    writeln('Alt-Q = redial last number');
    writeln('Alt-S = speed toggle');
    writeln('Alt-X = exit');
    writeln('PgUp  = send file from dloads');
    write('PgDn  = receive file into dloads');
    window(1,1,80,25); gotoxy(x,y);
  end;

  procedure om(ch:char);
  begin
    r.ax:=$0200;
    r.dx:=ord(ch);
    msdos(r);
  end;

begin
  clrscr; lnd:=0; eco:=false;
  if systat.maxbaud=300 then maxs:=0;
  if systat.maxbaud=1200 then maxs:=1;
  if systat.maxbaud=2400 then maxs:=2;
  assign(fil,'gfiles\numbers.dat');
  reset(fil);
  for i:=1 to 9 do read(fil,ns[i]);
  close(fil);
  writeln('Press [HOME] for help');
  writeln;
  hs:=maxs; cs(hs); bac:=false;
  done:=false;
  pc('ATQ0V1E1S2=43M1S11=50');
  rl:=timer;
  repeat
    if commpressed then begin
      c:=cinkey;
      if c=chr(12) then clrscr else
        if c=chr(8) then begin
          om(c);
          if bac then begin
            om(' '); om(#8);
          end;
        end
      else
        if c<>chr(0) then om(c);
    end else begin
      if timer<rl then rl:=rl-24.0*3600.0;
      if timer-rl>10.0*60.0 then done:=true;
    end;
    if keypressed then begin
      read(kbd,c);
      if c=chr(27) then
        if keypressed then begin
          read(kbd,c); case ord(c) of
            48:begin bac:=not bac; writeln; writeln;
                 if bac then writeln('-Destructive-') else writeln('=Non-Destructive=');
                 writeln; writeln;
               end;
            45:done:=true;
            31:begin hs:=hs+1; if hs>maxs then hs:=0; cs(hs); end;
            32:dial;
            16:if (lnd>0) and (lnd<10) then redial;
            35:hang;
            73:ul;
            81:dl;
            71:help;
            46:clrscr;
            18:begin eco:=not eco; writeln; writeln;
                 if eco then writeln('-= ECHO ON =-') else writeln('=- ECHO OFF -=');
                 writeln; writeln;
               end;
          end;
        end else
          om(c)
      else begin o1(c); if eco then om(c); end;
    rl:=timer;
    end;
  until done;
  hang; delay(1000); pc('ATS0=0Q0V0E0M0S2=1S7=30'); delay(100); dump;
end;

overlay procedure uedit(usern:integer);
var user,user1:userrec; c:char; r:restrictions; i,i1,x:integer; save:boolean; ii,is:str; f:file;
  mr:mailrec; byt:byte;
  searchopt:record
              sslh,ssll:byte;             bsl:boolean;
              sdslh,sdsll:byte;           bdsl:boolean;
              scomp:byte;                 bcomp:boolean;
              ssex:char;                  bsex:boolean;
              sagel,sageh:byte;           bage:boolean;
              sar:set of acrq;            bar:boolean;
              slastonh,slastonl:integer;  blaston:boolean;
            end;

  function filename(mrec:messages):str;
  begin
    filename:='msgs\'+mrec.ltr+cstr(mrec.number)+'.'+cstr(mrec.ext);
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

  procedure dsr(uname:str);
  var i,rn:integer; sr:smalrec;
  begin
    rn:=0;
    for i:=1 to systat.users do
      if srl[i].name=uname then
        rn:=i;
    if rn<>0 then begin
      for i:=rn to systat.users-1 do srl[i]:=srl[i+1];
      systat.users:=systat.users-1;
      savesystat;
      rewrite(sf); for i:=0 to systat.users do write(sf,srl[i]); close(sf);
    end else sl1('*** Couldn''t delete "'+uname+'"');
  end;

  procedure rsm;
  var x:smr; i:integer;
  begin
    {$I-} reset(smf); {$I+}
    if ioresult=0 then begin
      i:=0; ansic(1);
      repeat
        if i<=filesize(smf)-1 then begin seek(smf,i); read(smf,x); end;
        while (i<filesize(smf)-1) and (x.destin<>usernum) do begin
          i:=i+1; seek(smf,i); read(smf,x);
        end;
        if (x.destin=usernum) and (i<=filesize(smf)-1) then begin
          print(x.msg);
          seek(smf,i); x.destin:=-1; write(smf,x);
          smread:=true;
        end;
        i:=i+1;
      until (i>filesize(smf)-1) or hangup;
      close(smf);
      ansic(0);
    end;
  end;

  procedure finduser(var usernum:integer);
  var t,i,i1:integer;
      nn:str;
  begin
    input(nn,25);
    usernum:=value(nn); if usernum>0 then begin
      if usernum>filesize(uf)-1 then begin
        print('Unknown User.');
        usernum:=0; end
      else begin
        seek(uf,usernum);
        read(uf,user);
      end;
    end else begin
      i:=1; i1:=systat.users; t:=(i1+i) div 2;
      while ((i1-i)>1) and (srl[t].name<>nn) do begin
        if srl[t].name<nn then
          i:=t
        else
          i1:=t;
        t:=(i1+i) div 2;
      end;
      usernum:=0;
      if srl[i].name=nn then usernum:=srl[i].number;
      if srl[i1].name=nn then usernum:=srl[i1].number;
      if srl[t].name=nn then usernum:=srl[t].number;
      if usernum=0 then print('Unknown User.');
     end;
   end;

    procedure pcuropt;
    var c:char;
    begin
      prompt('1. Security level     : ');
      if searchopt.bsl then
        print(cstr(searchopt.ssll)+' to '+cstr(searchopt.sslh))
      else
        print('Inactive');
      prompt('2. D/L Security level : ');
      if searchopt.bdsl then
        print(cstr(searchopt.sdsll)+' to '+cstr(searchopt.sdslh))
      else
        print('Inactive');
      prompt('3. Computer type      : ');
      if searchopt.bcomp then
        print(comptyp[searchopt.scomp])
      else
        print('Inactive');
      prompt('4. Sex                : ');
      if searchopt.bsex then
        if searchopt.ssex='M' then
          print('Male')
        else
          print('Female')
      else
        print('Inactive');
      prompt('5. Age                : ');
      if searchopt.bage then
        print(cstr(searchopt.sagel)+' to '+cstr(searchopt.sageh))
      else
        print('Inactive');
      prompt('6. AR                 : ');
      if searchopt.bar then begin
        for c:='A' to 'G' do
          if c in searchopt.sar then outkey(c) else outkey(' ');
        nl;
      end else
        print('Inactive');
      prompt('7. Last On            : ');
      if searchopt.blaston then
        print(cstr(searchopt.slastonl)+' days to '+cstr(searchopt.slastonh)+' days ago')
      else
        print('Inactive');
    end;

  procedure stopt;
  var n:integer; c,ch:char; done:boolean; i:str;
    procedure chbyte(var x:byte);
    var i:str; n:integer;
    begin
      input(i,3); n:=x;
      if i<>'' then n:=value(i);
      if (n>=0) and (n<=255) then x:=n;
    end;
    procedure chword(var x:integer);
    var i:str; n:integer;
    begin
      input(i,3); n:=x;
      if i<>'' then n:=value(i);
      if (n>=0) and (n<=32767) then x:=n;
    end;
  begin
    cls; done:=false; pcuropt;
    repeat
      prompt('Change (?,Q) : ');
      onek(ch,'Q?1234567TL');
      case ch of
        'Q':done:=true;
        '?':begin
              nl;
              print('Q>uit          ?>help');
              print('L>ist options  T>oggle options');
              print('1-7> change options');
              nl;
            end;
        'L':pcuropt;
        'T':begin
              nl; prompt('Which (1-7) ? '); onek(ch,#13'1234567');
              case ch of
                '1':searchopt.bsl:=not searchopt.bsl;
                '2':searchopt.bdsl:=not searchopt.bdsl;
                '3':searchopt.bcomp:=not searchopt.bcomp;
                '4':searchopt.bsex:=not searchopt.bsex;
                '5':searchopt.bage:=not searchopt.bage;
                '6':searchopt.bar:=not searchopt.bar;
                '7':searchopt.blaston:=not searchopt.blaston;
              end;
              ch:=#0;
            end;
        '1':if searchopt.bsl then begin
             nl; print('Security Level:');
              prompt('Lower limit ('+cstr(searchopt.ssll)+') ? ');
              chbyte(searchopt.ssll);
              prompt('Upper limit ('+cstr(searchopt.sslh)+') ? ');
              chbyte(searchopt.sslh);
            end;
        '2':if searchopt.bdsl then begin
              nl; print('Download Security Level:');
              prompt('Lower limit ('+cstr(searchopt.sdsll)+') ? ');
              chbyte(searchopt.sdsll);
              prompt('Lower limit ('+cstr(searchopt.sdslh)+') ? ');
              chbyte(searchopt.sdslh);
            end;
        '3':if searchopt.bcomp then begin
              nl; for n:=1 to 8 do print(cstr(n)+'. '+comptyp[n]);
              nl; prompt('Comp type (1-8) ? '); onek(ch,'12345678');
              if ch in ['1'..'8'] then searchopt.scomp:=value(ch);
              ch:=#0;
            end;
        '4':if searchopt.bsex then begin
              nl; prompt('Sex (M,F) ? '); onek(searchopt.ssex,'MF');
            end;
        '5':if searchopt.bage then begin
              nl; print('Age:');
              prompt('Lower limit ('+cstr(searchopt.sagel)+') ? ');
              chbyte(searchopt.sagel);
              prompt('Upper limit ('+cstr(searchopt.sageh)+') ? ');
              chbyte(searchopt.sageh);
            end;
        '6':if searchopt.bar then begin
              prompt('Which board? '); onek(c,#13'ABCDEFG'); c:=upcase(c);
              if c in ['A'..'G'] then if c in searchopt.sar then
                searchopt.sar:=searchopt.sar-[c]
              else
                searchopt.sar:=searchopt.sar+[c];
            end;
        '7':if searchopt.blaston then begin
              nl; print('Limits of number of days since last logon:');
              prompt('Lower limit ('+cstr(searchopt.slastonl)+') ? ');
              chword(searchopt.slastonl);
              prompt('Upper limit ('+cstr(searchopt.slastonh)+') ? ');
              chword(searchopt.slastonh);
            end;
      end;
    until done or hangup;
  end;

  procedure delusr;
  var vdata:file of vdatar; vd:vdatar; j:integer;
  begin
    prompt('Delete? '); if yn and (not user.deleted) then begin
      save:=true; user.deleted:=true; dsr(user.name);
      i:=usernum; usernum:=usern; rsm; usernum:=i;
      user.waiting:=0; reset(mailfile);
      for i:=0 to filesize(mailfile)-1 do begin
        seek(mailfile,i); read(mailfile,mr); i1:=0;
        if (mr.destin=usern) or (abs(mr.from)=usern) then begin
          if abs(mr.from)=usern then i1:=mr.destin;
          assign(f,filename(mr.msg)); {$I-} erase(f); {$I+} x:=ioresult;
          mr.destin:=-1; mr.from:=0; seek(mailfile,i); write(mailfile,mr);
        end;
        if (i1>0) and (i1<filesize(uf)) then begin
          seek(uf,i1); read(uf,user1); user1.waiting:=user1.waiting-1;
          seek(uf,i1); write(uf,user1); if i1=1 then fw:=fw-1;
        end;
      end;
      close(mailfile);
      assign(vdata,'gfiles\voting.dat');
      reset(vdata);
      for j:=1 to filesize(vdata) do
        if user.vote[j]>0 then begin
          seek(vdata,j-1); read(vdata,vd);
          vd.answ[user.vote[j]].numres:=vd.answ[user.vote[j]].numres-1;
          seek(vdata,j-1); write(vdata,vd);
          user.vote[j]:=0;
        end;
      close(vdata);
    end;
  end;

  procedure renusr;
  begin
    if user.deleted then print('Can''t rename deleted users.') else begin
      nl;prompt('Enter new name or <CR>: '); input(ii,25);
      if (ii<>'') and (ii[1] in ['A'..'Z']) then begin
        dsr(user.name); isr(ii,usern); user.name:=ii; save:=true;
        if usern=usernum then thisuser.name:=ii;
      end;
    end;
  end;

  procedure printhelp;
  begin
    print('S - change seclev      A - change access');
    print('[ - down one user      ] - up one user');
    print('U - go to user         B - board access');
    print('D - delete user        R - restore user');
    print('N - change name        P - change phone number');
    print('E - change real name   Q - quit');
    print('L - aLert for user     T - Transfer SL');
    print('{ - search down        } - search up');
    print('O - set search Options C - Computer type');
    print('G - set aGe            F - user note');
    pausescr;
  end;

  procedure search(i:integer);
  var n:integer; u:userrec;

    function okusr(n:integer):boolean;
    var ok:boolean;
    begin
      seek(uf,n); read(uf,u); ok:=true;
      with searchopt do begin
        if bsl then
          if (u.sl<ssll) or (u.sl>sslh) then ok:=false;
        if bdsl then
          if (u.dsl<sdsll) or (u.dsl>sdslh) then ok:=false;
        if bcomp then
          if u.comptype<>scomp then ok:=false;
        if bsex then
          if (ssex<>u.sex) and (u.sex<>' ') then ok:=false;
        if bage then
          if ((u.age<sagel) or (u.age>sageh)) and (u.age<>0) then ok:=false;
        if bar then
          if not (u.ar>=sar) then ok:=false;
        if blaston then
          if (daynum(u.laston)<daynum(date)-slastonh) or
             (daynum(u.laston)>daynum(date)-slastonl) then ok:=false;
      end;
      okusr:=ok;
    end;

  begin
    n:=usern;
    repeat
      usern:=usern+i;
      if usern=0 then usern:=filesize(uf)-1;
      if usern=filesize(uf) then usern:=1;
    until okusr(usern) or (usern=n);
  end;

begin
  reset(uf);
  with searchopt do begin
    bsl:=false; bdsl:=false; bcomp:=false; bsex:=false; bage:=false; bar:=false; blaston:=false;
    sslh:=255; ssll:=0; sdslh:=255; sdsll:=0; scomp:=1; ssex:='M';
    sagel:=0; sageh:=255; sar:=[]; slastonh:=32767; slastonl:=0;
  end;
  repeat
   seek(uf,usern); read(uf,user); save:=false;
   if (usern=usernum) and useron then user:=thisuser;
   with user do begin
    cls;
    prompt('Name         : '+name+' #'+cstr(usern));
    if deleted then print('  XXXXXXXXXXXXXXX') else nl;
    print('Real name    : '+realname);
    print('Phone number : '+ph);
    if realsl=255 then
      print('Password     : '+pw)
    else
      writeln('Password     : '+pw);
    print('Last on      : '+laston);
    print('Messages     : P='+cstr(msgpost)+' E='+cstr(emailsent)+' F='+
      cstr(feedback)+' W='+cstr(waiting));
    prompt('Logged on    : '+cstr(loggedon)); if laston=date then
      prompt('  '+cstr(ontoday)) else prompt('  0');
    print('  I'+cstr(illegal));
    print('Computer type: '+comptyp[comptype]);
    print('Time spent on: '+cstrr(ttimeon,10));
    if (sex='M') or (sex='F') then
      print('Sex, Age     : '+sex+' '+cstr(age));
    print('Sec Lev      : '+cstr(sl));
    if (sl=99) or (lcosysop in seclev[sl].anst) then
      print('SBN          : '+cstr(sbn));
    print('DL Sec Lev   : '+cstr(dsl)+' - '+cstr(uploads)+'-'+cstr(uk)+
      ' / '+cstr(downloads)+'-'+cstr(dk));
    if ac<>[] then begin
      prompt('Restrictions : ');
      for r:=rlogon to rmsg do
        if r in ac then prompt(copy('LCVBA*PEKM',ORD(R)+1,1)) else prompt(' '); nl;
    end;
    if ar<>[] then begin
      prompt('Board access : ');
      for c:='A' to 'G' do
        if c in ar then outkey(c) else outkey(' '); nl;
    end;
    if note<>'' then
      print('Note         : '+note);
    nl;
    if (nomail in option) or (forusr<>0) then begin
      prompt('Mail         : ');
      if nomail in option then
        print('Closed')
      else
        print('Forwarded to #'+cstr(forusr));
    end;
    if alert in option then print('Alert set.');
    nl;
   end;
   prompt('Option :'); onek(c,'QSA[]UBDRNPELTOCGF{}?'); c:=upcase(c);
   case c of
      'B': begin
             prompt('Which board? '); onek(c,#13'ABCDEFG'); c:=upcase(c);
             if c in ['A'..'G'] then if c in user.ar then user.ar:=user.ar-[c]
               else user.ar:=user.ar+[c];
             if c in ['A'..'G'] then save:=true;
           end;
      'O': stopt;
      'F': begin prompt('Note: '); inputl(user.note,39); save:=true; end;
      'G': begin
             prompt('New age? '); input(ii,3); byt:=value(ii);
             if (byt>8) and (byt<100) then begin
               user.age:=byt; save:=true;
             end;
           end;
      'C': begin
             nl; for i:=1 to 8 do print(cstr(i)+'. '+comptyp[i]);
             nl; prompt('Comp type (1-8) ? '); onek(c,'12345678');
             if c in ['1'..'8'] then user.comptype:=value(c);
             c:=#0; save:=true;
           end;
      '}': search(1);
      '{': search(-1);
      'U': begin
             prompt('Enter user: ');
             finduser(i); if i>0 then usern:=i;
           end;
      '[': begin
             usern:=usern-1; if usern=0 then usern:=filesize(uf)-1;
           end;
      ']': begin
             usern:=usern+1; if usern=filesize(uf) then usern:=1;
           end;
      'A': begin save:=true;
              print('LCVBA*PEKM');
              nl;prompt('Which? ');; onek(c,'LCVBA*PEKM'+#13); c:=upcase(c); print(c); nl;
              if c<>#13 then acch(c,user); save:=true;
           end;
      'S': if user.sl<>255 then begin prompt('Enter new SL: '); input(ii,4);
                 if ii<>'' then begin
                   byt:=value(ii); save:=true; if byt<255 then user.sl:=byt;
                 end;
                 if (user.sl=99) or (lcosysop in seclev[user.sl].anst) then begin
                   prompt('Which board #? '); input(ii,2);
                   if ii<>'' then user.sbn:=value(ii);
                   save:=true;
                 end;
           end;
      'T': begin prompt('Enter new DSL: '); input(ii,4);
                 if ii<>'' then user.dsl:=value(ii); save:=true;
           end;
      'D': delusr;
      'R': if user.deleted then begin save:=true; isr(user.name,usern); user.deleted:=false; end;
      'N': renusr;
      'P': begin prompt('New phone number: '); input(ii,12); if ii<>'' then
             begin user.ph:=ii; save:=true; end;
           end;
      'E': begin prompt('New Real Name: '); inputl(ii,14); if ii<>'' then
             begin user.realname:=ii; save:=true; end;
           end;
      'L': begin
             if alert in user.option then
               user.option:=user.option-[alert] else
               user.option:=user.option+[alert];
             save:=true;
           end;
      '?': printhelp;
   end;
   if save then begin seek(uf,usern); write(uf,user); if usern=usernum then thisuser:=user; end;
  until (c='Q') or hangup;
  close(uf);
end;

overlay procedure voteprint;
var vdata:file of vdatar; vd:vdatar; vn:integer; t:text; i1,i2:integer; u:userrec;
    x:array[1..maxusers] of array[1..9] of integer;
    s1,s2:str;

begin
  assign(t,'gfiles\votes.txt');
  rewrite(t);
  writeln(t); writeln(t,'Votes as of '+dat);
  reset(uf);
  print('Beginning output to file "VOTES.TXT"');
  i1:=1;
  while (i1<filesize(uf)) do begin
    seek(uf,i1); read(uf,u);
    for i2:=1 to 9 do
      x[i1][i2]:=u.vote[i2];
    i1:=i1+1;
  end;
  close(uf);
  assign(vdata,'gfiles\voting.dat');
  reset(vdata);
  for vn:=1 to 9 do begin
    seek(vdata,vn-1); read(vdata,vd);
    if vd.numa<>0 then begin
      writeln(t); writeln(t,vd.question);
      print(vd.question);
      for i1:=1 to vd.numa do begin
        writeln(t,'   '+vd.answ[i1].ans);
        for i2:=1 to systat.users do begin
          if x[srl[i2].number][vn]=i1 then begin
            writeln(t,'      '+srl[i2].name+' #'+cstr(srl[i2].number));
          end;
        end;
      end;
    end;
  end;
  close(t);
  close(vdata);
  print('Output complete.');
end;

overlay procedure tedit;
var cur,nex,las,b4:strptr;
    top,bottom,used:strptr;
    tline,curline,c1,c2:integer;
    fil:text;
    abort,next,done,allread:boolean;
    i1,i2:str;

procedure inli(var i:str);
var cp,rp:integer; c,c1:char; cv,cc:integer;

  procedure bkspc;
  begin
    if cp>1 then begin
      if (i[cp-2]=#3) and (i[cp-1] in [#0..#8]) then begin
        cp:=cp-1;
        ansic(0);
      end else
        if i[cp-1]=#8 then begin
          prompt(' ');
          rp:=rp+1;
        end else
          if i[cp-1]<>#10 then begin
            prompt(#8+' '+#8);
            rp:=rp-1;
          end;
      cp:=cp-1;
    end;
  end;

begin
  rp:=1; cp:=1;
  i:='';
  if ll<>'' then begin prompt(ll); i:=ll; ll:=''; cp:=length(i)+1; rp:=cp;end;
  repeat
    getkey(c);
    case ord(c) of
      32..255:if (cp<strlen) and (rp<thisuser.linelen) then begin
                i[cp]:=c; cp:=cp+1; rp:=rp+1; outkey(c); thisline:=thisline+c;
              end;
            8:bkspc;
           24:begin
                cp:=1; for cv:=1 to rp-1 do prompt(#8+' '+#8);
                ansic(0);
                rp:=1;
              end;
           23:if cp>1 then repeat
                bkspc;
              until (cp=1) or (i[cp]=' ') or ((i[cp]=chr(8)) and (i[cp-1]<>#3));
           14:if (not (rbackspace in thisuser.ac)) and (rp>1) and (cp<strlen) then begin
                prompt(chr(8)); i[cp]:=chr(8); cp:=cp+1; rp:=rp-1;
              end;
{           10:if (not (rbackspace in thisuser.ac)) and (cp<strlen) then begin
                prompt(c); i[cp]:=c; cp:=cp+1;
              end;}
           16:if okansi and (cp<strlen-1) then begin
                getkey(c1);
                if c1 in ['0'..'8'] then begin
                  i[cp]:=#3;
                  cp:=cp+1;
                  i[cp]:=chr(ord(c1)-ord('0'));
                  cp:=cp+1;
                  ansic(ord(i[cp-1]));
                end;
              end;
            9:begin
                cv:=5-(cp mod 5); if (cp+cv<strlen) and (rp+cv<thisuser.linelen) then
                  for cc:=1 to cv do begin
                    rp:=rp+1; prompt(' ');
                    i[cp]:=' '; cp:=cp+1;
                  end;
              end;
  end;
  until (c=chr(13)) or ((rp=thisuser.linelen) and (wordwrap in thisuser.defaults)) or hangup;
  i[0]:=chr(cp-1);
  if c<>chr(13) then begin
    cv:=cp-1;
    while (cv>1) and (i[cv]<>' ') and ((i[cv]<>chr(8)) or (i[cv-1]=#3)) do
      cv:=cv-1;
    if (cv>(rp div 2)) and (cv<>cp-1) then begin
      ll:=copy(i,cv+1,cp-cv); for cc:=cp-2 downto cv do prompt(chr(8));
      for cc:=cp-2 downto cv do prompt(' ');
      i[0]:=chr(cv-1);
    end;
  end;
  nl;
  if c=chr(13) then i:=i+chr(1);
end;

  function newptr(var x:strptr):boolean;
  begin
    if used<>nil then begin
      x:=used;
      used:=used^.next;
      newptr:=true;
    end else begin
      if (maxavail<0) or (maxavail>100) then begin
        new(x);
        newptr:=true;
      end else newptr:=false;
    end;
  end;

  procedure oldptr(var x:strptr);
  begin
    x^.next:=used;
    used:=x;
  end;

  procedure pline(cl:integer; var cp:strptr; var abort:boolean);
  var next:boolean; i:str;
  begin
    if not abort then begin
      if cp=nil then i:='      [END]' else begin
        i:=cstr(cl);
        while length(i)<4 do i:=' '+i;
        i:=i+': '+cp^.i;
      end;
      printacr(i,abort,next);
    end;
  end;

  procedure pl;
  var abort:boolean;
  begin
    abort:=false;
    pline(curline,cur,abort);
  end;

begin
  nl; allread:=true;
  used:=nil;
  top:=nil;
  bottom:=nil;
  fix(ix[2]);
  if (pos('.MSG',ix[2])=0) and (pos('.TXT',ix[2])=0) then ix[2]:='';
  if ix[2]='' then print('Illegal filename.') else begin
    assign(fil,ix[2]); abort:=false;
    {$I-} reset(fil); {$I+}
    tline:=0;
    new(cur);
    cur^.last:=nil;
    cur^.i:='';
    if ioresult<>0 then begin
      {$I-} rewrite(fil); {$I+}
      if ioresult<>0 then begin
        print('Illegal filename.');
        abort:=true;
      end else begin
        close(fil); erase(fil);
        print('New file.');
        tline:=0;
        cur:=nil; top:=cur; bottom:=cur;
      end;
    end else begin
      abort:=not newptr(nex);
      top:=nex;
      print('Loading...');
      while (not eof(fil)) and (not abort) do begin
        tline:=tline+1;
        cur^.next:=nex;
        nex^.last:=cur;
        cur:=nex;
        readln(fil,i1);
        cur^.i:=i1;
        abort:=not newptr(nex);
      end;
      close(fil);
      cur^.next:=nil;
      if tline=0 then begin cur:=nil; top:=nil; end;
      bottom:=cur;
      if abort then begin print('Not all of file read.'); allread:=false; end;
      abort:=false;
    end;
    if not abort then begin
      print('Total lines: '+cstr(tline));
      cur:=top;
      if top<>nil then top^.last:=nil;
      curline:=1;
      done:=false;
      pl;
      repeat
        prompt(':');
        input(i1,10);
        if i1='' then i1:='+';
        if value(i1)>0 then begin
          c1:=value(i1);
          if (c1>0) and (c1<=tline) then begin
            while c1<>curline do
              if c1<curline then begin
                if cur=nil then begin
                  cur:=bottom;
                  curline:=tline;
                end else begin
                  curline:=curline-1;
                  cur:=cur^.last;
                end;
              end else begin
                curline:=curline+1;
                cur:=cur^.next;
              end;
            pl;
          end;
        end else case i1[1] of
          '+':if cur<>nil then begin
                c1:=value(copy(i1,2,9));
                if c1=0 then c1:=1;
                while (cur<>nil) and (c1>0) do begin
                  cur:=cur^.next;
                  curline:=curline+1;
                  c1:=c1-1;
                end;
                pl;
              end;
          '?':begin
                print('P:rint line      L:ist');
                print('-:back line      +:forward line');
                print('T:op             B:ottom');
                print('I:nsert lines    D:elete line');
                print('R:eplace line    C:lear workspace');
                print('Q:uit            S:ave');
              end;
          '-':begin
                c1:=value(copy(i1,2,9));
                if c1=0 then c1:=1;
                if cur=nil then begin
                  cur:=bottom;
                  curline:=tline;
                  c1:=c1-1;
                end;
                if cur<>nil then
                  if cur^.last<>nil then begin
                    while (cur^.last<>nil) and (c1>0) do begin
                      cur:=cur^.last;
                      curline:=curline-1;
                      c1:=c1-1;
                    end;
                    pl;
                  end;
              end;
          'C':begin
                prompt('Clear workspace? ');
                if yn then begin
                  tline:=0; curline:=1;
                  cur:=nil; top:=nil; bottom:=nil;
                  release(topheap);
                end;
              end;
          'P':pl;
          'D':begin
                c1:=value(copy(i1,2,9));
                if c1=0 then c1:=1;
                while (cur<>nil) and (c1>0) do begin
                  las:=cur^.last;
                  nex:=cur^.next;
                  if las<>nil then las^.next:=nex;
                  if nex<>nil then nex^.last:=las;
                  oldptr(cur);
                  if bottom=cur then bottom:=las;
                  if top=cur then top:=nex;
                  cur:=nex;
                  tline:=tline-1;
                  c1:=c1-1;
                end;
                pl;
              end;
          'R':if cur<>nil then begin
                pl;
                i2:=cstr(curline); while length(i2)<>4 do i2:=' '+i2;
                i2:=i2+': '; prompt(i2);
                inli(i1);
                cur^.i:=i1;
              end;
          'I':begin
                abort:=false; ll:='';
                print('Enter "." on a seperate line to exit insert mode.');
                i1:=''; thisuser.linelen:=thisuser.linelen-6;
                while (not hangup) and (not abort) and (i1<>'.') and (i1<>'.'+#1) do begin
                  i2:=cstr(curline); while length(i2)<>4 do i2:=' '+i2;
                  i2:=i2+': '; prompt(i2);
                  inli(i1);
                  if (i1<>'.') and (i1<>'.'+#1) then begin
                    abort:=not newptr(nex);
                    if not abort then begin
                      nex^.i:=i1;
                      if (top=cur) then
                        if cur=nil then begin
                          nex^.last:=nil;
                          nex^.next:=nil;
                          top:=nex;
                          bottom:=nex;
                        end else begin
                          nex^.next:=cur;
                          cur^.last:=nex;
                          top:=nex;
                        end
                      else begin
                        if cur=nil then begin
                          bottom^.next:=nex;
                          nex^.last:=bottom;
                          nex^.next:=nil;
                          bottom:=nex;
                        end else begin
                          las:=cur^.last;
                          nex^.last:=las;
                          nex^.next:=cur;
                          cur^.last:=nex;
                          las^.next:=nex;
                        end;
                      end;
                      curline:=curline+1;
                      tline:=tline+1;
                    end else print('No room left.');
                  end;
                end;
                thisuser.linelen:=thisuser.linelen+6;
              end;
          'T':begin
                cur:=top;
                curline:=1;
                pl;
              end;
          'B':begin
                cur:=nil;
                curline:=tline+1;
                pl;
              end;
          'L':begin
                abort:=false;
                nex:=cur;
                c1:=curline;
                while (not abort) and (nex<>nil) do begin
                  pline(c1,nex,abort);
                  nex:=nex^.next;
                  c1:=c1+1;
                end;
              end;
          'Q':done:=true;
          'S':begin
                if not allread then begin
                  prompt('Not all of file read.  Save anyway? ');
                  allread:=yn;
                end;
                if allread then begin
                  done:=true; c1:=0;
                  writeln('Saving...');
                  sysoplog('TEDIT: Saved "'+ix[2]+'"');
                  rewrite(fil);
                  cur:=top;
                  while cur<>nil do begin
                    writeln(fil,cur^.i);
                    cur:=cur^.next;
                    c1:=c1+1;
                  end;
                  if c1=0 then writeln(fil);
                  close(fil);
                end;
              end;
        end;
      until done or hangup;
    end;
  end;
  release(topheap);
end;

overlay procedure loadhelp;
var f:file; ch1:char; a,b,c:integer;
    help:array[0..25000] of char;
begin
  assign(f,'gfiles\help.msg');
  for ch1:='0' to '^' do helpi[ch1]:=0;
  {$I-} reset(f,1); {$I+}
  if ioresult=0 then begin
    blockread(f,help[1],25000,a);
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
    print('Help file loaded.');
  end else print('No help file present.');
  nl;
end;

overlay procedure gfileedit;
var b,b1:gft; f:file of gft; i:str; t,c:integer; ok,exit:boolean;
    gftit:array[1..150] of record tit:string[80]; arn:integer; gfile:boolean;end;
    nums,lgftn,numgft:integer;
    gfs:array[0..100] of record tit:string[80]; arn:integer; end;
    c1,c2,c3,c4:integer; s1,s2,s3,s4:str; ch:char;

  procedure gettit(n:integer);
  var r:integer; b:gft;
  begin
    numgft:=0;
    r:=n+1;
    if r<=t then begin
      seek(f,r); read(f,b);
      while (r<=t) and (b.filen[1]<>#1) do begin
        begin
          numgft:=numgft+1;
          gftit[numgft].tit:=b.title;
          gftit[numgft].arn:=r;
          gftit[numgft].gfile:=true;
        end;
        r:=r+1;
        if (r<=t) then begin seek(f,r); read(f,b);end;
      end;
    end;
  end;

  procedure getsec;
  var r:integer; b:gft;
  begin
    nums:=0;
    gfs[0].tit:='[ Main Section ]';
    gfs[0].arn:=0;
    for r:=1 to t do begin
      seek(f,r); read(f,b);
      if b.filen[1]=#1 then begin
        nums:=nums+1;
        gfs[nums].tit:='[ '+b.title+' ]';
        gfs[nums].arn:=r;
      end;
    end;
    gfs[nums+1].arn:=t+1;
  end;

  procedure listsec;
  var r:integer; i:str; abort,next:boolean;
  begin
    r:=0; abort:=false; nl; nl;
    while (r<=nums) and (not abort) do begin
      i:=cstr(r)+': '+gfs[r].tit;
      r:=r+1;
      printacr(i,abort,next);
    end;
  end;

  procedure lgft;
  var abort,next:boolean; c:integer; b:gft;
  begin
    nl; nl;
    if numgft=0 then print('No G-files.') else begin
      abort:=false; next:=false; c:=1;
      while (c<=numgft) and (not abort) do begin
        seek(f,gftit[c].arn); read(f,b);
        i:=cstr(c)+': '; if length(i)=3 then i:=' '+i;
        i:=i+b.filen;
        while length(i)<18 do i:=i+' ';
        i:=i+cstr(b.num);
        while length(i)<24 do i:=i+' ';
        i:=i+b.title;
        printacr(i,abort,next);
        c:=c+1;
      end;
    end;
  end;

begin
  nl;assign(f,'gfiles\gfiles.dat'); {$I-} reset(f); {$I+}
  if ioresult<>0 then begin
    rewrite(f); b.num:=0; write(f,b);
  end;
  seek(f,0); read(f,b); t:=b.num; exit:=false;
    repeat
      nl; nl;prompt('Gfile Edit: Q,I,D,S,? : ');
      onek(ch,'QIDS?'); getsec;
      case ch of
        'Q':exit:=true;
        '?':begin
              print('Q:uit from gfile edit   ?:this list');
              print('I:nsert G-file          D:delete G-file');
              print('S:ection modification');
            end;
        'S':begin
              prompt('I:nsert, D:elete, Q:uit ? '); onek(ch,'QID');
              case ch of
                'I':begin
                      listsec;
                      prompt('Before which section (1-'+cstr(nums+1)+') : '); input(s1,2);
                      c1:=value(s1);
                      if (c1>0) and (c1<=(nums+1)) then begin
                        if c1<=nums then
                          c1:=gfs[c1].arn
                        else
                          c1:=t+1;
                        prompt('Section title? '); inputl(b.title,40);
                        prompt('SL requirement? '); input(s1,3);
                        b.num:=value(s1); b.filen:=#1#0#0#0#0#0;
                        for c3:=t downto c1 do begin
                          seek(f,c3); read(f,b1); seek(f,c3+1); write(f,b1);
                        end;
                        seek(f,c1); write(f,b); t:=t+1;
                        b.num:=t; seek(f,0); write(f,b);
                      end else print('Illegal section number.');
                    end;
                'D':begin
                      listsec;
                      prompt('Delete which section (1-'+cstr(nums)+') : '); input(s1,2);
                      c1:=value(s1);
                      if ((c1>0) and (c1<=nums)) then begin
                        c2:=gfs[c1].arn;
                        if c1=nums then c3:=t+1 else c3:=gfs[c1+1].arn;
                        c1:=(c3-c2);
                        for c4:=c3 to t do begin
                          seek(f,c4); read(f,b); seek(f,c4-c1); write(f,b);
                        end;
                        seek(f,0); t:=t-c1; b.num:=t; write(f,b);
                      end;
                    end;
              end;
            end;
        'D':begin
              listsec;
              prompt('Which section (0-'+cstr(nums)+') : '); input(s1,2);
              c1:=value(s1);
              if (s1='0') or ((c1>0) and (c1<=nums)) then begin
                gettit(gfs[c1].arn);
                lgft;
                prompt('Delete which (1-'+cstr(numgft)+') :');
                input(s1,3);
                c1:=value(s1);
                if (c1>0) and (c1<=(numgft)) then begin
                  c1:=gftit[c1].arn;
                  for c2:=c1+1 to t do begin
                    seek(f,c2); read(f,b); seek(f,c2-1); write(f,b);
                  end;
                  seek(f,0); read(f,b); b.num:=b.num-1;
                  seek(f,0); write(f,b); t:=t-1;
                end;
              end;
            end;
        'I':begin
              listsec;
              prompt('Which section (0-'+cstr(nums)+') : '); input(s1,2);
              c1:=value(s1);
              if (s1='0') or ((c1>0) and (c1<=nums)) then begin
                gettit(gfs[c1].arn);
                lgft; c4:=c1;
                prompt('Insert before which (1-'+cstr(numgft+1)+') :');
                input(s1,3);
                c1:=value(s1);
                if (c1>0) and (c1<=(numgft+1)) then begin
                  if c1<=numgft then
                    c2:=gftit[c1].arn
                  else
                    c2:=gfs[c4+1].arn;
                  prompt('Enter filename of new G-file : ');
                  input(b.filen,12); if (pos('.TXT',b.filen)=0) and
                  (pos('.MSG',b.filen)=0) then b.filen:='';
                  assign(f1,'gfiles\'+b.filen); {$I-} reset(f1); {$I+}
                  ok:=false; if ioresult=0 then begin close(f1); ok:=true; end;
                  if b.filen='' then ok:=false;
                  if ok then begin
                    nl; prompt('Enter title : '); inputl(b.title,40);
                    prompt('Enter SL : ');
                    input(i,3); b.num:=value(i);
                    for c3:=t downto c2 do begin
                      seek(f,c3); read(f,b1); seek(f,c3+1); write(f,b1);
                    end;
                    seek(f,c2); write(f,b); t:=t+1;
                    seek(f,0); read(f,b); b.num:=b.num+1; seek(f,0); write(f,b);
                    systat.gfiledate:=date; savesystat;
                  end else print('Illegal filename.');
                end;
              end;
            end;
      end;
    until exit or hangup;
  close(f);
  nl;nl;
end;

overlay procedure ren;
begin
  fix(ix[2]); fix(ix[3]); abort:=false; nl;
  if (ix[2]='') or (ix[3]='') then begin abort:=true; print('Illegal filename.'); end;
  if not abort then begin
    assign(f,ix[2]); {$I-} reset(f); {$I+}
    if ioresult=0 then begin
      close(f); assign(f,ix[3]); {$I-} reset(f); {$I+}
      if ioresult<>0 then begin
        {$I-} rewrite(f); {$I+}
        if ioresult=0 then begin
          close(f); erase(f); assign(f,ix[2]); rename(f,ix[3]);
          print('Renamed.');
        end else print('Illegal filename.');
      end else begin close(f); print('Filename already in use.'); end;
    end else print('File not found.');
  end;
end;

overlay procedure copyfile(srcname,destname:str);
var buffer: array[1..16384] of byte;
    dfs,nrec:integer;
    src, dest: file;

    procedure dodate;
    var r:regs; od,ot,ha:integer;
    begin
      srcname:=srcname+#0;
      destname:=destname+#0;
      with r do begin
        ax:=$3d00; ds:=seg(srcname[1]); dx:=ofs(srcname[1]); msdos(r);
        ha:=ax; bx:=ha; ax:=$5700; msdos(r);
        od:=dx; ot:=cx; bx:=ha; ax:=$3e00; msdos(r);
        ax:=$3d02; ds:=seg(destname[1]); dx:=ofs(destname[1]); msdos(r);
        ha:=ax; bx:=ha; ax:=$5701; cx:=ot; dx:=od; msdos(r);
        ax:=$3e00; bx:=ha; msdos(r);
      end;
    end;

begin
  assign(src,srcname); reset(src,1);
  if destname[2]=':' then dfs:=freek(ord(destname[1])-ord('@')) else dfs:=freek(0);
  if trunc(longfilesize(src)/1024.0)+1>=dfs then begin
    print('Disk full.');
    close(src);
  end else begin
    assign(dest,destname); rewrite(dest,1);
    nl; print('Copying...');
    repeat
      blockread(src,buffer,16384,nrec);
      blockwrite(dest,buffer,nrec);
    until nrec<16384;
    close(dest);
    close(src);
    dodate;
  end;
end;

