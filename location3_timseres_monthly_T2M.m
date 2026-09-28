clc; clear; close all;

%% 1. إعداد البيانات (ملف T2M الشهري)
file_t2m = 'Monthly_T2M_Data.nc'; 
info = ncinfo(file_t2m);
all_vars = {info.Variables.Name};
if any(strcmp(all_vars, 'longitude')), lon_name = 'longitude'; else, lon_name = 'lon'; end
if any(strcmp(all_vars, 'latitude')),  lat_name = 'latitude';  else, lat_name = 'lat'; end

lon = ncread(file_t2m, lon_name);
lat = ncread(file_t2m, lat_name);
t2m_raw = ncread(file_t2m, 't2m');

if mean(t2m_raw(:), 'omitnan') > 200
    t2m_raw = t2m_raw - 273.15;
end

%% 2. تحديد المواقع الجغرافية والألوان
% المواقع ثابتة كما هي في الكود الأصلي
target_coords = [34.65, 27.15; 38.4, 20.7; 42.95, 13.25];
location_labels = {'North Red Sea', 'Central Red Sea', 'South Red Sea'};

% ألوان متباينة للتمييز بين المناطق على الخلفية البيضاء
colors = [0, 0.4470, 0.7410;      % أزرق (شمال)
          0.8500, 0.3250, 0.0980;   % برتقالي (وسط)
          0.4660, 0.6740, 0.1880];  % أخضر (جنوب)

%% 3. معالجة محور الوقت (بيانات شهرية)
num_months = size(t2m_raw, 3); 
time_vec = datetime(2023, 1, 1) + calmonths(0:num_months-1); 

%% 4. الرسم البياني المدمج (Single Plot)
figure('Color','w','Units','pixels','Position', [100 100 950 550]);
hold on;

for i = 1:3
    [~, lon_idx] = min(abs(double(lon) - target_coords(i,1)));
    [~, lat_idx] = min(abs(double(lat) - target_coords(i,2)));
    data_series = squeeze(t2m_raw(lon_idx, lat_idx, :));
    
    % رسم الخطوط مع نقاط دائرية
    plot(time_vec, data_series, '-o', 'LineWidth', 1.8, 'MarkerSize', 5, ...
        'Color', colors(i,:), 'MarkerFaceColor', colors(i,:), ...
        'DisplayName', location_labels{i});
end

% --- تنسيق المحاور والجماليات ---
ax = gca;
set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'Box', 'on', 'TickDir', 'in');
grid on;
ax.GridLineStyle = ':';
ax.GridAlpha = 0.3;

% العناوين (نص أسود عريض)
title('Monthly Air Temperature at 2m (t2m) - Red Sea Regions', ...
    'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
ylabel('Temperature [°C]', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
xlabel('Time (Months)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');

% تنسيق الوقت على محور X
xlim([time_vec(1) time_vec(end)]);
xtickformat('MMM yyyy');

% --- إضافة مفتاح الرسم (Legend) وتنسيقه بخلفية بيضاء ونص أسود ---
lgd = legend('Location', 'northeastoutside');
set(lgd, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', 'k', 'FontSize', 10);

hold off;