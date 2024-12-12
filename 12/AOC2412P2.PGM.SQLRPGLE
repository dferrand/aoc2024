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
dcl-s j int(5);
dcl-s row int(5);
dcl-s col int(5);
dcl-s result int(10) inz(0);
dcl-s currentChar char(1);
dcl-s area int(5);
dcl-s sides int(5);

dcl-pr explore;
  position int(5) value;
end-pr;

dcl-pr measure;
  position int(5) value;
end-pr;

fileName = %trim(input);

// Read the input data from the IFS, concatenating all lines
exec sql select listagg(line) into :data from table(qsys2.ifs_read_utf8(path_name => :fileName));

// Find first char
exec sql select regexp_instr(:data, '[^ ]') into :i from sysibm.sysdummy1;

dow i <> 0;
  currentChar = %subst(data:i:1);
  
  explore(i);

  j = i;
  dow j <> 0;
  measure(j);

  if j = LENGTH;
    j = 0;
  else;
    j = %scan('_':data:j+1);
  endif;
  enddo;

  result += area * sides;
  area = 0;
  sides = 0;

  data = %scanrpl('_':' ':data); // Replace _ with spaces

  // Find first char
  exec sql select regexp_instr(:data, '[^ ]') into :i from sysibm.sysdummy1;
enddo;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;

dcl-proc explore;

dcl-pi *n;
  position int(5) value;
end-pi;
dcl-s row int(5);
dcl-s col int(5);

if %subst(data:position:1) <> currentChar; // If this is a position from another region or already visited
  return;
endif;

%subst(data:position:1) = '_';

row = %div(position-1:WIDTH)+1;
col = %rem(position-1:WIDTH)+1;

// Explore up
if row > 1;
  explore(position-WIDTH);
endif;
 
// Explore right
if col < WIDTH;
  explore(position+1);
endif;
  
// Explore down
if row < HEIGHT;
  explore(position+WIDTH);
endif;
   
// Explore left
if col > 1;
  explore(position-1);
endif;

end-proc;

dcl-proc measure;

dcl-pi *n;
  position int(5) value;
end-pi;
dcl-s row int(5);
dcl-s col int(5);

row = %div(position-1:WIDTH)+1;
col = %rem(position-1:WIDTH)+1;

// Check up
if (row = 1 or %subst(data:position-WIDTH:1) <> '_') and (
  col = 1 or not(%subst(data:position-1:1) = '_' and (row = 1 or %subst(data:position-WIDTH-1:1) <> '_')));
  sides += 1;
endif;
 
// Check right
if (col = WIDTH or %subst(data:position+1:1) <> '_') and (
  row = 1 or not(%subst(data:position-WIDTH:1) = '_' and (col = WIDTH or %subst(data:position-WIDTH+1:1) <> '_')));
  sides += 1;
endif;
 
// Check down
if (row = HEIGHT or %subst(data:position+WIDTH:1) <> '_') and (
  col = 1 or not(%subst(data:position-1:1) = '_' and (row = HEIGHT or %subst(data:position+WIDTH-1:1) <> '_')));
  sides += 1;
endif;
  
// Check left
if (col = 1 or %subst(data:position-1:1) <> '_') and (
  row = 1 or not(%subst(data:position-WIDTH:1) = '_' and (col = 1 or %subst(data:position-WIDTH-1:1) <> '_')));
  sides += 1;
endif;
    
area += 1;

end-proc;