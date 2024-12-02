**free

dcl-pi *n;
  input char(50);
end-pi;  

dcl-s fileName varchar(50);
dcl-s sim int(20) inz(0);

fileName = %trim(input);

exec sql select sum(integer(substring(a.line, 1, 5)) * (select
  count(*) from table(qsys2.ifs_read_utf8(path_name => :fileName)) b
  where substring(b.line, 9, 5) = substring(a.line, 1, 5))) into :sim 
  from table(qsys2.ifs_read_utf8(path_name => :fileName)) a;

snd-msg *info 'Similarity score is '+%char(sim) %target(*pgmbdy:1);

*inlr = *on;
return;
