function [V, sudut, iterasi, konvergen] = newton_raphson_pf(busdata, linedata, Ybus, tol, maks_iter)
% NEWTON_RAPHSON_PF  Aliran daya metode Newton-Raphson
%
% Input:
%   busdata   - data bus
%   linedata  - data saluran
%   Ybus      - matriks admitansi
%   tol       - toleransi konvergensi (misal 1e-6)
%   maks_iter - jumlah iterasi maksimum
%
% Output:
%   V         - magnitude tegangan tiap bus (p.u.)
%   sudut     - sudut fase tiap bus (radian)
%   iterasi   - jumlah iterasi yang dibutuhkan
%   konvergen - true jika konvergen

nbus = size(busdata, 1);
baseMVA = 100;

% === Inisialisasi ===
V     = busdata(:, 5);       % Magnitude tegangan awal
sudut = busdata(:, 6) * pi / 180;  % Sudut awal (rad)

% Tipe bus
tipe = busdata(:, 2);  % 1=Slack, 2=PV, 3=PQ

% Daya beban dan pembangkitan (dalam p.u.)
Pd = busdata(:, 3) / baseMVA;
Qd = busdata(:, 4) / baseMVA;

% Daya netto yang dijadwalkan (P_scheduled dan Q_scheduled)
% Untuk PV dan PQ: P_sch = Pgen - Pload
% Untuk PQ: Q_sch = Qgen - Qload
P_sch = -Pd;  % Awalnya hanya beban (generator di-set terpisah)
Q_sch = -Qd;

% Identifikasi bus
slack_bus = find(tipe == 1);
pv_bus   = find(tipe == 2);
pq_bus   = find(tipe == 3);

% Bus yang P-nya diupdate (PV + PQ)
bus_P = sort([pv_bus; pq_bus]);
% Bus yang Q-nya diupdate (hanya PQ)
bus_Q = pq_bus;

nP = length(bus_P);
nQ = length(bus_Q);

G = real(Ybus);
B = imag(Ybus);

fprintf('\n=== ITERASI NEWTON-RAPHSON ===\n');
fprintf('%-10s %-15s\n', 'Iterasi', 'Mismatch Maks');
fprintf('--------------------------------\n');

konvergen = false;

for iter = 1:maks_iter
    % === Hitung daya terhitung (P_calc, Q_calc) ===
    P_calc = zeros(nbus, 1);
    Q_calc = zeros(nbus, 1);
    
    for i = 1:nbus
        for j = 1:nbus
            P_calc(i) = P_calc(i) + V(i) * V(j) * ...
                (G(i,j) * cos(sudut(i) - sudut(j)) + B(i,j) * sin(sudut(i) - sudut(j)));
            Q_calc(i) = Q_calc(i) + V(i) * V(j) * ...
                (G(i,j) * sin(sudut(i) - sudut(j)) - B(i,j) * cos(sudut(i) - sudut(j)));
        end
    end
    
    % === Hitung mismatch ===
    dP = P_sch(bus_P) - P_calc(bus_P);
    dQ = Q_sch(bus_Q) - Q_calc(bus_Q);
    
    mismatch = [dP; dQ];
    maks_mismatch = max(abs(mismatch));
    
    fprintf('%-10d %-15.8f\n', iter, maks_mismatch);
    
    % === Cek konvergensi ===
    if maks_mismatch < tol
        konvergen = true;
        iterasi = iter;
        fprintf('KONVERGEN pada iterasi %d (mismatch = %.2e)\n', iter, maks_mismatch);
        return;
    end
    
    % === Bentuk Matriks Jacobian ===
    % J = [J1  J2]
    %     [J3  J4]
    
    J1 = zeros(nP, nP);  % dP/d(sudut)
    J2 = zeros(nP, nQ);  % dP/dV
    J3 = zeros(nQ, nP);  % dQ/d(sudut)
    J4 = zeros(nQ, nQ);  % dQ/dV
    
    % --- J1: dP/d(sudut) ---
    for m = 1:nP
        i = bus_P(m);
        for n = 1:nP
            j = bus_P(n);
            if i == j
                J1(m, n) = -Q_calc(i) - B(i,i) * V(i)^2;
            else
                J1(m, n) = V(i) * V(j) * ...
                    (G(i,j) * sin(sudut(i) - sudut(j)) - B(i,j) * cos(sudut(i) - sudut(j)));
            end
        end
    end
    
    % --- J2: dP/dV ---
    for m = 1:nP
        i = bus_P(m);
        for n = 1:nQ
            j = bus_Q(n);
            if i == j
                J2(m, n) = P_calc(i) / V(i) + G(i,i) * V(i);
            else
                J2(m, n) = V(i) * ...
                    (G(i,j) * cos(sudut(i) - sudut(j)) + B(i,j) * sin(sudut(i) - sudut(j)));
            end
        end
    end
    
    % --- J3: dQ/d(sudut) ---
    for m = 1:nQ
        i = bus_Q(m);
        for n = 1:nP
            j = bus_P(n);
            if i == j
                J3(m, n) = P_calc(i) - G(i,i) * V(i)^2;
            else
                J3(m, n) = -V(i) * V(j) * ...
                    (G(i,j) * cos(sudut(i) - sudut(j)) + B(i,j) * sin(sudut(i) - sudut(j)));
            end
        end
    end
    
    % --- J4: dQ/dV ---
    for m = 1:nQ
        i = bus_Q(m);
        for n = 1:nQ
            j = bus_Q(n);
            if i == j
                J4(m, n) = Q_calc(i) / V(i) - B(i,i) * V(i);
            else
                J4(m, n) = V(i) * ...
                    (G(i,j) * sin(sudut(i) - sudut(j)) - B(i,j) * cos(sudut(i) - sudut(j)));
            end
        end
    end
    
    % === Gabung Jacobian ===
    J = [J1  J2;
         J3  J4];
    
    % === Hitung koreksi ===
    koreksi = J \ mismatch;
    
    dSudut = koreksi(1:nP);
    dV     = koreksi(nP+1:end);
    
    % === Update variabel ===
    sudut(bus_P) = sudut(bus_P) + dSudut;
    V(bus_Q)     = V(bus_Q)     + dV;
end

% Jika sampai sini, tidak konvergen
iterasi = maks_iter;
konvergen = false;
fprintf('TIDAK KONVERGEN setelah %d iterasi\n', maks_iter);

end
