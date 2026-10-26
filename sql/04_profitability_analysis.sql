-- =============================================================================
-- 04_profitability_analysis.sql: Analisis Mendalam Profitabilitas (Profitability Deep Dive)
-- Dialek: Kompatibel dengan ANSI SQL / SQLite / PostgreSQL
-- Tujuan:
-- Mengevaluasi kinerja margin pada tingkat subkategori, mengidentifikasi produk
-- penghancur nilai (loss-making), memetakan matriks margin regional, serta
-- menentukan 10 produk paling menguntungkan dan 10 produk paling merugikan.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Peringkat Profitabilitas Subkategori & Perbandingan Margin
-- Penjelasan:
-- Mengagregasi data berdasarkan kategori dan subkategori untuk melihat subkategori
-- mana yang menghasilkan laba bersih positif versus yang mengalami kerugian bersih.
-- Diurutkan dari laba terendah (paling merugi) ke tertinggi.
-- Juga menghitung rasio transaksi merugi (`loss_rate_pct`).
-- -----------------------------------------------------------------------------
SELECT 
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,                                                -- Total nilai penjualan ($)
    ROUND(SUM(profit), 2) AS total_profit,                                              -- Total laba bersih ($)
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_pct,         -- Margin laba bersih (%)
    ROUND(AVG(discount) * 100.0, 2) AS avg_discount_pct,                                 -- Rata-rata diskon yang diberikan (%)
    COUNT(*) AS total_transactions,                                                     -- Jumlah baris transaksi
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_transactions,                   -- Jumlah transaksi yang mengalami kerugian
    ROUND(100.0 * SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS loss_rate_pct -- Persentase transaksi merugi (%)
FROM orders
GROUP BY category, sub_category
ORDER BY total_profit ASC;

-- -----------------------------------------------------------------------------
-- 2. Kinerja & Perbandingan Profitabilitas Regional
-- Penjelasan:
-- Menilai performa profitabilitas di 4 wilayah utama (Central, East, South, West).
-- Membantu manajemen mendeteksi wilayah yang mengalami inefisiensi margin akibat
-- rata-rata diskon yang terlalu agresif (seperti wilayah Central).
-- -----------------------------------------------------------------------------
SELECT 
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_pct,
    ROUND(AVG(discount) * 100.0, 2) AS avg_discount_pct,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_transactions
FROM orders
GROUP BY region
ORDER BY total_profit DESC;

-- -----------------------------------------------------------------------------
-- 3. Matriks Silang Kategori x Wilayah (Persentase Margin Laba)
-- Penjelasan:
-- Menggunakan agregasi kondisional (`CASE WHEN`) untuk membentuk tabel silang (pivot table)
-- margin laba per kategori di setiap wilayah dan membandingkannya dengan rata-rata nasional.
-- Menyoroti secara jelas jika suatu kategori merugi di wilayah tertentu (misal: Furniture di Central).
-- -----------------------------------------------------------------------------
SELECT 
    category,
    ROUND(100.0 * SUM(CASE WHEN region = 'Central' THEN profit ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN region = 'Central' THEN sales ELSE 0 END), 0), 2) AS central_margin_pct,
    ROUND(100.0 * SUM(CASE WHEN region = 'East' THEN profit ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN region = 'East' THEN sales ELSE 0 END), 0), 2) AS east_margin_pct,
    ROUND(100.0 * SUM(CASE WHEN region = 'South' THEN profit ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN region = 'South' THEN sales ELSE 0 END), 0), 2) AS south_margin_pct,
    ROUND(100.0 * SUM(CASE WHEN region = 'West' THEN profit ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN region = 'West' THEN sales ELSE 0 END), 0), 2) AS west_margin_pct,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS national_margin_pct
FROM orders
GROUP BY category
ORDER BY national_margin_pct DESC;

-- -----------------------------------------------------------------------------
-- 4. Profitabilitas Berdasarkan Segmen Pelanggan
-- Penjelasan:
-- Membandingkan kontribusi pendapatan, laba, dan margin di 3 segmen:
-- Consumer, Corporate, dan Home Office.
-- -----------------------------------------------------------------------------
SELECT 
    segment,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_pct,
    ROUND(AVG(discount) * 100.0, 2) AS avg_discount_pct
FROM orders
GROUP BY segment
ORDER BY total_profit DESC;

-- -----------------------------------------------------------------------------
-- 5. 10 Produk Paling Merugikan (Top 10 Worst Performing Products)
-- Penjelasan:
-- Mengidentifikasi SKU spesifik yang menghasilkan akumulasi kerugian terbesar
-- bagi perusahaan. Produk-produk ini menjadi kandidat utama untuk evaluasi harga,
-- negosiasi biaya pengadaan vendor, atau delisting.
-- -----------------------------------------------------------------------------
SELECT 
    product_name,
    category,
    sub_category,
    COUNT(*) AS times_sold,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(discount) * 100.0, 2) AS avg_discount_pct
FROM orders
GROUP BY product_name, category, sub_category
HAVING SUM(profit) < 0
ORDER BY total_profit ASC
LIMIT 10;

-- -----------------------------------------------------------------------------
-- 6. 10 Produk Paling Menguntungkan (Top 10 Most Profitable Products)
-- Penjelasan:
-- Mengidentifikasi produk-produk unggulan (champion products) dengan margin
-- dan kontribusi laba absolut tertinggi untuk dipertahankan ketersediaannya
-- dan dijadikan prioritas promosi/bundling.
-- -----------------------------------------------------------------------------
SELECT 
    product_name,
    category,
    sub_category,
    COUNT(*) AS times_sold,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_pct
FROM orders
GROUP BY product_name, category, sub_category
ORDER BY total_profit DESC
LIMIT 10;
