function automatic_threshold = auto_intensity( input )
% function from FIESTA described in section S.2 of
% https://www.cell.com/biophysj/biophysj/supplemental/S0006-3495(11)00467-X#secd1217733e1776

% convert image to double
input = double( input );
% find edges of objects
automatic_threshold = mean2(input)+std2(input);
% find edges of objects
output = edge(input,'sobel',[],'both','nothinning');
% close small gaps
output = bwmorph(output,'bridge');
% fill one-pixel holes
output = bwmorph( output,'fill');
% fill bigger holes in each object
% l = logical(imcomplement(output),4);
% l_props = regionprops(l,'Area','Image','BoundingBox','PixelIdxList');
% f = find([l_props.Area]<50);
% for n = f
% reg = imcrop(input,l_props(n).BoundingBox-[0 0 1 1]) .*l_props(n).Image;
% if mean2(reg) > automatic_threshold
% output(l_props(i).PixelIdxList) = 1;
% end
% end
% % multiply with low threshold image to rule out very dark areas
% output = output.*(input>automatic_threshold);

figure(7)
imshow(output)

end

