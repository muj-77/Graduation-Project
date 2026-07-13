clear; clc; close all;
%% 1. إعدادات الملفات
sst_file   = 'Monthly_SST_Data.nc';
gebco_file = 'gebco_2025_tid_n30.0_s10.0_w30.0_e45.0.nc';
fprintf('Loading SST Data...\n');
lon = double(ncread(sst_file, 'lon'));
lat = double(ncread(sst_file, 'lat'));
sst = double(ncread(sst_file, 'sst')); 
% --- معالجة البيانات ---
if mean(sst(:), 'omitnan') > 200
    sst = sst - 273.15;
end
sst(sst < 15) = NaN;
% =========================================================================
% فلترة وقص الخلجان خارج البحر الأحمر (تعديل الحدود الجغرافية)
% =========================================================================
[LON_init, LAT_init] = meshgrid(lon, lat);
LON_init = LON_init'; 
LAT_init = LAT_init';
for t = 1:size(sst, 3)
    slice = sst(:, :, t);
    
    % أ. إزالة خليج السويس وخليج العقبة (شمال خط عرض 27.5 شمالاً)
    slice(LAT_init > 27.5) = NaN;
    
    % ب. إزالة الطرف السفلي لخليج عدن (جنوب خط عرض 12.2 وشرق خط طول 43.5)
    slice(LAT_init < 12.2 & LON_init > 43.5) = NaN;
    
    sst(:, :, t) = slice;
end
fprintf('  -> Excluded Gulf of Suez, Gulf of Aqaba, and parts of Gulf of Aden.\n');
% =========================================================================
%% 2. تجهيز الشبكات (Grid Generation)
[LON, LAT] = meshgrid(lon, lat);
fine_lon = min(lon):0.05:max(lon); 
fine_lat = min(lat):0.05:max(lat);
[FINE_LON, FINE_LAT] = meshgrid(fine_lon, fine_lat);
%% 3. تجهيز التضاريس (Land Mask)
fprintf('Processing GEBCO Terrain...\n');
stride = 5; 
g_lon = double(ncread(gebco_file, 'lon', 1, Inf, stride));
g_lat = double(ncread(gebco_file, 'lat', 1, Inf, stride));
g_tid = double(ncread(gebco_file, 'tid', [1 1], [Inf Inf], [stride stride]));
land_mask = (g_tid == 0); 
%% 4. إعداد الفصول (Seasons setup)
season_names = {'Winter', 'Spring', 'Summer', 'Autumn'};

% ==========================================
% التعديل الأول: تغيير ترتيب أشهر الشتاء ليصبح ديسمبر (12) ثم يناير (1) ثم فبراير (2)
% ==========================================
season_months = {[12, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11]};

