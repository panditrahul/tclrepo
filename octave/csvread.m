function csvfile = csvread (csv) 

    data = strrep(
                    textread(
                                 csv          % File name within current working directory
                                ,'%s'               % Each row is a single string
                                ,'delimiter', '\n'  % Each new row is delimited by the newline character
                                ,'headerlines', 1   % Skip importing the first n rows
                            )
                    ,'"'
                    ,''
                );

    for i = 1:length(data)
        delimpos = findstr(data{i}, ",");

        start = 1;
        for j = 1:length(delimpos) + 1,

            if j < length(delimpos) + 1,
                csvfile{i,j} = data{i}(start:delimpos(j) - 1);
                start = delimpos(j) + 1;
            else
                csvfile{i,j} = data{i}(start:end);
            end

        end
    end
end
