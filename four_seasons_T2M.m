clear; clc; close all;
%% 1. إعدادات الملفات
t2m_file   = 'Monthly_T2M_Data.nc';       % ملف حرارة الهواء
gebco_file = 'gebco_2025_tid_n30.0_s10.0_w30.0_e45.0.nc'; % ملف التضاريس
fprintf('Loading T2M Data...\n');
lon = double(ncread(t2m_file, 'lon'));
lat = double(ncread(t2m_file, 'lat'));
t2m = double(ncread(t2m_file, 't2m')); 

% --- معالجة البيانات ---
% 1. تحويل الوحدات من كلفن إلى مئوية
if mean(t2m(:), 'omitnan') > 200
    t2m = t2m - 273.15;
    fprintf('  -> Converted to Celsius.\n');
end

% 2. تنظيف البيانات: القيم الشاذة جداً نعتبرها فراغاً
t2m(t2m < 5) = NaN;

% =========================================================================
% 3. فلترة وقص الخلجان خارج البحر الأحمر (تعديل الحدود الجغرافية)
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

%% 4. تعريف الفصول والرسم
seasons = {
    [12, 1, 2], 'Winter (DJF)';
    [3, 4, 5],  'Spring (MAM)';
    [6, 7, 8],  'Summer (JJA)';
    [9, 10, 11],'Autumn (SON)'
};
abc_labels = {'(a)', '(b)', '(c)', '(d)'};
clim_range = [10, 40]; 

figure('Name', 'T2M Seasonal Final', 'Color', 'w', 'Position', [100 100 1000 800]);
for s = 1:4
    % حساب متوسط الفصل
    season_indices = seasons{s, 1};
    season_mean = mean(t2m(:,:,season_indices), 3, 'omitnan'); 
    
    subplot(2, 2, s);
    hold on;
    
    % =====================================================================
    % تعديل مهم: جعل خلفية المحور رمادية متطابقة مع لون اليابسة لتغطية الفراغات البيضاء
    % =====================================================================
    set(gca, 'Color', [0.8 0.8 0.8]); 
    
    % --- المعالجة الذكية (Interpolation) ---
    V_season = season_mean'; 
    X = LON(:);
    Y = LAT(:);
    V = V_season(:);
    
    valid_idx = ~isnan(V);
    
    if sum(valid_idx) > 0
        F = scatteredInterpolant(X(valid_idx), Y(valid_idx), V(valid_idx), 'natural', 'nearest');
        season_interp = F(FINE_LON, FINE_LAT);
        
        interp_lat = FINE_LAT;
        interp_lon = FINE_LON;
        season_interp(interp_lat > 27.5) = NaN;
        season_interp(interp_lat < 12.2 & interp_lon > 43.5) = NaN;
        
        contourf(FINE_LON, FINE_LAT, season_interp, 30, 'LineColor', 'none');
    end
    
    % --- رسم اليابسة (Mask) ---
    contourf(g_lon, g_lat, double(land_mask'), [0.5 0.5], ...
        'FaceColor', [0.8 0.8 0.8], 'LineColor', 'k');
    
    % =====================================================================
    % تعديل مهم: تقريب الصورة وعمل زووم (Zoom) على أبعاد البحر الأحمر مباشرة
    % =====================================================================
    xlim([32 44]); 
    ylim([12 28]);
    % =====================================================================
    
    set(gca, 'XColor', 'k', 'YColor', 'k', 'FontSize', 9, 'FontWeight', 'bold');
    
    text(0.05, 1.05, abc_labels{s}, 'Units', 'normalized', ...
         'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k', ...
         'BackgroundColor', 'none', 'EdgeColor', 'k');
    
    colormap(gca, 'jet'); 
    clim(clim_range); 
    
    title(seasons{s, 2},'Color', 'k' ,'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Longitude'); ylabel('Latitude');
    
    set(gca, 'Box', 'on', 'Layer', 'top', 'FontSize', 10);
    
    c = colorbar;
    c.Label.String = 'Temperature (^\circC)';
    c.Color = 'k';
end
sgtitle(' Seasonal Mean Air Temperature (T2M)','Color', 'k', 'FontSize', 16, 'FontWeight', 'bold');
disp('Done: Seasonal T2M plots generated successfully.');

%% 5. حساب الإحصائيات الفصيلة وإنشاء الجدول (Seasonal T2M Statistics)
fprintf('Calculating Seasonal T2M Statistics...\n');
max_t2m_seas  = zeros(4, 1);
min_t2m_seas  = zeros(4, 1);
mean_t2m_seas = zeros(4, 1);
season_labels = {'Winter (DJF)', 'Spring (MAM)', 'Summer (JJA)', 'Autumn (SON)'};

for s = 1:4
    idx_months = seasons{s, 1};
    season_data_raw = t2m(:,:,idx_months);
    
    max_t2m_seas(s)  = max(season_data_raw(:), [], 'omitnan');
    min_t2m_seas(s)  = min(season_data_raw(:), [], 'omitnan');
    mean_t2m_seas(s) = mean(season_data_raw(:), 'omitnan');
end

total_max  = max(max_t2m_seas);           
total_min  = min(min_t2m_seas);           
total_mean = mean(mean_t2m_seas);         

final_labels = [season_labels, {'Total / Average'}];
final_min    = [min_t2m_seas; total_min];
final_max    = [max_t2m_seas; total_max];
final_mean   = [mean_t2m_seas; total_mean];

Seasonal_T2M_Table = table(final_labels', final_min, final_max, final_mean, ...
    'VariableNames', {'Season', 'Min_Temp_C', 'Max_Temp_C', 'Mean_Temp_C'});

fig_seas_t2m = figure('Name', 'Seasonal T2M Summary', 'Color', 'w', ...
                      'Position', [250 250 600 350], 'NumberTitle', 'off', 'MenuBar', 'none');
uit_seas_t2m = uitable(fig_seas_t2m, 'Data', table2cell(Seasonal_T2M_Table), ...
        'ColumnName', {'Season', 'Min (°C)', 'Max (°C)', 'Mean (°C)'}, ...
        'Units', 'normalized', 'Position', [0.02 0.02 0.96 0.96], ...
        'FontSize', 10, 'FontWeight', 'bold');

disp('Seasonal T2M Statistical Table with Total Summary generated successfully.');

% عرض الجدول وحفظه
disp(Seasonal_T2M_Table);
writetable(Seasonal_T2M_Table, 't2m_2.xlsx');