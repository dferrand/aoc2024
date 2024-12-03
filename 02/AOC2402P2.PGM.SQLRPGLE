**free
ctl-opt dftactgrp(*no);

dcl-pi *n;
  input char(50);
end-pi;

dcl-pr isSafe ind;
  data varchar(255);
  skip int(10) value;
end-pr;

dcl-s fileName varchar(50);

dcl-s data varchar(255);
dcl-s safeReports int(10) inz(0);

fileName = %trim(input);

exec sql declare c1 cursor for select cast(line as varchar(255)) from table(qsys2.ifs_read_utf8(path_name => :fileName));

exec sql open c1;

exec sql fetch from c1 into :data;

dow sqlcode = 0;

  if isSafe(data:0);
    safeReports += 1;
  endif;

  exec sql fetch from c1 into :data;
enddo;

exec sql close c1;

snd-msg *info 'Safe reports: ' + %char(safeReports) %target(*pgmbdy:1);

*inlr = *on;
return;

dcl-proc isSafe;

dcl-pi *n ind;
  data varchar(255);
  skip int(10) value;  // if skip is 0, there is no skip. If skip > 0, this is the index to skip. Passed by value for ease of calling
end-pi;

dcl-s value char(5);
dcl-s previous int(10);
dcl-s current int(10);
dcl-s index int(10) inz(1);
dcl-s realIndex int(10) inz(1); // This is the real index that doesn't take skipping into account
dcl-s increasing ind;

for-each value in %split(data);
  if realIndex <> skip;             // If the current index is the one to be skipped, then we skip
  current = %int(value);

  if index > 1;
    if index = 2;
      increasing = current > previous;
    else;
      if increasing <> (current > previous);
        if skip > 0;                 // If we are already skipping and still have a bad level, the report is unsafe since the Problem Dampener can only tolerate one bad level
          return *off;
        else;
          if index = 3;              // The 3rd value is a special case, the bad level can be fixed by removing the first, second or third value
            return isSafe(data:3) or isSafe(data:2) or isSafe(data:1);
          else;                      // After the third value, the direction can only be fixed by removing the current value
            return isSafe(data:index);
          endif;
        endif;
      endif;
    endif;
    if not (%abs(current - previous) in %range(1:3));
      if skip >0;         // If we are already skipping and still have a bad level, the report is unsafe since the Problem Dampener can only tolerate one bad level
        return *off;
      else;               // We try to fix the report by removing the current or the previous value
        return isSafe(data:index) or isSafe(data:index-1);
      endif;
    endif;
  endif;

  index += 1;
  previous = current;
  endif;
  realIndex += 1;   // realIndex is incremented even if we are skipping this value
endfor;

return *on;

end-proc;