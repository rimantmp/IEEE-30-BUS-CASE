function [V, sudut, P_gen, Q_gen, iterasi] = distributed_slack_bus(busdata, linedata, gendata, tol, maks_iter)
% DISTRIBUTED_SLACK_BUS  Aliran daya dengan metode Distributed Slack Bus
%
% Daya mismatch (losses) didistribusikan ke semua generator secara
% proporsional berdasarkan kapasitas daya maksimum (Pmax).
%
% Input:
%   busdata   - data bus
%   linedata  - data saluran
%   gendata   - data generator
%   tol       - toleransi (misal 1e-6)
%   maks_iter - iterasi maksimum luar (misal 20)

baseMVA = 100;
nbus = size(busdata, 1);
ngen = size(gendata, 1);

% Bentuk Y-Bus
Ybus = bentuk_ybus(busdata, linedata);

% === Hitung faktor partisipasi berdasarkan Pmax ===
Pmax = gendata(:, 6);  % Kolom 6 = Pmax
alpha = Pmax / sum(Pmax);

fprintf('\n========================================\n');
fprintf('  METODE DISTRIBUTED SLACK BUS\n');
fprintf('========================================\n');
fprintf('\n--- Faktor Partisipasi Generator ---\n');
fprintf('%-10s %-12s %-12s\n', 'Bus Gen', 'Pmax (MW)', 'Alpha');
fprintf('------------------------------------\n');
for g = 1:ngen
    fprintf('%-10d %-12.2f %-12.4f\n', gendata(g,1), Pmax(g), alpha(g));
end

% === Iterasi Luar: Distribusi Slack ===
busdata_dsb = busdata;

for iter_luar = 1:maks_iter
    fprintf('\n>>> Iterasi Distributed Slack ke-%d <<<\n', iter_luar);
    
    % Jalankan Newton-Raphson
    [V, sudut, iter_nr, konvergen] = newton_raphson_pf(busdata_dsb, linedata, Ybus, tol, 50);
    
    if ~konvergen
        fprintf('Newton-Raphson gagal konvergen pada iterasi luar %d\n', iter_luar);
        P_gen = zeros(ngen, 1);
        Q_gen = zeros(ngen, 1);
        iterasi = iter_luar;
        return;
    end
    
    % === Hitung daya yang dibangkitkan setiap bus ===
    G = real(Ybus);
    B = imag(Ybus);
    P_calc = zeros(nbus, 1);
    Q_calc = zeros(nbus, 1);
    
    for i = 1:nbus
        for j = 1:nbus
            P_calc(i) = P_calc(i) + V(i) * V(j) * ...
                (G(i,j)*cos(sudut(i)-sudut(j)) + B(i,j)*sin(sudut(i)-sudut(j)));
            Q_calc(i) = Q_calc(i) + V(i) * V(j) * ...
                (G(i,j)*sin(sudut(i)-sudut(j)) - B(i,j)*cos(sudut(i)-sudut(j)));
        end
    end
    
    % Daya di bus generator = P_calc (injeksi netto) + P_load
    P_gen = zeros(ngen, 1);
    Q_gen = zeros(ngen, 1);
    
    for g = 1:ngen
        bus_g = gendata(g, 1);
        P_gen(g) = (P_calc(bus_g) + busdata(bus_g, 3)/baseMVA) * baseMVA;
        Q_gen(g) = (Q_calc(bus_g) + busdata(bus_g, 4)/baseMVA) * baseMVA;
    end
    
    % Total pembangkitan dan beban
    total_P_gen  = sum(P_gen);
    total_P_load = sum(busdata(:, 3));
    total_losses = total_P_gen - total_P_load;
    
    fprintf('\nTotal Pembangkitan : %.4f MW\n', total_P_gen);
    fprintf('Total Beban        : %.4f MW\n', total_P_load);
    fprintf('Total Losses       : %.4f MW\n', total_losses);
    
    % === Hitung daya target setiap generator (distributed) ===
    % Setiap generator menanggung: beban lokal + alpha * losses
    P_gen_target = zeros(ngen, 1);
    for g = 1:ngen
        P_gen_target(g) = alpha(g) * (total_P_load + total_losses);
    end
    
    % === Cek konvergensi distribusi slack ===
    delta_gen = max(abs(P_gen - P_gen_target));
    fprintf('Delta distribusi   : %.6f MW\n', delta_gen);
    
    if delta_gen < tol * baseMVA
        fprintf('\nDISTRIBUTED SLACK BUS KONVERGEN pada iterasi %d!\n', iter_luar);
        iterasi = iter_luar;
        
        % Cetak hasil akhir
        fprintf('\n--- Hasil Akhir Generator ---\n');
        fprintf('%-10s %-15s %-15s %-15s\n', 'Bus', 'P_gen (MW)', 'Q_gen (MVAr)', 'Alpha');
        fprintf('-------------------------------------------------------\n');
        for g = 1:ngen
            fprintf('%-10d %-15.4f %-15.4f %-15.4f\n', gendata(g,1), P_gen(g), Q_gen(g), alpha(g));
        end
        return;
    end
    
    % === Update daya generator (kecuali slack bus) untuk iterasi berikutnya ===
    for g = 1:ngen
        bus_g = gendata(g, 1);
        if busdata(bus_g, 2) ~= 1  % Bukan slack bus
            % Update P_scheduled di busdata
            busdata_dsb(bus_g, 3) = busdata(bus_g, 3) - P_gen_target(g);
            % (P_sch = P_gen - P_load, jadi P_load_effective = P_load_asli - P_gen_target)
        end
    end
end

iterasi = maks_iter;
fprintf('Distributed Slack Bus tidak konvergen setelah %d iterasi\n', maks_iter);

end
