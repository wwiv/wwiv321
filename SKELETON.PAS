program skeleton;

{$V-} {$C-}
{$I COMMON.PAS}

procedure return;
var f:file;
begin
  assign(f,'bbs.com');
  print('Returning to BBS...');
  remove_port;
  if hangup then term_ready(false);
  execute(f);
end;

begin
  iport;


  return;
end.