**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-c WIDTH 140;
dcl-c HEIGHT 140;
dcl-c LENGTH 19600;

dcl-s fileName varchar(50);
dcl-s data char(LENGTH);
dcl-s i int(5);
dcl-s row int(5);
dcl-s col int(5);
dcl-s result int(10) inz(0);
dcl-s currentChar char(1);

dcl-ds dimension qualified;
  area int(5);
  perimeter int(5);
end-ds;

dcl-pr explore likeds(dimension);
  position int(5) value;
end-pr;

fileName = %trim(input);

// Read the input data from the IFS, concatenating all lines
exec sql select listagg(line) into :data from table(qsys2.ifs_read_utf8(path_name => :fileName));

// Find first char
exec sql select regexp_instr(:data, '[^ ]') into :i from sysibm.sysdummy1;

dow i <> 0;
  currentChar = %subst(data:i:1);
  
  dimension = explore(i);

  result += dimension.area * dimension.perimeter;

  data = %scanrpl('_':' ':data); // Replace _ with spaces

  // Find first char
  exec sql select regexp_instr(:data, '[^ ]') into :i from sysibm.sysdummy1;
enddo;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;

dcl-proc explore;

dcl-pi *n likeds(dimension);
  position int(5) value;
end-pi;
dcl-s row int(5);
dcl-s col int(5);
dcl-ds retVal likeds(dimension);
dcl-ds exploreResult likeds(dimension);


if %subst(data:position:1) = '_'; // IF this is an already visited position for this region
  retVal.area = 0;
  retVal.perimeter = 0;
  return retVal;
endif;

if %subst(data:position:1) <> currentChar; // If this is a position from another region
  retVal.area = 0;
  retVal.perimeter = 1;
  return retVal;
endif;

%subst(data:position:1) = '_';

row = %div(position-1:WIDTH)+1;
col = %rem(position-1:WIDTH)+1;

retVal.area = 1;
retVal.perimeter = 0;

// Explore up
if row = 1;
  retVal.perimeter += 1;
else;
  exploreResult = explore(position-WIDTH);
  retVal.area += exploreResult.area;
  retVal.perimeter += exploreResult.perimeter;
endif;
 
// Explore right
if col = WIDTH;
  retVal.perimeter += 1;
else;
  exploreResult = explore(position+1);
  retVal.area += exploreResult.area;
  retVal.perimeter += exploreResult.perimeter;
endif;
  
// Explore down
if row = HEIGHT;
  retVal.perimeter += 1;
else;
  exploreResult = explore(position+WIDTH);
  retVal.area += exploreResult.area;
  retVal.perimeter += exploreResult.perimeter;
endif;
   
// Explore left
if col = 1;
  retVal.perimeter += 1;
else;
  exploreResult = explore(position-1);
  retVal.area += exploreResult.area;
  retVal.perimeter += exploreResult.perimeter;
endif;

return retVal;

end-proc;