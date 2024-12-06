**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-pr processLine int(10);
  line varchar(1000);
end-pr;

dcl-s fileName varchar(50);

dcl-s line varchar(1000);
dcl-s result int(10) inz(0);

dcl-ds rule qualified;     // A rule is a pair of page numbers, the predecessor and the successor
  predecessor int(5);
  successor int(5);
end-ds;

// We store rules in a dynamic array
// We define the array elements as 4 bytes instead of a data structure because RPG 
// can only search over one field of a data structure, not the whole DS.
// We sort the array to use binary search which is faster
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

  result += processLine(line);     // processLine returns 0 for incorrectly ordered updates so we can safely add it to the result

exec sql fetch from c2 into :line;
enddo;

exec sql close c2;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;

dcl-proc processLine;

dcl-pi *n int(10);
  line varchar(1000);
end-pi;

dcl-s pages char(2) dim(*auto: 1000);
dcl-s i int(5);
dcl-s j int(5);

pages = %split(line:',');

for i = 1 to %elem(pages) - 1;         // i loops over all pages until the second to last
  rule.successor = %int(pages(i));
  for j = i+1 to %elem(pages);         // j loops from page i to the last one
    rule.predecessor = %int(pages(j));
    if %char(rule) in rules;           // If page order breaks a rule, we return 0
      return 0;
    endif;
  endfor;
endfor;

return %int(pages(%int(%elem(pages)/2) + 1));  // If no rule was broken, we return the middle page number

end-proc;