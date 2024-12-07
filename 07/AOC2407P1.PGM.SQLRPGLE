**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-pr solve int(20);
  target int(20) value;
  left int(20) value;
  right int(5) dim(30) value;
  rightElems int(5) value;
end-pr;

dcl-s fileName varchar(50);

dcl-s result int(20) inz(0);
dcl-s line varchar(1000);
dcl-s sum int(20);
dcl-s values int(5) dim(*auto:30);
dcl-s value varchar(5);

fileName = %trim(input);

// Read the input data from the IFS
exec sql declare c1 cursor for select cast(line as varchar(1000)) from table(qsys2.ifs_read_utf8(path_name => :fileName));
exec sql open c1;

// Read the first line
exec sql fetch from c1 into :line;

dow sqlcode = 0;
// read the sum
sum = %int(%left(line:%scan(':':line)-1));

// read the terms
%elem(values) = 0;
for-each value in %split(%subst(line:%scan(':':line)+1));
  values(*next) = %int(value);
endfor;

result += solve(sum:values(1):%subarr(values:2):%elem(values)-1);

// Read the next line
exec sql fetch from c1 into :line;
enddo;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;

dcl-proc solve;
dcl-pi *n int(20);
  target int(20) value;
  left int(20) value;
  right int(5) dim(30) value;
  rightElems int(5) value;
end-pi;

if rightElems = 1;
  if left+right(1) = target or left*right(1) = target;
    return target;
  else;
    return 0;
  endif;
else;
  if solve(target:left+right(1):%subarr(right:2:rightElems-1):rightElems-1) > 0 or solve(target:left*right(1):%subarr(right:2:rightElems-1):rightElems-1) > 0;
    return target;
  else;
    return 0;
  endif;
endif;

end-proc;