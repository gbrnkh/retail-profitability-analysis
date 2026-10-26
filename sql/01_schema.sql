-- =============================================================================
-- 01_schema.sql: Definisi Skema Database Superstore
-- Dialek: Kompatibel dengan ANSI SQL / SQLite / PostgreSQL
-- Penjelasan:
-- File ini mendefinisikan struktur tabel utama `orders` beserta aturan validasi
-- (CHECK constraints) dan indeks performa untuk mempercepat query analitik.
-- =============================================================================

-- Hapus tabel jika sudah ada sebelumnya untuk inisialisasi ulang yang bersih
DROP TABLE IF EXISTS orders;

-- Pembuatan tabel transaksi retail (orders)
-- Setiap baris mewakili 1 item produk dalam suatu transaksi pesanan (line-item grain).
CREATE TABLE orders (
    row_id          INTEGER PRIMARY KEY,                           -- ID unik untuk setiap baris transaksi
    order_id        VARCHAR(25) NOT NULL,                          -- ID unik transaksi pesanan (dapat memuat beberapa produk)
    order_date      DATE NOT NULL,                                 -- Tanggal pelanggan melakukan pemesanan
    ship_date       DATE NOT NULL,                                 -- Tanggal pesanan dikirim ke pelanggan
    ship_mode       VARCHAR(25) NOT NULL,                          -- Layanan pengiriman (Standard, Second Class, First Class, Same Day)
    customer_id     VARCHAR(20) NOT NULL,                          -- ID unik pelanggan
    customer_name   VARCHAR(100) NOT NULL,                         -- Nama lengkap pelanggan
    segment         VARCHAR(25) NOT NULL,                          -- Segmen pelanggan (Consumer, Corporate, Home Office)
    country         VARCHAR(50) NOT NULL,                          -- Negara transaksi (United States)
    city            VARCHAR(50) NOT NULL,                          -- Kota tujuan pengiriman
    state           VARCHAR(50) NOT NULL,                          -- Negara bagian tujuan pengiriman
    postal_code     VARCHAR(20),                                   -- Kode pos pengiriman (5 digit string)
    region          VARCHAR(25) NOT NULL,                          -- Wilayah makro geografis (Central, East, South, West)
    product_id      VARCHAR(25) NOT NULL,                          -- ID unik produk
    category        VARCHAR(50) NOT NULL,                          -- Kategori utama produk (Furniture, Office Supplies, Technology)
    sub_category    VARCHAR(50) NOT NULL,                          -- Subkategori detail produk (Chairs, Tables, Phones, dll)
    product_name    VARCHAR(255) NOT NULL,                         -- Nama lengkap/deskripsi model produk
    sales           NUMERIC(12, 4) NOT NULL CHECK (sales > 0),     -- Nilai pendapatan kotor setelah diskon (harus > 0)
    quantity        INTEGER NOT NULL CHECK (quantity > 0),         -- Jumlah unit produk yang dibeli (minimal 1 unit)
    discount        NUMERIC(5, 4) NOT NULL CHECK (discount >= 0.0 AND discount <= 1.0), -- Tingkat diskon dalam desimal (0.00 hingga 1.00)
    profit          NUMERIC(12, 4) NOT NULL                        -- Laba bersih (profit) atau kerugian (nilai negatif) dari transaksi
);

-- =============================================================================
-- Indeks Performa untuk Akselerasi Query Analisis & Agregasi
-- =============================================================================

-- Indeks untuk mempercepat filter dan pengelompokan berdasarkan tanggal (tren bulanan/tahunan)
CREATE INDEX idx_orders_order_date ON orders(order_date);

-- Indeks gabungan untuk analisis performa regional dan per negara bagian
CREATE INDEX idx_orders_region_state ON orders(region, state);

-- Indeks untuk agregasi hirarki produk (kategori & subkategori)
CREATE INDEX idx_orders_category_subcat ON orders(category, sub_category);

-- Indeks untuk pelacakan perilaku pesanan per pelanggan
CREATE INDEX idx_orders_customer ON orders(customer_id);

-- Indeks untuk mempercepat identifikasi dan pemfilteran transaksi yang merugi (profit < 0)
CREATE INDEX idx_orders_profit ON orders(profit);
