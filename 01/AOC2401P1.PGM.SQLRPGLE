**free

dcl-pi *n;
  input char(50);
end-pi;  

dcl-s fileName varchar(50);
dcl-s val1 int(10);
dcl-s val2 int(10);
dcl-s diff int(20) inz(0);

fileName = %trim(input);

exec sql declare c1 cursor for select integer(substring(line, 1, 5)) v
  from table(qsys2.ifs_read_utf8(path_name => :fileName))
  order by v;

exec sql declare c2 cursor for select integer(substring(line, 9, 5)) v
  from table(qsys2.ifs_read_utf8(path_name => :fileName))
  order by v;

exec sql open c1;
exec sql open c2;

exec sql fetch from c1 into :val1;
exec sql fetch from c2 into :val2;

dow sqlcode = 0;
  diff += %abs(val1-val2);

  exec sql fetch from c1 into :val1;
  exec sql fetch from c2 into :val2;
enddo;

exec sql close c1;
exec sql close c2;

snd-msg *info 'Distance is '+%char(diff) %target(*pgmbdy:1);

*inlr = *on;
return;
