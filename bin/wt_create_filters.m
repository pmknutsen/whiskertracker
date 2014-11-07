%%%% WT_CREATE_FILTERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create a filter for each angle for checking "whiskeriness"

function filters_vec = wt_create_filters(whisker_width,whisker_length)

flt = zeros(whisker_length);
start_ind = ceil(whisker_length/2)-floor(3*whisker_width/2);
flt(start_ind:start_ind+3*whisker_width-1,:) = ...
   [0.5 * ones(whisker_width,whisker_length);        ...
       -ones(whisker_width,whisker_length);             ...
       0.5 * ones(whisker_width,whisker_length)]        ...
      /whisker_width/ whisker_length; 

min_ang = -90;
max_ang = 90;

for ang=min_ang:max_ang
  
  filters_vec(:,:,ang-min_ang+1) = imrotate(flt,-ang,'bicubic','crop');  
  
end
  