-- =============================================================================
-- 03_sales_kpi.sql: Analisis Performa Penjualan & KPI Eksekutif
-- Dialek: Kompatibel dengan ANSI SQL / SQLite / PostgreSQL
-- Tujuan:
-- Menghitung metrik performa tingkat tinggi (High-Level Corporate KPIs),
-- tren pertumbuhan bulanan (MoM), pertumbuhan tahunan (YoY),
-- serta kontribusi pendapatan dan laba bersih per kategori produk.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Ringkasan KPI Eksekutif Utama (Corporate Headline Metrics)
-- Penjelasan:
-- Menghitung total pendapatan, total laba bersih, margin laba keseluruhan (%),
-- jumlah transaksi pesanan unik, jumlah pelanggan unik, total unit terjual,
-- rata-rata nilai pesanan (Average Order Value / AOV), dan rata-rata diskon.
-- -----------------------------------------------------------------------------
SELECT 
    ROUND(SUM(sales), 2) AS total_revenue,                                              -- Total pendapatan kotor ($)
    ROUND(SUM(profit), 2) AS total_profit,                                              -- Total laba bersih ($)
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS overall_profit_margin_pct, -- Persentase margin laba bersih (%)
    COUNT(DISTINCT order_id) AS total_orders,                                           -- Jumlah pesanan unik
    COUNT(DISTINCT customer_id) AS total_customers,                                     -- Jumlah pelanggan unik
    SUM(quantity) AS total_units_sold,                                                  -- Total kuantitas barang terjual
    ROUND(SUM(sales) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_order_value,      -- Nilai rata-rata per transaksi ($)
    ROUND(AVG(discount) * 100.0, 2) AS avg_discount_pct                                 -- Rata-rata tingkat diskon yang diberikan (%)
FROM orders;

-- -----------------------------------------------------------------------------
-- 2. Tren Penjualan & Laba Bulanan Menggunakan Window Function (Pertumbuhan MoM)
-- Penjelasan:
-- Query ini mengagregasi data berdasarkan tahun-bulan (`year_month`), lalu menggunakan
-- fungsi jendela `LAG()` untuk membandingkan penjualan bulan berjalan terhadap bulan
-- sebelumnya guna mendapatkan persentase pertumbuhan bulanan (Month-over-Month / MoM).
-- Berguna untuk mengidentifikasi lonjakan musiman (seasonality) seperti Q4 Holiday Season.
-- -----------------------------------------------------------------------------
WITH monthly_metrics AS (
    SELECT 
        SUBSTR(order_date, 1, 7) AS year_month,                                         -- Format YYYY-MM
        ROUND(SUM(sales), 2) AS monthly_sales,
        ROUND(SUM(profit), 2) AS monthly_profit,
        COUNT(DISTINCT order_id) AS monthly_orders,
        ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS monthly_margin_pct
    FROM orders
    GROUP BY SUBSTR(order_date, 1, 7)
)
SELECT 
    year_month,
    monthly_sales,
    monthly_profit,
    monthly_margin_pct,
    monthly_orders,
    LAG(monthly_sales) OVER (ORDER BY year_month) AS prev_month_sales,                  -- Nilai penjualan bulan sebelumnya
    ROUND(
        100.0 * (monthly_sales - LAG(monthly_sales) OVER (ORDER BY year_month)) / 
        NULLIF(LAG(monthly_sales) OVER (ORDER BY year_month), 0), 
        2
    ) AS mom_sales_growth_pct                                                           -- Persentase pertumbuhan penjualan MoM (%)
FROM monthly_metrics
ORDER BY year_month;

-- -----------------------------------------------------------------------------
-- 3. Performa Tahunan & Pertumbuhan Laba/Penjualan (YoY Growth)
-- Penjelasan:
-- Mengukur pertumbuhan bisnis dari tahun ke tahun (Year-over-Year / YoY)
-- untuk melihat ekspansi pendapatan (`annual_sales`) dan konsistensi perolehan laba
-- bersih (`annual_profit`).
-- -----------------------------------------------------------------------------
WITH yearly_metrics AS (
    SELECT 
        SUBSTR(order_date, 1, 4) AS order_year,                                         -- Ekstraksi tahun pemesanan (YYYY)
        ROUND(SUM(sales), 2) AS annual_sales,
        ROUND(SUM(profit), 2) AS annual_profit,
        ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_pct,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    GROUP BY SUBSTR(order_date, 1, 4)
)
SELECT 
    order_year,
    annual_sales,
    annual_profit,
    profit_margin_pct,
    total_orders,
    ROUND(
        100.0 * (annual_sales - LAG(annual_sales) OVER (ORDER BY order_year)) / 
        NULLIF(LAG(annual_sales) OVER (ORDER BY order_year), 0), 
        2
    ) AS yoy_sales_growth_pct,                                                          -- Pertumbuhan penjualan YoY (%)
    ROUND(
        100.0 * (annual_profit - LAG(annual_profit) OVER (ORDER BY order_year)) / 
        NULLIF(LAG(annual_profit) OVER (ORDER BY order_year), 0), 
        2
    ) AS yoy_profit_growth_pct                                                          -- Pertumbuhan laba bersih YoY (%)
FROM yearly_metrics
ORDER BY order_year;

-- -----------------------------------------------------------------------------
-- 4. Pangsa Kontribusi Kategori Produk terhadap Total Penjualan & Laba
-- Penjelasan:
-- Membandingkan kontribusi tiap kategori produk (Technology, Furniture, Office Supplies)
-- terhadap keseluruhan portofolio perusahaan menggunakan CROSS JOIN dengan CTE `totals`.
-- Mengungkap kategori yang menyumbang penjualan besar tetapi margin tipis/rendah.
-- -----------------------------------------------------------------------------
WITH totals AS (
    SELECT SUM(sales) AS grand_sales, SUM(profit) AS grand_profit FROM orders
)
SELECT 
    o.category,
    ROUND(SUM(o.sales), 2) AS category_sales,
    ROUND(100.0 * SUM(o.sales) / t.grand_sales, 2) AS sales_share_pct,                  -- Persentase kontribusi penjualan (%)
    ROUND(SUM(o.profit), 2) AS category_profit,
    ROUND(100.0 * SUM(o.profit) / t.grand_profit, 2) AS profit_share_pct,                -- Persentase kontribusi laba (%)
    ROUND(100.0 * SUM(o.profit) / NULLIF(SUM(o.sales), 0), 2) AS profit_margin_pct      -- Margin laba kategori (%)
FROM orders o
CROSS JOIN totals t
GROUP BY o.category, t.grand_sales, t.grand_profit
ORDER BY category_sales DESC;
