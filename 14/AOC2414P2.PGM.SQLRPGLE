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
dcl-c MIN_TIME 0;
dcl-c MAX_TIME 10000;

dcl-s fileName varchar(100);

dcl-s data varchar(255);
dcl-s x int(3);
dcl-s y int(3);
dcl-s vx int(3);
dcl-s vy int(3);
dcl-s time int(5);

dcl-s result int(20) inz(0);

dcl-s map uns(5) dim(LENGTH); // We store the number of robots per position

fileName = %trim(input);

// Read the input data from the IFS
exec sql declare c1 cursor for select line from table(qsys2.ifs_read_utf8(path_name => :fileName));

for time = MIN_TIME to MAX_TIME;
reset map;
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

  map(x+y*WIDTH+1) += 1;
  
  // Read next line
  exec sql fetch c1 into :data;
  enddo;

exec sql close c1;

for y = 0 to HEIGHT-1;
  data = '';
  for x = 0 to WIDTH -1;
    if map(x+y*WIDTH+1) > 0;
      data += '#';
    else;
      data += '.';
    endif;
  endfor;
  exec sql set :result = regexp_count(:data, '#################');
  if result > 0;
    snd-msg *info 'Time: ' + %char(time) + 's' %target(*pgmbdy:1); // Send message with answer
  endif;
endfor;
endfor;

*inlr = *on;
return;