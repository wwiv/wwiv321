
                      {*****************************}
                      {Copyright (c) 1986 Wayne Bell}
                      {*****************************}

procedure printfile1(fn:str; var abort:boolean);
begin
  pfl(fn,abort,false);
end;

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

function filename(mrec:messages):str;
begin
  filename:='msgs\'+mrec.ltr+cstr(mrec.number)+'.'+cstr(mrec.ext);
end;

procedure inmsg(var mrec:messages;an:anontyp;var title:str;tr,mp:boolean);
var li:array[1..75] of str; t1,t,maxli,lc:integer; filler,spc,ti,i:str;
saveline,exit,save,abortit,ab,nx:boolean; c:char; filvar:text;

  procedure ptl;
  begin
    nl;
    if okansi then begin
      prt('Title: '); mpl(30); inputl(title,30);
    end else begin
      print('       (---=----=----=----=----=----)');
      prt('Title: '); inputl(title,30);
    end;
  end;

  overlay procedure listit(linenum:boolean);
  var l:integer; abort,next:boolean;
  begin
    l:=1;
    abort:=false;
    while (l<>lc) and (not abort) do begin
      if linenum then print(cstr(l)+':');
      printa(li[l],abort,next);
      if pap<>0 then nl;
      l:=l+1;
    end;
    print('---===> Total lines: '+cstr(lc-1));
    saveline:=false;
  end;

  overlay procedure rpl(var i1:str; i2:str);
  var c1,c2:integer; i3:str;
  begin
    if i2[1]='/' then delete(i2,1,1);
    if i2[length(i2)]=#1 then i2:=copy(i2,1,length(i2)-1);
    if i2[length(i2)]='/' then i2:=copy(i2,1,length(i2)-1);
    c1:=pos('/',i2); i3:=copy(i2,1,c1-1);
    delete(i2,1,c1);
    if i2[length(i2)]='/' then i2:=copy(i2,1,length(i2)-1);
    c2:=pos(i3,i1);
    if (length(i1)-length(i3)+length(i2))>(thisuser.linelen+10) then
      print('Line would be too long')
    else
      if c2>0 then begin
        delete(i1,c2,length(i3));
        insert(i2,i1,c2);
      end;
  end;

  overlay procedure prhelp;
  begin
    print('/ES = immediate save');
    print('/EX = exit and edit');
    print('/ABT = abort');
    print('/CLR = clear message');
    print('/LI = list so far');
    print('/RL = replace last line');
    print('/SU/str1/str2/ = substitute in last line');
    print('/C: = center rest of line');
    print('/T: = boxed title');
    print('^P = change color (^P + digit (0-8))');
    saveline:=false;
  end;

  overlay procedure prhelp1;
  begin
    print('S:ave         L:ist');
    print('A:bort        C:ontinue');
    print('R:eplace line I:nsert line');
    print('D:elete line  T:itle change');
  end;

