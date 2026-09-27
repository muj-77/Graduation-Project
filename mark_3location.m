%% 1. تعريف الملف والمواقع
filename = 'gebco_2025_tid_n30.0_s10.0_w30.0_e45.0.nc';

% إحداثيات المواقع المطلوبة
lon_targets = [34.65, 38.4, 42.95];
lat_targets = [27.15, 20.7, 13.25];

%% 2. قراءة البيانات
lon = ncread(filename, 'lon');
lat = ncread(filename, 'lat');
tid_data = ncread(filename, 'tid');

%% 3. رسم الخريطة والألوان
figure('Color', 'w'); % جعل خلفية النافذة بيضاء
hold on;

% رسم البيانات
imagesc(lon, lat, tid_data'); 
set(gca, 'YDir', 'normal');

% إعداد الألوان: رصاصي لليابسة وأزرق للبحر
custom_map = [0.85 0.85 0.85; repmat([0 0.3 0.6], 255, 1)];
colormap(custom_map);

%% 4. تعديل خصائص المحاور (الأرقام والأسود)
ax = gca;
ax.XColor = 'k'; % لون أرقام خط الطول أسود
ax.YColor = 'k'; % لون أرقام خط العرض أسود
ax.FontSize = 11; % تكبير الخط قليلاً ليكون واضحاً
ax.FontWeight = 'bold';

%% 5. رسم المواقع والنصوص
plot(lon_targets, lat_targets, 'yo', 'MarkerSize', 12, ...
    'MarkerFaceColor', 'y', 'LineWidth', 1.5, 'MarkerEdgeColor', 'k');

% إضافة أسماء المواقع
labels = {' North Red Sea ', ' Central Red Sea ', ' South Red Sea '};
for i = 1:length(lon_targets)
    text(lon_targets(i), lat_targets(i), labels{i}, ...
        'Color', 'k', ... % نص أسود
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'VerticalAlignment', 'middle', ...
        'HorizontalAlignment', 'left');
end

%% 6. العناوين وتسمية المحاور (باللون الأسود)
xlabel('Longitude (East)', 'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Latitude (North)', 'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
title('Target Locations in the Red Sea', 'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold');

% ضبط الحدود لتكون محصورة على البحر الأحمر
axis([32 45 12 30]); 

grid on;
ax.GridColor = [0.5 0.5 0.5]; % لون الشبكة رصاصي غامق لتظهر بوضوح
ax.GridAlpha = 0.3;

hold off;