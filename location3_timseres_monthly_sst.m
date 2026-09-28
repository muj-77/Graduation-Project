clc; clear; close all;

%% 1. إعداد البيانات (الملف الشهري لـ SST)
file_sst = 'Monthly_SST_Data.nc'; 
info = ncinfo(file_sst);
all_vars = {info.Variables.Name};
if any(strcmp(all_vars, 'longitude')), lon_name = 'longitude'; else, lon_name = 'lon'; end
if any(strcmp(all_vars, 'latitude')),  lat_name = 'latitude';  else, lat_name = 'lat'; end
if any(strcmp(all_vars, 'sst')), var_name = 'sst'; else, var_name = 'SST'; end

lon = ncread(file_sst, lon_name);
lat = ncread(file_sst, lat_name);
sst_raw = ncread(file_sst, var_name);

if mean(sst_raw(:), 'omitnan') > 200
    sst_raw = sst_raw - 273.15;
end

%% 2. تحديد المواقع الجغرافية والألوان
target_coords = [34.65, 27.15; 38.4, 20.7; 42.95, 13.25];
location_labels = {'North Red Sea', 'Central Red Sea', 'South Red Sea'};

% اختيار ألوان متميزة للخطوط
colors = [0, 0.4470, 0.7410;      % أزرق للشمال
          0.8500, 0.3250, 0.0980;   % برتقالي للوسط
          0.4660, 0.6740, 0.1880];  % أخضر للجنوب

%% 3. معالجة محور الوقت (شهري)
num_months = size(sst_raw, 3); 
time_vec = datetime(2023, 1, 1) + calmonths(0:num_months-1); 

%% 4. الرسم البياني الموحد (Combined Plot)
figure('Color','w','Units','pixels','Position', [100 100 900 550]);
hold on;

for i = 1:3
    [~, lon_idx] = min(abs(double(lon) - target_coords(i,1)));
    [~, lat_idx] = min(abs(double(lat) - target_coords(i,2)));
    data_series = squeeze(sst_raw(lon_idx, lat_idx, :));
    
    % رسم الخط مع نقاط دائرية لكل موقع
    plot(time_vec, data_series, '-o', 'LineWidth', 1.8, 'MarkerSize', 5, ...
        'Color', colors(i,:), 'MarkerFaceColor', colors(i,:), ...
        'DisplayName', location_labels{i});
end

% تنسيق المحاور والخلفية
ax = gca;
set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'Box', 'on', 'TickDir', 'in');
grid on;
ax.GridLineStyle = ':';
ax.GridAlpha = 0.3;

% العناوين (باللون الأسود)
title('Monthly Sea Surface Temperature (SST) - Red Sea Regions', ...
    'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
ylabel('SST [°C]', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
xlabel('Time (Months)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');

% تنسيق التاريخ على محور X
xlim([time_vec(1) time_vec(end)]);
xtickformat('MMM yyyy');

% إضافة مفتاح الرسم وتنسيقه بخلفية بيضاء
lgd = legend('Location', 'northeastoutside');
set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', 'k', 'FontSize', 10);

hold off;