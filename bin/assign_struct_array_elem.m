function struct_array = assign_struct_array_elem(struct_array,index,struct_element)
% Assign struct-array(index) with struct_element 
% SA(i) = "merge"(SA(i),S)
% Syntax: o_struct_array = assign_struct_array_elem(struct_array,index,struct_element)

if isempty(struct_element)
    return;
end

field_names = fieldnames(struct_element);

for n = 1:length(field_names)
    struct_array(index).(field_names{n}) = struct_element.(field_names{n});
end
