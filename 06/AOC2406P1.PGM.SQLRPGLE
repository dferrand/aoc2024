**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-s fileName varchar(50);

dcl-c WIDTH 130;
dcl-c HEIGHT 130;
dcl-c LENGTH const(16900);

dcl-s data char(LENGTH);
dcl-s result int(10) inz(0);
dcl-s line int(10);
dcl-s col int(10);
dcl-s index int(10);
dcl-s pCurChar pointer;
dcl-s curChar char(1) based(pCurChar);
dcl-s pNextChar pointer;
dcl-s nextChar char(1) based(pNextChar);
dcl-s direction int(5) inz(1);             // 1-up, 2-right, 3-down, 4-left

fileName = %trim(input);

// Read the input data from the IFS concatenating all lines
exec sql select listagg(line) into :data from table(qsys2.ifs_read_utf8(path_name => :fileName));

// Find the initial position
index = %scan('^':data);
line = %div(index-1:WIDTH) + 1;
col = %rem(index-1:WIDTH) + 1;

pCurChar = %addr(data) + index - 1; // Mark initial position as used.
curChar = 'X';

// We loop until we exit the area
dou (line = 1 and direction = 1) or (col = WIDTH and direction = 2) or (line = HEIGHT and direction = 3) or (col = 1 and direction = 4); 
  select direction;                    // Move pNextChar to the next position depending on the direction
    when-is 1;                         // right
      pNextChar = pCurChar - WIDTH;
    when-is 2;                         // down
      pNextChar = pCurChar + 1;
    when-is 3;                         // left
      pNextChar = pCurChar + WIDTH;
    when-is 4;                         // up
      pNextChar = pCurChar - 1;
  endsl;

  if nextChar <> '#';                  // If nextChar is not an obstacle, we proceed
    pCurChar = pNextChar;
    line = %div(pCurChar-%addr(data):WIDTH) + 1;
    col = %rem(pCurChar-%addr(data):WIDTH) + 1;
    curChar = 'X';                     // Mark the position as visited
  else;                                // If next is an obstacle, we don't move and rotate right
    direction = %rem(direction:4) + 1;
  endif;
enddo;

// Use regular expression to count the visited positions
exec sql select REGEXP_COUNT(:data, 'X') into :result from sysibm.sysdummy1;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;