**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-c WIDTH 101;
dcl-c HEIGHT 103;
dcl-c MID_X 50;
dcl-c MID_Y 51;
dcl-c LENGTH 10403;
dcl-c TIME 100;

dcl-s fileName varchar(50);

dcl-s data varchar(255);
dcl-s x int(3);
dcl-s y int(3);
dcl-s vx int(3);
dcl-s vy int(3);

dcl-s result int(20) inz(0);

dcl-s map uns(5) dim(4); // We store the number of robots per quarter
dcl-s quadrant uns(3);

fileName = %trim(input);

// Read the input data from the IFS
exec sql declare c1 cursor for select line from table(qsys2.ifs_read_utf8(path_name => :fileName));
exec sql open c1;

// Read first line
exec sql fetch c1 into :data;
  dow sqlcode = 0;
  // Read initial position and speed
  exec sql set :x = int(regexp_substr(:data, 'p=(\d+),(\d+) v=(-?\d+),(-?\d+)', 1, 1, '', 1));
  exec sql set :y = int(regexp_substr(:data, 'p=(\d+),(\d+) v=(-?\d+),(-?\d+)', 1, 1, '', 2));
  exec sql set :vx = int(regexp_substr(:data, 'p=(\d+),(\d+) v=(-?\d+),(-?\d+)', 1, 1, '', 3));
  exec sql set :vy = int(regexp_substr(:data, 'p=(\d+),(\d+) v=(-?\d+),(-?\d+)', 1, 1, '', 4));

  // Compute final position
  x = %rem(x+vx*TIME:WIDTH);
  y = %rem(y+vy*TIME:HEIGHT);

  // Adjust x and y if they are negative
  if x < 0;
    x += WIDTH;
  endif;
  if y < 0;
    y += HEIGHT;
  endif;

  // We ignore robots in the middle
  if x<>MID_X and y<>MID_Y;
    // determine the quadrant
    if x<MID_X;
      quadrant = 1;
    else;
      quadrant = 2;
    endif;
    if y>MID_Y;
      quadrant += 2;
    endif;
    map(quadrant) += 1;
  endif;

  // Read next line
  exec sql fetch c1 into :data;
enddo;

exec sql close c1;

result = map(1)*map(2)*map(3)*map(4);

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;