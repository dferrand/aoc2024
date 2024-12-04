**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-pr isXmas ind;
  offset int(10) value;
end-pr;

dcl-s fileName varchar(50);

dcl-c WIDTH 140;
dcl-c HEIGHT 140;
dcl-c LENGTH const(19600);

dcl-s data char(LENGTH);
dcl-s result int(10) inz(0);
dcl-s line int(10) inz(1);
dcl-s col int(10) inz(1);
dcl-s index int(10);
dcl-s pCurChar pointer;
dcl-s curChar char(1) based(pCurChar);
dcl-s pScanChar pointer;
dcl-s scanChar char(1) based(pScanChar);

fileName = %trim(input);

// Read the input data from the IFS concatenating all lines
exec sql select listagg(line) into :data from table(qsys2.ifs_read_utf8(path_name => :fileName));

pCurChar = %addr(data);
for index = 1 to length;
  if curChar = 'X';
    if col <= WIDTH-3 and isXmas(1);  // Checking to the right
      result += 1;
    endif;
    if col <= WIDTH-3 and line <= HEIGHT-3 and isXmas(WIDTH+1); // Checking bottom right
      result += 1;
    endif;
    if line <= HEIGHT-3 and isXmas(WIDTH); // checking down
      result += 1;
    endif;
    if line <= HEIGHT-3 and col >= 4 and isXmas(WIDTH-1); // Checking bottom left
      result += 1;
    endif;
    if col >= 4 and isXmas(-1); // Checking left
      result += 1;
    endif;
    if col >= 4 and line >=4 and isXmas(-WIDTH-1); // Checking top left
      result += 1;
    endif;
    if line >= 4 and isXmas(-WIDTH); // Checking up
      result += 1;
    endif;
    if line >= 4 and col <= WIDTH-3 and isXmas(-WIDTH+1); // Checking top right
      result += 1;
    endif;
  endif;
  pCurChar += 1;
  if col < WIDTH;
    col += 1;
  else;
    col = 1;
    line += 1;
  endif;
endfor;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;

dcl-proc isXmas;

dcl-pi *n ind;
  offset int(10) value;
end-pi;
pScanChar = pCurChar + offset;
if scanChar <> 'M';
  return *off;
endif;
pScanChar += offset;
if scanChar <> 'A';
  return *off;
endif;
pScanChar += offset;
if scanChar <> 'S';
  return *off;
endif;

return *on;

end-proc;