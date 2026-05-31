%% ================================================================
%% SCRIPT UTAMA: ANALISIS KONTINGENSI SISTEM 30 BUS IEEE
%% METODE ALIRAN DAYA DISTRIBUTED SLACK BUS
%% ================================================================

clc; clear; close all;
fprintf('============================================================\n');
fprintf('  ANALISIS KONTINGENSI SISTEM TENAGA 30 BUS IEEE\n');
fprintf('  Metode: Distributed Slack Bus\n');
fprintf('  Perangkat Lunak: MATLAB (tanpa library tambahan)\n');
fprintf('============================================================\n');

%% 1. MUAT DATA
[busdata, linedata, gendata] = data_ieee30bus();
fprintf('\nData IEEE 30 Bus berhasil dimuat:\n');
fprintf('   - Jumlah Bus      : %d\n', size(busdata, 1));
fprintf('   - Jumlah Saluran  : %d\n', size(linedata, 1));
fprintf('   - Jumlah Generator: %d\n', size(gendata, 1));

%% 2. BENTUK MATRIKS Y-BUS
Ybus = bentuk_ybus(busdata, linedata);

%% 3. ALIRAN DAYA BASE CASE (Distributed Slack Bus)
fprintf('\n\n==============================\n');
fprintf('  ALIRAN DAYA - BASE CASE\n');
fprintf('==============================\n');

[V_base, sudut_base, P_gen_base, Q_gen_base, iter_base] = ...
    distributed_slack_bus(busdata, linedata, gendata, 1e-6, 20);

%% 4. TAMPILKAN PROFIL TEGANGAN
fprintf('\n\n--- Profil Tegangan Base Case ---\n');
fprintf('%-8s %-15s %-15s %-10s\n', 'Bus', 'V (p.u.)', 'Sudut (deg)', 'Status');
fprintf('--------------------------------------------------\n');
for i = 1:30
    if V_base(i) >= 0.95 && V_base(i) <= 1.05
        status = 'NORMAL';
    else
        status = 'DILUAR BATAS';
    end
    fprintf('%-8d %-15.4f %-15.4f %-10s\n', ...
        i, V_base(i), sudut_base(i)*180/pi, status);
end

%% 5. ANALISIS KONTINGENSI N-1: SALURAN TRANSMISI
fprintf('\n\n==========================================\n');
fprintf('  ANALISIS KONTINGENSI N-1: SALURAN\n');
fprintf('==========================================\n');

nline = size(linedata, 1);
hasil_kontingensi = zeros(nline, 4);  % [saluran, Vmin, bus_Vmin, PI]
V_kontingensi = zeros(30, nline);     % Simpan profil tegangan setiap kontingensi
konvergen_list = true(nline, 1);      % Status konvergensi

for k = 1:nline
    fprintf('\n--- Kontingensi: Lepas Saluran %d (Bus %d - %d) ---\n', ...
        k, linedata(k,1), linedata(k,2));
    
    % Hapus saluran ke-k
    linedata_cont = linedata;
    linedata_cont(k, :) = [];
    
    % Bentuk Y-Bus baru
    Ybus_cont = bentuk_ybus(busdata, linedata_cont);
    
    % Jalankan aliran daya
    [V_cont, sudut_cont, ~, conv_status] = newton_raphson_pf(busdata, linedata_cont, Ybus_cont, 1e-6, 50);
    
    if conv_status
        % Hitung Vmin dan Performance Index
        [Vmin, bus_vmin] = min(V_cont);
        delta_V = abs(V_cont - V_base);
        PI = sum((delta_V / 0.05).^2);  % Performance Index
        
        hasil_kontingensi(k, :) = [k, Vmin, bus_vmin, PI];
        V_kontingensi(:, k) = V_cont;
        
        fprintf('   Vmin = %.4f p.u. (Bus %d) | PI = %.4f\n', Vmin, bus_vmin, PI);
    else
        hasil_kontingensi(k, :) = [k, 0, 0, Inf];
        konvergen_list(k) = false;
        fprintf('   TIDAK KONVERGEN\n');
    end
end

%% 6. PERANKINGAN KEPARAHAN
fprintf('\n\n==========================================\n');
fprintf('  PERANKINGAN KEPARAHAN KONTINGENSI\n');
fprintf('==========================================\n');

[~, rank_idx] = sort(hasil_kontingensi(:, 4), 'descend');

fprintf('%-6s %-8s %-8s %-12s %-12s %-12s\n', ...
    'Rank', 'From', 'To', 'Vmin (p.u.)', 'Bus Vmin', 'Perf. Index');
