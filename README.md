# Analisis Kinerja Penjualan Retail & Profitabilitas
### *Mengungkap Kebocoran Profit (Profit Leakage) & Inefisiensi Diskon dalam Operasional Retail*

---

## 1. Ringkasan Eksekutif & Skenario Bisnis

Sebuah perusahaan ritel nasional yang beroperasi di Amerika Serikat menghasilkan pendapatan kotor sebesar **\$2.297.200,86** dari **9.994 baris transaksi** (5.009 pesanan unik) dengan laba bersih perusahaan sebesar **\$286.397,02** (margin keseluruhan **12,47%**).

Meskipun pertumbuhan pendapatan kotor terlihat sehat, audit profitabilitas mendalam mengungkap **kebocoran laba yang sangat masif**:
- **8.123 transaksi menguntungkan (81,28%)** menghasilkan laba **\$442.528,31** dengan rata-rata diskon hanya **8,1%**.
- **1.871 transaksi merugi (18,72%)** menghancurkan laba bersih sebesar **-\$156.131,29** dengan rata-rata diskon mencapai **48,1%**.
- **Akar Permasalahan**: Praktik diskon berlebihan yang melampaui batas toleransi, dikombinasikan dengan subsidi pengiriman gratis untuk barang furnitur berukuran besar (Tables dan Bookcases), menciptakan siklus negatif yang mengikis lebih dari **35,3% potensi laba kotor**.

Dengan menerapkan batas diskon bertingkat (governance cap), restrukturisasi biaya pengiriman barang berat, serta penyelarasan insentif tim sales berbasis margin, perusahaan diproyeksikan dapat memulihkan keuntungan sebesar **+\$95.000 hingga +\$115.000 per tahun**, yang akan mendongkrak laba bersih perusahaan sebesar **+33% hingga +40%**.

---

## 2. Pertanyaan Bisnis Utama yang Terjawab

| Area Fokus | Pertanyaan Strategis | Temuan Empiris Data |
| :--- | :--- | :--- |
| **Kinerja Penjualan** | Bagaimana tren penjualan dan apa pendorong utamanya? | CAGR 2014–2017 sebesar **20,4%**. Kuartal 4 (Q4) selalu menjadi puncak musiman (~33% dari penjualan tahunan) yang didorong oleh promo liburan akhir tahun. |
| **Profitabilitas** | Kategori dan subkategori mana yang menciptakan nilai riil? | **Technology** mencatatkan laba tertinggi (\$145,5 Ribu, margin 17,4%), dipimpin oleh **Copiers** (margin 32,3%) dan **Phones** (laba \$44,5 Ribu). Sebaliknya, **Tables** mencatat rugi bersih **-\$17.725,48** (margin -8,56%). |
| **Kebocoran & Diskon** | Pada ambang batas diskon berapa transaksi mulai merusak nilai bisnis? | **Jurang Batas 20% (The 20% Cliff)**: Transaksi dengan diskon <= 20% menghasilkan rata-rata margin +11,6% hingga +29,5%. Namun, pesanan dengan diskon > 20% runtuh ke margin negatif **-10,1% hingga -48,2%**. |
| **Variansi Regional** | Mengapa wilayah Central tertinggal jauh dibanding West dan East? | **Wilayah Central** memiliki margin terendah (**7,92%**) dan rata-rata diskon tertinggi (**24,0%**), yang dipicu oleh kerugian parah di negara bagian **Texas** (-\$25,7 Ribu) dan **Illinois** (-\$12,6 Ribu). |

---

## 3. Struktur & Arsitektur Repositori

