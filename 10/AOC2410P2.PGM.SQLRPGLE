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
dcl-s result int(20) inz(0);

fileName = %trim(input);

// Read the input data from the IFS, concatenating all lines
exec sql select listagg(line) into :data from table(qsys2.ifs_read_utf8(path_name => :fileName));

index = %scan('0':data);

dou index = 0;
  explore(index:'1');
  if index = LENGTH;
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
if target = search;
  if search = '9';
    result += 1;
  else;
    explore(pos:%char(%int(search)+1));
  endif;
endif;

end-proc;