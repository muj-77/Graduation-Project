%% مشروع التخرج: تحليل حرارة الهواء (T2M) - مع رسم التضاريس
clear; clc; close all;
%% 1. إعدادات الملفات
t2m_file   = 'Monthly_T2M_Data.nc';
gebco_file = 'gebco_2025_tid_n30.0_s10.0_w30.0_e45.0.nc';
fprintf('Loading T2M Data...\n');
lon = double(ncread(t2m_file, 'lon'));
lat = double(ncread(t2m_file, 'lat'));
t2m = double(ncread(t2m_file, 't2m')); 

% تحويل الوحدات
if mean(t2m(:), 'omitnan') > 200
    t2m = t2m - 273.15;
end
clim_range = [floor(min(t2m(:))), ceil(max(t2m(:)))];
abc_labels = {'(a)', '(b)', '(c)', '(d)', '(e)', '(f)'};

% =========================================================================
% فلترة وقص الخلجان خارج البحر الأحمر (تعديل الحدود الجغرافية)
% =========================================================================
[LON_init, LAT_init] = meshgrid(lon, lat);
LON_init = LON_init'; 
LAT_init = LAT_init';

for t = 1:size(t2m, 3)
    slice = t2m(:, :, t);
    
    % أ. إزالة خليج السويس وخليج العقبة (شمال خط عرض 27.5 شمالاً)
    slice(LAT_init > 27.5) = NaN;
    
    % ب. إزالة الطرف السفلي لخليج عدن (جنوب خط عرض 12.2 وشرق خط طول 43.5)
    slice(LAT_init < 12.2 & LON_init > 43.5) = NaN;
    
    t2m(:, :, t) = slice;
end
fprintf('  -> Excluded Gulf of Suez, Gulf of Aqaba, and parts of Gulf of Aden.\n');
% =========================================================================

%% 2. تجهيز التضاريس (Land Mask)
fprintf('Processing GEBCO Terrain...\n');
stride = 5; 
g_lon = double(ncread(gebco_file, 'lon', 1, Inf, stride));
g_lat = double(ncread(gebco_file, 'lat', 1, Inf, stride));
g_tid = double(ncread(gebco_file, 'tid', [1 1], [Inf Inf], [stride stride]));
land_mask = (g_tid == 0); 
clim_range = [5, 40];

%% 3. رسم المتوسطات الشهرية مقسمة حسب الفصول
months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
% تعريف الفصول والأشهر التابعة لها (كل صف يمثل فصل)
seasons = {'Winter ', [12, 1, 2];
           '-Spring ', [3, 4, 5];
           'Summer ', [6, 7, 8];
           'Autumn ', [9, 10, 11]};
start_fig_num = 5;

for s = 1:4
    season_name = seasons{s, 1};
    season_indices = seasons{s, 2};
    
    current_fig_num = start_fig_num + s - 1;
    % إنشاء نافذة جديدة لكل فصل
    figure('Name', season_name, 'Color', 'w', 'Position', [150 150 1000 400]);
    
    for i = 1:3
        m = season_indices(i); % تحديد رقم الشهر
        subplot(1, 3, i);      % ترتيب 1x3 (3 صور بجانب بعض)
        hold on;
        
        % =====================================================================
        % تعديل مهم: جعل خلفية المحور رمادية متطابقة مع لون اليابسة لتغطية الفراغات البيضاء
        % =====================================================================
        set(gca, 'Color', [0.6 0.6 0.6]); 
        
        % رسم الحرارة
        pcolor(lon, lat, t2m(:,:,m)'); 
        shading interp;
        
        % رسم التضاريس
        contourf(g_lon, g_lat, double(land_mask'), [0.5 0.5], ...
            'FaceColor', [0.6 0.6 0.6], 'LineColor', 'k', 'LineWidth', 0.5);
        
        % =====================================================================
        % تعديل مهم: تقريب الصورة وعمل زووم (Zoom) على أبعاد البحر الأحمر مباشرة
        % =====================================================================
        xlim([32 44]); 
        ylim([12 28]);
        % =====================================================================
        
        set(gca, 'XColor', 'k', 'YColor', 'k', 'FontSize', 9, 'FontWeight', 'bold');
        
        % (a)(b)(c) تعديل وضع مسميات 
        text(0.10, 1.00, abc_labels{i}, 'Units', 'normalized', ...
             'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
             'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
        colormap(gca, 'jet'); 
        clim(clim_range); % تحديث لتوافق الإصدارات بدلاً من caxis
        
        title(months{m},'Color', 'k', 'FontWeight', 'bold');
        set(gca, 'Layer', 'top', 'Box', 'on');
        
        set(gcf, 'Position', [100, 100, 1200, 500]); % تكبير النافذة يعطي مساحة للتنفس
        
        % إضافة شريط الألوان في آخر صورة من كل فصل
        if i 
            c = colorbar;
            c.Label.String = 'Temperature (°C)';
            c.Color = 'k';
        end
    end
   
     sgtitle([ ' T2M - ', season_name], ...
            'Color', 'k', 'FontSize', 16, 'FontWeight', 'bold');
end
disp('Done: Figures generated for each season.');

%% 4. حساب الإحصائيات الشهرية وإنشاء الجدول المطور (T2M Statistics)
fprintf('Calculating Monthly T2M Statistics and Total Summary...\n');
max_t2m  = zeros(12, 1);
min_t2m  = zeros(12, 1);
mean_t2m = zeros(12, 1);
month_list = {'January', 'February', 'March', 'April', 'May', 'June', ...
              'July', 'August', 'September', 'October', 'November', 'December'};

for m = 1:12
    current_data = t2m(:,:,m);
    
    max_t2m(m)  = max(current_data(:), [], 'omitnan');
    min_t2m(m)  = min(current_data(:), [], 'omitnan');
    mean_t2m(m) = mean(current_data(:), 'omitnan');
end

total_max  = max(max_t2m);           
total_min  = min(min_t2m);           
total_mean = mean(mean_t2m);         

final_month_list = [month_list, {'Total / Average'}];
final_min  = [min_t2m; total_min];
final_max  = [max_t2m; total_max];
final_mean = [mean_t2m; total_mean];

T2M_Stats_Table = table(final_month_list', final_min, final_max, final_mean, ...
    'VariableNames', {'Month', 'Min_Temp_C', 'Max_Temp_C', 'Mean_Temp_C'});

fig_table = figure('Name', 'Monthly Statistical Summary', 'Color', 'w', ...
                   'Position', [200 100 650 550], 'NumberTitle', 'off', 'MenuBar', 'none');

uit = uitable(fig_table, 'Data', table2cell(T2M_Stats_Table), ...
        'ColumnName', {'Month', 'Min (°C)', 'Max (°C)', 'Mean (°C)'}, ...
        'Units', 'normalized', 'Position', [0.02 0.02 0.96 0.96], ...
        'FontSize', 10, 'FontWeight', 'bold');

disp('Done: Monthly Statistical Table with Annual Summary generated.');


% عرض الجدول وحفظه
disp(T2M_Stats_Table);
writetable(T2M_Stats_Table, 't2m_1.xlsx');

