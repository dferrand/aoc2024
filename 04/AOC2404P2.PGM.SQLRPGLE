**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-s fileName varchar(50);

dcl-c WIDTH 140;
dcl-c HEIGHT 140;
dcl-c LENGTH const(19600);

dcl-s data char(LENGTH);
dcl-s result int(10) inz(0);
dcl-s line int(10) inz(2);
dcl-s col int(10) inz(2);
dcl-s index int(10);
dcl-s pCurChar pointer;
dcl-s curChar char(1) based(pCurChar);
dcl-s pScanChar1 pointer;
dcl-s scanChar1 char(1) based(pScanChar1);
dcl-s pScanChar2 pointer;
dcl-s scanChar2 char(1) based(pScanChar2);
dcl-s pScanChar3 pointer;
dcl-s scanChar3 char(1) based(pScanChar3);
dcl-s pScanChar4 pointer;
dcl-s scanChar4 char(1) based(pScanChar4);

fileName = %trim(input);

// Read the input data from the IFS concatenating all lines
exec sql select listagg(line) into :data from table(qsys2.ifs_read_utf8(path_name => :fileName));

pCurChar = %addr(data)+WIDTH+1;        // We start on the second column of the second line
for index = 1 to (WIDTH-2)*(HEIGHT-2); // We skip the first and last lines and columns
  if curChar = 'A';
    pScanChar1 = pCurChar - WIDTH - 1; // top left
    pScanChar2 = pCurChar - WIDTH + 1; // top right
    pScanChar3 = pCurChar + WIDTH - 1; // bottom left
    pScanChar4 = pCurChar + WIDTH + 1; // bottom right

    if (scanChar1 = 'M' and scanChar4 = 'S') or (scanChar1 = 'S' and scanChar4='M');
      if (scanChar2 = 'M' and scanChar3 = 'S') or (scanChar2 = 'S' and scanChar3='M');
        result += 1;
      endif;
    endif;
  endif;
  if col < WIDTH-1;  // If we are not on the second to last column, we advance to the next column
    col += 1;
    pCurChar += 1;
  else;              // If we are on the second to last column, we skip to the second column of next line
    col = 2;
    line += 1;
    pCurChar += 3;
  endif;
endfor;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;