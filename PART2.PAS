overlay procedure readmail;
var in1,i,i1,mc,x,nmf:integer; c:char; abort,next:boolean; mr:mailrec; a:boolean;
  filevar:file; ii,is:str;
begin
  nl; helpl:='M';
  if thisuser.waiting=0 then print('You have no mail.') else begin
    reset(mailfile);
    if thisuser.waiting>1 then begin
      reset(uf);nl;
      print('Mail summary: :'+cstr(thisuser.waiting)+': pieces:'); mc:=0;
      i:=0; i1:=1; while (i<filesize(mailfile)) and not hangup do begin
        seek(mailfile,i); read(mailfile,mr); if mr.destin=usernum then
         if (mr.from<=0) and not (emailn in seclev[thisuser.sl].anst)
          then begin print(cstr(i1)+': >UNKNOWN<'); mc:=mc+1; end else begin
          seek(uf,abs(mr.from)); read(uf,user); print(''+cstr(i1)+' :'+user.name+
          ' #'+cstr(abs(mr.from))); i1:=i1+1; mc:=mc+1;
        end;
        i:=i+1;
      end;
      close(uf);nl;nl;
      ansic(5); print('Hit <ENTER> to read mail'); input(ii,2);nl;nl;
      thisuser.waiting:=mc; if usernum=1 then fw:=mc;
    end;
    i:=0; nmf:=0;
    repeat
      abort:=false;
      if i<=filesize(mailfile)-1 then begin seek(mailfile,i); read(mailfile,mr); end;
      while (i<filesize(mailfile)-1) and (mr.destin<>usernum) do begin
        i:=i+1; seek(mailfile,i); read(mailfile,mr);
      end;
      if (mr.destin=usernum) and (i<=filesize(mailfile)-1) then begin
      nmf:=nmf+1;
      repeat
        a:=false; if emailn in seclev[thisuser.sl].anst then a:=true;
        irt:='Your previous letter';
        nl; if mr.title<>'' then print('Title: '+mr.title); irt:=mr.title;
        if irt='' then irt:='Your previous letter';
        readmsg(mr.msg,a,next); next:=false; tleft;
        repeat
          nl; prt('Mail: D,I,R,A,? :');
          if cs then onek(c,'?ZDIRAV') else onek(c,'?DIRA');
          case c of
            'I':next:=true;
            '?':begin
                  print('D:elete     I:gnore');
                  print('R:e-read    A:uto-reply');
                end;
            'A','D','Z':begin
                      if c<>'Z' then ssm(abs(mr.from),nam+' read your letter on '+date);
                      is:=rmail(i); next:=true; nmf:=nmf-1;
                      thisuser.waiting:=thisuser.waiting-1;
                      topscr;
                    end;
            'V':if cs then vallastuser;
          end;
          if c='A' then begin
            in1:=thisuser.waiting;
            close(mailfile); autoreply; reset(mailfile);
            nmf:=nmf+thisuser.waiting-in1;
          end;
        until (C IN ['D','I','R','A','Z']) or hangup;
      until next or hangup;
      i:=i+1;
    end else i:=i+1;
    until (i>filesize(mailfile)-1) or hangup;
    close(mailfile); if not hangup then thisuser.waiting:=nmf;
  end;
end;

overlay procedure newuser;
var n:integer;
begin
  sl1('*** NEW USER *** '+time+' '+date+'   '+spd);
  if systat.users>=maxusers then begin
    print('Sorry, there are the maximum number');
    print('of users already.');
    hangup:=true;
  end else begin
    p1;
    reset(uf); n:=forwardm(1); close(uf);
    if p2 then email(n,true);
  end;
end;

