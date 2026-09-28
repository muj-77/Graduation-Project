clc; clear; close all;

%% 1. إعداد البيانات (ملف SST للبحر الأحمر)
file_sst = 'Daily_SST_Data.nc'; 
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

%% 2. تحديد المواقع الجغرافية
target_coords = [34.65, 27.15; 38.4, 20.7; 42.95, 13.25];
location_labels = {'North Red Sea', 'Central Red Sea', 'South Red Sea'};

% ألوان واضحة للخطوط على الخلفية البيضاء
colors = [0, 0.4470, 0.7410;      % أزرق
          0.8500, 0.3250, 0.0980;   % برتقالي
          0.4660, 0.6740, 0.1880];  % أخضر

%% 3. معالجة محور الوقت
num_days = size(sst_raw, 3); 
time_vec = datetime(2023,1,1) + days(0:num_days-1); 

%% 4. الرسم البياني الموحد بخلفية بيضاء
figure('Color','w','Units','pixels','Position', [100 100 1100 420]);
hold on;

for i = 1:3
    [~, lon_idx] = min(abs(double(lon) - target_coords(i,1)));
    [~, lat_idx] = min(abs(double(lat) - target_coords(i,2)));
    data_series = squeeze(sst_raw(lon_idx, lat_idx, :));
    
    plot(time_vec, data_series, 'LineWidth', 1.5, 'Color', colors(i,:), 'DisplayName', location_labels{i});
end

% --- تنسيق منطقة الرسم (تغيير اللون الأسود إلى أبيض) ---
ax = gca;
set(ax, 'Color', 'w');        % جعل خلفية الرسم بيضاء
set(ax, 'XColor', 'k');       % جعل محور X أسود
set(ax, 'YColor', 'k');       % جعل محور Y أسود
grid on;
ax.GridLineStyle = ':';
ax.GridAlpha = 0.2;           % شفافية الشبكة لتبدو هادئة
ax.Box = 'on';
ax.TickDir = 'in';

% العناوين
title('Daily Sea Surface Temperature (SST) - Red Sea Regions', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
ylabel('SST [°C]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
xlabel('Date (Daily)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');

xlim([time_vec(1) time_vec(end)]);
xtickformat('MMM');

% --- تنسيق المربع الصغير (Legend) ---
lgd = legend('Location', 'northeastoutside');
set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', 'k'); % خلفية بيضاء، نص أسود، إطار أسود

hold off;