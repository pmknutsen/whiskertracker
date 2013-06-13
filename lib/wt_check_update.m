function wt_check_update()
% wt_check_update
% Check online for updates to the Whisker Tracker application

% Compare commit SHA hash on disk with latest version online
hWin = msgbox('Checking for a newer version of this software...', 'Whisker Tracker Update');
sResp = urlread('https://api.github.com/repos/pmknutsen/whiskertracker/commits');
[~,~,~,~,cSHA] = regexp(sResp, '[{"sha":"(\w+)"');
sSHA = cell2mat(cSHA{1});
close(hWin)
if strcmp(wt_get_build_number(), sSHA(1:10))
    msgbox('You have the latest version of this software.', 'Whisker Tracker Update')
else
    msgbox(sprintf('A newer version of Whisker Tracker is available at:\nhttps://github.com/pmknutsen/whiskertracker'), 'Whisker Tracker Update')
end

return
