# Direktori Data Mentah (Raw Data)

## Informasi Dataset
- **Nama Dataset**: Sample Superstore Dataset (Retail AS)
- **Sumber Asli**: 
  - [Kaggle - Superstore Dataset Final](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final)
  - [CSVbase - Sample Superstore](https://csvbase.com/djkoogy/Sample-Superstore)
- **Domain**: Penjualan Retail, Logistik, dan Analisis Profitabilitas
- **Granularitas**: Tingkat baris transaksi per item (setiap baris mewakili produk spesifik dalam suatu pesanan)
- **Total Baris Data (Asli)**: 9.994 baris
- **Periode Waktu**: 2014 – 2017

## Kebijakan Penyimpanan Data
File data transaksional mentah dan file biner berukuran besar dikecualikan dari version control melalui `.gitignore` untuk menjaga ukuran repositori tetap ringan. Untuk mereproduksi analisis ini:
1. Unduh file CSV mentah dari tautan sumber di atas.
2. Tempatkan file mentah tersebut di direktori ini (`data/raw/Sample - Superstore.csv`).
3. Jalankan notebook `notebooks/01_data_quality_and_cleaning.ipynb` untuk membersihkan, menstandarisasi, dan mengekspor data yang telah diproses ke `data/processed/Sample_Superstore_Cleaned_Final.csv`.
