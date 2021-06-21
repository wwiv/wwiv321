overlay function checkpw:boolean;
var i:str;
begin
  prompt('PW? ');
  echo:=false;
  input(i,8);
  echo:=true;
  checkpw:=(i=systat.sysoppw);
end;

overlay procedure finduser(var usernum:integer);
var t,i,i1:integer;
    nn:str;
begin
  input(nn,25);
  usernum:=value(nn); if usernum>0 then begin
    reset(uf);
    if usernum>filesize(uf)-1 then begin
      print('Unknown User.');
      usernum:=0; end
    else begin
      seek(uf,usernum);
      read(uf,user);
      if user.deleted then begin
        print('Unknown User.');
        usernum:=0; end;
      end;
    close(uf); end
  else begin
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
    if nn='NEW' then usernum:=-1;
    if usernum=0 then print('Unknown User.');
   end;
 end;

overlay procedure post;
var b:messagerec; i:str; mesag:messages; a:anontyp; c:char;
begin
  if (thisuser.sl<boards[board].postsl) or (rpost in thisuser.ac) then
    print('You can''t post here')
  else begin
   irt:='';
   if ((ptoday>=seclev[thisuser.sl].posts) and (thisuser.sl<55)) or
      (ptoday>20) then
     print('Too many messages posted today.') else begin
    a:=boards[board].anonymous;
    if (a=no) and (pana in seclev[thisuser.sl].anst) then
      a:=yes;
    if rpostan in thisuser.ac then a:=no;
    inmsg(mesag,a,i,true,false);
      if mesag.ext<>0 then begin
        b.message:=mesag;
        b.title:=i;
        b.owner:=usernum;
        b.date:=daynum(date);
        b.mage:=maxage(thisuser.sl);
        if rvalidate in thisuser.ac then
          b.messagestat:=unvalidated else b.messagestat:=validated;
        if rmsg in thisuser.ac then b.messagestat:=deleted;
        iscan;
        if tnum>=boards[board].maxmsgs then deletem(1);
        mary[0].message.number:=tnum+1;
        mary[tnum]:=b;
        bchanged:=true;
        thisuser.msgpost:=thisuser.msgpost+1; ptoday:=ptoday+1;
        systat.msgposttoday:=systat.msgposttoday+1;
        sysoplog('+'+i+' posted on '+boards[board].name); topscr;
        print('Message posted on '+boards[board].name+'.');
      end;
   end;
  end;
end;

overlay procedure p1;
var c:char; tries,i,ii,t:integer; s,s1,s2:str; tf:boolean; fi:text; pasw:str;
begin
  if incom then begin
    nl;nl;printfile('gfiles\system.msg');
    nl;nl;printfile('gfiles\newuser.msg');
    tries:=0; pasw:='';
    while (systat.boardpw<>pasw) and (not hangup) do begin
      prompt('Newuser password :'); echo:=false; input(pasw,38);
      echo:=true; tries:=tries+1;
      if (pasw='OFF') or (pasw='BYE') then tries:=4;
      if tries>=4 then
        hangup:=true
      else
        if (systat.boardpw<>pasw) and (pasw<>'') then
          sl1('Wrong newuser password: '+pasw);
    end;
  end;
  repeat
    t:=0;
    repeat
      print('Enter your full name, or your alias.');
      prompt(':'); input(thisuser.name,25); tf:=false;
      if (thisuser.name='BYE') or (thisuser.name='OFF') then hangup:=true; nl;
      if not (thisuser.name[1] in ['A'..'Z']) or (thisuser.name='') then tf:=true;
      for i:=1 to systat.users do if srl[i].name=thisuser.name then tf:=true;
      assign(fi,'gfiles\trashcan.txt');{$I-} reset(fi); {$I+}
      if ioresult=0 then begin
        s2:=' '+thisuser.name+' ';
        while not eof(fi) do begin
          readln(fi,s1); if s1[length(s1)]=#1 then s1[length(s1)]:=' ' else s1:=s1+' ';
          s1:=' '+s1; for i:=1 to length(s1) do s1[i]:=upcase(s1[i]);
          if pos(s1,s2)<>0 then tf:=true;
        end;
        close(fi);
      end;
      if tf and (not hangup) then begin
        print(chr(7)+'Sorry, can''t use that name.');
        t:=t+1;
        sl1('Unacceptable name     : '+thisuser.name);
      end;
      if t>=3 then hangup:=true;
    until (tf=false) or hangup;
    print('Enter your VOICE phone number in the');
    print('form:');
    print(' ###-###-####.'); prompt(':');
    input(thisuser.ph,12);
    nl; print('Enter your REAL first name.');
    prompt (':');
    inputl(thisuser.realname,14);
    nl; print('Which computer type do you have?');
    for i:=1 to 8 do
      print(cstr(i)+'. '+comptyp[i]);
    nl; prompt('Which? ');
    onek(c,'12345678');
    nl; prompt('Your sex (M,F) ? ');
    onek(thisuser.sex,'MF');
    nl; prompt('Your age? '); ini(thisuser.age);
    thisuser.comptype:=value(c); nl; nl;
    print('['+thisuser.name+'] ['+thisuser.realname+']');
    print('['+thisuser.ph+'] ['+comptyp[thisuser.comptype]+']');
    if thisuser.sex='M' then print('[Male] ['+cstr(thisuser.age)+' Yrs]') else
      print('[Female] ['+cstr(thisuser.age)+' Yrs]');
    c:='Y'; if (length(thisuser.ph)<>12) or (thisuser.ph[4]<>'-') or
      (thisuser.ph[8]<>'-') then begin print('Enter the phone number right!'); c:='N'; end;
    if thisuser.realname='' then c:='N';
    if (thisuser.age<5) or (thisuser.age>200) then begin print('Yeah, sure.'); c:='N'; end;
    nl; if c='Y' then begin dump; prompt('Is this correct? ');
      if yn then c:='Y' else c:='N'; end else
        print('Please use proper format.');
  until (c='Y') or hangup;
end;

