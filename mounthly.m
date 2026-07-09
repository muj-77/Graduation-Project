clc; clear;
% 1. تعريف أسماء الملفات في مصفوفة (Cell Array)
files = {'data_of_sst_and_2m_1.nc', 'data_of_sst_and_2m_2.nc'};
% مصفوفات فارغة لتجميع البيانات
lon = []; lat = []; time = []; t2m = []; sst = [];
% 2. حلقة لقراءة ودمج البيانات
for i = 1:length(files)
    f = files{i};
    
    % قراءة خطوط الطول والعرض (نكتفي بأخذها من أول ملف فقط لأنها ثابتة غالباً)
    if i == 1
        lon = ncread(f, 'longitude');
        lat = ncread(f, 'latitude');
    end
    
    % قراءة البيانات المتغيرة ودمجها عبر البعد الزمني (البعد الثالث لـ t2m و sst)
    time = [time; ncread(f, 'valid_time')];
    t2m  = cat(3, t2m, ncread(f, 't2m'));
    sst  = cat(3, sst, ncread(f, 'sst'));
end
%% ===== تحويل الوقت =====
ref_date = datetime(1970,1,1);
time_dt  = ref_date + seconds(time);
%% ===== تحويل من Kelvin إلى Celsius =====
t2m = t2m - 273.15;
sst = sst - 273.15;
%% ===== تحويل من ساعي إلى يومي =====
day_id = dateshift(time_dt,'start','day');
[unique_days,~,idx_day] = unique(day_id);
nDays = length(unique_days);
sst_daily  = zeros(length(lon), length(lat), nDays);
t2m_daily  = zeros(length(lon), length(lat), nDays);
for i = 1:nDays
    ind = (idx_day == i);
    sst_daily(:,:,i) = mean(sst(:,:,ind), 3, 'omitnan');
    t2m_daily(:,:,i) = mean(t2m(:,:,ind), 3, 'omitnan');
end
%% ===== تحويل من يومي إلى شهري =====
month_id = dateshift(unique_days,'start','month');
[unique_months,~,idx_month] = unique(month_id);
nMonths = length(unique_months);
sst_monthly = zeros(length(lon), length(lat), nMonths);
t2m_monthly = zeros(length(lon), length(lat), nMonths);
for i = 1:nMonths
    ind = (idx_month == i);
    sst_monthly(:,:,i) = mean(sst_daily(:,:,ind), 3, 'omitnan');
    t2m_monthly(:,:,i) = mean(t2m_daily(:,:,ind), 3, 'omitnan');
end
disp(['إجمالي عدد الأيام بعد الدمج = ', num2str(nDays)])
disp(['إجمالي عدد الأشهر بعد الدمج = ', num2str(nMonths)])

%% ===== حفظ البيانات اليومية (Daily) في ملفات منفصلة =====

% 1. حفظ SST اليومي
sst_daily_filename = 'Daily_SST_Data.nc';
if exist(sst_daily_filename, 'file'), delete(sst_daily_filename); end
nccreate(sst_daily_filename, 'lon', 'Dimensions', {'lon', length(lon)});
nccreate(sst_daily_filename, 'lat', 'Dimensions', {'lat', length(lat)});
nccreate(sst_daily_filename, 'time', 'Dimensions', {'time', nDays});
nccreate(sst_daily_filename, 'sst', 'Dimensions', {'lon', length(lon), 'lat', length(lat), 'time', nDays});

ncwrite(sst_daily_filename, 'lon', lon);
ncwrite(sst_daily_filename, 'lat', lat);
ncwrite(sst_daily_filename, 'time', days(unique_days - datetime(1970,1,1))); 
ncwrite(sst_daily_filename, 'sst', sst_daily);
ncwriteatt(sst_daily_filename, 'sst', 'units', 'Celsius');
ncwriteatt(sst_daily_filename, 'time', 'units', 'days since 1970-01-01');
disp(['تم حفظ ملف SST اليومي بنجاح: ', sst_daily_filename]);

% 2. حفظ T2M اليومي
t2m_daily_filename = 'Daily_T2M_Data.nc';
if exist(t2m_daily_filename, 'file'), delete(t2m_daily_filename); end
nccreate(t2m_daily_filename, 'lon', 'Dimensions', {'lon', length(lon)});
nccreate(t2m_daily_filename, 'lat', 'Dimensions', {'lat', length(lat)});
nccreate(t2m_daily_filename, 'time', 'Dimensions', {'time', nDays});
nccreate(t2m_daily_filename, 't2m', 'Dimensions', {'lon', length(lon), 'lat', length(lat), 'time', nDays});

ncwrite(t2m_daily_filename, 'lon', lon);
ncwrite(t2m_daily_filename, 'lat', lat);
ncwrite(t2m_daily_filename, 'time', days(unique_days - datetime(1970,1,1)));
ncwrite(t2m_daily_filename, 't2m', t2m_daily);
ncwriteatt(t2m_daily_filename, 't2m', 'units', 'Celsius');
ncwriteatt(t2m_daily_filename, 'time', 'units', 'days since 1970-01-01');
disp(['تم حفظ ملف T2M اليومي بنجاح: ', t2m_daily_filename]);

%% ===== حفظ البيانات الشهرية (Monthly) في ملفات منفصلة =====
% (بقية الكود الخاص بك كما هو)

sst_filename = 'Monthly_SST_Data.nc';
if exist(sst_filename, 'file'), delete(sst_filename); end 
nccreate(sst_filename, 'lon', 'Dimensions', {'lon', length(lon)});
nccreate(sst_filename, 'lat', 'Dimensions', {'lat', length(lat)});
nccreate(sst_filename, 'time', 'Dimensions', {'time', nMonths});
nccreate(sst_filename, 'sst', 'Dimensions', {'lon', length(lon), 'lat', length(lat), 'time', nMonths});

ncwrite(sst_filename, 'lon', lon);
ncwrite(sst_filename, 'lat', lat);
ncwrite(sst_filename, 'time', days(unique_months - datetime(1970,1,1))); 
ncwrite(sst_filename, 'sst', sst_monthly);
ncwriteatt(sst_filename, 'sst', 'units', 'Celsius');
ncwriteatt(sst_filename, 'time', 'units', 'days since 1970-01-01');
disp(['تم حفظ ملف SST الشهري بنجاح: ', sst_filename]);

t2m_filename = 'Monthly_T2M_Data.nc';
if exist(t2m_filename, 'file'), delete(t2m_filename); end
nccreate(t2m_filename, 'lon', 'Dimensions', {'lon', length(lon)});
nccreate(t2m_filename, 'lat', 'Dimensions', {'lat', length(lat)});
nccreate(t2m_filename, 'time', 'Dimensions', {'time', nMonths});
nccreate(t2m_filename, 't2m', 'Dimensions', {'lon', length(lon), 'lat', length(lat), 'time', nMonths});

ncwrite(t2m_filename, 'lon', lon);
ncwrite(t2m_filename, 'lat', lat);
ncwrite(t2m_filename, 'time', days(unique_months - datetime(1970,1,1)));
ncwrite(t2m_filename, 't2m', t2m_monthly);
ncwriteatt(t2m_filename, 't2m', 'units', 'Celsius');
ncwriteatt(t2m_filename, 'time', 'units', 'days since 1970-01-01');
disp(['تم حفظ ملف T2M الشهري بنجاح: ', t2m_filename]);