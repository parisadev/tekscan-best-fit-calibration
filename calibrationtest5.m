% MATLAB Script to Calibrate Tekscan Force Based on Zwick Force
% User Specifies Number of Calibration Points, and Script Selects the Best Points

% Prompt the user to select the Excel file

[fileName, filePath] = uigetfile('*.xlsx', 'Select the Excel file containing Tekscan and Zwick data');
if isequal(fileName, 0)
    error('No file selected. Please run the script again and select a file.');
end
fullFileName = fullfile(filePath, fileName);

% Read data from Excel file
data = xlsread(fullFileName);
if size(data, 2) < 2
    error('The selected Excel file must contain at least two columns: Tekscan and Zwick data.');
end
tekscanForce = data(:, 1); % Column 1: Tekscan force
RealForce = data(:, 2);   % Column 2: Zwick force

% Ask user to input the number of calibration points
numTotalPoints = length(tekscanForce);
fprintf('Total available data points: %d\n', numTotalPoints);
numCalibrationPoints = input('Enter the number of calibration points to use: ');

if numCalibrationPoints <= 1 || numCalibrationPoints > numTotalPoints
    error('Invalid number of calibration points. Must be between 2 and %d.', numTotalPoints);
end

% Automatically select the best calibration points
% Selecting points to cover the range of Tekscan data uniformly
[~, sortedIndices] = sort(tekscanForce); % Sort data by Tekscan force
selectedIndices = round(linspace(1, numTotalPoints, numCalibrationPoints));
selectedPoints = sortedIndices(selectedIndices);

x = tekscanForce(selectedPoints); % Independent variable (Tekscan)
y = zwickForce(selectedPoints);   % Dependent variable (Zwick)

% Define models to test
models = {
    'Linear', @(p, x) p(1) * x + p(2), [1, 1];  % Linear: y = m*x + b
    'Quadratic', @(p, x) p(1)*x.^2 + p(2)*x + p(3), [1, 1, 1];  % Quadratic: y = ax^2 + bx + c
    'Cubic', @(p, x) p(1)*x.^3 + p(2)*x.^2 + p(3)*x + p(4), [1, 1, 1, 1];  % Cubic: y = ax^3 + bx^2 + cx + d
    '4th Degree Polynomial', @(p, x) p(1)*x.^4 + p(2)*x.^3 + p(3)*x.^2 + p(4)*x + p(5), [1, 1, 1, 1, 1];  % 4th Degree Polynomial
    'Exponential', @(p, x) p(1) * exp(p(2) * x), [1, 0.001];  % Exponential: y = a*exp(b*x)
    'Logarithmic', @(p, x) p(1) * log(x) + p(2), [1, 1];  % Logarithmic: y = a*log(x) + b
    'Power', @(p, x) p(1) * x.^p(2), [1, 1];  % Power: y = a*x^b
    'Sinusoidal', @(p, x) p(1) * sin(p(2) * x + p(3)) + p(4), [1, 1, 1, 1];  % Sinusoidal: y = a*sin(b*x + c) + d
    'Cosinusoidal', @(p, x) p(1) * cos(p(2) * x + p(3)) + p(4), [1, 1, 1, 1];  % Cosinusoidal: y = a*cos(b*x + c) + d
};

% Initialize variables to store best fit results
bestModel = '';
bestParams = [];
bestRsq = -inf;
bestRMSE = inf;

% Iterate through models
fprintf('Testing models...\n');
for i = 1:size(models, 1)
    % Get current model details
    modelName = models{i, 1};
    modelFunc = models{i, 2};
    initialParams = models{i, 3};
    
    % Fit the model using nonlinear least squares
    try
        params = nlinfit(x, y, modelFunc, initialParams);
    catch
        fprintf('Failed to fit %s model. Skipping...\n', modelName);
        continue;
    end
    
    % Predict values using the fitted parameters
    yPred = modelFunc(params, x);
    
    % Calculate R-squared
    SS_res = sum((y - yPred).^2);
    SS_tot = sum((y - mean(y)).^2);
    R_squared = 1 - (SS_res / SS_tot);
    
    % Calculate RMSE
    RMSE = sqrt(mean((y - yPred).^2));
    
    % Display results
    fprintf('%s Model: R^2 = %.4f, RMSE = %.4f\n', modelName, R_squared, RMSE);
    
    % Update best model if this one is better
    if R_squared > bestRsq
        bestRsq = R_squared;
        bestRMSE = RMSE;
        bestModel = modelName;
        bestParams = params;
    end
end

% Output best model
fprintf('\nNumber of data points used: %d\n', numCalibrationPoints);
fprintf('Best Model: %s\n', bestModel);
fprintf('Best Parameters: %s\n', mat2str(bestParams));
fprintf('R^2: %.4f, RMSE: %.4f\n', bestRsq, bestRMSE);

% Optional: Plot the best fit
if ~isempty(bestModel)
    figure;
    scatter(tekscanForce, zwickForce, 'b', 'filled'); hold on;
    scatter(x, y, 'g', 'filled', 'MarkerEdgeColor', 'k'); % Highlight selected points
    bestFitFunc = models{strcmp(models(:, 1), bestModel), 2};
    yBestFit = bestFitFunc(bestParams, tekscanForce);
    plot(tekscanForce, yBestFit, 'r-', 'LineWidth', 2);
    title(['Best Fit: ', bestModel]);
    xlabel('Tekscan Force');
    ylabel('Zwick Force');
    legend('All Data', 'Selected Points', 'Best Fit');
    grid on;
end

% Calculate RMSE for all data using the best model
if ~isempty(bestModel)
    bestFitFunc = models{strcmp(models(:, 1), bestModel), 2};
    yPredAll = bestFitFunc(bestParams, tekscanForce); % Predict values for all data
    RMSEAll = sqrt(mean((zwickForce - yPredAll).^2)); % RMSE for all data
    
    fprintf('RMSE for all data (using best model): %.4f\n', RMSEAll);
    
end