overlay function p2:boolean;
var c:char; tries,i,ii,t:integer; s,s1,s2:str; tf,tf1:boolean; fi:text; pasw:str;
begin
  tf1:=false;
  if not hangup then begin
    with thisuser do begin
      deleted:=false; waiting:=0; laston:='Never.';loggedon:=0; msgpost:=0;
      emailsent:=0; feedback:=0; linelen:=80; pagelen:=25;
      defaults:=[onekey,wordwrap,mmnu]; ontoday:=0; illegal:=0;
      option:=[]; dsl:=0; downloads:=0; uploads:=0; uk:=0; dk:=0;
      ttimeon:=0.0; for i:=1 to 72 do res[i]:=0; note:='';
      dlnscn:=[]; for i:=0 to 39 do dlnscn:=dlnscn+[i];
      forusr:=0;
      if incom then sl:=10 else sl:=30;
      ac:=[rvalidate]; ar:=[]; for i:=1 to 9 do vote[i]:=0; qscan[1].ext:=1;
      qscan[1].ltr:='A'; qscan[1].number:=-32767;
      for i:=2 to 19 do qscan[i]:=qscan[1];
      for i:=1 to 19 do qscn[i]:=true;
      macro[1]:='THIS IS THE CTRL-D MACRO';
      macro[2]:='THIS IS THE CTRL-F MACRO';
      sbn:=0;
      cols:=dcols;
    end;
    nl;
    if thisuser.comptype=1 then begin
      prompt('Can you display ANSI graphics (Y/N) ? ');
      if yn then begin
        thisuser.defaults:=thisuser.defaults+[ansi];
        prompt('Do you have a color monitor (Y/N) ? ');
        if yn then thisuser.defaults:=thisuser.defaults+[color];
        prompt('Can your terminal play music (Y/N) ? ');
        if yn then thisuser.defaults:=thisuser.defaults+[music];
      end;
      nl;
    end;
    nl;
    prompt('How wide is your screen');
    prompt('(32-80), <CR>=80 ? ');
    ini(thisuser.linelen);
    if thisuser.linelen=0 then thisuser.linelen:=80;
    randomize;
    thisuser.pw:='';
    for i:=1 to 6 do begin
      ii:=random(36);
      if ii<10 then c:=chr(ord('0')+ii)
        else c:=chr(ord('A')+ii-10);
      thisuser.pw:=thisuser.pw+c;
    end;
    print('You may enter your own password or have');
    print('one picked randomly for you. Do you');
    prompt('want one picked for you (Y/N) ? ');
    tf:=false;
    if not yn then
      repeat
        nl;
        prompt('Enter password: '); input(thisuser.pw,8);
        if length(thisuser.pw)<3 then
          print('Must be 3 chars.')
        else begin
          prompt('Is this correct (Y/N) ? ');
          tf:=yn;
        end;
      until tf or hangup;
    reset(uf);
    ii:=0;
    for i:=1 to filesize(uf)-1 do begin
      seek(uf,i);
      read(uf,user);
      if user.deleted and (ii=0) then ii:=i;
    end;
    if ii=0 then usernum:=filesize(uf) else usernum:=ii;
    seek(uf,usernum);
    write(uf,thisuser);
    close(uf);
    isr(thisuser.name,usernum); nl; nl;
    repeat
      print('Your user number is '+cstr(usernum));
      print('Your password is "'+thisuser.pw+'".');
      print('Please write them down and re-type');
      print('your password for verification.');
      echo:=false; prompt('Password: '); input(s,8); echo:=true;
    until (s=thisuser.pw) or hangup;
    nl; nl;
    if incom then begin
      topscr;
      printfile('gfiles\feedback.msg');
      irt:='New User Application';
      nl; tf1:=true;
    end;
  end;
  p2:=tf1;
end;

overlay function rmail(n:integer):str;
var tu,cn,c:integer; f:file; mr,mr1:mailrec; u:userrec; dm:boolean;
begin
  dm:=true; mailread:=true;
  seek(mailfile,n); read(mailfile,mr); tu:=mr.destin;
  if mr.msg.ext>128 then begin
    for c:=0 to filesize(mailfile)-1 do begin
      seek(mailfile,c); read(mailfile,mr1);
      if (mr1.msg.ltr=mr.msg.ltr) and (mr1.msg.number=mr.msg.number)
      and (mr.msg.ext=mr1.msg.ext) and (c<>n) and (mr1.destin<>-1) then
        dm:=false;
    end;
  end;
  if dm then begin
    assign(f,filename(mr.msg)); {$I-} erase(f); {$I+} cn:=ioresult;
  end;
  mr.destin:=-1; mr.from:=0; mr.mage:=0;
  seek(mailfile,n); write(mailfile,mr);
  reset(uf);
  if (tu>0) and (tu<filesize(uf)) then begin
    seek(uf,tu); read(uf,u); u.waiting:=u.waiting-1;
    seek(uf,tu); write(uf,u);if tu=1 then fw:=fw-1;
  end;
  close(uf);
  rmail:=u.name+' #'+cstr(tu);
end;

overlay procedure dsr(uname:str);
var i,rn:integer; sr:smalrec;
begin
  rn:=0;
  for i:=1 to systat.users do
    if srl[i].name=uname then
      rn:=i;
  if rn<>0 then begin
    for i:=rn to systat.users-1 do srl[i]:=srl[i+1];
    systat.users:=systat.users-1; savesystat;
    rewrite(sf); for i:=0 to systat.users do write(sf,srl[i]); close(sf);
  end else sl1('*** Couldn''t delete "'+uname+'"');
end;

overlay procedure ssm(dest:integer; s:str);
var x:smr; u:userrec;
begin
  {$I-} reset(smf);{$I+}
  if ioresult<>0 then rewrite(smf);
  seek(smf,filesize(smf)); x.msg:=s; x.destin:=dest;
  write(smf,x);
  close(smf);
  reset(uf);
  if (dest>0) and (dest<=filesize(uf)) then begin
    seek(uf,dest); read(uf,u);
    if not (smw in u.option) then
      begin u.option:=u.option+[smw]; seek(uf,dest); write(uf,u); end;
  end;
  close(uf);
  if (dest=usernum) then thisuser.option:=thisuser.option+[smw];
end;

overlay procedure rsm;
var x:smr; i:integer;
begin
  {$I-} reset(smf); {$I+}
  if ioresult=0 then begin
    i:=0;
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
  end;
end;

overlay procedure chbds;
var i:str; i1,ii:integer;
begin
  repeat
    helpl:='I';
    nl;nl;print('boards to Q-scan marked with ''*''');
    nl; for ii:=1 to numboards do if boardac(ii) then begin
      if thisuser.qscn[ii] then prompt('*  ') else prompt('   ');
      if boards[ii].key=' ' then i:=cstr(ii) else i:=boards[ii].key;
      if length(i)=1 then i:=' '+i;
      i:=i+' : '+boards[ii].name;print(i);
    end;
    repeat
     prt('Enter board #, Q, or ? :'); input(i,2);
     ii:=value(i);
     if (ii>0) and (ii<=numboards) then
       if (boards[ii].key=' ') and boardac(ii) then thisuser.qscn[ii]:=
         not thisuser.qscn[ii]
       else
     else begin
       i1:=0;
       for ii:=1 to numboards do if boards[ii].key=i then i1:=ii;
       if (i1<>0) and (i<>' ') then if boardac(ii) then
         thisuser.qscn[ii]:=not thisuser.qscn[ii];
     end;
    until (i='Q') or (i='?') or hangup;
  until (i='Q') or hangup;
