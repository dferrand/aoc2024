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
dcl-s i int(5);
dcl-s j int(5);
dcl-s positions int(10) dim(10000);
dcl-s fillings int(10) dim(9999);

dcl-s result int(20) inz(0);

fileName = %trim(input);

// Read the input data from the IFS, concatenating all lines
exec sql select line into :data from table(qsys2.ifs_read_utf8(path_name => :fileName));

// Calculate initial position of each File
for i = 1 to 10000;
  positions(i) = position;
  if i < 10000;
    position += %int(%subst(data:2*(i-1)+1:1))+%int(%subst(data:2*(i-1)+2:1));
  endif;
endfor;

// Defragment
for i = 19999 downto 3 by 2;
  rightCount = %int(%subst(data:i:1));
  j = 2;
  leftCount = %int(%subst(data:j:1));
  dow j<=i and rightCount > leftCount;
    j += 2;
    leftCount = %int(%subst(data:j:1));
  enddo;
  if leftCount >= rightCount;
    positions(%div(i+1:2)) = positions(%div(j:2))+%int(%subst(data:j-1:1))+fillings(%div(j:2));
    fillings(%div(j:2)) += rightCount;
    leftCount -= rightCount;
    %subst(data:j:1) = %char(leftCount);
  endif;
endfor;

// Compute checksum
for i = 1 to 10000;
  position = positions(i);
  for j = 1 to %int(%subst(data:2*(i-1)+1:1));
    result += (i-1)*position;
    position += 1;
  endfor;
endfor;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;