```text
retail-profitability-analysis/
├── README.md                               # Ringkasan proyek, metodologi, temuan kunci & panduan
├── requirements.txt                        # Dependensi paket Python (Streamlit, Plotly, Pandas, dll.)
├── app.py                                  # Dashboard web analitik interaktif berbasis Streamlit
├── .gitignore                              # Aturan pengabaian file Git untuk environment dan cache
├── data/
│   ├── raw/
│   │   └── README.md                       # Asal-usul data sumber mentah & panduan unduh
│   └── processed/
│       ├── .gitkeep                        # Penjaga direktori Git
│       ├── Sample_Superstore_Cleaned_Final.csv  # Dataset 9.994 baris yang telah dibersihkan & terstandarisasi
│       └── superstore.db                   # Database SQLite terindeks untuk query SQL langsung
├── notebooks/
│   ├── 01_data_quality_and_cleaning.ipynb  # Audit missing value, validasi batasan, pipeline pembersihan
│   └── 02_profitability_analysis.ipynb     # Analisis eksploratif (EDA), diagnosis diskon & grafik visual
├── sql/
│   ├── 01_schema.sql                       # Definisi tabel, aturan validasi (constraints) & indeks
│   ├── 02_data_quality.sql                 # Query audit kualitas dan validasi kepatuhan data
│   ├── 03_sales_kpi.sql                    # KPI eksekutif, tren MoM bulanan & pertumbuhan YoY
│   ├── 04_profitability_analysis.sql       # Peringkat subkategori, matriks margin regional silang
│   └── 05_discount_analysis.sql            # Kelompok diskon, kuantifikasi kebocoran profit & analisis negara bagian
└── docs/
    ├── data_dictionary.md                  # Spesifikasi lengkap kolom dan definisi kamus data
    └── business_recommendations.md         # Rekomendasi strategi eksekutif, tata kelola & mitigasi risiko
```

---

## 4. Rincian Analisis Komprehensif (Roadmap 5 Hari)

### Hari 1: Validasi Kualitas Data & Penjaminan Mutu (QA)
- **Audit Integritas Data**: Memeriksa seluruh 9.994 baris untuk memastikan tidak ada nilai null, tidak ada duplikasi data, dan integritas tanggal pengiriman valid (`ship_date >= order_date`).
- **Standardisasi**: Mengonversi semua nama kolom ke format standar huruf kecil `snake_case`. Menstandarisasi format kode pos sebagai string 5 digit.
- **Verifikasi Batasan**: Memverifikasi bahwa 100% data transaksi mematuhi batasan aturan bisnis (`sales > 0`, `quantity >= 1`, `0.0 <= discount <= 0.8`).
- **File Output**: [`01_data_quality_and_cleaning.ipynb`](notebooks/01_data_quality_and_cleaning.ipynb) dan [`data_dictionary.md`](docs/data_dictionary.md).

### Hari 2: Analisis SQL Terstruktur
Agregasi data dijalankan menggunakan ANSI SQL dengan Common Table Expressions (CTE), fungsi jendela (window functions), dan agregasi kondisional:
```sql
-- Jurang Batas Diskon 20% (dari sql/05_discount_analysis.sql)
SELECT 
    CASE 
        WHEN discount = 0 THEN '1. Tanpa Diskon (0%)'
        WHEN discount <= 0.10 THEN '2. Rendah (0.01 - 10%)'
        WHEN discount <= 0.20 THEN '3. Moderat (10.01 - 20%)'
        WHEN discount <= 0.30 THEN '4. Tinggi (20.01 - 30%)'
        ELSE '5. Curam (> 30%)'
    END AS discount_tier,
    COUNT(*) AS transaction_rows,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_pct
FROM orders
GROUP BY 1
ORDER BY MIN(discount);
```
**Hasil Query SQL**:
| Kelompok Diskon | Jumlah Transaksi | Total Penjualan ($) | Total Laba ($) | Margin Laba (%) |
| :--- | :--- | :--- | :--- | :--- |
| **0% (Harga Penuh)** | 4.798 | \$1.077.885,64 | +\$318.174,15 | **+29,51%** |
| **>0% - 10%** | 94 | \$54.498,44 | +\$9.049,52 | **+16,61%** |
| **>10% - 20%** | 3.709 | \$791.956,89 | +\$91.767,14 | **+11,58%** |
| **>20% - 30%** | 227 | \$103.191,24 | -\$10.368,61 | **-10,05%** |
| **>30% (Diskon Curam)** | 1.166 | \$269.668,65 | -\$122.225,18 | **-48,16%** |

