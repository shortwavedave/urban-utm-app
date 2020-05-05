classdef AgentFaceDetector < handle
    %AGENTFACEDETECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numPts = 0
        faceDetector
        pointTracker
        oldPoints
        bboxPoints
    end
    
    methods
        function obj = AgentFaceDetector()
            %AGENTFACEDETECTOR Construct an instance of this class
            %   Detailed explanation goes here
            % Create the face detector object.
            obj.faceDetector = vision.CascadeObjectDetector();

            % Create the point tracker object.
            obj.pointTracker = vision.PointTracker('MaxBidirectionalError', 2);
        end
        
        function im_out = overlayDetect(obj, im_in)
            % https://www.mathworks.com/help/vision/examples/face-detection-and-tracking-using-live-video-acquisition.html
            videoFrameGray = rgb2gray(im_in);
            im_out = im_in;
            if obj.numPts < 10
                % Detection mode.
                bbox = obj.faceDetector.step(videoFrameGray);

                if ~isempty(bbox)
                    % Find corner points inside the detected region.
                    points = detectMinEigenFeatures(...
                        videoFrameGray, 'ROI', bbox(1, :));

                    % Re-initialize the point tracker.
                    xyPoints = points.Location;
                    obj.numPts = size(xyPoints,1);
                    release(obj.pointTracker);
                    initialize(obj.pointTracker, xyPoints, videoFrameGray);

                    % Save a copy of the points.
                    obj.oldPoints = xyPoints;

                    % Convert the rectangle represented as [x, y, w, h] into an
                    % M-by-2 matrix of [x,y] coordinates of the four corners. This
                    % is needed to be able to transform the bounding box to display
                    % the orientation of the face.
                    obj.bboxPoints = bbox2points(bbox(1, :));

                    % Convert the box corners into the [x1 y1 x2 y2 x3 y3 x4 y4]
                    % format required by insertShape.
                    bboxPolygon = reshape(obj.bboxPoints', 1, []);

                    % Display a bounding box around the detected face.
                    im_out = insertShape(im_in, 'Polygon', ...
                        bboxPolygon, 'LineWidth', 3);

                    % Display detected corners.
                    im_out = insertMarker(im_out, xyPoints, '+', ...
                        'Color', 'white');
                end
            else
                % Tracking mode.
                [xyPoints, isFound] = step(obj.pointTracker, videoFrameGray);
                visiblePoints = xyPoints(isFound, :);
                oldInliers = obj.oldPoints(isFound, :);

                obj.numPts = size(visiblePoints, 1);

                if obj.numPts >= 10
                    % Estimate the geometric transformation between the old points
                    % and the new points.
                    [xform, ~, visiblePoints] = ...
                        estimateGeometricTransform(...
                        oldInliers, visiblePoints, 'similarity', ...
                        'MaxDistance', 4);

                    % Apply the transformation to the bounding box.
                    obj.bboxPoints = transformPointsForward(xform, obj.bboxPoints);

                    % Convert the box corners into the [x1 y1 x2 y2 x3 y3 x4 y4]
                    % format required by insertShape.
                    bboxPolygon = reshape(obj.bboxPoints', 1, []);

                    % Display a bounding box around the face being tracked.
                    im_out = insertShape(im_in, 'Polygon', ...
                        bboxPolygon, 'LineWidth', 3);

                    % Display tracked points.
                    im_out = insertMarker(im_out, visiblePoints, ...
                        '+', 'Color', 'white');

                    % Reset the points.
                    obj.oldPoints = visiblePoints;
                    setPoints(obj.pointTracker, obj.oldPoints);
                else
                    im_out = obj.overlayDetect(im_in);
                end
            

            end 
        end
    end
end