overlay function getuser:boolean;
var tries:integer; pasw,phone:str; done,nu,ok:boolean;
begin
  macok:=false; nu:=false;
  window(1,5,80,25);
  echo:=true;nl;nl;nl;nl;nl;
  pasw:='';
  printfile('gfiles\welcome.msg');
  tries:=0;
  repeat
    repeat
      print('Enter number or name or "NEW"');
      prompt('NN: '); finduser(usernum);
      if usernum=0 then tries:=tries+1;
    until (tries=3) or hangup or (usernum<>0);
    if tries>=3 then hangup:=true;
    ok:=true; done:=false;
    if usernum=-1 then begin
      done:=true; ok:=false;
      if incom and systat.closedsystem then begin
        printfile('gfiles\system.msg');
        printfile('gfiles\nonewusr.msg');
        hangup:=true;
      end else
        nu:=true;
    end else begin
      echo:=false; reset(uf); seek(uf,usernum); read(uf,thisuser);
      topscr;
      prompt('PW: '); input(pasw,8);
      prompt('PH: ###-###-'); input(phone,4); echo:=true;
      if (thisuser.pw<>pasw) or (copy(thisuser.ph,9,4)<>phone) then begin
        nl; print(chr(7)+'ILLEGAL LOGON'+CHR(7)); nl;
        if (not hangup) and (usernum<>0) then sl1('### ILLEGAL LOGON USER #'+cstr(usernum));
        thisuser.illegal:=thisuser.illegal+1; seek(uf,usernum);
        write(uf,thisuser);
        ok:=false; tries:=tries+1; if tries>=3 then hangup:=true;
      end else done:=true;
      if (thisuser.sl=255) and ok and incom and not hangup then begin echo:=false;
        prompt('SY: '); input(pasw,8); echo:=true; if pasw<>systat.sysoppw then begin
          nl;print(chr(7)+'ILLEGAL LOGON'+chr(7)); nl; ok:=false;
          sl1('$$$$ ILLEGAL SYSOP SECOND PW $$$$'); done:=false;
          tries:=tries+1; if tries>=3 then hangup:=true;
        end;
      end;
      close(uf);
    end;
  until hangup or done;
  if not (nu or hangup) then begin
    if (rlogon in thisuser.ac) and (thisuser.laston=date) then begin
      print('You can only log on once per day.');
      hangup:=true; sl1(thisuser.name+' #'+cstr(usernum)+' tried logging on');
    end;
    if tries=3 then hangup:=true;
  end;
  getuser:=nu;
  checkit:=false;
end;

overlay procedure vote;
var vdata:file of vdatar; vd:vdatar; int,int2:integer; i,i1,ij:str; abort,next,done,lq:boolean;

procedure vote1(qnum:integer);
begin
  seek(vdata,qnum-1); read(vdata,vd);
  if vote1x(qnum,vd) then begin
    seek(vdata,qnum-1); write(vdata,vd);
  end;
end;

begin
  i:=''; done:=false; lq:=true; helpl:='V';
  assign(vdata,'gfiles\voting.dat');
  {$I-} reset(vdata); {$I+}
  if ioresult<>0 then print('No voting data found.') else
  repeat
    done:=false;
    ij:='Q?';
    abort:=false;
    if lq then begin
      cls; printacr('Current Questions:',abort,next); nl;
    end;
    int2:=0;
    for int:=1 to 9 do begin
      seek(vdata,int-1); read(vdata,vd);
      if vd.numa<>0 then begin
        int2:=int2+1;
        if lq and not abort then begin
          if thisuser.vote[int]=0 then i1:='* ' else i1:='  ';
          i1:=i1+cstr(int)+': '+vd.question;
          printacr(i1,abort,next);
        end;
        ij:=ij+cstr(int);
      end;
    end;
    lq:=false;
    if int2=0 then begin done:=true; print('No voting questions now.') end
    else begin
      nl; nl; prt('Which question (#,Q,?) : ');
      onek(i[1],ij); i[0]:=#1;
      int:=value(i); if i='Q' then done:=true; if i='?' then lq:=true;
      if (int>0) and (int<10) then vote1(int);
    end;
  until done or hangup;
  close(vdata);
end;

overlay function logon:boolean;
var fil:file of str; lo:array[1..8] of str; num:integer; i:str; ul:text; c:char;
    abort,rm:boolean;
