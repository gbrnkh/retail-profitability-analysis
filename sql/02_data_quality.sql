-- =============================================================================
-- 02_data_quality.sql: Audit Kualitas Data & Integritas Transaksi
-- Dialek: Kompatibel dengan ANSI SQL / SQLite / PostgreSQL
-- Tujuan:
-- Melakukan verifikasi menyeluruh terhadap kelengkapan data (null values),
-- keunikan kunci primer (duplikasi), urutan kronologis tanggal pengiriman,
-- serta kepatuhan batasan numerik (nilai penjualan, kuantitas, diskon).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Pemeriksaan Jumlah Baris dan Nilai Null pada Kolom Kritis
-- Penjelasan: Memastikan tidak ada nilai yang hilang (missing values) pada data transaksi.
-- Hasil yang diharapkan: Semua kolom bernilai 0 untuk penghitungan null.
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN row_id IS NULL THEN 1 ELSE 0 END) AS null_row_ids,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_dates,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_ids,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS null_sales,
    SUM(CASE WHEN profit IS NULL THEN 1 ELSE 0 END) AS null_profit,
    SUM(CASE WHEN discount IS NULL THEN 1 ELSE 0 END) AS null_discount
FROM orders;

-- -----------------------------------------------------------------------------
-- 2. Deteksi Duplikasi Data Transaksi
-- Penjelasan:
-- a) Memastikan kolom `row_id` benar-benar unik dan berfungsi sebagai Primary Key.
-- b) Memeriksa apakah terdapat duplikasi item produk dalam satu nomor pesanan yang sama.
-- -----------------------------------------------------------------------------
-- Pemeriksaan keunikan baris berdasarkan row_id (harus mengembalikan 0 baris)
SELECT 
    row_id, 
    COUNT(*) AS duplicate_count
FROM orders
GROUP BY row_id
HAVING COUNT(*) > 1;

-- Pemeriksaan duplikasi kombinasi pesanan dan produk (order_id + product_id)
SELECT 
    order_id, 
    product_id, 
    COUNT(*) AS line_duplicate_count
FROM orders
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

-- -----------------------------------------------------------------------------
-- 3. Validasi Integritas Tanggal Pengiriman
-- Penjelasan:
-- Secara logika bisnis, tanggal kirim (`ship_date`) tidak boleh terjadi sebelum
-- tanggal pemesanan (`order_date`). Query pertama harus mengembalikan nilai 0.
-- Query kedua digunakan untuk memeriksa rentang waktu seluruh data transaksi.
-- -----------------------------------------------------------------------------
-- Memastikan tidak ada pesanan dengan tanggal kirim tidak valid (ship_date < order_date)
SELECT 
    COUNT(*) AS invalid_shipping_dates
FROM orders
WHERE ship_date < order_date;

-- Mengetahui cakupan rentang tanggal pemesanan dan pengiriman
SELECT 
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order,
    MIN(ship_date)  AS earliest_shipment,
    MAX(ship_date)  AS latest_shipment
FROM orders;

-- -----------------------------------------------------------------------------
-- 4. Audit Nilai Batas Numerik (Rentang Nilai Minimum dan Maksimum)
-- Penjelasan:
-- Memeriksa sebaran statistik nilai numerik (sales, quantity, discount, profit)
-- untuk mendeteksi outlier ekstrem atau angka yang tidak masuk akal secara bisnis.
-- -----------------------------------------------------------------------------
SELECT 
    MIN(sales) AS min_sales,
    MAX(sales) AS max_sales,
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity,
    MIN(discount) AS min_discount,
    MAX(discount) AS max_discount,
    MIN(profit) AS min_profit,
    MAX(profit) AS max_profit
FROM orders;

-- -----------------------------------------------------------------------------
-- 5. Verifikasi Kepatuhan Aturan Bisnis (Business Rule Validation)
-- Penjelasan:
-- Memvalidasi batasan ketat:
-- - Nilai penjualan (`sales`) harus > 0 (tidak boleh ada penjualan gratis/negatif).
-- - Kuantitas unit (`quantity`) harus >= 1.
-- - Diskon (`discount`) harus berada pada rentang yang valid (antara 0% hingga 100%).
-- Hasil yang diharapkan: Semua kolom count mengembalikan angka 0.
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(CASE WHEN sales <= 0 THEN 1 END) AS invalid_sales_count,
    COUNT(CASE WHEN quantity <= 0 THEN 1 END) AS invalid_quantity_count,
    COUNT(CASE WHEN discount < 0 OR discount > 1 THEN 1 END) AS invalid_discount_count
FROM orders;
