function wt_package_distribution
% WT_PACKAGE_DISTRIBUTION
% Packages the WhiskerTracker software in a zip file for distribution.
%
%  - depends on Linux environment to run
%  - zip file 
%  - include build number in package name
%  - exclude .asv, .mbk and .mat files
%  - exclude .svn directories
%  - exclude ./bin/src directory

sBuild = wt_get_build_number;
sArchName = ['whiskertracker_build_' sBuild '.zip'];

sPath = which('wt');
sPath = sPath(1:end-19);
cd(sPath)

sCommand = ['zip -rb' sPath ' -n .asv:.mbk:.mat:.svn:.svn-base ' sArchName ' -x \*.svn']

% initial compress without .svn directories
sCmd = ['zip -r ' sArchName ' ./whiskertracker/'];
system(sCmd)

% delete .asv files
sCmd = ['zip -d ' sArchName ' \*.asv']
system(sCmd)

% delete .mat files
sCmd = ['zip -d ' sArchName ' \*.mat']
system(sCmd)

% delete .mbk files
sCmd = ['zip -d ' sArchName ' \*.mbk']
system(sCmd)

% delete .svn directories
sCmd = ['zip -d ' sArchName ' \*.svn\*']
system(sCmd)

% delete src directory
sCmd = ['zip -d ' sArchName ' \*src\*']
system(sCmd)

% delete wiki directory
sCmd = ['zip -d ' sArchName ' \*wiki\*']
system(sCmd)

% delete movies directory
sCmd = ['zip -d ' sArchName ' \*movies\*']
system(sCmd)

% delete .m~ files
sCmd = ['zip -d ' sArchName ' \*.m~']
system(sCmd)

% zip demo movies
sCmd = ['zip -r9 demo_anesthetized.zip ./whiskertracker/movies/demo_anesthetized.avi'];
system(sCmd)
sCmd = ['zip -r9 demo_freely_moving.zip ./whiskertracker/movies/demo_freely_moving.avi'];
system(sCmd)

