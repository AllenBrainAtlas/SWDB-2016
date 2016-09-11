
%% Notebook with self test script for xml_io_tools Package
% Created as part of package testing.
%% 

%% Test reading/writing data structures without attributes
% *Create data structure without attributes*
tree=[];
tree.Double = -3.14e2;
tree.Complex = 1.23+i*3.21;
tree.Empty  = [];
tree.RowVec = -2:0.8:3;
tree.ColVec = [6;7;8];
tree.Matrix = [1 2 3; 4 5 6; 7 8 9];
tree.Sparse = sparse(2,3,-5);
tree.Character = 'Q';
tree.String = 'Single String';
tree.StringCellArray = {'Jack', ' Jill ', '', 'XML Chars: <&> ', 'Special Chars: !$^*()_+=-@#{}[];:,./\?''"'};
tree.CharArray = [' Jack'; 'Jill '; '<&''">'];
tree.Boolean = (1==2);
tree.Struct.Parent.Child1 = 1;
tree.Struct.Parent.Child2 = 2;
tree.EmptyStruct = struct([]);
tree.StructArray(1).CellArray = {'John', 3.14, 0:0.11:1, [], '', {'cell', 1, 'of cells'}};
tree.StructArray(2).CellArray = {1:5, 'Jack', sparse(eye(3)), 1+sqrt(-(5:7)), {}};
fprintf('Original Structure:\n');
xml_gen_object_display(tree) % function by Ohad Gal with some minor corrections

%%
% *Write it to the XML file and display the file*
xml_write('test1.xml', tree, 'test');
fprintf('File Produced:\n');
disp(textread('test1.xml','%s','delimiter','\n','whitespace',''))

%%
% * *Read XML file* 
% * *Write it again*
% * *Make sure both files are the identical*
tree2 = xml_read ('test1.xml');
xml_write('test2.xml', tree2, 'test');
t1=textread('test1.xml','%s');
t2=textread('test2.xml','%s');
if (length(t1)==length(t2) && all(strcmp(t1,t2)))
  fprintf('Files test1.xml and test2.xml are identical\n');
else
  fprintf('Files test1.xml and test2.xml are different\n');
  return
end



%% Test reading/writing data structures with attributes
% *Create data structure with attributes*
tree=[];
tree.Double.CONTENT = -3.14e2;
tree.Double.ATTRIBUTE.Unit = 'cm';
tree.Complex.CONTENT = 1.23+i*3.21;
tree.Complex.ATTRIBUTE.Comment = 'Complex Number';
tree.Empty.ATTRIBUTE.Comment = 'Empty';
tree.Array.CONTENT  = -2:0.8:3;
tree.Array.ATTRIBUTE.Length  = length(tree.Array.CONTENT);
tree.Array.ATTRIBUTE.Comment = 'Array of Doubles';
tree.Matrix.CONTENT = [1 2 3; 4 5 6; 7 8 9];
tree.Matrix.ATTRIBUTE.Size  = size(tree.Matrix.CONTENT);
tree.Sparse.CONTENT = sparse(2,3,-5);
tree.Sparse.ATTRIBUTE.Size  = size(tree.Sparse.CONTENT);
tree.Character.CONTENT = 'Q';
tree.Character.ATTRIBUTE.Comment = 'Single Character';
tree.String.CONTENT = 'Clothes make the man. Naked people have little or no influence on society';
tree.String.ATTRIBUTE.QuoteBy = 'Mark Twain';
tree.StringCellArray.CONTENT = {'Jack', ' Jill ', '', 'XML Chars: <&> ', 'Special Chars: !$^*()_+=-@#{}[];:,./\?''"'};
tree.StringCellArray.ATTRIBUTE.foo = 'foo';
tree.CharArray.CONTENT = [' Jack'; 'Jill '; '<&''">'];
tree.CharArray.ATTRIBUTE.foo = 'foo';
tree.Boolean.CONTENT = (1==2);
tree.Boolean.ATTRIBUTE.means = 'false';
tree.Struct.Parent.Child1 = 1;
tree.Struct.Parent.Child2.CONTENT = 2;
tree.Struct.Parent.Child2.ATTRIBUTE.foo = 'foo';
tree.Struct.Parent.ATTRIBUTE.foo = 'foo';
tree.Struct.ATTRIBUTE.foo = 'foo';
tree.EmptyStruct.CONTENT = struct([]);
tree.EmptyStruct.ATTRIBUTE.foo = 'foo';
tree.StructArray(1).CellArray.CONTENT = {'John', 3.14, 0:0.11:1, [], '', {'cell', 1, 'of cells'}};
tree.StructArray(2).CellArray = {1:5, 'Jack', sparse(eye(3)), 1+sqrt(-(5:7)), {}};
fprintf('Original Structure:\n');
xml_gen_object_display(tree) % function by Ohad Gal with some minor corrections
%%
% *Write it to the XML file and display the file*
xml_write('test1.xml', tree, 'test');
fprintf('File Produced:\n');
disp(textread('test1.xml','%s','delimiter','\n','whitespace',''))
%%
% * *Read XML file* 
% * *Write it again*
% * *Make sure both files are the identical*
tree2=xml_read ('test1.xml');
xml_write('test2.xml', tree2, 'test');
t1=textread('test1.xml','%s');
t2=textread('test2.xml','%s');
if (length(t1)==length(t2) && all(strcmp(t1,t2)))
  fprintf('Files test1.xml and test2.xml are identical\n');
