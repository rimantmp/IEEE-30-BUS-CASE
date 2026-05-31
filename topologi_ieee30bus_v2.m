%% ================================================================
%% TOPOLOGI DIAGRAM IEEE 30 BUS - VERSI 2
%% Dengan simbol standar teknik tenaga listrik
%% (Generator, Transformator, Beban, Busbar)
%% ================================================================

clc; clear; close all;

%% === DATA ===
saluran = [
    1  2;  1  3;  2  4;  3  4;  2  5;  2  6;  4  6;  5  7;
    6  7;  6  8;  6  9;  6 10;  9 11;  9 10;  4 12; 12 13;
   12 14; 12 15; 12 16; 14 15; 16 17; 15 18; 18 19; 19 20;
   10 20; 10 17; 10 21; 10 22; 21 22; 15 23; 22 24; 23 24;
   24 25; 25 26; 25 27; 28 27; 27 29; 27 30; 29 30;  8 28;
    6 28;
];

% Saluran yang memiliki transformator (tap ratio != 0 dan != 1)
% Berdasarkan data IEEE 30 Bus:
%   Saluran 11 (6-9)   tap=0.978
%   Saluran 12 (6-10)  tap=0.969
%   Saluran 15 (4-12)  tap=0.932
%   Saluran 36 (28-27) tap=0.968
saluran_trafo = [11, 12, 15, 36];

tipe_bus = zeros(30, 1);
tipe_bus(1)  = 1;  % Slack
tipe_bus(2)  = 2;  % Generator
tipe_bus(5)  = 2;
tipe_bus(8)  = 2;
tipe_bus(11) = 2;
tipe_bus(13) = 2;

% Beban [P(MW), Q(MVAr)]
beban_P = [0; 21.7; 2.4; 7.6; 94.2; 0; 22.8; 30; 0; 5.8;
           0; 11.2; 0; 6.2; 8.2; 3.5; 9.0; 3.2; 9.5; 2.2;
           17.5; 0; 3.2; 8.7; 0; 3.5; 0; 0; 2.4; 10.6];
beban_Q = [0; 12.7; 1.2; 1.6; 19.0; 0; 10.9; 30; 0; 2.0;
           0; 7.5; 0; 1.6; 2.5; 1.8; 5.8; 0.9; 3.4; 0.7;
           11.2; 0; 1.6; 6.7; 0; 2.3; 0; 0; 0.9; 1.9];

% Daya generator [Pg(MW)]
gen_P = zeros(30,1);
gen_P(1) = 260; gen_P(2) = 40; gen_P(5) = 0;
gen_P(8) = 0;   gen_P(11) = 0; gen_P(13) = 0;

%% === KOORDINAT BUS ===
pos = [
    2.0  14.0;   % Bus 1
    5.0  14.0;   % Bus 2
    2.0  11.5;   % Bus 3
    5.0  11.5;   % Bus 4
    8.5  14.0;   % Bus 5
    8.5  11.5;   % Bus 6
   11.0  13.0;   % Bus 7
   13.5  11.5;   % Bus 8
    8.5   9.0;   % Bus 9
   11.5   9.0;   % Bus 10
    8.5   6.5;   % Bus 11
    5.0   9.0;   % Bus 12
    5.0   6.5;   % Bus 13
    3.0   6.5;   % Bus 14
    1.5   6.5;   % Bus 15
    3.0   4.5;   % Bus 16
    6.5   4.5;   % Bus 17
    0.0   4.5;   % Bus 18
    0.0   2.5;   % Bus 19
    3.0   2.5;   % Bus 20
   11.5   6.5;   % Bus 21
   13.5   6.5;   % Bus 22
    1.5   4.5;   % Bus 23
    6.5   2.5;   % Bus 24
    9.5   2.5;   % Bus 25
   11.5   1.0;   % Bus 26
   13.5   2.5;   % Bus 27
   15.5   9.0;   % Bus 28
   15.5   2.5;   % Bus 29
   17.0   2.5;   % Bus 30
];

%% === GAMBAR DIAGRAM ===
fig = figure('Name', 'Single-Line Diagram IEEE 30 Bus', ...
       'Position', [30 30 1500 950], ...
       'Color', 'w');

hold on;
axis off;
axis equal;

