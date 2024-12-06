**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

// In part 2, process line will be recursive but we don't want to return the middle
// page number if the update is correctly ordered. Therefore, we add the swapped
// parameter that will be *off on the initial call and *on in the recursive calls
// it will know wether to return 0 or the middle page
dcl-pr processLine int(10);   
  line varchar(1000) value;
  swapped ind value;        
end-pr;

dcl-s fileName varchar(50);

dcl-s line varchar(1000);
dcl-s result int(10) inz(0);

dcl-ds rule qualified;
  predecessor int(5);
  successor int(5);
end-ds;

dcl-s rules char(4) ascend dim(*auto:2000);

fileName = %trim(input);

// Read the rules from the IFS
exec sql declare c1 cursor for select int(left(line, position('|', line)-1)) a, 
int(substr(line, position('|', line)+1)) b from table(qsys2.ifs_read_utf8(path_name => :fileName)) 
where line like '%|%' order by a, b;

exec sql open c1;

exec sql fetch c1 into :rule;
dow sqlcode = 0;

  rules(*next) = rule;

exec sql fetch c1 into :rule;
enddo;

exec sql close c1;

// Read updates from the IFS
exec sql declare c2 cursor for select cast(line as varchar(1000)) from table(qsys2.ifs_read_utf8(path_name => :fileName)) 
where line like '%,%';

exec sql open c2;

exec sql fetch from c2 into :line;

dow sqlcode = 0;

  result += processLine(line:*off);

exec sql fetch from c2 into :line;
enddo;

exec sql close c2;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;

dcl-proc processLine;

dcl-pi *n int(10);
  line varchar(1000) value;
  swapped ind value;
end-pi;

dcl-s pages char(2) dim(*auto: 1000);
dcl-s i int(5);
dcl-s j int(5);
dcl-s swap char(2);

pages = %split(line:',');

for i = 1 to %elem(pages) - 1;
  rule.successor = %int(pages(i));
  for j = i+1 to %elem(pages);
    rule.predecessor = %int(pages(j));
    if %char(rule) in rules;              // If pages(i) and pages(j) break a rule, we swap them and recursively call processLine until the update is correctly ordered
      swap = pages(i);
      pages(i) = pages(j);
      pages(j) = swap;
      return processLine(%concatarr(',' : pages):*on);
    endif;
  endfor;
endfor;
if swapped;
  return %int(pages(%int(%elem(pages)/2) + 1));
else;
  return 0;
endif;

end-proc;