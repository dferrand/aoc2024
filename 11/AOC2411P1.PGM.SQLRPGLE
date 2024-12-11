**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-s fileName varchar(50);
dcl-s data char(255);
dcl-s value char(255);
dcl-s i int(5);
dcl-s stone int(20);
dcl-s result int(10) inz(0);

dcl-s currentState int(20) dim(*auto:1677310);
dcl-s newState int(20) dim(*auto:1677310);

fileName = %trim(input);

// Read the input data from the IFS
exec sql select line into :data from table(qsys2.ifs_read_utf8(path_name => :fileName));

// Load current State from input data
for-each value in %split(data);
  currentState(*next) = %int(value);
endfor;

for i = 1 to 25;
  for-each stone in currentState;
    if stone = 0;
      newState(*next) = 1;
    else;
      if %rem(%len(%char(stone)):2) = 0;
        newState(*next) = %int(%subst(%char(stone):1:%div(%len(%char(stone)):2)));
        newState(*next) = %int(%subst(%char(stone):%div(%len(%char(stone)):2)+1));
      else;
        newState(*next) = stone*2024;
      endif;
    endif;
  endfor;
  currentState = newState;
  %elem(newState) = 0;
endfor;

result = %elem(currentState);

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;