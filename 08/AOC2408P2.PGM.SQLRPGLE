**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-c WIDTH 50;
dcl-c HEIGHT 50;
dcl-c LENGTH 2500;

dcl-s fileName varchar(50);
dcl-s data char(LENGTH);
dcl-s antinodes char(LENGTH) inz(*all' ');
dcl-s index int(5);
dcl-s searchIndex int(5);
dcl-s row int(5);
dcl-s col int(5);
dcl-s searchRow int(5);
dcl-s searchCol int(5);
dcl-s antinodeRow int(5);
dcl-s antinodeCol int(5);
dcl-s deltaRow int(5);
dcl-s deltaCol int(5);
dcl-s frequency char(1);

dcl-s result int(20) inz(0);

fileName = %trim(input);

// Read the input data from the IFS, concatenating all lines
exec sql select listagg(line) into : data from table(qsys2.ifs_read_utf8(path_name => :fileName));

for index = 1 to LENGTH-1;
  frequency = %subst(data:index:1);
  if frequency <> '.';
    searchIndex = %scan(frequency:data:index+1);
    row = %div(index-1:WIDTH)+1;
    col = %rem(index-1:WIDTH)+1;
    dow searchIndex > 0;
      searchCol = %rem(searchIndex-1:WIDTH)+1;
      searchRow = %div(searchIndex-1:WIDTH)+1;

      // Try the antinodes "before"
      antinodeRow = row;
      antinodeCol = col;
      dow antinodeRow >= 1 and antinodeRow <= WIDTH and antinodeCol >= 1 and antinodeCol <= HEIGHT;
        %subst(antinodes:(antinodeRow-1)*WIDTH+antinodeCol-1:1) = 'X';
        antinodeRow = antinodeRow - (searchRow - row);
        antinodeCol = antinodeCol - (searchCol - col);
      enddo;

      // Try the antinode "after"
      antinodeRow = searchRow;
      antinodeCol = searchCol;
      dow antinodeRow >= 1 and antinodeRow <= WIDTH and antinodeCol >= 1 and antinodeCol <= HEIGHT;
        %subst(antinodes:(antinodeRow-1)*WIDTH+antinodeCol-1:1) = 'X';
        antinodeRow = antinodeRow + (searchRow - row);
        antinodeCol = antinodeCol + (searchCol - col);
      enddo;

      if searchIndex = LENGTH;
        searchIndex = 0;
      else;
        searchIndex = %scan(frequency:data:searchIndex+1);
      endif;
    enddo;
  endif;
endfor;

// Count the X in antinodes
exec sql select regexp_count(:antinodes, 'X') into :result from sysibm.sysdummy1;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;