fprintf('------------------------------------------------------------\n');

for r = 1:min(10, nline)
    k = rank_idx(r);
    if konvergen_list(k)
        fprintf('%-6d %-8d %-8d %-12.4f %-12d %-12.4f\n', ...
            r, linedata(k,1), linedata(k,2), ...
            hasil_kontingensi(k,2), hasil_kontingensi(k,3), hasil_kontingensi(k,4));
    else
        fprintf('%-6d %-8d %-8d %-12s %-12s %-12s\n', ...
            r, linedata(k,1), linedata(k,2), 'N/A', 'N/A', 'COLLAPSE');
    end
end

%% 7. VISUALISASI

% --- Grafik 1: Profil Tegangan Base Case ---
figure('Position', [50 50 900 500]);
bar(1:30, V_base, 'FaceColor', [0.2 0.6 0.9]);
hold on;
yline(0.95, 'r--', 'Batas Bawah (0.95)', 'LineWidth', 1.5);
yline(1.05, 'r--', 'Batas Atas (1.05)', 'LineWidth', 1.5);
xlabel('Nomor Bus');
ylabel('Tegangan (p.u.)');
title('Profil Tegangan Sistem 30 Bus IEEE - Kondisi Normal');
grid on; ylim([0.9 1.1]);
set(gca, 'XTick', 1:30);
saveas(gcf, 'grafik_tegangan_base.png');
fprintf('\nGrafik tersimpan: grafik_tegangan_base.png\n');

% --- Grafik 2: Perbandingan Normal vs Kontingensi Terparah ---
% Cari kontingensi terparah yang konvergen
rank_konvergen = rank_idx(konvergen_list(rank_idx));
if ~isempty(rank_konvergen)
    k_terparah = rank_konvergen(1);
    V_worst = V_kontingensi(:, k_terparah);
    
    figure('Position', [50 50 900 500]);
    plot(1:30, V_base, 'b-o', 'LineWidth', 2, 'DisplayName', 'Normal');
    hold on;
    plot(1:30, V_worst, 'r-s', 'LineWidth', 2, 'DisplayName', ...
        sprintf('Kontingensi Sal. %d-%d', linedata(k_terparah,1), linedata(k_terparah,2)));
    yline(0.95, 'k--', 'LineWidth', 1);
    yline(1.05, 'k--', 'LineWidth', 1);
    xlabel('Nomor Bus'); ylabel('Tegangan (p.u.)');
    title('Perbandingan Profil Tegangan: Normal vs Kontingensi Terparah');
    legend('Location', 'best'); grid on;
    set(gca, 'XTick', 1:30);
    saveas(gcf, 'grafik_perbandingan.png');
    fprintf('Grafik tersimpan: grafik_perbandingan.png\n');
end

% --- Grafik 3: Performance Index ---
figure('Position', [50 50 900 500]);
PI_plot = hasil_kontingensi(:, 4);
PI_plot(PI_plot == Inf) = max(PI_plot(PI_plot ~= Inf)) * 1.5;  % Ganti Inf untuk plotting
bar(PI_plot, 'FaceColor', [0.9 0.3 0.3]);
xlabel('Nomor Saluran');
ylabel('Performance Index');
title('Indeks Keparahan Kontingensi per Saluran');
grid on;
saveas(gcf, 'grafik_performance_index.png');
fprintf('Grafik tersimpan: grafik_performance_index.png\n');

% --- Grafik 4: Distribusi Daya Generator (Base Case) ---
figure('Position', [50 50 700 400]);
gen_labels = cell(1, length(gendata(:,1)));
for g = 1:size(gendata,1)
    gen_labels{g} = sprintf('Bus %d', gendata(g,1));
end
bar_data = [P_gen_base, Q_gen_base];
b = bar(bar_data);
b(1).FaceColor = [0.2 0.6 0.9];
b(2).FaceColor = [0.9 0.6 0.2];
set(gca, 'XTickLabel', gen_labels);
xlabel('Generator');
ylabel('Daya (MW / MVAr)');
title('Distribusi Daya Generator - Distributed Slack Bus');
legend('P (MW)', 'Q (MVAr)', 'Location', 'best');
grid on;
saveas(gcf, 'grafik_distribusi_generator.png');
fprintf('Grafik tersimpan: grafik_distribusi_generator.png\n');

fprintf('\n\nSIMULASI SELESAI! Semua grafik tersimpan sebagai file PNG.\n');
fprintf('============================================================\n');
