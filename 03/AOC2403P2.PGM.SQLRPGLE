**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-pr processLine;
  line varchar(32000);
end-pr;

dcl-s fileName varchar(50);

dcl-s line varchar(32000);
dcl-s result int(10) inz(0);
dcl-s inDo ind inz(*on);

fileName = %trim(input);

// Read the input data from the IFS one line at a time
exec sql declare c1 cursor for select cast(line as varchar(32000)) from table(qsys2.ifs_read_utf8(path_name => :fileName));

exec sql open c1;

// Read first line
exec sql fetch from c1 into :line;

// Loop until the end of the file
dow sqlcode = 0;

  processLine(line);

  // Read next line
  exec sql fetch from c1 into :line;
enddo;

exec sql close c1;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;

dcl-proc processLine;

dcl-pi *n;
  line varchar(32000);
end-pi;

dcl-s val1 int(10);         // First operand
dcl-s val2 int(10);         // Second operand
dcl-s pos int(10) inz(1);   // currentPosition
dcl-s nextPosition int(10); // next position

// search for the first do(), don't() or mul(xxx,xxx)
exec sql select regexp_instr(:line, 'mul\((\d{1,3}),(\d{1,3})\)|do\(\)|don''t\(\)', :pos) into :nextPosition from sysibm.sysdummy1;

dow nextPosition > 0;

  select %subst(line: nextPosition: 3);
    when-is 'do('; // If we found a do(), we set inDo to *on
      inDo = *on;
    when-is 'don'; // If we found a don't(), we set inDo to *off
      inDo = *off;
    when-is 'mul'; // If we found a mul() we process the multiplication only if inDo is set to *on
      if inDo;
        exec sql select int(regexp_substr(:line, 'mul\((\d{1,3}),(\d{1,3})\)', :nextPosition, 1, 'c', 1)) into :val1 from sysibm.sysdummy1;
        exec sql select int(regexp_substr(:line, 'mul\((\d{1,3}),(\d{1,3})\)', :nextPosition, 1, 'c', 2)) into :val2 from sysibm.sysdummy1;

        result += val1 * val2;
      endif;
  endsl;
  pos = nextPosition + 1;
// search for the next do(), don't() or mul(xxx,xxx)
exec sql select regexp_instr(:line, 'mul\((\d{1,3}),(\d{1,3})\)|do\(\)|don''t\(\)', :pos) into :nextPosition from sysibm.sysdummy1;
enddo;

end-proc;