%% --- 1. GAMBAR SALURAN TRANSMISI ---
for k = 1:size(saluran, 1)
    f = saluran(k, 1);
    t = saluran(k, 2);
    x = [pos(f,1) pos(t,1)];
    y = [pos(f,2) pos(t,2)];
    
    if ismember(k, saluran_trafo)
        % Saluran dengan transformator: garis lebih tebal, warna berbeda
        plot(x, y, '-', 'Color', [0.4 0.2 0.0], 'LineWidth', 2.0);
        % Gambar simbol transformator di tengah saluran
        mx = mean(x);
        my = mean(y);
        gambar_trafo(mx, my, 0.3);
    else
        % Saluran transmisi biasa
        plot(x, y, '-', 'Color', [0.2 0.2 0.2], 'LineWidth', 1.2);
    end
    
    % Label nomor saluran
    mx = mean(x);
    my = mean(y);
    % Offset label sedikit agar tidak menimpa garis
    text(mx + 0.15, my + 0.15, sprintf('L%d', k), ...
        'FontSize', 6, 'Color', [0.6 0.1 0.1], ...
        'FontAngle', 'italic', 'HorizontalAlignment', 'left');
end

%% --- 2. GAMBAR BUSBAR (GARIS TEBAL) DI SETIAP BUS ---
busbar_len = 0.4;  % Panjang busbar
for i = 1:30
    x = pos(i, 1);
    y = pos(i, 2);
    
    % Gambar busbar (garis horizontal tebal)
    plot([x - busbar_len, x + busbar_len], [y, y], '-k', 'LineWidth', 4);
    
    % Nomor bus
    text(x, y + 0.35, sprintf('Bus %d', i), ...
        'FontSize', 7, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'Color', [0.0 0.0 0.5]);
end

%% --- 3. GAMBAR SIMBOL GENERATOR ---
gen_buses = find(tipe_bus == 1 | tipe_bus == 2);
for idx = 1:length(gen_buses)
    i = gen_buses(idx);
    x = pos(i, 1);
    y = pos(i, 2);
    
    if tipe_bus(i) == 1
        % Slack Bus — warna merah
        warna_gen = [0.85 0.1 0.1];
        label_extra = 'Slack';
    else
        % PV Bus — warna hijau
        warna_gen = [0.0 0.6 0.2];
        label_extra = '';
    end
    
    gambar_generator(x, y - 1.0, 0.35, warna_gen);
    
    % Garis penghubung generator ke busbar
    plot([x, x], [y, y - 0.65], '-', 'Color', warna_gen, 'LineWidth', 1.5);
    
    % Label generator
    if gen_P(i) > 0
        teks = sprintf('%d MW\n%s', gen_P(i), label_extra);
    else
        teks = sprintf('Gen\n%s', label_extra);
    end
    text(x, y - 1.6, teks, ...
        'FontSize', 6, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'Color', warna_gen);
end

%% --- 4. GAMBAR SIMBOL BEBAN ---
for i = 1:30
    if beban_P(i) > 0
        x = pos(i, 1);
        y = pos(i, 2);
        
        % Tentukan posisi simbol beban (di bawah atau di samping busbar)
        % Hindari tumpang tindih dengan generator
        if tipe_bus(i) == 1 || tipe_bus(i) == 2
            % Bus generator: beban di samping kanan
            bx = x + 0.8;
            by = y;
            gambar_beban(bx + 0.4, by - 0.5, 0.25);
            plot([bx, bx + 0.4], [by, by], '-k', 'LineWidth', 1);
            plot([bx + 0.4, bx + 0.4], [by, by - 0.3], '-k', 'LineWidth', 1);
            text(bx + 0.8, by - 0.3, sprintf('%g MW\n%g MVAr', beban_P(i), beban_Q(i)), ...
                'FontSize', 5.5, 'HorizontalAlignment', 'left', 'Color', [0.3 0.0 0.0]);
        else
            % Bus beban: beban di bawah
            gambar_beban(x, y - 0.9, 0.25);
            plot([x, x], [y, y - 0.7], '-k', 'LineWidth', 1);
            text(x + 0.3, y - 0.9, sprintf('%g MW\n%g MVAr', beban_P(i), beban_Q(i)), ...
                'FontSize', 5.5, 'HorizontalAlignment', 'left', 'Color', [0.3 0.0 0.0]);
        end
    end
end

%% --- 5. JUDUL ---
title({'SINGLE-LINE DIAGRAM SISTEM TENAGA IEEE 30 BUS'; ...
       'Analisis Kontingensi - Metode Distributed Slack Bus'}, ...
    'FontSize', 14, 'FontWeight', 'bold');

%% --- 6. LEGENDA MANUAL ---
% Buat legenda di pojok kanan bawah
lx = 15.0;  % Posisi x legenda
ly = 14.5;  % Posisi y legenda
lw = 3.5;   % Lebar kotak legenda
lh = 3.5;   % Tinggi kotak legenda