month_labels = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
clim_range = [floor(min(sst(:), [], 'omitnan')), ceil(max(sst(:), [], 'omitnan'))];
abc_labels = {'(a)', '(b)', '(c)', '(d)', '(e)', '(f)'};
%% 5. رسم كل فصل في نافذة مستقلة
for s = 1:4
    current_season_indices = season_months{s};
    
    figure(s); 
    set(gcf, 'Name', ['Season ' num2str(s)], 'Color', 'w', 'Position', [100 100 1100 500]);
    
    for i = 1:length(current_season_indices)
        m = current_season_indices(i); 
        
        subplot(1, 3, i); 
        hold on;
        
        % =====================================================================
        % تعديل مهم: جعل خلفية المحور رمادية متطابقة مع لون اليابسة لتغطية الفراغات البيضاء
        % =====================================================================
        set(gca, 'Color', [0.8 0.8 0.8]); 
        
        % استخراج بيانات الشهر الحالي
        current_sst = sst(:,:,m)'; 
        X = LON(:); Y = LAT(:); V = current_sst(:);
        valid_idx = ~isnan(V);
        
        if sum(valid_idx) > 0
            F = scatteredInterpolant(X(valid_idx), Y(valid_idx), V(valid_idx), 'natural', 'nearest');
            sst_interp = F(FINE_LON, FINE_LAT);
            
            % استبعاد الفراغات الجغرافية المقصوصة من شبكة التنعيم لمنع زحف الألوان
            interp_lat = FINE_LAT;
            interp_lon = FINE_LON;
            sst_interp(interp_lat > 27.5) = NaN;
            sst_interp(interp_lat < 12.2 & interp_lon > 43.5) = NaN;
            
            pcolor(FINE_LON, FINE_LAT, sst_interp); 
            shading interp;
        end
        
        % رسم اليابسة
        contourf(g_lon, g_lat, double(land_mask'), [0.5 0.5], ...
                 'FaceColor', [0.8 0.8 0.8], 'LineColor', 'k', 'LineWidth', 0.5);
             
        % ==========================================
        % التعديل الثاني: استخدام الدليل 'i' لضمان بقاء الترتيب التصاعدي للحروف (a), (b), (c)
        % ==========================================
        text(0.10, 1.00, abc_labels{i}, 'Units', 'normalized', ...
             'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
             'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
         
        % =====================================================================
        % تعديل مهم: تقريب الصورة وعمل زووم (Zoom) على أبعاد البحر الأحمر مباشرة
        % =====================================================================
        xlim([32 44]); 
        ylim([12 28]);
        % =====================================================================
        
        colormap(gca, 'jet'); 
        clim(clim_range); % التحديث القياسي بدلاً من caxis لضمان التوافقية
        
        set(gca, 'XColor', 'k', 'YColor', 'k', 'FontSize', 9, 'FontWeight', 'bold');
        title(month_labels{m}, 'Color', 'k','FontWeight', 'bold');
        set(gca, 'Box', 'on', 'Layer', 'top'); 
        
        c = colorbar;
        c.Label.String = 'Temperature (^\circC)';
        c.Color = 'k';
    end
    
    sgtitle(['Sea Surface Temperature - ', season_names{s}], ...
           'Color', 'k', 'FontSize', 16, 'FontWeight', 'bold');
end
disp('Done: Figures generated for each season.');
%% 6. حساب الإحصائيات الشهرية والسنوية وإنشاء الجدول المطور
fprintf('Generating Monthly and Annual Statistics Table...\n');
max_vals  = zeros(12, 1);
min_vals  = zeros(12, 1);
mean_vals = zeros(12, 1);
for m = 1:12
    month_data = sst(:,:,m);
    
    max_vals(m)  = max(month_data(:), [], 'omitnan');
    min_vals(m)  = min(month_data(:), [], 'omitnan');
    mean_vals(m) = mean(month_data(:), 'omitnan');
end
total_max  = max(max_vals);           
total_min  = min(min_vals);           
total_mean = mean(mean_vals);         
final_labels = [month_labels, {'Total / Average'}];
final_min    = [min_vals; total_min];
final_max    = [max_vals; total_max];
final_mean   = [mean_vals; total_mean];
Monthly_Stats_Table = table(final_labels', final_min, final_max, final_mean, ...
    'VariableNames', {'Month', 'Min_Temp_C', 'Max_Temp_C', 'Mean_Temp_C'});
disp('--- Monthly Sea Surface Temperature Statistics with Annual Summary ---');
disp(Monthly_Stats_Table);
fig_table = figure('Name', 'Statistical Summary Table', 'Color', 'w', ...
                   'Position', [200 100 650 550], 'NumberTitle', 'off', 'MenuBar', 'none');
uit = uitable(fig_table, 'Data', table2cell(Monthly_Stats_Table), ...
        'ColumnName', {'Month', 'Min (°C)', 'Max (°C)', 'Mean (°C)'}, ...
        'Units', 'normalized', 'Position', [0.02 0.02 0.96 0.96], ...
        'FontSize', 10, 'FontWeight', 'bold');
fprintf('Done: Statistical Table with Annual Summary generated.\n');
% عرض الجدول وحفظه
disp(Monthly_Stats_Table);
writetable(Monthly_Stats_Table, 'sst_1.xlsx');