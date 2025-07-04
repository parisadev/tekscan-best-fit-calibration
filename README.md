# tekscan-best-fit-calibration
This MATLAB script is designed to calibrate Tekscan force data based on real force measurements obtained from a testing machine.
Key Features
  Prompts the user to select an Excel file containing:
  
    Column 1: Raw Tekscan output
    
    Column 2: Corresponding real force data from the testing machine
  
  Allows the user to specify the number of calibration points
  
  Automatically selects the best calibration points from the dataset in evenly distributed
  
  Evaluates and compares multiple fitting functions to find the best calibration model, including:
  
        Linear
        
        Quadratic
        
        Cubic
        
        4th-degree Polynomial
        
        Exponential
        
        Logarithmic
        
        Power
        
        Sinusoidal
        
        Cosinusoidal

