% ExportToExcel(cHeaders, cData)
% by Naama Rubin
function ExportToExcel(cHeaders, cData)

% Open new instance of Excel
Excel = actxserver('Excel.Application');
set(Excel, 'Visible', 1);

% Create new workbook
Workbooks = Excel.Workbooks;
Workbook = invoke(Workbooks, 'Add');
Sheets = Excel.ActiveWorkBook.Sheets;

% Sheet columns
cCols = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'};

% Make the 1st sheet active
invoke(get(Sheets, 'Item', 1), 'Activate');
Activesheet = Excel.Activesheet;

% Iterate over cells that contain data
for c = 1:length(cHeaders)
    % Insert header
    Range = get(Activesheet, 'Range', sprintf('%s1', cCols{c}), sprintf('%s1', cCols{c}));
    set(Range, 'Value', cHeaders{c})
    % Insert data
    nLastRow = length(cData{c});
    Range = get(Activesheet, 'Range', sprintf('%s2', cCols{c}), sprintf('%s%d', cCols{c}, nLastRow));
    set(Range, 'Value', cData{c})
    % Remove NaN's in data
    vNaNIndx = find(isnan(cData{c}));
    for i = 1:length(vNaNIndx)
        Range = get(Activesheet, 'Range', sprintf('%s%d', cCols{c}, vNaNIndx(i)+1), sprintf('%s%d', cCols{c}, vNaNIndx(i)+1));
        set(Range, 'Value', '')
    end
end

return;
