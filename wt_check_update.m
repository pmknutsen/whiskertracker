function wt_check_update()

% Compare commit SHA hash on disk with latest version online
hWin = msgbox('Checking for a newer version of WhiskerTracker...', 'WhiskerTracker Update');
sResp = urlread('https://api.github.com/repos/pmknutsen/whiskertracker/commits');
[~,~,~,~,cSHA] = regexp(sResp, '[{"sha":"(\w+)"');
sSHA = cell2mat(cSHA{1});
close(hWin)
if strcmp(wt_get_build_number(), sSHA(1:10))
    msgbox('You have the latest version of WhiskerTracker.', 'WhiskerTracker Update')
else
    msgbox(sprintf('A new version of WhiskerTracker is available at:\nhttps://github.com/pmknutsen/whiskertracker'), 'WhiskerTracker Update')
end

return
