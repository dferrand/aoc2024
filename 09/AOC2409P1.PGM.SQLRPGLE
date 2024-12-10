**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-c LENGTH 19999;

dcl-s fileName varchar(50);
dcl-s data char(LENGTH);
dcl-s position int(10) inz(0);
dcl-s leftID int(10) inz(0);
dcl-s rightID int(10) inz(9999);
dcl-s leftIndex  int(10) inz(1);
dcl-s rightIndex int(10) inz(19999);
dcl-s leftCount int(3);
dcl-s rightCount int(3);
dcl-s i int(3);

dcl-s result int(20) inz(0);

fileName = %trim(input);

// Read the input data from the IFS, concatenating all lines
exec sql select line into :data from table(qsys2.ifs_read_utf8(path_name => :fileName));

leftCount = %int(%subst(data:1:1));
rightCount = %int(%subst(data:19999:1));

dow leftIndex < rightIndex;
  for i = 1 to leftcount;
    result += position*leftID;
    position += 1;
  endfor;

  leftIndex += 1;
  leftCount = %int(%subst(data:leftindex:1));
  for i = 1 to leftCount;
    if rightCount = 0;
      rightIndex -=  2;
      rightCount = %int(%subst(data:rightIndex:1));
      rightID -= 1;
    endif;
    result += position*rightID;
    rightCount -= 1;
    position += 1;
  endfor;
  leftIndex += 1;
  leftCount = %int(%subst(data:leftIndex:1));
  leftID += 1;
enddo;

for i = 1 to rightCount;
  result += position*rightID;
  position += 1;
endfor;


snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;