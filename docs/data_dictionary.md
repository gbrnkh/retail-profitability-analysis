# Kamus Data (Data Dictionary): Superstore Orders

Dokumen ini merinci skema, definisi, rentang nilai yang valid, serta transformasi yang diterapkan pada setiap kolom di dalam file `data/processed/Sample_Superstore_Cleaned_Final.csv`.

| Nama Kolom (Column Name) | Tipe Data | Deskripsi | Contoh Nilai | Aturan Bisnis & Batasan (Constraints) |
| :--- | :--- | :--- | :--- | :--- |
| `row_id` | Integer | Pengenal unik untuk setiap baris transaksi | `1`, `9994` | Primary key baris; bilangan bulat berurutan |
| `order_id` | String | Pengenal unik untuk suatu transaksi pesanan | `CA-2016-152156` | Format: `[Negara/Kurir]-[Tahun]-[6 digit]` |
| `order_date` | Date (YYYY-MM-DD) | Tanggal pelanggan melakukan pemesanan | `2016-11-08` | Rentang: `2014-01-03` hingga `2017-12-30` |
| `ship_date` | Date (YYYY-MM-DD) | Tanggal pesanan dikirimkan | `2016-11-11` | Harus `>= order_date` |
| `ship_mode` | String | Kelas / metode layanan pengiriman | `Standard Class`, `Second Class`, `First Class`, `Same Day` | Standard Class paling dominan (~60%) |
| `customer_id` | String | Pengenal unik untuk setiap pelanggan | `CG-12520` | Format: `[Inisial]-[5 digit]` |
| `customer_name`| String | Nama lengkap pelanggan | `Claire Gute` | Dibersihkan dari spasi yang tidak perlu |
| `segment` | String | Segmen klasifikasi bisnis pelanggan | `Consumer`, `Corporate`, `Home Office` | Consumer adalah segmen terbesar |
| `country` | String | Negara lokasi terjadinya transaksi | `United States` | Nilai tunggal: United States |
| `city` | String | Kota tujuan pengiriman | `Henderson`, `Los Angeles` | Format title case terstandarisasi |
| `state` | String | Negara bagian tujuan pengiriman | `California`, `Texas`, `New York` | Mencakup 49 negara bagian (termasuk DC) |
| `postal_code` | String | Kode pos 5 digit di AS | `42420`, `90036` | Ditambahkan angka nol di depan jika diperlukan; disimpan sebagai string |
| `region` | String | Wilayah makro geografis pelaporan | `Central`, `East`, `South`, `West` | 4 wilayah teritori utama |
| `product_id` | String | Pengenal unik untuk setiap produk | `FUR-BO-10001798` | Format: `[KATEGORI]-[SUBKAT]-[8 digit]` |
| `category` | String | Kategori produk tingkat atas | `Furniture`, `Office Supplies`, `Technology` | 3 kategori produk utama |
| `sub_category` | String | Klasifikasi produk terperinci | `Bookcases`, `Chairs`, `Storage`, `Phones` | 17 subkategori produk |
| `product_name` | String | Deskripsi / nama model barang | `Bush Somerset Collection Bookcase` | Teks yang telah dibersihkan |
| `sales` | Float | Nilai pendapatan kotor setelah diskon | `261.96` | Mata uang USD ($). Wajib bernilai positif (> 0) |
| `quantity` | Integer | Jumlah unit barang yang dibeli | `2`, `5`, `9` | Bilangan bulat `>= 1` |
| `discount` | Float | Tingkat diskon dalam bentuk desimal | `0.00`, `0.20`, `0.70` | Rentang: `0.00` (0%) hingga `0.80` (80%) |
| `profit` | Float | Laba bersih atau rugi dari baris transaksi | `41.91`, `-383.03` | Mata uang USD ($). Bisa bernilai negatif (rugi) |

---

## Rumus Metrik Turunan (Derived Metrics)
- **Margin Laba / Profit Margin (%)**: `(profit / sales) * 100`
- **Perkiraan Biaya Pokok (Estimated COGS)**: `sales - profit`
- **Harga Asli Sebelum Diskon (List Price)**: `sales / (1 - discount)`
- **Besaran Nilai Diskon Efektif (Discount Loss Amount)**: `List Price * discount`
