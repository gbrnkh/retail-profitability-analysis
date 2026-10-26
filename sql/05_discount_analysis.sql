-- =============================================================================
-- 05_discount_analysis.sql: Efektivitas Diskon & Kebocoran Profit (Profit Leakage)
-- Dialek: Kompatibel dengan ANSI SQL / SQLite / PostgreSQL
-- Tujuan:
-- Menganalisis elastisitas margin pada berbagai tingkatan diskon (discount tiers),
-- mengukur besaran kerugian akibat pemberian diskon berlebih, membuktikan batas
-- kritis diskon 20% (The 20% Cliff), serta mendeteksi negara bagian dengan
-- kebocoran margin tertinggi.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Kinerja Berdasarkan Kelompok Diskon (Granular Discount Tiers)
-- Penjelasan:
-- Mengelompokkan transaksi ke dalam 6 tingkatan diskon untuk melihat korelasi
-- langsung antara persentase diskon dengan margin laba dan rasio transaksi merugi.
-- Terlihat jelas bahwa setelah diskon melewati 20%, margin runtuh menjadi negatif.
-- -----------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN discount = 0 THEN '1. Tanpa Diskon (0%)'
        WHEN discount <= 0.10 THEN '2. Rendah (0.01 - 10%)'
        WHEN discount <= 0.20 THEN '3. Moderat (10.01 - 20%)'
        WHEN discount <= 0.30 THEN '4. Tinggi (20.01 - 30%)'
        WHEN discount <= 0.50 THEN '5. Curam (30.01 - 50%)'
        ELSE '6. Ekstrem (> 50%)'
    END AS discount_tier,
    COUNT(*) AS transaction_count,                                                      -- Jumlah transaksi
    ROUND(SUM(sales), 2) AS total_sales,                                                -- Total penjualan ($)
    ROUND(SUM(profit), 2) AS total_profit,                                              -- Total laba ($)
    ROUND(AVG(profit), 2) AS avg_profit_per_line,                                       -- Rata-rata laba per baris pesanan ($)
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_pct,         -- Margin laba (%)
    ROUND(100.0 * SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_loss_making -- Persentase transaksi merugi (%)
FROM orders
GROUP BY 1
ORDER BY MIN(discount);

-- -----------------------------------------------------------------------------
-- 2. Kuantifikasi Kebocoran Profit: Transaksi Untung vs. Transaksi Buntung
-- Penjelasan:
-- Memisahkan transaksi menjadi 2 kubu: transaksi menghasilkan untung (profit >= 0)
-- dan transaksi merugi (profit < 0).
-- Mengungkap fakta empiris bahwa 18.72% transaksi merusak laba sebesar -$156.131
-- yang didorong oleh rata-rata diskon 48.1%.
-- -----------------------------------------------------------------------------
SELECT 
    CASE WHEN profit >= 0 THEN 'Transaksi Menguntungkan' ELSE 'Transaksi Merugi' END AS order_health,
    COUNT(*) AS transaction_count,                                                      -- Jumlah transaksi
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) AS share_of_transactions_pct, -- Pangsa transaksi (%)
    ROUND(SUM(sales), 2) AS total_sales,                                                -- Total penjualan ($)
    ROUND(100.0 * SUM(sales) / (SELECT SUM(sales) FROM orders), 2) AS share_of_sales_pct,      -- Pangsa penjualan ($)
    ROUND(SUM(profit), 2) AS net_profit_impact,                                         -- Dampak laba bersih ($)
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS margin_pct,                -- Margin laba (%)
    ROUND(AVG(discount) * 100.0, 2) AS avg_discount_pct                                 -- Rata-rata diskon yang diberikan (%)
FROM orders
GROUP BY CASE WHEN profit >= 0 THEN 'Transaksi Menguntungkan' ELSE 'Transaksi Merugi' END;

-- -----------------------------------------------------------------------------
-- 3. Aturan Ambang Batas Diskon 20% (The 20% Discount Cliff Rule)
-- Penjelasan:
-- Menguji batasan kebijakan diskon maksimal 20%.
-- Data membuktikan transaksi dengan diskon <= 20% menghasilkan margin sehat (+16.9%),
-- sedangkan transaksi dengan diskon > 20% menghasilkan margin hancur (-35.6%).
-- -----------------------------------------------------------------------------
SELECT 
    CASE WHEN discount <= 0.20 THEN 'Diskon <= 20% (Zona Aman)' ELSE 'Diskon > 20% (Zona Bahaya)' END AS discount_policy_segment,
    COUNT(*) AS total_rows,                                                             -- Total baris transaksi
    ROUND(SUM(sales), 2) AS total_revenue,                                              -- Total pendapatan ($)
    ROUND(SUM(profit), 2) AS net_profit,                                                -- Total laba bersih ($)
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_pct,         -- Persentase margin laba (%)
    ROUND(AVG(discount) * 100.0, 2) AS avg_discount_applied,                             -- Rata-rata diskon diterapkan (%)
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_rows,                           -- Jumlah transaksi merugi
    ROUND(100.0 * SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS loss_transaction_rate -- Rasio transaksi merugi (%)
FROM orders
GROUP BY CASE WHEN discount <= 0.20 THEN 'Diskon <= 20% (Zona Aman)' ELSE 'Diskon > 20% (Zona Bahaya)' END;

-- -----------------------------------------------------------------------------
-- 4. Pelanggaran Kebijakan Diskon per Negara Bagian (Top 10 State Leakage)
-- Penjelasan:
-- Menemukan 10 negara bagian yang mengalami kerugian profit terbesar akibat
-- praktik diskon diskresioner yang tidak terkontrol (seperti Texas, Pennsylvania, Illinois, Ohio).
-- -----------------------------------------------------------------------------
SELECT 
    state,
    region,
    COUNT(*) AS transaction_count,                                                      -- Jumlah transaksi di negara bagian
    ROUND(SUM(sales), 2) AS total_sales,                                                -- Total penjualan ($)
    ROUND(SUM(profit), 2) AS total_profit,                                              -- Total kerugian/laba bersih ($)
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_pct,         -- Persentase margin laba (%)
    ROUND(AVG(discount) * 100.0, 2) AS avg_discount_pct,                                 -- Rata-rata diskon di negara bagian (%)
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_rows,                           -- Jumlah transaksi merugi
    ROUND(100.0 * SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS loss_row_pct -- Persentase transaksi merugi (%)
FROM orders
GROUP BY state, region
HAVING SUM(profit) < 0
ORDER BY total_profit ASC
LIMIT 10;