### Hari 3: Analisis Data Eksploratif (EDA) & Diagnosis Kebocoran Profit
Dianalisis dalam [`notebooks/02_profitability_analysis.ipynb`](notebooks/02_profitability_analysis.ipynb):
1. **Penghancuran Nilai pada Subkategori Tertentu**:
   - **Tables**: Penjualan kotor \$206,9 Ribu menghasilkan rugi bersih **-\$17.725,48** (margin -8,56%). Sebanyak 63,6% transaksi meja dijual dalam keadaan rugi.
   - **Bookcases**: Penjualan kotor \$114,9 Ribu menghasilkan kerugian **-\$3.472,56** (margin -3,02%).
   - **Supplies**: Penjualan kotor \$46,7 Ribu menghasilkan kerugian **-\$1.189,10** (margin -2,55%).
2. **Ketimpangan Regional & Wilayah Mengalami Kerugian Besar**:
   - Wilayah Central sangat terbebani oleh pemberian diskon promosi berlebihan (rata-rata diskon 24,0%).
   - Negara bagian paling merugikan: **Texas** mencatat rugi **-\$25.729,39** dari penjualan \$170,2 Ribu (margin -15,12%; rata-rata diskon 37,0%).
   - Terburuk kedua: **Pennsylvania** rugi **-\$15.559,96** (margin -13,35%; rata-rata diskon 32,9%).

### Hari 4: Pengembangan Dashboard Web Interaktif Streamlit
Aplikasi web analitik responsif dibangun dalam file [`app.py`](app.py) menggunakan **Streamlit** dan **Plotly**:
- **Tab Ringkasan Eksekutif**: Kartu metrik KPI dinamis, grafik pergerakan penjualan & profit bulanan interaktif, kontribusi kategori, dan profitabilitas regional.
- **Tab Diagnosis Kebocoran Profit**: Peringkat laba bersih per subkategori (menyorot Tables & Bookcases dengan warna merah), scatter plot diskon vs. laba, serta visualisasi batas kritis diskon 20%.
- **Tab Simulator Kebijakan Diskon (What-If)**: Slider simulasi batas maksimum diskon yang secara dinamis menghitung potensi pengembalian laba bersih dan peningkatan margin.
- **Sandbox Query SQL Terintegrasi**: Terminal query SQLite langsung di dalam browser yang memungkinkan pengguna menjalankan query analitis SQL khusus.

```bash
# Menjalankan dashboard web interaktif
streamlit run app.py
```

### Hari 5: Rekomendasi Bisnis Strategis

#### 1. Terapkan Matriks Persetujuan Diskon Berjenjang (Batas Maksimal 20%)
- **Kebijakan**: Batasi diskon diskresioner tim sales maksimal **15%**. Diskon **15,1%–20%** wajib disetujui Manajer Penjualan. Diskon **> 20%** wajib mendapatkan persetujuan VP Sales dengan skema bundling margin-netral.
- **Dampak Finansial**: Mengeliminasi diskon non-strategis di atas 20% menyelamatkan **\$95.000–\$115.000** per tahun.

#### 2. Restrukturisasi Pengiriman & Pemenuhan Furnitur Besar
- **Kebijakan**: Hentikan subsidi "Gratis Ongkir" untuk Tables dan Bookcases yang diberi harga diskon. Terapkan biaya tambahan pengiriman kargo ($25–$50) untuk barang berat/besar.
- **Rasionalisasi Pemasok**: Negosiasikan ulang harga grosir dengan vendor (misal: *Chromcraft*, *Bretford*); delist produk yang konsisten merugi.
- **Dampak Finansial**: Mengubah performa Tables dari margin -8,6% ke titik impas (break-even) langsung mengembalikan keuntungan **\$17.700+** per tahun ke EBITDA.

#### 3. Alihkan Skema Insentif Penjualan Regional dari Volume ke Margin Laba
- **Kebijakan**: Di wilayah Central (Texas, Illinois) dan East (Pennsylvania, Ohio), gantikan bonus target kuota omzet kotor menjadi **Kontribusi Dolar Margin Laba Kotor (Gross Margin Dollars)**.
- **Dampak Finansial**: Meningkatkan margin wilayah Central dari 7,92% menjadi setara rata-rata nasional (12,5%) menghasilkan tambahan laba sebesar **\$22.900+**.

