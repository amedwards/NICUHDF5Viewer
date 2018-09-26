function removefromresultsfile2(filename,tagcategoryname,tagcategorynum,tagnumber)
    % This removes a particular tag from a results file
    %
    % filename: the input file name with .hdf5 extension
    % tagcategoryname: the name of the tag category from which the tag needs to be removed
    % tagcategorynum: what number (in the tag category box) is the tag category
    % tagnumber: in the tag box, which tag number needs to be removed?
    %
    % Load the Results File:
    resultfilename = strrep(filename,'.hdf5','_results.mat');
    load(resultfilename,'result_name','result_data','result_tags','result_tagcolumns','result_tagtitle');
    
    index = find(strcmp(result_name, tagcategoryname));
    result_tags(tagcategorynum).tagtable(tagnumber,:) = [];
    result_data(index).data = zeros(size(result_data(index).data));
    for t=1:length(result_tags(tagcategorynum).tagtable)
        [~,startindex] = min(abs(result_data(index).time-result_tags(tagcategorynum).tagtable(t,1)));
        [~,endindex] = min(abs(result_data(index).time-result_tags(tagcategorynum).tagtable(t,2)));
        result_data(index).data(startindex:endindex) = ones(endindex-startindex+1,1);
    end
    save(resultfilename,'result_data','result_name','result_tags','result_tagcolumns','result_tagtitle');
end