end;

overlay procedure pmsg(x:integer);
begin
  if x=1 then begin
    writeln; writeln;
    writeln('This option is provided mainly so that you may have your uploaded');
    writeln('Files on a different drive or directory.  If you change this path');
    writeln('All subsequent accesses to the file system will go to this');
    writeln('drive/directory, even if all your files are in a different one.');
    writeln;
    writeln('Therefore, if you want to change your download directory, you');
    writeln('will need to move all your files from the old one to the new');
    writeln('drive/directory.');
    writeln;
  end else begin
    writeln; writeln; writeln; writeln;
    writeln('Your path must be in the following form:');
    writeln; writeln('D:directory\'); writeln;
    writeln('Where:');
    writeln('  D = drive specifier, such as A, C, or D');
    writeln('  directory = directory specifier.');
    writeln;
    writeln('The drive should be a hard disk.');
    writeln('The directory must be a valid directory on the drive specified.');
    writeln('It may contain a path from the root directory, or merely a');
    writeln('Directory relative to the default directory on that path.');
    writeln;
  end;
end;

overlay procedure pdfinf;
begin
  print(chr(12)+'Your defaults:');nl;
  print('1. Screen size    : '+cstr(thisuser.linelen)+'X'+cstr(thisuser.pagelen));
  prompt('2. Input          : ');
    if onekey in thisuser.defaults then print('One key') else print('Line');
  prompt('3. Wordwrap       : ');
    if wordwrap in thisuser.defaults then print('On') else print('Off');
  prompt('4. ANSI Graphics  : ');
    if ansi in thisuser.defaults then print('On') else print('Off');
  prompt('5. Display color  : ');
    if color in thisuser.defaults then print('On') else print('Off');
  prompt('6. Pause on screen: '); if pause in thisuser.defaults then
    print('On') else print('Off');
  if nomail in thisuser.option then
    print('7. Mailbox        : Closed')
  else
    if thisuser.forusr<>0 then
      print('7. Mail           : Forwarded to user #'+cstr(thisuser.forusr))
    else
      print('7. Mailbox        : Normal');
  print('8. Configured Q-scan');
  if okansi then print('9. Set colors');
end;

overlay procedure forwardmail;
var u:userrec; n:integer; i:str; tf:boolean;
begin
  nl;
  print('If you forward your mail, all mail');
  print('addressed to you will go to that person');
  print('Now enter the user''s number, or just');
  print('hit <CR> to deactivate mail forwarding.');
  prt(': '); input(i,4);
  n:=value(i);
  nl;
  if n=0 then begin
    thisuser.forusr:=0;
    print('Forwarding deactivated.');
  end else begin
    reset(uf); tf:=true;
    if n>=filesize(uf) then tf:=false else begin
      seek(uf,n); read(uf,u);
      if u.deleted or (nomail in u.option) then tf:=false;
    end;
    if n=usernum then tf:=false;
    if tf then begin
      thisuser.forusr:=n;
      print('Forwarding set to: '+u.name+' #'+cstr(n));
    end else
      print('Sorry, can''t forward to that user.');
    close(uf);
  end;
end;

overlay procedure bed;
var i1,i2,ii:integer; c:char; ij:str;
begin
  prt('Board number to delete? '); inu(ii);
  if (ii>0) and (ii<=numboards) then begin
    prompt(boards[ii].name+'   Delete it? ');
    if yn then begin
      numboards:=numboards-1; for i1:=ii to numboards do
        boards[i1]:=boards[i1+1];
      rewrite(bf); for i1:=1 to numboards do write(bf,boards[i1]);
      close(bf); reset(uf); for i1:=1 to filesize(uf)-1 do begin
        seek(uf,i1);read(uf,user); for i2:=ii to numboards do begin
          user.qscn[i2]:=user.qscn[i2+1]; user.qscan[i2]:=user.qscan[i2+1];
        end;
        seek(uf,i1); write(uf,user);
      end; close(uf);
      for i2:=ii to numboards do begin
        thisuser.qscn[i2]:=thisuser.qscn[i2+1]; thisuser.qscan[i2]:=thisuser.qscan[i2+1];
      end;
    end;
  end;
end;

overlay procedure bem;
var i1,i2,ii:integer; c:char; ij:str;
begin
  prt('Board number to edit? '); inu(ii);
  if (ii>0) and (ii<=numboards) then begin with boards[ii] do
  repeat
    cls;
    print('   Board      : '+cstr(ii));
    print('1. Name       : '+name);
    print('2. Filename   : '+filename);
    print('3. Key        : '+key);
    print('4. SL         : '+cstr(sl));
    print('5. Post SL    : '+cstr(postsl));
    print('6. AR         : '+ar);
    print('7. Password   : "'+pw+'"');
    print('8. Max Mess   : '+cstr(maxmsgs));
    prompt('9. Anonymous  : '); case anonymous of
      yes:print('Yes');
      no:print('No');
      forced:print('Force');
      dearabby:print('Dear abby');
    end;
    print('Q. Quit');
    nl; prt('Which? '); onek(c,'Q123456789');
    case c of
      '1':begin prt('New name? '); inputl(name,30); end;
      '2':begin
            prt('New filename? ');
            input(filename,8);
            if pos('.',filename)>0 then
              filename:=copy(filename,1,pos('.',filename)-1);
          end;
      '3':begin prt('New key? '); getkey(c); key:=c; nl;
                if not (key in ['"','#','%','&','(',')','+',',','-',
                   ':',';','<','=','>']) then key:=' '; end;
      '4':begin prt('New SL? '); ini(sl); end;
      '5':begin prt('New Post SL? '); ini(postsl); end;
      '6':begin prt('New AR? '); getkey(c); ar:=upcase(c);
            if (ar<'A') or (ar>'G') then ar:='@'; nl; end;
      '7':begin prt('New PW? '); input(pw,10); end;
      '8':begin prt('Max messages? '); ini(maxmsgs);
                if maxmsgs>200 then maxmsgs:=200; end;
      '9':begin prt('New ANST (Y,N,F,D) ? '); onek(c,'YNFD');
            case c of
              'Y':anonymous:=yes;
              'N':anonymous:=no;
              'F':anonymous:=forced;
              'D':anonymous:=dearabby;
            end;
          end;
    end;
  until (c='Q') or hangup;
  reset(bf); seek(bf,ii-1); write(bf,boards[ii]); close(bf); c:=' ';
 end;
end;

overlay procedure bei;
var i1,i2,ii:integer; c:char; ij:str;
begin
  prt('Board number to insert before? '); inu(ii);
  if (ii>0) and (ii<=numboards+1) and (numboards<19) then begin
    numboards:=numboards+1; for i1:=numboards downto ii do
      boards[i1]:=boards[i1-1];
    with boards[ii] do begin
      name:='NEW BOARD';
      filename:='newboard';
      sl:=30;
      postsl:=30;
      maxmsgs:=50;
      pw:='';
      anonymous:=no;
      ar:='@';
      key:=' ';
    end;
    rewrite(bf); for i1:=1 to numboards do write(bf,boards[i1]);
    close(bf); reset(uf); for i1:=1 to filesize(uf)-1 do begin
      seek(uf,i1);read(uf,user); for i2:=numboards downto ii do begin
        user.qscn[i2]:=user.qscn[i2-1]; user.qscan[i2]:=user.qscan[i2-1];
      end;
      user.qscan[ii].number:=-32767; user.qscan[ii].ltr:='A'; user.qscn[ii]:=true;
      user.qscan[ii].ext:=1; seek(uf,i1); write(uf,user);
    end; close(uf);
    for i2:=numboards downto ii do begin
      thisuser.qscn[i2]:=thisuser.qscn[i2-1]; thisuser.qscan[i2]:=thisuser.qscan[i2-1];
    end;
    thisuser.qscan[ii].number:=-32767; thisuser.qscan[ii].ltr:='A'; thisuser.qscn[ii]:=true;
    thisuser.qscan[ii].ext:=1;
  end;
end;

overlay procedure dlbed;
var i1,ii,i2:integer;
    c:char;
    d:dlnscan;
begin
  prt('Directory number to delete? '); inu(ii);
  if (ii>0) and (ii<=maxulb) then begin
    prt(uboards[ii].name+'   Delete it? ');
    if yn then begin
      maxulb:=maxulb-1; for i1:=ii to maxulb do
        uboards[i1]:=uboards[i1+1];
      rewrite(ulf); for i1:=0 to maxulb do write(ulf,uboards[i1]);
      close(ulf); reset(uf);
      for i1:=1 to filesize(uf)-1 do begin
        seek(uf,i1);read(uf,user); d:=[];
        for i2:=0 to ii-1 do
          if i2 in user.dlnscn then
            d:=d+[i2];
        for i2:=ii+1 to 39 do
          if i2 in user.dlnscn then
            d:=d+[i2-1];
        user.dlnscn:=(d+[39]); seek(uf,i1); write(uf,user);
      end; close(uf);
      d:=[];
      for i2:=0 to ii-1 do
        if i2 in thisuser.dlnscn then
          d:=d+[i2];
      for i2:=ii+1 to 39 do
        if i2 in thisuser.dlnscn then
          d:=d+[i2-1];
      thisuser.dlnscn:=(d+[39]);
    end;
  end;
end;

overlay procedure dlbem;
var i1,ii,i2:integer;
    c:char;
    d:dlnscan;
begin
  prt('Directory number to edit? '); inu(ii); cls;
  if (ii>=0) and (ii<=maxulb) then with uboards[ii] do begin
    repeat
      cls; print('   Directory  : '+cstr(ii));
      print('1. Name       : '+name);
      print('2. Filename   : '+filename);
      print('3. DSL        : '+cstr(dsl));
      print('4. Password   : "'+password+'"');
      print('5. Max files  : '+cstr(maxfiles));
      nl; prt('Which? '); onek(c,'Q12345');
      case c of
        '1':begin prt('New name? '); inputl(name,25); end;
        '2':begin
              prt('New filename? ');
              input(filename,8);
              if pos('.',filename)>0 then
                filename:=copy(filename,1,pos('.',filename)-1);
            end;
        '3':begin prt('New DSL? '); ini(dsl); end;
        '4':begin prt('New PW? '); input(password,10); end;
        '5':begin prt('Max files? '); inu(maxfiles); end;
      end;
    until (c='Q') or hangup;
    reset(ulf); seek(ulf,ii); write(ulf,uboards[ii]); close(ulf); c:=' ';
  end;
end;

overlay procedure dlbei;
var i1,ii,i2:integer;
    c:char;
    d:dlnscan;
begin
  prt('Directory number to insert before? '); inu(ii);
  if (ii>0) and (ii<=maxulb+1) and (maxulb<19) then begin
    maxulb:=maxulb+1; for i1:=maxulb downto ii do
      uboards[i1]:=uboards[i1-1];
    with uboards[ii] do begin
      name:='NEW DIRECTORY';
      filename:='newdir';
      dsl:=0;
      maxfiles:=50;
      password:='';
    end;
    rewrite(ulf); for i1:=0 to maxulb do write(ulf,uboards[i1]);
    close(ulf);reset(uf);
    for i1:=1 to filesize(uf)-1 do begin
      seek(uf,i1);read(uf,user); d:=[];
      for i2:=0 to ii-1 do
        if i2 in user.dlnscn then
          d:=d+[i2];
      for i2:=ii to 38 do
        if i2 in user.dlnscn then
          d:=d+[i2+1];
      d:=d+[ii]; user.dlnscn:=d;
      seek(uf,i1); write(uf,user);
    end; close(uf);
    d:=[];
    for i2:=0 to ii-1 do
      if i2 in thisuser.dlnscn then
        d:=d+[i2];
    for i2:=ii to 38 do
      if i2 in thisuser.dlnscn then
        d:=d+[i2+1];
    d:=d+[ii]; thisuser.dlnscn:=d;
  end;
end;

overlay procedure chstb;
var i:str;
begin
  writeln;
  write('New NewUser Password : ');
  input(i,8);
  writeln;
  writeln('NewUser Password: "'+i+'"');
  writeln;
  write('Is this what you want? ');
  if yn then systat.boardpw:=i;
end;

overlay procedure chsta;
var i:str;
begin
  writeln;
  write('New System Password : ');
  input(i,8);
  writeln;
  writeln('System Password: "'+i+'"');
  writeln;
  write('Is this what you want? ');
  if yn then systat.sysoppw:=i;
end;

overlay procedure chstc;
var i:str; b2:boolean;
begin
  writeln;
  write('Do you want the system closed? ');
  b2:=yn;
  writeln;
  write('System: '); if b2 then writeln('Closed') else writeln('Open');
  writeln;
  write('Is this what you want? ');
  if yn then systat.closedsystem:=b2;
end;

overlay procedure chstd;
var i:str; c1:integer;
begin
  writeln;
  write('Com port (1-2) ? ');
  inu(c1);
  if (c1<1) or (c1>2) then c1:=systat.comport;
  writeln;
  writeln('Com Port : '+cstr(c1));
  writeln;
  write('Is this what you want? ');
  if yn then begin
    writeln;
    write('Are you absolutely sure? ');
    if yn then begin
      writeln;
      write('Positive? ');
      if yn then begin
        writeln('If you don''t have a modem hooked up to that com port, then');
        writeln('the BBS will hang and you will have a helluva time fixing');
        writeln('it.  If you do have to fix it, you have to directly write to');
        writeln('the status.dat file for the one byte telling the com port,');
        writeln('and change it back.');
        writeln;
        write('Are you still sure you want to do this? ');
          if yn then begin systat.comport:=c1; remove_port; iport; end;
      end;
    end;
  end;
end;

overlay procedure chste;
var i:str; c1:integer;
begin
  writeln;
  write('Modem speed (300,1200,2400) ? ');
  inu(c1);
  if (c1<>300) and (c1<>1200) and (c1<>2400) then c1:=systat.maxbaud;
  writeln;
  writeln('Modem Speed : '+cstr(c1));
  writeln;
  write('Is this what you want? ');
  if yn then begin
    writeln;
    write('Are you absolutely sure? ');
    if yn then begin
      writeln('If your actual modem speed is LESS than what you specified,');
      writeln('and you do change this, the BBS will hang and you will have');
      writeln('a helluva time fixing it.  You will have to directly access');
      writeln('the status.msg file and change the two bytes specifying the');
      writeln('modem speed.');
      writeln;
      write('Are you still sure you want to do this? ');
      if yn then
        systat.maxbaud:=c1;
    end;
  end;
end;

overlay procedure chstg;
var i1,i2:str; t1,t2,t1h,t1m,t2h,t2m:integer;
begin
  writeln;
  write('Do you want to declare sysop hours? ');
  if yn then begin
    writeln;
    writeln('All entries 24 hour time.  Hour: (0-23), Minute: (0-59)');
    writeln('Chat on time:');
    write('  Hour   : ');
    inu(t1h);
    if (t1h<0) or (t1h>23) then t1h:=0;
    write('  Minute : ');
    inu(t1m);
    if (t1m<0) or (t1m>59) then t1m:=0;
    writeln;
    writeln('Chat off time:');
    write('  Hour   : ');
    inu(t2h);
    if (t2h<0) or (t2h>23) then t2h:=0;
    write('  Minute : ');
    inu(t2m);
    if (t2m<0) or (t2m>59) then t2m:=0;
    t1:=t1h*60+t1m;
    t2:=t2h*60+t2m;
    writeln;
    writeln;
    writeln('Hours: '+tch(cstr(t1h))+':'+tch(cstr(t1m))+' to '+
            tch(cstr(t2h))+':'+tch(cstr(t2m)));
    writeln;
    write('Is this what you want? ');
    if yn then begin
      systat.lowtime:=t1;
      systat.hitime:=t2;
    end;
  end else begin
    systat.lowtime:=0;
    systat.hitime:=0;
  end;
end;

overlay procedure mmacroo;
var mc,c:char; n1,n,mcn,mn:integer; i:str;
begin
  nl; prt('Which (D,F,Q=Quit) :'); onek(c,'QDF');
  if c<>'Q' then begin
    nl;nl; mc:=c; print('Enter your macro now, Ctrl-'+mc);
    print('to end macro.'); nl;if mc='D' then mcn:=4 else mcn:=6;
    n:=1; i:=''; macok:=false; if mc='D' then mn:=1 else mn:=2;
    helpl:=#0;
    repeat
      getkey(c);
      if (ord(c)<32) then
        if not((c=#8) or (c=#10) or (c=#13) or (c=#14) or (c=#9) or (c=#16) or
               (c=chr(mcn))) then c:=chr(0);
        if c=#8 then if n<2 then c:=#0 else begin
          oc(#8); oc(' '); oc(#8);
          n:=n-1; c:=#0; if i[n]<#32 then begin
            oc(#8); oc(' '); oc(#8);
          end;
        end;
      if (c<>#0) and (c<>chr(mcn)) then begin
        if (c=#16) or (c=#14) or (c=#9) then prompt('^'+chr(ord(c)+64))
        else oc(c);
        i[n]:=c; n:=n+1;
        if c=#13 then oc(chr(10));
      end;
    until (c=chr(mcn)) or (n=80) or hangup;
    nl; helpl:='H';
    if n=80 then begin
      print('Macro limit is 79 chars.');
      print('That much saved.');
    end;
    i[0]:=chr(n-1);
    print('Ctrl-'+mc+' macro is now:'); prompt('"');
    for n1:=1 to length(i) do
      if i[n1]>=' ' then
        prompt(i[n1])
      else
        prompt('^'+chr(64+ord(i[n1])));
    print('"'); dump;
    prompt('Is this what you want? ');
    if yn then begin thisuser.macro[mn]:=i; print('Macro saved.') end
    else print('Macro not saved, then.');
    macok:=true;
  end;
end;

overlay procedure readamsg;
var filv:text; i,n:str; ii:integer;
begin
  nl;nl;assign(filv,'gfiles\auto.msg');
  {$I-} reset(filv); {$I+}
  if ioresult<>0 then print('No Auto-message') else begin
    readln(filv,n);
    if n[1]='@' then
      if postn in seclev[thisuser.sl].anst then n:='<<< '+copy(n,2,length(n))+' >>>'
      else n:='>UNKNOWN<';
    if n[1]='!' then
      if so then n:='<<< '+copy(n,2,length(n))+' >>>'
      else n:='>UNKNOWN<';
    print('Auto message by: '+n); nl;
    for ii:=1 to 3 do begin
      readln(filv,i); print(i); end;
    close(filv);
  end;
  nl;nl;
end;


overlay procedure logon1;
var fil:file of str; lo:array[1..8] of str; num:integer; i:str; ul:text; c:char;
    abort:boolean; var d1,d2:zlogt; zf:file of zlogt; n:integer;

begin
  realsl:=thisuser.sl; cls;nl;nl;
  assign(fil,'gfiles\laston.dat');
  reset(fil); for num:=1 to 8 do read(fil,lo[num]);
  print('Last few callers:');nl;
  if cosysop in seclev[thisuser.sl].anst then for num:=1 to 8 do print(lo[num]) else
    for num:=5 to 8 do print(lo[num]);
  if realsl<>255 then begin
    seek(fil,0); for num:=2 to 8 do write(fil,lo[num]);
    i:=cstr(systat.callernum)+': '+nam;
    write(fil,i);
  end;
  close(fil);
  print('You are caller #'+cstr(systat.callernum));
  if thisuser.laston=date then thisuser.ontoday:=thisuser.ontoday+1
    else thisuser.ontoday:=1;
  if systat.lastdate<>date then begin
    assign(zf,'gfiles\zlog.dat');
    {$I-} reset(zf); {$I+}
    if ioresult<>0 then begin
      rewrite(zf);
      d1.date:='';
      for n:=1 to 97 do
        write(zf,d1);
    end;
    d1.date:=systat.lastdate;
    d1.active:=systat.activetoday;
    d1.calls:=systat.callstoday;
    d1.post:=systat.msgposttoday;
    d1.email:=systat.emailtoday;
    d1.fback:=systat.fbacktoday;
    d1.up:=systat.uptoday;
    for n:=95 downto 0 do begin
      seek(zf,n);
      read(zf,d2);
      seek(zf,n+1);
      write(zf,d2);
    end;
    seek(zf,0);
    write(zf,d1);
    close(zf);
    systat.lastdate:=date;
    assign(ul,'gfiles\ysysop.log'); {$I-} erase(ul); {$I+} num:=ioresult;
    sl1(''); sl1('Total Time On = '+ cstr(systat.activetoday));
    sl1('Calls Today: '+cstr(systat.callstoday));
    sl1('Messages posted today: '+cstr(systat.msgposttoday));
    sl1('Files u/l today: '+cstr(systat.uptoday));
    close(sysopf); rename(sysopf,'gfiles\ysysop.log');
    assign(sysopf,'gfiles\sysop.log');
    rewrite(sysopf); writeln(sysopf); close(sysopf); append(sysopf);
    assign(ul,'gfiles\user.log'); rewrite(ul); writeln(ul); close(ul);
    with systat do begin
      activetoday:=0; callstoday:=0; msgposttoday:=0; emailtoday:=0;
      fbacktoday:=0; uptoday:=0;
    end;
    enddayf:=true;
  end;
end;

overlay function vote1x(qnum:integer; var vd:vdatar):boolean;
var cv,tv,ii:integer; ij,i,i1,i2:str; c:char; abort,next,bb:boolean;
begin
  i2:='                                  '; cls; bb:=false;
  if vd.numa=0 then print('Inactive question.') else begin
    print('Question #'+cstr(qnum)+':');
    nl; print(vd.question); nl;
    tv:=0; for ii:=1 to vd.numa do tv:=tv+vd.answ[ii].numres;
    print('Users voting: '+ctp(tv,systat.users)); if tv=0 then tv:=1;
    nl; print('0:No Comment');
    ij:='Q0';
    ii:=1; abort:=false;
    while (ii<=vd.numa) do begin
      ij:=ij+cstr(ii);
      i1:=copy(vd.answ[ii].ans,1,25);
      i1:=i1+copy(i2,1,25-length(i1))+' :';
      i:=copy(cstr(vd.answ[ii].numres),1,3);
      i1:=i1+copy(i2,1,3-length(i))+i+' '+ctp(vd.answ[ii].numres,tv);
      printacr(cstr(ii)+':'+i1,abort,next);
      ii:=ii+1;
    end;
    nl;nl;
    i:='Your vote: '+vd.answ[thisuser.vote[qnum]].ans; print(i);
    if not(rvoting in thisuser.ac) and (not hangup) and (thisuser.sl>10) then begin
      ynq('Change it? '); if yn then begin
        nl; prt('Which number (0-'+cstr(vd.numa)+') ? ');
        onek(i[1],ij);
        i[0]:=#1; ii:=value(i); if (i<>'') and (ii>=0) and (ii<=vd.numa) then begin
          if thisuser.vote[qnum]<>0 then
            vd.answ[thisuser.vote[qnum]].numres:=vd.answ[thisuser.vote[qnum]].numres-1;
          thisuser.vote[qnum]:=ii;
          if ii<>0 then vd.answ[ii].numres:=vd.answ[ii].numres+1;
          bb:=true;
          cls; print('Current Standings for question #'+cstr(qnum)+' : '); nl; print(vd.question); nl;
          tv:=0; for ii:=1 to vd.numa do tv:=tv+vd.answ[ii].numres;
          print('Users voting: '+ctp(tv,systat.users)); nl; if tv=0 then tv:=1;
          abort:=false; ii:=1;
          while (ii<=vd.numa) and (not abort) do begin
            i1:=copy(vd.answ[ii].ans,1,25);
            i1:=i1+copy(i2,1,25-length(i1))+' :';
            i:=copy(cstr(vd.answ[ii].numres),1,3);
            i1:=i1+copy(i2,1,3-length(i))+i+' '+ctp(vd.answ[ii].numres,tv);
            printacr(cstr(ii)+':'+i1,abort,next);
            ii:=ii+1;
          end;
        end;
      end;
    end;
    dump;
  end;
  vote1x:=bb;
end;

overlay procedure wmsg;
var filvar:text; ii:integer; li:array[1..3] of str; n:str;
begin
  nl;print('Enter three lines:'); nl;
  for ii:=1 to 3 do begin
    prt(cstr(ii)+':'); inputl(li[ii],37);
  end;
  n:=nam; if pana in seclev[thisuser.sl].anst then begin
    nl; ynq('Anonymous? ');
    if yn then
      if realsl=255 then
        n:='!'+n
      else
        n:='@'+n;
  end;
  prompt('Is this alright? ');
  if yn then begin
    assign(filvar,'gfiles\auto.msg');
    rewrite(filvar); writeln(filvar,n);
    for ii:=1 to 3 do writeln(filvar,li[ii]);
    close(filvar); print('Auto-message saved.');
    if (realsl<>255) or incom then begin
      sysoplog('Changed Auto-message');
      for ii:=1 to 3 do sysoplog('   '+li[ii]);
    end;
  end else prompt('Nothing saved.');
end;

overlay procedure email(touser:integer; xx:boolean);
var mr:mailrec; t,e,cp:integer; f:messages; a:anontyp; i:str; us:userrec; ok:boolean;
  procedure nope(i:str);
  begin
    if ok then print(i);
    ok:=false;
  end;
begin
  ok:=not xx;
  reset(uf);
  if (touser>0) and (touser<filesize(uf)) then begin
    seek(uf,touser); read(uf,user); close(uf);
    if ((remail in thisuser.ac) or (thisuser.sl<=10)) and (user.sl<>255) then
      nope('You can''t send mail.');
    if (etoday>=seclev[thisuser.sl].emails) and (thisuser.sl<55) and (user.sl<>255) then
      nope('Too much E-mail sent today.');
    if (user.sl=255) and (ftoday>=5) and (not so) then
      nope('Too much F-back sent today.');
    if (touser=usernum) and (not so) then
      nope('Can''t E-mail yourself');
    if (((user.sl=255) and (user.waiting>50)) or ((user.sl<>255) and
      (user.waiting>15))) and (not so) then
      nope('Mailbox full.');
    if (nomail in user.option) and (not cs) then
      nope('Mailbox closed.');
    if user.deleted then
      nope('Deleted user.');
    if xx then ok:=true;
    if ok then begin
      a:=no; if sanm in seclev[thisuser.sl].anst then a:=yes;
      inmsg(f,a,i,false,false);
      if f.ext<>0 then begin
        {$I-} reset(mailfile); {$I+}
        if (ioresult<>0) then
          rewrite(mailfile);
        e:=filesize(mailfile);
        if e=0 then cp:=0 else begin
          cp:=-1; t:=e-1;
          seek(mailfile,t); read(mailfile,mr);
          while (t>0) and (mr.destin=-1) do begin
            t:=t-1; seek(mailfile,t); read(mailfile,mr);
          end;
          cp:=t+1;
        end;
        seek(mailfile,cp);
        mr.msg:=f; if lan then mr.from:=-usernum else mr.from:=usernum;
        mr.destin:=touser;
        mr.title:=i; mr.date:=daynum(date);
        mr.mage:=maxage(thisuser.sl);
        write(mailfile,mr);
        if touser=1 then begin thisuser.feedback:=thisuser.feedback+1;
          ftoday:=ftoday+1; fw:=fw+1; end else begin thisuser.emailsent:=
          thisuser.emailsent+1; etoday:=etoday+1; end;
        close(mailfile); reset(uf); seek(uf,touser); read(uf,user);
        user.waiting:=user.waiting+1; seek(uf,touser); write(uf,user);
        if touser=usernum then thisuser.waiting:=thisuser.waiting+1;
        i:=user.name+' #'+cstr(touser);
        close(uf); topscr;
        if useron then sysoplog('Mail sent to '+i);
        print('Mail sent to '+i);
      end;
    end;
  end;
end;

overlay function forwardm(n:integer):integer;
var chk:array[1..maxusers] of boolean; cur:integer; u:userrec; done:boolean;
begin
  for cur:=1 to maxusers do chk[cur]:=false;
  cur:=n; done:=false;
  while not done do
    if chk[cur] then begin
      done:=true;
      cur:=0;
    end else
      if (cur<filesize(uf)) and (cur>0) then begin
        seek(uf,cur); read(uf,u);
        if u.deleted then begin
          done:=true;
          cur:=0;
        end else begin
          if u.forusr=0 then begin
            done:=true;
            if ((nomail in u.option) and not cs) or ((n=1) and (u.waiting>50))
               or ((n<>1) and (u.waiting>15)) or ((cur=usernum) and not so) then
                 cur:=0;
          end else begin
            chk[cur]:=true;
            cur:=u.forusr;
          end;
        end;
      end else begin
        done:=true;
        cur:=0;
      end;
  forwardm:=cur;
end;

overlay procedure smail2(na:emary);
var f:messages; a:anontyp; i:str; c1,t,cp,e:integer; mr:mailrec; us:userrec;
begin
  if na[1]<>0 then begin
    a:=no; if sanm in seclev[thisuser.sl].anst then a:=yes;
    irt:='Mass Mail.';
    inmsg(f,a,i,false,true);
    if f.ext<>0 then begin
      {$I-} reset(mailfile); {$I+}
      if (ioresult<>0) then
        rewrite(mailfile);
      e:=filesize(mailfile);
      if e=0 then cp:=0 else begin
        cp:=-1; t:=e-1;
        seek(mailfile,t); read(mailfile,mr);
        while (t>0) and (mr.destin=-1) do begin
          t:=t-1; seek(mailfile,t); read(mailfile,mr);
        end;
        cp:=t+1;
      end;
      seek(mailfile,cp);
      mr.msg:=f; if lan then mr.from:=-usernum else mr.from:=usernum;
      mr.title:=i; mr.date:=daynum(date);
      mr.mage:=maxage(thisuser.sl);
      c1:=1; nl; print('Sending mail to:');
      while (na[c1]<>0) and (c1<=20) do begin
        mr.destin:=na[c1];
        write(mailfile,mr);
        if na[c1]=1 then begin
          thisuser.feedback:=thisuser.feedback+1;
          ftoday:=ftoday+1;
          fw:=fw+1;
        end else begin
          thisuser.emailsent:=thisuser.emailsent+1;
          etoday:=etoday+1;
        end;
        seek(uf,na[c1]); read(uf,us);
        us.waiting:=us.waiting+1; seek(uf,na[c1]); write(uf,us);
        if na[c1]=usernum then thisuser.waiting:=thisuser.waiting+1;
        i:=us.name+' #'+cstr(na[c1]);
        sysoplog('Mult-mail sent to '+i);
        print('  '+i);
        c1:=c1+1;
      end;
      close(mailfile); topscr;
    end;
  end;
end;

overlay procedure chcolors;
var mcol,ocol:byte; c,c1,c2:integer; cl:boolean; i:str; done:boolean; ch:char;

  function colo(n:integer):str;
  begin
    case n of
      0:colo:='Black';
      1:colo:='Blue';
      2:colo:='Green';
      3:colo:='Cyan';
      4:colo:='Red';
      5:colo:='Magenta';
      6:colo:='Yellow';
      7:colo:='White';
    end;
  end;

  function dt(n:integer):str;
  var i:str;
  begin
    i:=colo(n and 7)+' on '+colo((n shr 4) and 7);
    if (n and 8)<>0 then i:=i+', High Intensity';
    if (n and 128)<>0 then i:=i+', Blinking';
    dt:=i;
  end;

  function stf(n:integer):str;
  var i:str;
  begin
    case n of
      1:i:='Default';
      2:i:='Unused';
      3:i:='Yes/No';
      4:i:='Prompts';
      5:i:='Note';
      6:i:='Input line';
      7:i:='Y/N question';
      8:i:='Blinking';
    end;
    i:=cstr(n)+'. '+i;
    while length(i)<20 do i:=i+' ';
    stf:=i;
  end;

  procedure liststf;
  var c:integer;
  begin
    nl;
    for c:=1 to 8 do begin
      prompt(stf(c)); ansic(c); print(dt(thisuser.cols[cl,c]));
    end;
    nl;
  end;

begin
  cl:=color in thisuser.defaults;
  nl; if cl then print('Set multiple colors.')
  else print('Set B&W colors.');
  ch:='?'; done:=false;
  repeat
    case ch of
      'Q':done:=true;
      '?':liststf;
      '1'..'8':begin
            nl; print('Current:'); c1:=value(ch); nl;
            prompt(stf(c1)); ansic(c1); print(dt(thisuser.cols[cl,c1]));
            nl; nl; print('Colors:'); nl;
            for c:=0 to 7 do begin
              prompt(cstr(c)+'. '+colo(c)+' '); setc(c); print(colo(c));
            end;
            ocol:=thisuser.cols[cl,c1]; nl;
            prt('Foreground? '); onek(ch,#13+'01234567');
            if ch=#13 then
              mcol:= ocol and 7
            else
              mcol:=value(ch);
            prt('Background? '); onek(ch,#13+'01234567');
            if ch=#13 then
              mcol:=mcol or (ocol and 112)
            else
              mcol:=mcol or (value(ch) shl 4);
            ynq('Intensified? ');
            if yn then mcol:=mcol or 8;
            ynq('Blinking? ');
            if yn then mcol:=mcol or 128;
            nl; nl; prompt(stf(c1)); setc(mcol); print(dt(mcol));
            nl; prompt('Is this correct? ');
            if yn then  thisuser.cols[cl,c1]:=mcol;
          end;
    end;
    if not done then begin
      nl; prt('Colors: 1-8,Q,?  : '); onek(ch,'Q?12345678');
    end;
  until done or hangup;
end;

overlay procedure chn(fn:str);
var f:file;
begin
  assign(f,fn+'.CHN');
  {$I-} reset(f); {$I+}
  if ioresult=0 then begin
    print('Loading...');
    close(f);
    remove_port;
    ret:=200;
    chain(f);
  end else print('File not found.');
end;

overlay procedure chcha;
var f:file of chnft; c:chnft; c1:integer; f1:file; ch1:char;
begin
  prt('Filename (.CHN) ? '); mpl(8); input(c.filen,8);
  if pos('.',c.filen)>0 then
    c.filen:=copy(c.filen,1,pos('.',c.filen)-1);
  assign(f1,c.filen+'.chn');
  {$I-} reset(f1); {$I+}
  if ioresult<>0 then begin
    nl; print('File "'+c.filen+'.CHN" does not exist.');
    prompt('Press return.');
    input(i,3);
  end else begin
    close(f1);
    nl; prt('Description? '); mpl(40); inputl(c.descr,40);
    nl; prt('SL restriction? '); mpl(3); ini(c.sl);
    nl; prt('AR restriction? '); mpl(1); onek(ch1,#13+'ABCDEFG');
    nl; ynq('Require ANSI graphics? '); c.ansir:=yn;
    if ch1=#13 then ch1:='@';
    c.ar:=ch1;
    numchns:=numchns+1; chns[numchns]:=c;
    assign(f,'gfiles\chains.dat');
    rewrite(f); for c1:=1 to numchns do write(f,chns[c1]);
    close(f);
  end;
end;

overlay procedure initp1;
var a:integer;
begin
  ldate:=daynum(date);
  ch:=false; lil:=0; thisuser.pagelen:=20; buf:=''; chatcall:=false;
  spd:=''; lastname:=''; ll:=''; i:=''; chatr:='';
  assign(bf,'gfiles\boards.dat');
  assign(uf,'gfiles\user.lst');
  assign(sf,'gfiles\names.lst');
  assign(sysopf,'gfiles\sysop.log');
  {$I-} append(sysopf); {$I+}
  if ioresult<>0 then begin
    rewrite(sysopf);
    writeln(sysopf);
  end;
  assign(mailfile,'gfiles\email.dat');
  assign(systatf,'gfiles\status.dat');
  reset(systatf); read(systatf,systat);close(systatf); iport;
  assign(smf,'gfiles\shortmsg.dat');
  assign(cf,'gfiles\chat.msg'); cfo:=false;
  reset(sf); for a:=0 to systat.users do read(sf,srl[a]); close(sf);
  for a:=systat.users+1 to maxusers do begin srl[a].name:=''; srl[a].number:=0; end;
  assign(ulf,'gfiles\uploads.dat');
  reset(ulf); maxulb:=-1;
  while not eof(ulf) do begin maxulb:=maxulb+1; read(ulf,uboards[maxulb]); end;
  close(ulf);
  hangup:=false;
  incom:=false; outcom:=false;
  echo:=true; doneday:=false;
  reset(bf);
  numboards:=filesize(bf);
  for a:=1 to numboards do
    read(bf,boards[a]);
  close(bf);
  assign(slf,'gfiles\seclev.dat'); reset(slf); for a:=0 to 255 do read(slf,seclev[a]);
  close(slf);
  reset(uf);
  if filesize(uf)>1 then begin seek(uf,1); read(uf,user); fw:=user.waiting;
  end else fw:=0;
  close(uf);
end;

overlay procedure getcallera(var c:char; var chkcom:boolean);
var rl,rl1:real; i:str;
begin
    if commpressed then c:=cinkey;
    if c='2' then begin
      chkcom:=true; rl:=timer; write('* ');
      while (c<>#13) and (abs(rl-timer)<0.2) do c:=cinkey;
    end;
    if chkcom then begin
      pr('ATA'); writeln('Answering phone, "H" to abort');
      delay(50); dump; rl1:=timer; i:=''; rl:=0.0;
      repeat
        chkcom:=false;
        if keypressed then begin read(kbd,c);
          if upcase(c)='H' then begin
            chkcom:=true;
            pr('A');
            delay(200);
            dump;
          end;
        end;
        c:=cinkey;
        if (rl<>0.0) and (abs(rl-timer)>2.0) and (c=#0) then c:=#13;
        if (c<#32) and (c<>#13) then c:=#0;
        if c<>#0 then
          if c<>#13 then begin i:=i+c; rl:=timer; end else begin
            if i='1' then begin spd:='300'; chkcom:=true; end;
            if i='5' then begin spd:='1200'; chkcom:=true; end;
            if i='10' then begin spd:='2400'; chkcom:=true; end;
            if i='3' then chkcom:=true;
            rl:=0.0;
          end;
        if c=#13 then i:='';
        if abs(timer-rl1)>45.0 then chkcom:=true;
      until chkcom;
      if abs(timer-rl1)>45.0 then c:='X';
      clrscr;
    end;
    if spd<>'KB' then incom:=true;
end;

overlay procedure beephim;
var rl,rl1:real; ch:char;
begin
  beepend:=false;
  rl:=timer;
  repeat
    write(^G);
    rl1:=timer;
    while (abs(rl1-timer)<0.9) and (not keypressed) do;
  until (abs(rl-timer)>30.0) or keypressed;
end;

