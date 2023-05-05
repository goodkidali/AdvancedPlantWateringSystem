% Ali Saheb - 218791376 - alisaheb@my.yorku.ca
% Major Project - Smart Plant Live Alarm System
while true
clear,clc

a = arduino('COM3','uno','Libraries', 'I2C');
v = readVoltage(a,'A1');
dry = 3.5;
moist = 3.2;
wet = 2.5;

% Read and display voltage reading

disp('Reading moisture sensor voltage...');pause(2)

% While loop so that system is constantly running if water is needed
stop = false;
while ~stop
    
    fprintf('The moisture sensor voltage reading is %.1f. ',v);
    
    if v>=dry
    disp('Therefore plant is dry, requires water.'); pause(1);
    disp('watering...');
    writeDigitalPin(a,'D2',1);writePWMDutyCycle(a,'D5',0.33);...
        pause(10) ; writeDigitalPin(a,'D2',0);writeDigitalPin(a,'D5',0); 
    disp('watering successful!')
    elseif v>=moist && v<dry
    disp('Therefore plant is moist, requires slight amount of water.'); ...
        pause(1);
    disp('slightly watering...');
    writeDigitalPin(a,'D2',1);writePWMDutyCycle(a,'D5',0.33);...
        pause(5) ; writeDigitalPin(a,'D2',0);writeDigitalPin(a,'D5',0); 
    disp('slight watering successful!')
    elseif v<2
    disp('Therefore plant is very wet. Maybe too wet... no water needed.')
    
    else 
    disp('Therefore plant is wet, no water needed.')
    end
    
    % Live graph showing voltage readings
    max_samples = 200;
    figure
    h = animatedline;
    ax = gca;
    ax.YGrid = 'on';
    ax.YLim = [-0.1 5];
    title('Moisture sensor voltage vs time (live)');
    ylabel('Voltage [volt]');
    xlabel('Time [HH:MM:SS]');
    stop = false;
    startTime = datetime('now');
    for i=1:max_samples
    % Read current voltage value
    voltage = readVoltage(a,'A1');
    % Get current time
    t = datetime('now') - startTime;
    % Add points to animation
    addpoints(h,datenum(t),voltage)
    % Update axes
    ax.XLim = datenum([t-seconds(15) t]);
    datetick('x','keeplimits')
    drawnow
    % Check stop condition
    stop = readDigitalPin(a,'D6');
    end
    % end process if there is enough water
    v = readVoltage(a,'A1');
   
    if v<moist
        fprintf('New voltage reading is %.1f. ',v); 
        stop = true;
    end
    
end
pause(3)

clear,clc
a = arduino('COM3','uno','Libraries', 'I2C');
% Mint prefers temperatures between 55 and 70°F (13–21ºC).

cold=13;
pristine=17;
hot=21;

addrs = scanI2CBus(a);
tmp102 = device(a,'I2CAddress',0x3C);

write(tmp102, 0x0, 'uint8');
data = read(tmp102, 2, 'uint8');
temperature = (double(bitshift(int16(data(1)), 4)) + double(bitshift...
    (int16(data(2)), -4))) * 0.0625;
% Covert temperature to degrees celcius
temperature_celsius = (temperature - 32)*5/9; 

fprintf('Current temperature is %.1f degrees celsius. ',temperature_celsius);

if temperature_celsius<=cold
    disp('WARNING: Plant should be moved to warmer conditions!')
    writePWMDutyCycle(a,'D5',0.9); writeDigitalPin(a,'D4',1); pause(1);
    writeDigitalPin(a,'D5',0);writeDigitalPin(a,'D4',0);
    writePWMDutyCycle(a,'D5',0.9); writeDigitalPin(a,'D4',1); pause(1);
    writeDigitalPin(a,'D5',0);writeDigitalPin(a,'D4',0);
    
elseif temperature_celsius<hot && temperature_celsius>cold
    disp('Plant is in PRISTINE temperatures!')
    writeDigitalPin(a,'D13',1); pause(1);writeDigitalPin(a,'D13',0)
    
elseif temperature_celsius>=hot
    
    % it's not as serious for a mint plant to be in warm conditions as it
    % is to be in cold, therefore less of a warning than cold conditions.
    
    disp('Suggestion: Plant should be moved to cooler conditions!')
    writePWMDutyCycle(a,'D5',0.9); writeDigitalPin(a,'D4',1); pause(0.1);
    writeDigitalPin(a,'D5',0);writeDigitalPin(a,'D4',0);
    writePWMDutyCycle(a,'D5',0.9); writeDigitalPin(a,'D4',1); pause(0.1);
    writeDigitalPin(a,'D5',0);writeDigitalPin(a,'D4',0);
    disp('Enabling fan for limited cooling...')
    writeDigitalPin(a,'D7',1);pause(10);writeDigitalPin(a,'D7',0)
    disp('Limited cooling complete!')
    
    % While the fan may not do a very good job changing the temperature of
    % the plant, it is a good addition to cool the plant down in hotter
    % conditions.
    
end
pause(3)

% Mint plants can survive in direct sunlight, however prefer to be in the
% shade.

sunlight = 1.5;
dark = 0.5;

v_light = readVoltage(a,'A2');

fprintf('Light sensor voltage reading is %.2f, ',v_light)

if v_light>=sunlight
    disp('meaning plant is in direct sunlight. Requires more shade.')
    writePWMDutyCycle(a,'D5',0.9); writeDigitalPin(a,'D4',1); pause(0.2);
    writeDigitalPin(a,'D5',0);writeDigitalPin(a,'D4',0);
elseif v_light<=dark
    disp('meaning plant is in dark conditions. Requires more sunlight.')
    writePWMDutyCycle(a,'D5',0.3); writeDigitalPin(a,'D4',1); pause(0.4);
    writeDigitalPin(a,'D5',0);writeDigitalPin(a,'D4',0);
else
    disp('meaning plant is in a well shaded area! No action required.')
    writeDigitalPin(a,'D13',1); pause(1);writeDigitalPin(a,'D13',0)
end
pause(5)
clc

disp('System Reboot...');pause(1)

end