begin
  logon1; rm:=false;
  if (realsl<>255) or incom then begin
    sl1('');
    sl1(cstr(systat.callernum)+': '+nam+' '+time+' '+date+'  '+spd+
      '  - '+cstr(thisuser.ontoday));
    if realsl<>255 then begin
      assign(ul,'gfiles\user.log'); append(ul);
      writeln(ul,cstr(systat.callernum)+': '+nam+'   '+spd+' - '+cstr(thisuser.ontoday)); close(ul);
      systat.callernum:=systat.callernum+1; systat.callstoday:=systat.callstoday+1;
    end;
  end;
  nl;nl; board:=1;
  mread:=0; extratime:=0.0; chattime:=0.0; timeon:=timer; extramsgs:=0;
  dump;
  if incom then begin
    printfile1('gfiles\logon.msg',abort);
    if not (abort or (pause in thisuser.defaults)) then
      pausescr;
  end;
  readamsg; savesystat;
  nl; nl; prompt('Name: '); ansic(3); print(nam);
  print('Time allowed on: '+cstr(seclev[thisuser.sl].ttime));
  if thisuser.waiting<>0 then print('Mail waiting   : '+cstr(thisuser.waiting));
  if thisuser.illegal<>0 then begin
    prompt(#7); ansic(8);
    print('Illegal logons : '+cstr(thisuser.illegal));
  end;
  if thisuser.laston<>date then print('Last on        : '+thisuser.laston)
    else print('Times on today : '+cstr(thisuser.ontoday));
  if (daynum(thisuser.laston)<=daynum(systat.gfiledate)) and
    (daynum(thisuser.laston)>0) then begin
    nl;
    print('There may be new g-files');
  end;
  abort:=false;
  for num:=1 to 9 do
    if vqu[num] and (thisuser.vote[num]=0) then abort:=true;
  if abort then begin nl; ansic(5); print('You haven''t voted yet.'); end;
  if thisuser.forusr<>0 then begin
    nl;
    ansic(5); print('Your mail is being forwarded to user #'+cstr(thisuser.forusr));
  end;
  nl;nl;useron:=true; topscr;
  if smw in thisuser.option then rsm;
  thisuser.option:=thisuser.option-[smw];
  if (alert in thisuser.option) and sysop1 then chatcall:=true;
  if thisuser.waiting<>0 then begin
    nl;nl; ynq('Read your mail now? ');
    if yn then begin nl; rm:=true; end;
    nl;nl;
  end;
  logon:=rm;
end;

overlay procedure reqchat;
begin
  helpl:='C';
  nl;nl; if (not sysop) or (rchat in thisuser.ac)
  then begin
    ansic(5); print('Sysop not available.');
    print('Use Feedback instead.');
    irt:='Tried chatting.';
    imail(1);
  end else begin
    if not chatcall then begin
      prt('Reason: '); inputl(i,70);
      if i<>'' then begin
        sysoplog('Chat: '+i);
        ansic(8); print('Chat call now on.');
        sound(440); delay(500); nosound;
        chatr:=i; chatcall:=true;
      end else chatr:='';
    end else
      begin chatcall:=false; print('Chat call turned off.'); chatr:='';end;
  end;
  nl;nl; tleft;
end;

overlay procedure abbs;
var filvar:text; i,i1,i2:str; c:char; tf:text; there:boolean;
begin
  if not(ramsg in thisuser.ac) and (thisuser.sl>10) then begin
    nl; ynq('Do you want to add to the bbs list? '); helpl:='A';
    if yn then begin
      repeat
        print('Enter the phone number in the form:');
        print(' ###-###-####');
        prt(':'); mpl(12); input(i1,12);
      until (length(i1)=12) or (i1='') or hangup;
      assign(tf,'gfiles\bbslist.msg'); there:=false;
      {$I-} reset(tf); {$I+} if ioresult=0 then while not eof(tf) do begin
        readln(tf,i); if copy(i,1,12)=i1 then there:=true;
      end;
      close(tf);
      if there then begin nl;nl; print('It''s already in there.');
        i1:=''; end;
      i:=i1; if i<>'' then begin
        print('Enter the name of the BBS:');
        prt(':'); mpl(49); inputl(i1,49);
        i:=i+'  '+i1;
        while length(i)<63 do i:=i+' ';
        nl; print('Enter max speed of system (ie, 300,1200,2400).');
        prt(':'); mpl(4); input(i2,4);
        if i2='' then
          i:=i+'        '
        else begin
          while length(i2)<4 do i2:=' '+i2;
          i:=i+'  ['+i2+']';
        end;
        if i1<>'' then begin
          print('Enter a 4 character BBS type (ie, WWIV).');
          prt(':');
          mpl(4);
          input(i1,4);
          if i1<>'' then i:=i+' ('+i1+')';
          nl;print(i); nl; ynq('Is this correct? ');
          if yn then begin
            assign(filvar,'gfiles\bbslist.msg'); {$I-} append(filvar); {$I+}
            if ioresult<>0 then
              rewrite(filvar);
            writeln(filvar,i);
            close(filvar);
            sysoplog('Added "'+i+'"');
          end;
        end;
      end;
    end;
  end;
end;

overlay procedure yourinfo;
begin
  cls;
  print('Your name      : '+nam);
  print('Phone number   : '+thisuser.ph);
  print('Mail waiting   : '+cstr(thisuser.waiting));
  print('Sec Lev        : '+cstr(thisuser.sl));
  print('Last on        : '+thisuser.laston);
  print('Times on       : '+cstr(1+thisuser.loggedon));
  print('On today       : '+cstr(thisuser.ontoday));
  print('Messages posted: '+cstr(thisuser.msgpost));
  print('E-mail sent    : '+cstr(thisuser.emailsent+thisuser.feedback));
  print('Time spent on  : '+cstrr(thisuser.ttimeon+((timer-timeon+30)/60),10)+' Minutes');
  print('Time this call : '+ctim(timer-timeon));
end;

overlay procedure prg(x:boolean);
var q:boolean;

procedure purge(var quit:boolean);
var cn:integer; c:char; a,b:boolean;
begin
  quit:=false;
  nl;
  print('== Purge '+boards[board].name+' ==');
  iscan;
  cn:=1;
  while (cn<=tnum) and (not quit) and (not hangup) do begin
    if mary[cn].owner<>usernum then cn:=cn+1 else begin
      readm(cn,a,b); nl;
      prt('D:elete, I:gnore, Q:uit :'); onek(c,'QDI');
      case c of
        'D':begin
              sysoplog('-'+mary[cn].title+' purged off '+boards[board].name);
              deletem(cn);
            end;
        'Q':begin quit:=true; cn:=tnum+1; end;
        'I':cn:=cn+1;
      end;
    end;
  end;
  print('== '+boards[board].name+' Purge Done ==');
  nl;
  savebase;
end;

procedure gpurge;
var quit:boolean;
begin
  print('=== GLOBAL PURGE ===');
  board:=1; repeat
    if (thisuser.sl>=boards[board].sl) and
      ((boards[board].ar='@') or (boards[board].ar in thisuser.ar)) then
        purge(quit);
    board:=board+1;
  until (board>numboards) or hangup or quit;
  board:=1;
  print('=== GLOBAL PURGE DONE ===');
end;

begin
  helpl:='J';
  if x then gpurge else purge(q);
end;

overlay procedure wamsg;
var filvar:text; ch:char;
begin
 helpl:='W'; ch:='?';
 repeat
   nl;
   if ch='?' then begin
     print('Options: ');
     print(' R. Read auto-message.');
     print(' W. Write auto-message.');
     print(' A. Auto-reply to auto-message.');
     print(' Q. Quit to BBS.');
   end;
   nl;
   prt('Which (R,W,A,Q,?) : '); onek(ch,'QRWA?');
   case ch of
     'R':readamsg;
     'W':if (ramsg in thisuser.ac) or (thisuser.sl<=10) then
           print('Sorry, you can''t.')
         else
           wmsg;
     'A':begin
           nl; assign(filvar,'gfiles\auto.msg');
           {$I-} reset(filvar); {$I+}
           irt:='Your auto-message';
           if ioresult<>0 then
             print('Nothing to reply to.')
           else begin
             readln(filvar,lastname);
             close(filvar);
             if lastname[1]='@' then
               if not (postn in seclev[thisuser.sl].anst) then
                 lastname:='';
             if (lastname[1]='!') and so then
               lastname:='';
             if lastname='' then
               print('You can''t reply')
             else
               autoreply;
           end;
         end;
   end;
 until (ch='Q') or hangup;
end;

overlay procedure removem;
var t:integer; i:str;
begin
  print('You have the following messages posted:');
  iscan; helpl:='R';
  for t:=1 to tnum do begin
    if mary[t].owner=usernum then
      print(cstr(t)+': '+mary[t].title);
  end; prt('Message to remove? ');
  input(i,3); t:=value(i);
  if t<>0 then
    if (t<1) or (t>tnum) then
        print('Illegal number') else begin
        if (mary[t].owner<>usernum) and not lcs then
          print('You didn''t write it.') else begin
            print(cstr(t)+': '+mary[t].title); ynq('Remove it? ');
            if yn then begin
              sysoplog('-'+mary[t].title+' deleted off of '+boards[board].name);
              deletem(t); print('Removed.');
            end;
          end;
        end;
  savebase;
end;

overlay procedure boardlist;
var b:integer; i:str; abort,next:boolean;
begin
  nl;nl; print('Boards available to you:'); print('');
  b:=1; abort:=false;
  while (b<=numboards) and (not abort) do begin
    if boardac(b) then begin
       if boards[b].key=' ' then i:=cstr(b)
       else i:=boards[b].key;
       if length(i)=1 then i:=' '+i;
       i:=i+' : '+boards[b].name;
       printacr(i,abort,next);
    end;
    b:=b+1;
  end;
  nl;nl;
end;

overlay procedure delmail;
var tu,d,i,x:integer; mr:mailrec; f:file; u:userrec; c:char; abort,next,done:boolean;
begin
  helpl:='K';
  ynq('Kill old E-mail? '); if yn then begin
  nl;nl;d:=daynum(date); reset(uf); reset(mailfile);i:=0; done:=false;
  while (i<filesize(mailfile)) and (not hangup) and (not done) do begin
    seek(mailfile,i); read(mailfile,mr);
    if (abs(mr.from)=usernum) and (mr.destin<>-1) then repeat
      tu:=mr.destin; seek(uf,tu); read(uf,u);
      nl;print('To   : '+u.name+' #'+cstr(tu));
      print('Title: '+mr.title);
      print('Sent : '+cstr(d-mr.date)+' days ago');
      nl; prt('R:ead, D:elete, N:ext, Q:uit : ');
      onek(c,'QNDR');
      case c of
        'Q':done:=true;
        'D':begin
              close(uf); sysoplog('Deleted mail to '+rmail(i)); reset(uf);
              if tu=usernum then thisuser.waiting:=thisuser.waiting-1;
              print('Mail deleted.');
            end;
        'R':begin nl; nl; readmsg(mr.msg,abort,next);end;
      end;
    until hangup or (c<>'R');
    i:=i+1;
  end;
  close(uf); close(mailfile); topscr;
 end;
end;

overlay procedure gfiles;
var b:gft; f:file of gft; i:str; t,c:integer; deep,exit:boolean;
    gftit:array[1..150] of record tit:string[80]; arn:integer; gfile:boolean;end;
    lgftn,lgftnt,numgft:integer; titl:str;

  procedure gettit(n:integer);
  var r:integer; b:gft;
  begin
    numgft:=0;
    if n>0 then begin
      seek(f,n); read(f,b); titl:='[ '+b.title+' ]';
    end else titl:='[ Main Section ]';
    r:=n+1;
    if r<=t then begin
      seek(f,r); read(f,b);
      while (r<=t) and (b.filen[1]<>#1) do begin
        if b.num<=thisuser.sl then begin
          numgft:=numgft+1;
          gftit[numgft].tit:=b.title;
          gftit[numgft].arn:=r;
          gftit[numgft].gfile:=true;
        end;
        r:=r+1;
        if (r<=t) then begin seek(f,r); read(f,b); end;
      end;
    end;
    if n=0 then
      while (r<=t) do begin
        seek(f,r); read(f,b);
        if (b.filen[1]=#1) and (b.num<=thisuser.sl) then begin
          numgft:=numgft+1;
          gftit[numgft].tit:='[ '+b.title+' ]';
          gftit[numgft].arn:=r;
          gftit[numgft].gfile:=false;
        end;
        r:=r+1;
      end;
  end;

  procedure lgft;
  var abort,next:boolean; c:integer;
  begin
    nl; print(titl); nl;
    if numgft=0 then print('No G-files.') else begin
      abort:=false; next:=false; c:=1;
      while (c<=numgft) and (not abort) do begin
        printacr(cstr(c)+': '+gftit[c].tit,abort,next);
        c:=c+1;
      end;
    end;
  end;

begin
  nl;assign(f,'gfiles\gfiles.dat'); {$I-} reset(f); {$I+}
  if ioresult<>0 then begin
    rewrite(f); b.num:=0; write(f,b);
  end;
  seek(f,0); read(f,b); t:=b.num; helpl:='G';
  if t=0 then print('No G-files yet.') else begin
    gettit(0); exit:=false;
    lgft; lgftn:=0; deep:=false; lgftnt:=0;
    repeat
      nl; nl;
      prt('Gfiles: (1-'+cstr(numgft)+', ^'+cstr(lgftn)+'),?,Q : ');
      input(i,3);
      if i='' then if lgftn=numgft then i:='Q' else i:=cstr(lgftn+1);
      if i='?' then lgft;
      if i='Q' then
        if deep then begin
          deep:=false;
          gettit(0);
          lgft;
          lgftn:=lgftnt;
        end else exit:=true;
      c:=value(i);
      if (c>0) and (c<=numgft) then begin
        if gftit[c].gfile=true then begin
          seek(f,gftit[c].arn);
          read(f,b);
          printfile('gfiles\'+b.filen);
          lgftn:=c;
        end else begin
          gettit(gftit[c].arn);
          lgftn:=c;
          if numgft>0 then begin
            lgft;
            lgftnt:=c; lgftn:=0;
            deep:=true;
          end else begin
            gettit(0);
            nl; print('No G-files there.');
          end;
        end;
      end;
    until exit or hangup;
  end;
  close(f);
  nl;nl;
end;

overlay procedure chpw;
var i:str;
begin
  cls; print('Your current password is "'+thisuser.pw+'"');
  print('If you change it, it must be between');
  print('three and eight characters. Do you want');
  helpl:='Z';
  prompt('to change it? ');
  if yn then begin
   repeat
     print('Enter new password:'); print(' (-!----)'); prt(':');
     mpl(8); input(i,8);
     nl;
   until (length(i)>2) or (i='') or hangup;
   if i<>'' then begin
     nl; nl; nl;
     print('Password: "'+i+'"');
     ynq('Is this what you want? ');
     if yn then begin
       if not hangup then thisuser.pw:=i;
       sysoplog('Changed password.');
     end else print('Password not changed.');
   end else print('Password not changed.');
  end;
end;

overlay procedure mmacro;
var i:str; c,mc:char; mcn,n,n1,mn:integer; done:boolean;
begin
  done:=false; helpl:='H';
  repeat
    nl; prt('Macros: M,L,Q,? :'); onek(c,'QML?');
    case c of
      '?':begin
            print('M:ake macro    L:ist macros');
            print('Q:uit          ?:this');
          end;
      'Q':done:=true;
      'L':begin
            nl; print('Current Macros:');
            for n:=1 to 2 do begin nl;
              if n=1 then print('Ctrl-D:') else print('Ctrl-F:');
              prompt('"');
              for n1:=1 to length(thisuser.macro[n]) do
                if thisuser.macro[n][n1]>=' ' then
                  prompt(thisuser.macro[n][n1])
                else
                  prompt('^'+chr(64+ord(thisuser.macro[n][n1])));
              print('"');
            end;
          end;
      'M':mmacroo;
    end;
  until done or hangup;
end;

overlay procedure default;
var c:char; i:str; i1,ii:integer;
begin
 c:='?';
 repeat
  if c='?' then pdfinf;
  nl;nl; helpl:='D'; prt('Enter number to change, Q or ? :');
  if okansi then onek(c,'Q123456789?') else onek(c,'Q12345678?'); nl;
  case c of
    '1':begin
          nl;nl;prt('Number of characters per line? ');
          input(i,2); if i<>'' then thisuser.linelen:=value(i);
          if thisuser.linelen>80 then thisuser.linelen:=80;
          if thisuser.linelen<32 then thisuser.linelen:=32;
          prt('Number of lines per page? ');
          input(i,2); if i<>'' then thisuser.pagelen:=value(i);
          if thisuser.pagelen>25 then thisuser.pagelen:=25;
          if thisuser.pagelen<4 then thisuser.pagelen:=4;
        end;
    '2':begin
          if not (onekey in thisuser.defaults) then begin
            thisuser.defaults:=thisuser.defaults+[onekey];
            print('One key input.'); end
          else begin
            thisuser.defaults:=thisuser.defaults-[onekey];
            print('Full line input.'); end
        end;
    '3':begin
          if not (wordwrap in thisuser.defaults) then begin
            thisuser.defaults:=thisuser.defaults+[wordwrap];
            print('Wordwrap on.'); end
          else begin
            thisuser.defaults:=thisuser.defaults-[wordwrap];
            print('Wordwrap off.'); end;
        end;
    '4':begin
          if not (ansi in thisuser.defaults) then begin
            thisuser.defaults:=thisuser.defaults+[ansi];
            print('ANSI active.'); end
          else begin
            thisuser.defaults:=thisuser.defaults-[ansi];
            print('ANSI disabled.'); end;
        end;
    '5':begin
          if not (color in thisuser.defaults) then begin
            thisuser.defaults:=thisuser.defaults+[color];
            print('Color on.'); end
          else begin
            thisuser.defaults:=thisuser.defaults-[color];
            print('Color off.'); end;
        end;
    '6':if pause in thisuser.defaults then
           begin thisuser.defaults:=thisuser.defaults-[pause];
           print('No pause on screen.'); end else
           begin thisuser.defaults:=thisuser.defaults+[pause];
           print('Pause on screen active.'); end;
    '7':if nomail in thisuser.option then begin
           thisuser.option:=thisuser.option-[nomail];
           print('Mailbox now open.');
         end else
           if thisuser.forusr<>0 then begin
             thisuser.forusr:=0;
             print('Mail no longer forwarded.');
           end else begin
             ynq('Do you want to close your mailbox? ');
             if yn then begin
               thisuser.option:=thisuser.option+[nomail];
               print('Mailbox now closed.');
               ansic(5); print('You >CAN NOT< recieve mail now.');
             end else begin
               ynq('Do you want your mail forwarded? ');
               if yn then forwardmail;
             end;
           end;
    '8':chbds;
    '9':if okansi then chcolors;
  end;
 until hangup or (c='Q');
 topscr;
end;

overlay procedure logoff;
var s,d:integer; mr:mailrec; x:smr; tt:integer;
begin
  term_ready(false);
  if timer<timeon then timeon:=timeon-86400.0;
  tt:=trunc((timer-timeon+30)/60);
  thisuser.laston:=systat.lastdate;
  thisuser.loggedon:=thisuser.loggedon+1;
  thisuser.sl:=realsl;
  thisuser.illegal:=0;
  thisuser.ttimeon:=thisuser.ttimeon+tt;
  reset(uf); seek(uf,usernum); write(uf,thisuser); close(uf);
  systat.activetoday:=systat.activetoday+tt;
  systat.fbacktoday:=systat.fbacktoday+ftoday;
  systat.emailtoday:=systat.emailtoday+etoday;
  savesystat;
  window(1,1,80,25);clrscr;
  if (realsl<>255) or incom then begin
    if hungup then sl1('*** HUNG UP ***');
    sl1('Read: '+cstr(mread)+'   Time on: '+cstr(tt));
  end;
  if mailread then begin
    {$I-}  reset(mailfile) {$I+};
    if ioresult=0 then
      if filesize(mailfile)>1 then begin
        s:=0; d:=0;
        while s<filesize(mailfile) do begin
          seek(mailfile,s); read(mailfile,mr);
          if (mr.destin<>-1) then
            if s=d then d:=d+1 else begin
              seek(mailfile,d); write(mailfile,mr); d:=d+1;
            end;
          s:=s+1;
        end;
        seek(mailfile,d); truncate(mailfile);
      end;
    close(mailfile);
  end;
  if smread then begin
    {$I-}  reset(smf) {$I+};
    if ioresult=0 then begin
      if filesize(smf)>1 then begin
        s:=0; d:=0;
        while s<filesize(smf) do begin
          seek(smf,s); read(smf,x);
          if x.destin<>-1 then
            if s=d then d:=d+1 else begin
              seek(smf,d); write(smf,x); d:=d+1;
            end;
          s:=s+1;
        end;
        seek(smf,d);
        truncate(smf);
      end;
      close(smf);
    end;
  end;
  if beepend then beephim;
end;

overlay procedure endday;
var cn,d,i,tu,fu:integer; mr:mailrec; f:file; u:userrec; b:messagerec; is:str;
  function old(dat,mage:byte):boolean;
  begin
    old:=(d-dat>mage) and (mage<255) and (mage-(d-dat)>-5) and (dat>0);
  end;
begin
  d:=daynum(date);
  if d<>ldate then
    if (d-ldate)=1 then
      ldate:=ldate+1
    else begin
      writeln('Date corrupted.');
      halt(1);
    end;
  reset(mailfile);
  for i:=0 to filesize(mailfile)-1 do begin
    seek(mailfile,i); read(mailfile,mr);
    if old(mr.date,mr.mage) and (mr.destin<>-1) then begin
      fu:=abs(mr.from);
      is:=rmail(i);
      ssm(fu,is+' never got your letter.');
    end;
  end;
  close(mailfile);
  reset(uf);
  for board:=1 to numboards do begin
    iscan;
    cn:=1;
    while cn<=tnum do begin
      if old(mary[cn].date,mary[cn].mage) or (mary[cn].messagestat=deleted) then
        deletem(cn)
      else
        cn:=cn+1;
    end;
    savebase;
  end;
  close(uf);
end;

overlay procedure smail(tf:boolean);
var ix,c1,c2,c3,c4:integer; c:char;
    mr:mailrec; t,e,cp:integer; f:messages; a:anontyp; i:str; us:userrec;
    na:emary; ok,abort:boolean;
begin
  if tf=false then begin
    irt:=''; helpl:='Q';
    print('Enter user name or number.'); prt(':');
    finduser(ix);
    if ix>0 then
      imail(ix);
  end else if not((remail in thisuser.ac) or
    ((etoday>=seclev[thisuser.sl].emails) and (thisuser.sl<55))) then begin
      reset(uf); helpl:='E'; irt:='';
      repeat
        nl; nl; print('Send mail to more than one user.'); ok:=false;
        print('Enter user NUMBERS, separated by commas, max 20.');
        prt(':'); input(i,78); abort:=(i='');
        for c1:=1 to 20 do na[c1]:=0;
        c1:=1; c2:=1;
        while i<>'' do begin
          c3:=pos(',',i);
          if c3=0 then c3:=length(i)+1;
          c4:=value(copy(i,1,c3-1));
          i:=copy(i,c3+1,length(i)-c3);
          if (c4<1) or (c4>maxusers) or (c4>=filesize(uf)) then c4:=0;
          if c4<>0 then begin
            seek(uf,c4); read(uf,us);
            if us.deleted or (((c4=1) and (us.waiting>50)) or ((c4<>1) and
              (us.waiting>15)) or ((nomail in us.option) and not cs)) and (not so) or
              ((c4=usernum) and (not cs)) then begin
                print('Can''t E-mail '+us.name+' #'+cstr(c4));
                c4:=0;
              end;
            if (c4<>0) and (us.forusr<>0) then c4:=forwardm(c4);
            if not cs then
              for c2:=1 to 20 do
                if na[c2]=c4 then
                  c4:=0;
            if (c4<>0) and (c1<=20) then begin
              na[c1]:=c4;
              c1:=c1+1;
            end;
          end;
        end;
        if not abort then begin
          nl; print('Users marked:');
          c1:=1;
          while (na[c1]<>0) and (c1<=20) do begin
            seek(uf,na[c1]); read(uf,us); print('  '+us.name+' #'+cstr(na[c1]));
            c1:=c1+1;
          end;
          if na[1]=0 then print('  None');
          nl; ynq('Is this correct? ');  ok:=yn;
        end else ok:=true;
      until ok or hangup;
      smail2(na);
      close(uf);
    end;
end;

overlay procedure ulist;
var ct,inte:integer; abort,next:boolean; u:userrec;
begin
  nl;
  print('Users with access to current board:');
  nl;
  reset(uf); ct:=0;
  inte:=0; abort:=false;
  while (not abort) and (inte<systat.users) do begin
    inte:=inte+1;
    seek(uf,srl[inte].number); read(uf,u);
    if (u.sl>=100) or ((u.sl>=boards[board].sl) and
      ((boards[board].ar='@') or (boards[board].ar in u.ar))) then begin
        printacr(srl[inte].name+' #'+cstr(srl[inte].number),abort,next);
        ct:=ct+1;
      end;
  end;
  if not abort then begin
    nl;
    printacr(cstr(ct)+' Users.',abort,next);
  end;
  close(uf);
end;

overlay procedure dloads;
var f:file; ok:boolean;
begin
  ok:=true;
  if (thisuser.sl<=10) or (thisuser.dsl=0) then ok:=false;
  if cs then ok:=true;
  if not ok then print('You can''t access the file system.') else chn('dloads');
end;

overlay procedure dos(c:char);
var f:file;
begin
  cmd:=upcase(c);
  assign(f,'dos.chn');
  {$I-} reset(f); {$I+}
  if ioresult=0 then begin
    print('Loading.');
    close(f);
    remove_port;
    if useron then
      case upcase(c) of
        'U':sysoplog('DOS: Uedit');
        'E':sysoplog('DOS: Tedit');
        'G':sysoplog('DOS: G-file edit');
        'D':sysoplog('DOS: Filemaint');
      end;
    chain(f);
  end else print('Dos system not present.');
end;

overlay procedure pver;
var abort,next:boolean;
begin
  nl; nl;
  abort:=false;
  printacr('WWIV BBS system, version 3.21d',abort,next);
  nl;
  printacr('Please address software donations to:',abort,next);
  nl;
  printacr('   Wayne Bell',abort,next);
  printacr('   Box 636',abort,next);
  printacr('   904 Silver Spur Road',abort,next);
  printacr('   Rolling Hills Estates, CA  90274',abort,next);
  nl;
end;

overlay procedure getnewinfo;
var i:str;
begin
  nl; nl; print('Please enter the following information:'); nl;
  prompt('What is your sex (M,F) ? ');
  onek(thisuser.sex,'MF');
  repeat
    prompt('What is your age in years? ');
    ini(thisuser.age);
  until ((thisuser.age>8) and (thisuser.age<120)) or hangup;
  prompt('Can you display ANSI graphics (Y/N) ? ');
  if yn then begin
    thisuser.defaults:=thisuser.defaults+[ansi];
    prompt('Do you have a color monitor (Y/N) ? ');
    if yn then thisuser.defaults:=thisuser.defaults+[color];
  end;
  nl; nl; print('Thank you.'); nl;
end;

overlay procedure chains;
var n,n1:integer; ch:char; i:str; indx:array[1..9] of integer;
begin
  nl; nl;
  n:=0; n1:=1;
  while (n1<=numchns) do begin
    if (thisuser.sl>=chns[n1].sl) and ((chns[n1].ar in thisuser.ar)
        or (chns[n1].ar='@') or cs) and (not (chns[n1].ansir and (not okansi))) then begin
      n:=n+1;
      indx[n]:=n1;
    end;
    n1:=n1+1;
  end;
  if n=0 then
    print('None available.')
  else begin
    i:='Q';
    if n=1 then
      chn(chns[indx[1]].filen)
    else begin
      for n1:=1 to numchns do begin
        print(cstr(n1)+'. '+chns[indx[n1]].descr);
        i:=i+cstr(n1);
      end;
      nl; prt('Which (Q=Quit) ? ');
      onek(ch,i);
      if ch<>'Q' then
        chn(chns[indx[value(ch)]].filen);
    end;
  end;
end;

