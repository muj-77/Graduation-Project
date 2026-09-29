%% مشروع التخرج: تحليل السلاسل الزمنية اليومية (Pure Daily SST vs T2M)
clear; clc; close all;

%% 1. إعدادات الملفات اليومية (تأكد من وجود الملفين)
file_sst = 'Daily_SST_Data.nc'; 
file_t2m = 'Daily_T2M_Data.nc'; 

fprintf('Generating Raw Daily Time Series (Pure Vibrations) for 2025...\n');

% قراءة الإحداثيات والبيانات اليومية
lon = double(ncread(file_sst, 'lon'));
lat = double(ncread(file_sst, 'lat'));
sst_raw = double(ncread(file_sst, 'sst'));
t2m_raw = double(ncread(file_t2m, 't2m'));

% تحويل الوحدات إلى مئوية
if mean(sst_raw(:), 'omitnan') > 200, sst_raw = sst_raw - 273.15; end
if mean(t2m_raw(:), 'omitnan') > 200, t2m_raw = t2m_raw - 273.15; end

%% 2. إعداد الوقت والمواقع لعام 2025
target_coords = [34.65, 27.15; 38.4, 20.7; 42.95, 13.25];
location_names = {'North Red Sea', 'Central Red Sea', 'South Red Sea'};
panel_labels = {'a', 'b', 'c'};

% بناء المحور الزمني اليومي لعام 2025 (365 يوم)
time_vec = datetime(2025, 1, 1) + days(0:size(sst_raw, 3)-1);

%% 3. الرسم الاحترافي (خلفية بيضاء - بيانات خام واضحة)
figure('Name', 'Raw Daily Analysis 2025', 'Color', 'w', 'Units', 'pixels', 'Position', [50 50 1450 950]);

fprintf('\n=== Raw Daily Statistics for 2025 ===\n');

for i = 1:3
    % إيجاد أقرب إحداثيات للموقع
    [~, lon_idx] = min(abs(lon - target_coords(i,1)));
    [~, lat_idx] = min(abs(lat - target_coords(i,2)));
    
    % استخراج البيانات اليومية الخام (بدون تنعيم) بناءً على طلبك
    data_sst = squeeze(sst_raw(lon_idx, lat_idx, :));
    data_t2m = squeeze(t2m_raw(lon_idx, lat_idx, :));
    
    % --- الطلب رقم 2: طباعة الإحصائيات في الكوماند ويندو ---
    fprintf('--- Panel (%s): %s ---\n', panel_labels{i}, location_names{i});
    fprintf('   SST -> Max: %.2f | Min: %.2f | Mean: %.2f\n', max(data_sst), min(data_sst), mean(data_sst, 'omitnan'));
    fprintf('   T2M -> Max: %.2f | Min: %.2f | Mean: %.2f\n\n', max(data_t2m), min(data_t2m), mean(data_t2m, 'omitnan'));

    ax = subplot(3,1,i);
    set(ax, 'Color', 'w'); % خلفية بيضاء لبروز الذبذبات
    hold on;
    
    % رسم الخطوط اليومية الخام (نفس ألوانك المفضلة)
    p1 = plot(time_vec, data_sst, '-', 'LineWidth', 1.2, 'Color', [0 0.45 0.74], 'DisplayName', 'SST (Daily)');
    p2 = plot(time_vec, data_t2m, '-', 'LineWidth', 1.0, 'Color', [0.85 0.33 0.1], 'DisplayName', 'T2M (Daily)');

    % --- الطلب رقم 1: المسميات (a,b,c) في الخارج ---
    title(sprintf('(%s) %s', panel_labels{i}, location_names{i}), 'FontSize', 18, 'FontWeight', 'bold', 'Color', 'k');
    ylabel('Temperature (°C)', 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'k');
    
    % --- الطلب رقم 3: توسيع المدى الصادي (+5 و -5) لجميع الرسمات ---
    all_vals = [data_sst; data_t2m];
    current_min = min(all_vals);
    current_max = max(all_vals);
    ylim([current_min - 5, current_max + 5]);
    
    % تنسيق المحاور وتكبير الأرقام
    set(ax, 'XColor', 'k', 'YColor', 'k', 'FontSize', 16, 'FontWeight', 'bold', 'LineWidth', 1.5);
    grid on; ax.GridLineStyle = ':'; ax.GridAlpha = 0.4;
    
    xlim([datetime(2025,1,1) datetime(2025,12,31)]);
    
    % تنسيق التاريخ (اسم الشهر فقط)
    if i < 3
        xticklabels([]); 
    else
        xtickformat('MMM'); 
        xlabel('Daily of the Year 2025', 'FontSize', 18, 'FontWeight', 'bold', 'Color', 'k');
    end
    
    if i == 1
        legend([p1, p2], 'Location', 'northeast', 'FontSize', 13, 'TextColor', 'w');
    end
end

% العنوان الرئيسي
sgtitle('Daily Red Sea Analysis 2025: SST vs T2M (Raw Daily Data)', ...
        'FontSize', 22, 'FontWeight', 'bold', 'Color', 'k');

%% حساب الارتباط (لآخر منطقة تم استخراج بياناتها)
% ملاحظة: data_sst و data_t2m تحتوي على بيانات الموقع الأخير في الحلقة
r = corr(data_sst, data_t2m);
fprintf('معامل الارتباط r = %.4f\n', r);

%% تفسير النتيجة
if r >= 0.7
    fprintf('ارتباط قوي موجب ✅\n');
elseif r >= 0.4
    fprintf('ارتباط متوسط موجب\n');
elseif r >= 0
    fprintf('ارتباط ضعيف موجب\n');
% ... بقية الشروط ...
end

%% Scatter Plot للتأكيد البصري
figure('Color','w', 'Position',[100 100 500 500]);
scatter(data_sst, data_t2m, 20, 'filled', ...
        'MarkerFaceColor', [0.20 0.53 0.74], ...
        'MarkerFaceAlpha', 0.5);
% خط الاتجاه
hold on;
p = polyfit(data_sst, data_t2m, 1);
x_line = linspace(min(data_sst), max(data_sst), 100);
plot(x_line, polyval(p, x_line), 'r-', 'LineWidth', 2);

% إضافة r على الرسم
text(0.05, 0.92, sprintf('r = %.4f', r), ...
     'Units','normalized', 'FontSize',13, ...
     'FontWeight','bold', 'Color','r');
xlabel('SST [°C]', 'FontSize',11, 'FontWeight','bold');
ylabel('T2m [°C]', 'FontSize',11, 'FontWeight','bold');
title('SST vs T2m – South Red Sea', 'FontSize',13, 'FontWeight','bold');
grid on; box on;