% Kotak legenda
rectangle('Position', [lx, ly - lh, lw, lh], ...
    'FaceColor', [0.98 0.98 0.98], 'EdgeColor', [0.3 0.3 0.3], ...
    'LineWidth', 1.2, 'Curvature', 0.05);

text(lx + lw/2, ly - 0.3, 'LEGENDA', ...
    'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% Item 1: Generator (Slack)
gambar_generator(lx + 0.5, ly - 1.0, 0.25, [0.85 0.1 0.1]);
text(lx + 1.0, ly - 1.0, 'Slack Bus (Generator)', ...
    'FontSize', 7, 'VerticalAlignment', 'middle');

% Item 2: Generator (PV)
gambar_generator(lx + 0.5, ly - 1.6, 0.25, [0.0 0.6 0.2]);
text(lx + 1.0, ly - 1.6, 'PV Bus (Generator)', ...
    'FontSize', 7, 'VerticalAlignment', 'middle');

% Item 3: Beban
gambar_beban(lx + 0.5, ly - 2.2, 0.2);
text(lx + 1.0, ly - 2.2, 'Beban (Load)', ...
    'FontSize', 7, 'VerticalAlignment', 'middle');

% Item 4: Saluran transmisi
plot([lx + 0.2, lx + 0.8], [ly - 2.7, ly - 2.7], '-', ...
    'Color', [0.2 0.2 0.2], 'LineWidth', 1.5);
text(lx + 1.0, ly - 2.7, 'Saluran Transmisi', ...
    'FontSize', 7, 'VerticalAlignment', 'middle');

% Item 5: Transformator
gambar_trafo(lx + 0.5, ly - 3.2, 0.2);
text(lx + 1.0, ly - 3.2, 'Transformator', ...
    'FontSize', 7, 'VerticalAlignment', 'middle');

%% --- 7. INFO SISTEM ---
annotation('textbox', [0.01 0.01 0.25 0.05], ...
    'String', 'IEEE 30 Bus  |  41 Saluran  |  6 Generator  |  Base: 100 MVA', ...
    'FontSize', 8, 'EdgeColor', 'none', 'FontAngle', 'italic');

%% === SIMPAN ===
print(gcf, 'topologi_ieee30bus_v2', '-dpng', '-r300');
fprintf('✅ Tersimpan: topologi_ieee30bus_v2.png (300 DPI)\n');

print(gcf, 'topologi_ieee30bus_v2', '-dpdf');
fprintf('✅ Tersimpan: topologi_ieee30bus_v2.pdf\n');


%% ================================================================
%% LOCAL FUNCTIONS (harus di paling bawah)
%% ================================================================

function gambar_generator(x, y, r, warna)
% Gambar simbol generator (lingkaran dengan gelombang sinus di dalam)
    theta = linspace(0, 2*pi, 60);
    % Lingkaran luar
    fill(x + r*cos(theta), y + r*sin(theta), warna, ...
        'EdgeColor', 'k', 'LineWidth', 1.2, 'FaceAlpha', 0.3);
    
    % Gelombang sinus di dalam (~)
    t = linspace(-r*0.6, r*0.6, 30);
    s = 0.15 * r * sin(t * 8 / r);
    plot(x + t, y + s, '-', 'Color', warna, 'LineWidth', 1.5);
    
    % Huruf G
    text(x, y - r*0.5, 'G', 'FontSize', max(5, round(r*15)), ...
        'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'top', 'Color', warna);
end

function gambar_beban(x, y, sz)
% Gambar simbol beban (panah ke bawah / segitiga terbalik)
    % Segitiga terbalik
    tx = [x - sz, x + sz, x, x - sz];
    ty = [y, y, y - sz*1.5, y];
    fill(tx, ty, [0.2 0.2 0.2], 'EdgeColor', 'k', 'LineWidth', 1);
end

function gambar_trafo(x, y, r)
% Gambar simbol transformator (dua lingkaran bersinggungan)
    theta = linspace(0, 2*pi, 40);
    % Lingkaran 1
    plot(x - r*0.4 + r*0.5*cos(theta), y + r*0.5*sin(theta), ...
        '-', 'Color', [0.4 0.2 0.0], 'LineWidth', 1.5);
    % Lingkaran 2
    plot(x + r*0.4 + r*0.5*cos(theta), y + r*0.5*sin(theta), ...
        '-', 'Color', [0.4 0.2 0.0], 'LineWidth', 1.5);
end