begin
 if freek(0)>10 then begin
  helpl:='F';lc:=1;spc:='                                                                              ';
  filler:='-------------------------------------------------------------------------------';
  ll:=''; if thisuser.sl<45 then maxli:=30 else if thisuser.sl<60 then
    maxli:=50 else if thisuser.sl<80 then maxli:=60 else maxli:=75;
  if tr then begin
    repeat
      ptl;
      if title<>'' then begin ynq('Ok? '); c:='N'; if yn then c:='Y'; end else c:='Y';
    until (c='Y') or hangup;
  end else ptl;
 end else begin
   title:=''; tr:=true;
   print('Not enough disk space');
 end;
 if (title<>'') or not tr then begin
  print('Enter message now, max '+cstr(maxli)+' lines.');
  print('Enter "/HELP" for help');
  print(copy('[---=----=----=----=----=----=----=----]----=----=----=----=----=----=----=----]',
    1,thisuser.linelen));
 repeat
  repeat
    saveline:=true; exit:=false; save:=false; abortit:=false;
    inli(i); if (i[1]=^J) and (i[2]='/') then i:=copy(i,2,length(i));
    ti:=copy(i,1,3); if ti[length(ti)]=#1 then ti:=copy(ti,1,length(ti)-1);
    ti[1]:=upcase(ti[1]); ti[2]:=upcase(ti[2]); ti[3]:=upcase(ti[3]);
    if (ti='/RL') and (lc>1) then begin print('Replace:'); saveline:=false; lc:=lc-1; end;
    if ti='/EX' then begin exit:=true; saveline:=false; end;
    if (ti='/ES') or (ti='/S') then begin exit:=true; save:=true; saveline:=false; end;
    if ti='/C:' then begin
      i:=copy(i,4,length(i)-3);
      if i[length(i)]<>#1 then i:=i+#1;
      i:=#2+i;
    end;
    if (ti='/T:') and (maxli-lc>2) then begin
      i:=copy(i,4,length(i)-3);
      if i[length(i)]=#1 then i:=copy(i,1,length(i)-1);
      li[lc]:=#2+'+-'+copy(filler,1,length(i))+'-+'+#1;
      li[lc+1]:=#2+'! '+i+' !'+#1;
      li[lc+2]:=li[lc];
      saveline:=false; lc:=lc+3;
    end;
    if ti='/AB' then if upcase(i[4])='T'then begin
      exit:=true; abortit:=true; saveline:=false; end;
    if ti='/CL' then if upcase(i[4])='R' then begin
      saveline:=false; lc:=1;
      print('Message cleared.... Start over...');
    end;
    if (ti='/SU') and (lc>1) then begin
      rpl(li[lc-1],copy(i,4,80));
      print('Last line: '); ab:=false;
      printacr(li[lc-1],ab,nx);
      saveline:=false;
    end;
    if ti='/HE' then prhelp;
    if ti='/LI' then begin
      ynq('With line numbers? '); if yn then listit(true) else listit(false);
    end;
    if saveline then begin li[lc]:=i; lc:=lc+1; if lc>maxli then exit:=true;
      if lc+4=maxli then print('=5 lines left =');
    end;
  until exit or hangup;
  if hangup then abortit:=true;
  if (not abortit) and (not save) then
  repeat
    prt('S,L,A,C,R,I,D,T,U,? :'); ONEK(c,'SULACRIDT?');
    case c of
      'L':begin prompt('With line numbers? '); if yn then listit(true) else listit(false); end;
      'T':ptl;
      'D':begin
            prompt('Line number to delete (1-'+cstr(lc-1)+')? ');
            input(i,4);t:=value(i); if (t>0) and (t<lc) then begin
              for t1:=t to lc-2 do li[t1]:=li[t1+1]; lc:=lc-1;
            end;
          end;
      'R':begin
            prompt('Line number to replace (1-'+cstr(lc-1)+')? ');
            input(i,4);t:=value(i); if (t>0) and (t<lc) then begin
              print('Old line:'); ab:=false; printa(li[t],ab,nx);
              print('Enter new line:'); inli(i);
              if (li[t][length(li[t])]=#1) and (i[length(i)]<>#1) then
                li[t]:=i+#1 else li[t]:=i;
            end;
          end;
      'U':begin
            prompt('Line number to update (1-'+cstr(lc-1)+')? ');
            input(i,4);t:=value(i); if (t>0) and (t<lc) then begin
              nl; ab:=false; printa(li[t],ab,nx); nl; print('Format: oldstr/newstr');
              prompt('Update: '); inputl(i,70); rpl(li[t],i);
              nl; ab:=false; printa(li[t],ab,nx); nl; nl;
            end;
          end;
      'I':if (lc<maxli) then begin
            prompt('Line number to insert before (1-'+cstr(lc-1)+')? ');
            input(i,4); t:=value(i); if (t>0) and (t<lc) then begin
              for t1:=lc downto t+1 do li[t1]:=li[t1-1]; lc:=lc+1;
              print('New line:'); inli(li[t]);
            end;
          end;
      'A':begin
            prompt('Abort? ');
            if yn then abortit:=true else c:=' ';
          end;
      'S':save:=true;
      'C':if lc>maxli then begin print('Too long.'); c:=' '; end else
            print('Continue...');
      '?':prhelp1;
    end;
  until (c='S') or (c='A') or (c='C') or hangup;
 until abortit or save or hangup;
 if lc=1 then begin abortit:=true; save:=false; end;
 if save then begin
   case an of
     no      : ti:=nam;
     forced  : if (thisuser.sl>=99) then ti:='!'+nam else ti:='@'+nam;
     yes     : begin
                 ynq('Anonymous? '); ansic(0);
                 if yn then
                   if (thisuser.sl>=99) then
                     ti:='!'+nam
                   else
                     ti:='@'+nam
                 else
                   ti:=nam;
               end;
     dearabby: begin
                 nl;print('Post as:'); print('1. Abby');
                 print('2. Problemed Person'); print('3. '+nam);
                 nl;prompt('Which? '); onek(c,'123N'+#13);
                case c of
                 '1'        : ti:='+'+nam;
                 '2'        : ti:='-'+nam;
                 '3',#13,'N': ti:=nam;
                end;
               end;
   end;
   if ti=nam then lan:=false else lan:=true;
   print('Saving...');
   while (lc>1) and ((li[lc-1]='') or (li[lc-1]=chr(10))) do lc:=lc-1;
   mrec:=systat.hmsg; mrec.number:=mrec.number+1; if mrec.number=-32767 then
     mrec.ltr:=succ(mrec.ltr);
   if mrec.ltr>'Z' then begin
     mrec.ltr:='A';
     mrec.ext:=mrec.ext+1;
     if mrec.ext>=128 then mrec.ext:=1;
   end;
   systat.hmsg:=mrec;
   if mp then mrec.ext:=mrec.ext+128;
   i:=filename(mrec);
   assign(filvar,i);
   rewrite(filvar);
   writeln(filvar,ti); ti:=dat; writeln(filvar,ti);
   if irt<>'' then begin
     writeln(filvar,'RE: '+irt);
     writeln(filvar); writeln(filvar); writeln(filvar);
   end;
   for t:=1 to lc-1 do
     writeln(filvar,li[t]);
   close(filvar); savesystat;
 end else begin print('Aborted.'); mrec.ext:=0; end;
 end else begin print('Aborted.'); mrec.ext:=0; end;
end;

procedure readmsg(mrec:messages;rname:boolean; var next:boolean);
var f,n,rn,d:str; filvar:text; abort:boolean;
begin
  lastname:=''; next:=false;
  f:=filename(mrec); rn:='';
  if cs and (not hangup) then writeln('Filename: '+f);
  assign(filvar,f); {$I-} reset(filvar); {$I+}
  if ioresult<>0 then print('File not found.') else
  if (not hangup) then begin
    readln(filvar,n);
    readln(filvar,d); lastname:=n;
    if ((n[1]='@') and rname) or ((n[1]='!') and so) then
      n:='<<< '+copy(n,2,length(n)-1)+' >>>'
    else
      if (n[1] in ['!','@']) then
        begin
          lastname:='';
          n:='>UNKNOWN<';
          d:='<-> INACTIVE <->';
        end;
    if (N[1]='+') or (n[1]='-') then begin
      rn:=copy(n,2,length(n)-1);
      if n[1]='+' then n:='Abby' else n:='Problemed Person';
      if not rname then begin d:='<-> INACTIVE <->'; rn:=''; lastname:=''; end;
    end;
    abort:=false;
    printacr('Name: '+n,abort,next); if not abort then begin
      if  rn<>'' then print('Name: '+rn);
      printacr('Date: '+d,abort,next); nl;
      while (not abort) and (not eof(filvar)) do begin
        readln(filvar,n); printa(n,abort,next);
      end;
      if not abort then nl;
    end;
  end;
  close(filvar); nl;
end;
