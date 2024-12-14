**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-s fileName varchar(50);

dcl-s data varchar(255);
dcl-s val varchar(10);

dcl-s result int(20) inz(0);

dcl-s ax int(5);
dcl-s ay int(5);
dcl-s bx int(5);
dcl-s by int(5);
dcl-s x int(20);
dcl-s y int(20);
dcl-s a packed(20:5);
dcl-s b packed(20:5);

fileName = %trim(input);

// Read the input data from the IFS
exec sql declare c1 cursor for select line from table(qsys2.ifs_read_utf8(path_name => :fileName));
exec sql open c1;

// Read first line
exec sql fetch c1 into :data;

dow sqlcode = 0;
  // extract ax
  exec sql set :val = regexp_substr(:data, 'Button A: X\+(\d+), Y\+(\d+)', 1, 1, 'c', 1);
  ax = %int(val);
  // extract ay
  exec sql set :val = regexp_substr(:data, 'Button A: X\+(\d+), Y\+(\d+)', 1, 1, 'c', 2);
  ay = %int(val);

  // Read second line
  exec sql fetch c1 into :data;
  // extract bx
  exec sql set :val = regexp_substr(:data, 'Button B: X\+(\d+), Y\+(\d+)', 1, 1, 'c', 1);
  bx = %int(val);
  // extract by
  exec sql set :val = regexp_substr(:data, 'Button B: X\+(\d+), Y\+(\d+)', 1, 1, 'c', 2);
  by = %int(val);
 
  // Read third line
  exec sql fetch c1 into :data;
  // extract x
  exec sql set :val = regexp_substr(:data, 'Prize: X=(\d+), Y=(\d+)', 1, 1, 'c', 1);
  x = %int(val);
  // extract y
  exec sql set :val = regexp_substr(:data, 'Prize: X=(\d+), Y=(\d+)', 1, 1, 'c', 2);
  y = %int(val);

  a = (x*by-bx*y)/(ax*by-bx*ay);
  b = (x*ay-ax*y)/(-ax*by+bx*ay);

  if a>=0 and b>=0 and %int(a) = a and %int(b) = b;
    if a*ax+b*bx = x and a*ay+b*by = y;
      result += %int(a)*3 + %int(B);
    endif;
  endif;
 
  // Read next 2 lines
  exec sql fetch c1 into :data;
  exec sql fetch c1 into :data;
enddo;

exec sql close c1;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;