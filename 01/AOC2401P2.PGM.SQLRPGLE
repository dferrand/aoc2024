**free

// One parameter: the path to the input file
dcl-pi *n;
  input char(50);
end-pi;  

dcl-s fileName varchar(50); // ifs_read_utf8 doesn't like trailing spaces in the file name, so we use a VARCHAR to get rid of them
dcl-s sim int(20) inz(0);   // Will contain the similarity score

fileName = %trim(input);

// We use SELECT INTO since we're reading a single value
exec sql select sum(integer(substring(a.line, 1, 5)) * (select
  count(*) from table(qsys2.ifs_read_utf8(path_name => :fileName)) b
  where substring(b.line, 9, 5) = substring(a.line, 1, 5))) into :sim 
  from table(qsys2.ifs_read_utf8(path_name => :fileName)) a;

// Give the answer to the user
snd-msg *info 'Similarity score is '+%char(sim) %target(*pgmbdy:1);

*inlr = *on;
return;
