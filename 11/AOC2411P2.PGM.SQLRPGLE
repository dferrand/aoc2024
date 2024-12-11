**free
ctl-opt dftactgrp(*no);  // We're using procedure so we can't be in the default activation group

dcl-pi *n;
  input char(50);
end-pi;

dcl-pr addState;
  stone uns(20) value;
  count uns(20) value;
end-pr;

dcl-s fileName varchar(50);
dcl-s data char(255);
dcl-s value char(255);
dcl-s result uns(20) inz(0);
dcl-s stone uns(20);

dcl-ds state qualified;
  stone uns(20);
  count uns(20);
end-ds;

dcl-ds currentState likeds(state) dim(*auto:1000000);
dcl-ds newState likeds(state) dim(*auto:1000000);

dcl-s i int(5);

fileName = %trim(input);

// Read the input data from the IFS
exec sql select line into :data from table(qsys2.ifs_read_utf8(path_name => :fileName));

// Load current State from input data
for-each value in %split(data);
  state.stone = %int(value);
  state.count = 1;
  currentState(*next) = state;
endfor;

for i = 1 to 75;
  for-each state in currentState;
    if state.stone = 0;
      addState(1:state.count);
      else;
      if %rem(%len(%char(state.stone)):2) = 0;
        addState(%int(%subst(%char(state.stone):1:%div(%len(%char(state.stone)):2))):state.count);
        addState(%int(%subst(%char(state.stone):%div(%len(%char(state.stone)):2)+1)):state.count);
      else;
        addState(state.stone*2024:state.count);
      endif;
    endif;
  endfor;
  %elem(currentState) = %elem(newState);
  currentState = newState;
  %elem(newState) = 0;
endfor;

for-each state in currentState;
  result += state.count;
endfor;

snd-msg *info 'Result: ' + %char(result) %target(*pgmbdy:1); // Send message with answer

*inlr = *on;
return;

dcl-proc addState;

dcl-pi *n;
  stone uns(20) value;
  count uns(20) value;
end-pi;

dcl-ds wState likeds(state);
dcl-s i int(10);

i = %lookup(stone:newState(*).stone);
if i = 0;
  wState.stone = stone;
  wState.count = count;
  newState(*next) = wState;
else;
  newState(i).count += count;
endif;

end-proc;