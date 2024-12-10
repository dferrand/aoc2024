**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-pr explore;
  pos int(10) value;
  search char(1) value;
end-pr;

dcl-pr process;
  pos int(10) value;
  search char(1) value;
end-pr;

dcl-c WIDTH 54;
dcl-c HEIGHT 54;
dcl-c LENGTH 2916;

dcl-s fileName varchar(50);
dcl-s data char(LENGTH);

dcl-s index int(10) inz(1);
dcl-s trailheads int(5) dim(*auto:292); // Store reachable ends of trails from current traihead
dcl-s result int(20) inz(0);

fileName = %trim(input);

// Read the input data from the IFS, concatenating all lines
exec sql select listagg(line) into :data from table(qsys2.ifs_read_utf8(path_name => :fileName));

//  Search first trailhead 
index = %scan('0':data);

dou index = 0;
  
  explore(index:'1');   // find 1 around current position
  result += %elem(trailheads);  // append number of trail ends from current trailhead
  %elem(trailheads) = 0;  // reset trail ends
  if index = LENGTH;    // If we're not on the last position, find next 0
    index = 0;
  else;
    index = %scan('0':data:index+1);
  endif;
enddo;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;

dcl-proc explore;

dcl-pi *n;
  pos int(10) value;
  search char(1) value;
end-pi;
  
  dcl-s line int(5);
  dcl-s col int(5);

  line = %div(pos-1:WIDTH)+1;
  col = %rem(pos-1:WIDTH)+1;

  // explore up
  if line > 1;
    process(pos-WIDTH:search);
  endif;

  // explore right
  if col < WIDTH;
    process(pos+1:search);
  endif;

  // explore down
  if line < HEIGHT;
    process(pos+WIDTH:search);
  endif;

  // explore left
  if col > 1;
    process(pos-1:search);
  endif;

end-proc;

dcl-proc process;

dcl-pi *n;
  pos int(10) value;
  search char(1) value;
end-pi;
dcl-s target char(1);

target = %subst(data:pos:1);
if target = search;    // If the position is the requested elevation
  if search = '9';     // If we are at the end of the trail
    if not(pos in trailheads);   // IF the trail end hasn't already been registered
      trailheads(*next) = pos;   // add the trail end to the list
    endif;
  else;                // If we are not at the end of the trail
    explore(pos:%char(%int(search)+1));  // Explore from here for the next elevation level
  endif;
endif;

end-proc;