else
  fprintf('Files test1.xml and test2.xml are different\n');
  return
end

%% Another test of reading/writing data structures with attributes
% *Create data struct*
tree = [];
tree.StructArray(1).ATTRIBUTE.Num = 1;
tree.StructArray(1).CellArray.CONTENT = {'John', 3.14};
tree.StructArray(1).CellArray.ATTRIBUTE.foo = 'foo';
tree.StructArray(2).CellArray = {1:5, 'Jack'};
tree.StructArray(2).ATTRIBUTE.Num = 2;
tree.StructArray(3).CONTENT = {'Jim', 123};
tree.StructArray(3).ATTRIBUTE.Num = 3;
fprintf('Original Structure:\n');
xml_gen_object_display(tree) % function by Ohad Gal with some minor corrections
%%
% *Write it to the XML file and display the file*
xml_write('test1.xml', tree, 'test');
fprintf('File Produced:\n');
disp(textread('test1.xml','%s','delimiter','\n','whitespace',''))
%%
% * *Read XML file* 
% * *Write it again*
% * *Make sure both files are the identical*
tree2 = xml_read ('test1.xml');
xml_write('test2.xml', tree2, 'test');
t1=textread('test1.xml','%s');
t2=textread('test2.xml','%s');
if (length(t1)==length(t2) && all(strcmp(t1,t2)))
  fprintf('Files test1.xml and test2.xml are identical\n');
else
  fprintf('Files test1.xml and test2.xml are different\n');
  return
end

%% Show use of ItemName preference parameter in xml_read
% *First use default iterator 'item'*
xmlfile = fullfile(matlabroot, 'toolbox/matlab/general/info.xml');
tree = xml_read(xmlfile);
fprintf('tree.list: [%i struct]\n', length(tree.list));
xml_gen_object_display(tree.list)
%%
% *Then, use ItemName = 'listitem' which matches iterator used in the file* 
Pref = [];
Pref.ItemName = 'listitem';
tree = xml_read(xmlfile, Pref);
fprintf('tree.list: [%i struct]\n', length(tree.list));
xml_gen_object_display(tree.list)



%% Test reading and writing of a large XML file
% *Read in a large Matlab file, and write it out*
% In order to get "nicest" data structure cell arrays were allowed when
% reading. Also in order to get output file in similar format as input,
% preference was set to avoid the 'item' notation.
xmlfile = fullfile(matlabroot, 'help/techdoc/helpindex.xml');
Pref = [];
Pref.Str2Num   = false;   % don't convert strings that look like numbers to numbers
Pref.NoCells   = false;   % allow output to have cell arrays
fprintf('xml_read timing: ');
tic; tree1 = xml_read(xmlfile, Pref); toc;

Pref.StructItem = false;  % do not use item notation with structures
Pref.CellItem   = false;  % do not use item notation with cells
fprintf('xml_write timing: ');
tic; xml_write('test1.xml', tree1, 'index',Pref); toc;
fprintf('tree: \n');
xml_gen_object_display(tree1)
%%
% * *Read test1.xml file, that was just created* 
% * *Compare the new data structures with the original data structure*
tree2 = xml_read ('test1.xml',Pref);
if (length(tree1.indexitem)==length(tree2.indexitem))
  fprintf('tree1.indexitem and tree1.indexitem have the same length\n');
else
  fprintf('tree1.indexitem and tree1.indexitem don''t have the same length\n');
  return
end
%%
% * *Write new data structures to the file*
% * *Make sure both files are the identical*
xml_write('test2.xml', tree2, 'index',Pref);
t1=textread('test1.xml','%s');
t2=textread('test2.xml','%s');
if (all(strcmp(t1,t2)))
  fprintf('Files test1.xml and test2.xml are identical\n');
else
  fprintf('Files test1.xml and test2.xml are different\n');
  return
end

