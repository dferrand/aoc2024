**free

// One parameter: the path to the input file
dcl-pi *n;
  input char(50);
end-pi;  


dcl-s fileName varchar(50); // ifs_read_utf8 doesn't like trailing spaces in the file name, so we use a VARCHAR to get rid of them
dcl-s val1 int(10);         // will hold the current value from the first list
dcl-s val2 int(10);         // will hold the current value from the second list
dcl-s diff int(20) inz(0);  // will hole the distance between the lists

fileName = %trim(input);

// Cursor for the first list
exec sql declare c1 cursor for select integer(substring(line, 1, 5)) v
  from table(qsys2.ifs_read_utf8(path_name => :fileName))
  order by v;

// Cursor for the second list
exec sql declare c2 cursor for select integer(substring(line, 9, 5)) v
  from table(qsys2.ifs_read_utf8(path_name => :fileName))
  order by v;

exec sql open c1;
exec sql open c2;

// Read the first pair
exec sql fetch from c1 into :val1;
exec sql fetch from c2 into :val2;

dow sqlcode = 0;
  diff += %abs(val1-val2);   // distance is the absolute value of the difference

  // Read the next pair.
  exec sql fetch from c1 into :val1;
  exec sql fetch from c2 into :val2;
enddo;

exec sql close c1;
exec sql close c2;

// Give the answer to the user
snd-msg *info 'Distance is '+%char(diff) %target(*pgmbdy:1);

*inlr = *on;
return;