---

## 5. Dashboard Web Interaktif Streamlit

Proyek ini dilengkapi dengan aplikasi dashboard web interaktif yang siap dijalankan dengan **Streamlit** dan **Plotly** (`app.py`), memberikan antarmuka visual analisis data modern dan intuitif.

### Kemampuan Utama:
- **Ringkasan Eksekutif**: Kartu metrik KPI dinamis, grafik tren bulanan interaktif, performa kategori, dan pencapaian laba regional.
- **Diagnosis Kebocoran Profitabilitas**: Peringkat subkategori (menyoroti Tables & Bookcases dalam warna merah), scatter plot hubungan tingkat diskon vs. laba, serta analisis jurang batas diskon 20%.
- **Simulator What-If Interaktif**: Slider penyesuaian batas toleransi diskon maksimal (0% hingga 50%) untuk mengkalkulasi proyeksi pemulihan laba dan perbaikan margin secara langsung.
- **Sandbox Analisis SQL**: Editor SQL SQLite terintegrasi untuk mengeksekusi query khusus langsung di browser tanpa instalasi DBMS terpisah.
- **Filter Dinamis & Ekspor Data**: Filter tanggal, wilayah, kategori, segmen pelanggan, dan rentang diskon di bilah samping (sidebar), lengkap dengan tombol unduh data CSV yang telah difilter.

```bash
# Menjalankan Dashboard Streamlit
streamlit run app.py
```

---

## 6. Cara Menjalankan Proyek Secara Lokal

### Prasyarat
- Python 3.10+
- SQLite3
- Peramban Web (Google Chrome, Microsoft Edge, Mozilla Firefox)

### Panduan Instalasi & Eksekusi
```bash
# 1. Clone repositori ini
git clone https://github.com/your-username/retail-profitability-analysis.git
cd retail-profitability-analysis

# 2. Buat dan aktifkan virtual environment
python -m venv venv
# Pada Windows:
.\venv\Scripts\activate
# Pada macOS/Linux:
source venv/bin/activate

# 3. Pasang seluruh dependensi yang diperlukan
pip install -r requirements.txt

# 4. Jalankan dashboard analitik Streamlit
streamlit run app.py
```

### Menjalankan Query SQL melalui Python
```python
import sqlite3
import pandas as pd

conn = sqlite3.connect('data/processed/superstore.db')
with open('sql/03_sales_kpi.sql', encoding='utf-8') as f:
    queries = f.read().split(';')
print(pd.read_sql(queries[0], conn))
```

---

## 7. Daftar Kesiapan Portofolio (Portfolio Checklist)

- [x] **Audit Kualitas Data & Pembersihan**: CSV bersih telah diverifikasi; audit missing values, duplikasi, dan validasi aturan bisnis selesai di `notebooks/01_data_quality_and_cleaning.ipynb`.
- [x] **Rangkaian Script SQL Terstruktur**: 5 skrip SQL lengkap mencakup skema, kualitas data, KPI penjualan, profitabilitas, dan analisis diskon di folder `sql/`.
- [x] **Validasi Silang (Cross-Validation)**: Keselarasan agregasi data 100% identik antara hasil eksekusi SQL dan analisis Python Pandas.
- [x] **Notebook EDA Interaktif**: Notebook Jupyter dengan narasi, visualisasi, metrik, dan sorotan temuan bisnis dalam Bahasa Indonesia di `notebooks/02_profitability_analysis.ipynb`.
- [x] **Dashboard Streamlit Interaktif**: Aplikasi web penuh dengan filter dinamis, simulator what-if, dan SQL query sandbox di `app.py`.
- [x] **Bukti Data Empiris**: Angka data riil yang presisi (8.123 transaksi untung vs 1.871 transaksi rugi, kebocoran margin -$156,1 Ribu, batas kritis diskon 20%).
- [x] **Rekomendasi Bisnis Terukur**: 3 rekomendasi prioritas dengan estimasi nilai pengembalian finansial (ROI) dan keterbatasan analisis di `docs/business_recommendations.md`.
