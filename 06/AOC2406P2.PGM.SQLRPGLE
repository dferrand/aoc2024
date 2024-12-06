**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-pr isLoop ind end-pr;

dcl-s fileName varchar(50);

dcl-c WIDTH 130;
dcl-c HEIGHT 130;
dcl-c LENGTH const(16900);

dcl-s data char(LENGTH);
dcl-s dataOrig char(LENGTH);
dcl-s result int(10) inz(0);
dcl-s line int(10);
dcl-s col int(10);
dcl-s index int(10);
dcl-s i int(10);
dcl-s pCurChar pointer;
dcl-s curChar char(1) based(pCurChar);
dcl-s pNextChar pointer;
dcl-s nextChar char(1) based(pNextChar);
dcl-s direction int(5) inz(1);             // 1-up, 2-right, 3-down, 4-left

fileName = %trim(input);

// Read the input data from the IFS concatenating all lines
exec sql select listagg(line) into :dataOrig from table(qsys2.ifs_read_utf8(path_name => :fileName));

for i = 1 to LENGTH;                       // Loop over all the positions of the map
  pNextChar = %addr(dataOrig) + i -1;
  if nextChar = '.';                       // We only add an obstacle if the position is empty
    direction = 1;                         // Reset direction to up
    data = dataOrig;                       // Reset the map to the original map
    pNextChar = %addr(data) + i -1;
    nextChar = '#';                        // Add the obstacle
    if isLoop();                           // If the guard enters a loop, we add 1 to the result
      result += 1;
    endif;
  endif;
endfor;


snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;

dcl-proc isLoop;

dcl-pi *n ind;
end-pi;

// Find the initial position
index = %scan('^':dataOrig);
line = %div(index-1:WIDTH) + 1;
col = %rem(index-1:WIDTH) + 1;

// Mark the initial position with the original direction (up)
pCurChar = %addr(data) + index - 1;
curChar = '1';

// Loop until we exit the area
dou (line = 1 and direction = 1) or (col = WIDTH and direction = 2) or (line = HEIGHT and direction = 3) or (col = 1 and direction = 4); 
  select direction;
    when-is 1;
      pNextChar = pCurChar - WIDTH;
    when-is 2;
      pNextChar = pCurChar + 1;
    when-is 3;
      pNextChar = pCurChar + WIDTH;
    when-is 4;
      pNextChar = pCurChar - 1;
  endsl;

  if nextChar = %char(direction);          // If the next position was already visited with the same direction, then we're in a loop, we exit and return *on
    return *on;
  endif;
  if nextChar <> '#';
    pCurChar = pNextChar;
    line = %div(pCurChar-%addr(data):WIDTH) + 1;
    col = %rem(pCurChar-%addr(data):WIDTH) + 1;
    curChar = %char(direction);
  else;
    direction = %rem(direction:4) + 1;
  endif;
enddo;

return *off;                               // If the guard exits the area, that means it's not a loop
end-proc;