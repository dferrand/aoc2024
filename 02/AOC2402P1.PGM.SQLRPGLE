**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-pr isSafe ind;
  data varchar(255);
end-pr;

dcl-s fileName varchar(50);

dcl-s data varchar(255);
dcl-s safeReports int(10) inz(0);

fileName = %trim(input);

// Read the input data from the IFS one line at a time
exec sql declare c1 cursor for select cast(line as varchar(255)) from table(qsys2.ifs_read_utf8(path_name => :fileName));

exec sql open c1;

// Read first line
exec sql fetch from c1 into :data;

// Loop until the end of the file
dow sqlcode = 0;

  // If the report is safe we increment the safe counter
  if isSafe(data);
    safeReports += 1;
  endif;

  // Read next line
  exec sql fetch from c1 into :data;
enddo;

exec sql close c1;

snd-msg *info 'Safe reports: ' + %char(safeReports) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;

dcl-proc isSafe;

dcl-pi *n ind;
  data varchar(255);
end-pi;

dcl-s value char(5);        // Current value as a string
dcl-s previous int(10);     // Previous value
dcl-s current int(10);      // Current value as an integer
dcl-s index int(10) inz(1); // Current index of the value in the report (starts at 1)
dcl-s increasing ind;       // *on if the reports values are increasing, *off if decreasing

// Split the report into values and loop over each value
for-each value in %split(data);
  current = %int(value); // Convert the current value to integer

  if index > 1; // We only start testing at the second value
    if index = 2; // On the second value, we determine if the report is increasing or decreasing
      increasing = current > previous;
    else;         // After the second value, we check if the report keeps increasing or decreasing
      if increasing <> (current > previous); // If the current value doesn't conform to the report direction, the report is unsafe
        return *off;
      endif;
    endif;
    if not (%abs(current - previous) in %range(1:3)); // If the difference from the previous value is not between 1 and 3, the report is unsafe
      return *off;
    endif;
  endif;

  index += 1;          // Increase the index
  previous = current;  // The current value is stored as the previous value for the next iteration
endfor;

return *on; // If we get here, the report isn't unsafe, therefore it is safe

end-proc;