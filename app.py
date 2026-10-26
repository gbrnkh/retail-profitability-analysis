import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime
import sqlite3
import os

# ==============================================================================
# 1. KONFIGURASI HALAMAN & STYLING TAMPILAN
# ==============================================================================
st.set_page_config(
    page_title="Analisis Kinerja Penjualan & Profitabilitas Retail",
    page_icon="📈",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS untuk kartu metrik eksekutif dan tampilan visual modern
st.markdown("""
<style>
    .main-header {
        font-size: 2.1rem;
        font-weight: 800;
        color: #1E293B;
        margin-bottom: 0.2rem;
    }
    .sub-header {
        font-size: 1.05rem;
        color: #64748B;
        margin-bottom: 1.5rem;
    }
    .kpi-card {
        background: #FFFFFF;
        padding: 1.2rem;
        border-radius: 10px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06);
        border-left: 5px solid #3B82F6;
        margin-bottom: 1rem;
    }
    .kpi-title {
        font-size: 0.85rem;
        font-weight: 600;
        color: #64748B;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }
    .kpi-value {
        font-size: 1.8rem;
        font-weight: 800;
        color: #0F172A;
        margin: 0.2rem 0;
    }
    .kpi-subtitle {
        font-size: 0.8rem;
        color: #10B981;
        font-weight: 600;
    }
    .kpi-card-danger {
        border-left-color: #EF4444 !important;
    }
    .kpi-card-warning {
        border-left-color: #F59E0B !important;
    }
    .kpi-card-success {
        border-left-color: #10B981 !important;
    }
    .metric-pill {
        display: inline-block;
        padding: 0.2rem 0.6rem;
        border-radius: 9999px;
        font-size: 0.75rem;
        font-weight: 700;
    }
    .pill-red { background: #FEE2E2; color: #991B1B; }
    .pill-green { background: #D1FAE5; color: #065F46; }
    .pill-blue { background: #DBEAFE; color: #1E40AF; }
</style>
""", unsafe_allow_html=True)

# ==============================================================================
# 2. PEMUATAN DATA & CACHING
# ==============================================================================
@st.cache_data
def load_data():
    file_path = "data/processed/Sample_Superstore_Cleaned_Final.csv"
    if not os.path.exists(file_path):
        file_path = "Sample_Superstore_Cleaned_Final.csv"
    
    df = pd.read_csv(file_path)
    df['order_date'] = pd.to_datetime(df['order_date'])
    df['ship_date'] = pd.to_datetime(df['ship_date'])
    df['year'] = df['order_date'].dt.year
    df['year_month'] = df['order_date'].dt.to_period('M').astype(str)
    
    # Definisi kelompok diskon (discount bands)
    bins = [-0.001, 0.0001, 0.1001, 0.2001, 0.3001, 1.0]
    labels = ['0%', '>0-10%', '>10-20%', '>20-30%', '>30%']
    df['discount_band'] = pd.cut(df['discount'], bins=bins, labels=labels)
    df['is_loss'] = df['profit'] < 0
    return df

df_raw = load_data()

# ==============================================================================
# 3. SIDEBAR: KONTROL INTERAKTIF & FILTER
# ==============================================================================
with st.sidebar:
    st.image("https://img.icons8.com/fluency/96/bullish.png", width=64)
    st.title("Filter & Cakupan Analisis")
    st.markdown("Sesuaikan dimensi data yang ingin dianalisis:")
    
    # Filter Rentang Tanggal
    min_date = df_raw['order_date'].min().date()
    max_date = df_raw['order_date'].max().date()
    date_range = st.date_input(
        "Rentang Tanggal Pesanan",
        value=(min_date, max_date),
        min_value=min_date,
        max_value=max_date
    )
    
    # Filter Wilayah Geografis
    regions = sorted(df_raw['region'].unique())
    selected_regions = st.multiselect("Wilayah Geografis (Region)", options=regions, default=regions)
    
    # Filter Kategori Produk
    categories = sorted(df_raw['category'].unique())
    selected_categories = st.multiselect("Kategori Produk (Category)", options=categories, default=categories)
    
    # Filter Segmen Pelanggan
    segments = sorted(df_raw['segment'].unique())
    selected_segments = st.multiselect("Segmen Pelanggan (Segment)", options=segments, default=segments)
    
    # Filter Slider Rentang Diskon
    discount_range = st.slider("Rentang Diskon (%)", 0, 80, (0, 80), step=5)
    
    st.divider()
    st.markdown("**Informasi Dataset:**")
    st.caption("Sample Superstore yang Telah Dibersihkan (Retail AS)\n9.994 baris transaksi | 2014 - 2017")
    
    if st.button("Atur Ulang Semua Filter", use_container_width=True):
        st.rerun()

# Penerapan Filter
start_date = pd.to_datetime(date_range[0])
end_date = pd.to_datetime(date_range[1]) if len(date_range) > 1 else start_date

df_filtered = df_raw[
    (df_raw['order_date'] >= start_date) &
    (df_raw['order_date'] <= end_date) &
    (df_raw['region'].isin(selected_regions)) &
    (df_raw['category'].isin(selected_categories)) &
    (df_raw['segment'].isin(selected_segments)) &
    (df_raw['discount'] >= discount_range[0] / 100.0) &
    (df_raw['discount'] <= discount_range[1] / 100.0)
]

# Peringatan jika tidak ada data yang cocok dengan kombinasi filter
if df_filtered.empty:
    st.warning("⚠️ Tidak ada data yang sesuai dengan filter yang dipilih. Silakan perluas kriteria filter Anda di bilah samping.")
    st.stop()

# ==============================================================================
# 4. HEADER UTAMA & KARTU KPI EKSEKUTIF
# ==============================================================================
st.markdown('<div class="main-header">📊 Analisis Kinerja Penjualan & Profitabilitas Retail</div>', unsafe_allow_html=True)
st.markdown('<div class="sub-header">Dashboard Eksekutif & Diagnosis Kebocoran Profitabilitas | Analitik SQL + Python</div>', unsafe_allow_html=True)

# Kalkulasi Metrik KPI Ringkasan
total_sales = df_filtered['sales'].sum()
total_profit = df_filtered['profit'].sum()
margin_pct = (total_profit / total_sales * 100) if total_sales > 0 else 0
total_orders = df_filtered['order_id'].nunique()
total_customers = df_filtered['customer_id'].nunique()
loss_rows = df_filtered['is_loss'].sum()
loss_amount = df_filtered[df_filtered['is_loss']]['profit'].sum()
loss_rate = (loss_rows / len(df_filtered) * 100) if len(df_filtered) > 0 else 0

c1, c2, c3, c4, c5 = st.columns(5)
with c1:
    st.markdown(f"""
    <div class="kpi-card">
        <div class="kpi-title">Total Pendapatan</div>
        <div class="kpi-value">${total_sales:,.0f}</div>
        <div class="kpi-subtitle">{df_filtered['quantity'].sum():,} unit terjual</div>
    </div>
    """, unsafe_allow_html=True)
with c2:
    profit_color = "kpi-card-success" if total_profit >= 0 else "kpi-card-danger"
    st.markdown(f"""
    <div class="kpi-card {profit_color}">
        <div class="kpi-title">Laba Bersih</div>
        <div class="kpi-value">${total_profit:,.0f}</div>
        <div class="kpi-subtitle">Laba bersih operasional</div>
    </div>
    """, unsafe_allow_html=True)
with c3:
    margin_color = "kpi-card-success" if margin_pct >= 12 else ("kpi-card-warning" if margin_pct > 0 else "kpi-card-danger")
    st.markdown(f"""
    <div class="kpi-card {margin_color}">
        <div class="kpi-title">Margin Laba Bersih</div>
        <div class="kpi-value">{margin_pct:.2f}%</div>
        <div class="kpi-subtitle">Target benchmark: 12,5%</div>
    </div>
    """, unsafe_allow_html=True)
with c4:
    st.markdown(f"""
    <div class="kpi-card">
        <div class="kpi-title">Total Pesanan</div>
        <div class="kpi-value">{total_orders:,}</div>
        <div class="kpi-subtitle">{total_customers:,} pelanggan unik</div>
    </div>
    """, unsafe_allow_html=True)
with c5:
    st.markdown(f"""
    <div class="kpi-card kpi-card-danger">
        <div class="kpi-title">Kebocoran Profit</div>
        <div class="kpi-value">-${abs(loss_amount):,.0f}</div>
        <div class="kpi-subtitle" style="color:#EF4444">{loss_rows:,} baris rugi ({loss_rate:.1f}%)</div>
    </div>
    """, unsafe_allow_html=True)

# ==============================================================================
# 5. TAB NAVIGASI DASHBOARD
# ==============================================================================
tab1, tab2, tab3, tab4 = st.tabs([
    "📈 Ringkasan Eksekutif", 
    "🔍 Diagnosis Kebocoran Profit", 
    "💡 Simulator Kebijakan What-If", 
    "🗄️ Sandbox Analisis SQL"
])

# ------------------------------------------------------------------------------
# TAB 1: RINGKASAN EKSEKUTIF
# ------------------------------------------------------------------------------
with tab1:
    col_left, col_right = st.columns([2, 1])
    
    with col_left:
        st.subheader("Tren Pendapatan & Laba Bulanan")
        monthly_df = df_filtered.groupby('year_month')[['sales', 'profit']].sum().reset_index()
        
        fig_trend = go.Figure()
        fig_trend.add_trace(go.Scatter(
            x=monthly_df['year_month'], y=monthly_df['sales'],
            name='Pendapatan Penjualan ($)', line=dict(color='#2563EB', width=3),
            mode='lines+markers'
        ))
        fig_trend.add_trace(go.Scatter(
            x=monthly_df['year_month'], y=monthly_df['profit'],
            name='Laba Bersih ($)', line=dict(color='#10B981', width=3),
            mode='lines+markers'
        ))
        fig_trend.update_layout(
            height=380,
            hovermode="x unified",
            xaxis_title="Tahun-Bulan",
            yaxis_title="Jumlah ($)",
            legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
            margin=dict(l=20, r=20, t=30, b=20)
        )
        st.plotly_chart(fig_trend, use_container_width=True)
        
    with col_right:
        st.subheader("Penjualan vs. Laba per Kategori")
        cat_df = df_filtered.groupby('category')[['sales', 'profit']].sum().reset_index()
        fig_cat = go.Figure(data=[
            go.Bar(name='Penjualan ($)', x=cat_df['category'], y=cat_df['sales'], marker_color='#60A5FA'),
            go.Bar(name='Laba Bersih ($)', x=cat_df['category'], y=cat_df['profit'], marker_color='#34D399')
        ])
        fig_cat.update_layout(
            barmode='group', height=380,
            xaxis_title="Kategori",
            yaxis_title="Jumlah ($)",
            legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
            margin=dict(l=20, r=20, t=30, b=20)
        )
        st.plotly_chart(fig_cat, use_container_width=True)

    col_b1, col_b2 = st.columns([1, 1])
    with col_b1:
        st.subheader("Kinerja Laba per Wilayah")
        reg_df = df_filtered.groupby('region')[['sales', 'profit']].sum().reset_index()
        reg_df['margin'] = (reg_df['profit'] / reg_df['sales'] * 100).round(1)
        reg_df = reg_df.sort_values(by='profit', ascending=True)
        
        fig_reg = px.bar(
            reg_df, x='profit', y='region', orientation='h',
            text=reg_df.apply(lambda r: f"${r['profit']:,.0f} ({r['margin']}%)", axis=1),
            color='profit',
            color_continuous_scale=['#EF4444', '#F59E0B', '#10B981'],
            labels={'profit': 'Laba Bersih ($)', 'region': 'Wilayah'}
        )
        fig_reg.update_layout(height=320, coloraxis_showscale=False, margin=dict(l=20, r=20, t=20, b=20))
        st.plotly_chart(fig_reg, use_container_width=True)

    with col_b2:
        st.subheader("Pangsa Laba Berdasarkan Segmen Pelanggan")
        seg_df = df_filtered.groupby('segment')['profit'].sum().reset_index()
        fig_seg = px.pie(
            seg_df, values='profit', names='segment',
            hole=0.45,
            color_discrete_sequence=['#3B82F6', '#F59E0B', '#8B5CF6']
        )
        fig_seg.update_layout(height=320, margin=dict(l=20, r=20, t=20, b=20))
        st.plotly_chart(fig_seg, use_container_width=True)

# ------------------------------------------------------------------------------
# TAB 2: DIAGNOSIS KEBOCORAN PROFIT
# ------------------------------------------------------------------------------
with tab2:
    st.subheader("Peringkat Laba Subkategori: Penghasil Nilai vs. Perusak Nilai")
    sub_df = df_filtered.groupby(['category', 'sub_category']).agg(
        sales=('sales', 'sum'),
        profit=('profit', 'sum'),
        avg_discount=('discount', 'mean'),
        loss_tx=('is_loss', 'sum'),
        total_tx=('row_id', 'count')
    ).reset_index()
    sub_df['margin_pct'] = (sub_df['profit'] / sub_df['sales'] * 100).round(2)
    sub_df['loss_rate'] = (sub_df['loss_tx'] / sub_df['total_tx'] * 100).round(1)
    sub_df = sub_df.sort_values(by='profit', ascending=True)

    col_sub1, col_sub2 = st.columns([1, 1])
    with col_sub1:
        fig_sub = px.bar(
            sub_df, y='sub_category', x='profit', orientation='h',
            color='profit',
            color_continuous_scale=['#DC2626', '#E2E8F0', '#16A34A'],
            color_continuous_midpoint=0,
            text_auto='$.2s',
            title="Kontribusi Laba Bersih per Subkategori",
            labels={'profit': 'Laba Bersih ($)', 'sub_category': 'Subkategori'}
        )
        fig_sub.update_layout(height=450, coloraxis_showscale=False)
        st.plotly_chart(fig_sub, use_container_width=True)
        
    with col_sub2:
        st.markdown("**Batas Kritis Diskon 20% (Kejatuhan Margin Laba)**")
        band_df = df_filtered.groupby('discount_band', observed=False).agg(
            sales=('sales', 'sum'),
            profit=('profit', 'sum')
        ).reset_index()
        band_df['margin_pct'] = (band_df['profit'] / band_df['sales'] * 100).round(2)
        
        fig_band = px.bar(
            band_df, x='discount_band', y='margin_pct',
            color='margin_pct',
            color_continuous_scale=['#DC2626', '#E2E8F0', '#16A34A'],
            color_continuous_midpoint=0,
            text=band_df['margin_pct'].apply(lambda v: f"{v:.1f}%"),
            title="% Margin Laba Berdasarkan Kelompok Diskon",
            labels={'discount_band': 'Kelompok Diskon', 'margin_pct': 'Margin Laba (%)'}
        )
        fig_band.add_hline(y=0, line_dash="dash", line_color="black")
        fig_band.update_layout(height=450, coloraxis_showscale=False, yaxis_title="Margin Laba (%)")
        st.plotly_chart(fig_band, use_container_width=True)

    st.divider()
    col_s1, col_s2 = st.columns([1.5, 1])
    with col_s1:
        st.subheader("Diagram Pencar Transaksi: Tingkat Diskon vs. Laba ($)")
        fig_scatter = px.scatter(
            df_filtered, x='discount', y='profit',
            color='is_loss',
            color_discrete_map={True: '#EF4444', False: '#3B82F6'},
            hover_data=['product_name', 'sub_category', 'sales', 'state'],
            opacity=0.6,
            labels={'is_loss': 'Status Rugi', 'discount': 'Tingkat Diskon (0.0 - 0.8)', 'profit': 'Laba Bersih ($)'}
        )
        fig_scatter.add_vline(x=0.2, line_dash="dot", line_color="#D97706", annotation_text="Garis Batas Bahaya 20%")
        fig_scatter.update_layout(height=400)
        st.plotly_chart(fig_scatter, use_container_width=True)

    with col_s2:
        st.subheader("Matriks Margin Kategori × Wilayah")
        heat_data = df_filtered.pivot_table(
            index='category', columns='region', values=['profit', 'sales'], aggfunc='sum'
        )
        margin_matrix = (heat_data['profit'] / heat_data['sales'] * 100).round(1)
        fig_heat = px.imshow(
            margin_matrix, text_auto=True, aspect="auto",
            color_continuous_scale='RdYlGn', color_continuous_midpoint=10,
            title="Heatmap Margin Laba (%)",
            labels=dict(x="Wilayah", y="Kategori", color="Margin (%)")
        )
        fig_heat.update_layout(height=400)
        st.plotly_chart(fig_heat, use_container_width=True)

# ------------------------------------------------------------------------------
# TAB 3: SIMULATOR KEBIJAKAN WHAT-IF & REKOMENDASI
# ------------------------------------------------------------------------------
with tab3:
    st.subheader("🎯 Simulator Strategis Interaktif: Batasi Diskon Maksimal")
    st.markdown("""
    Jelajahi potensi pemulihan keuntungan perusahaan jika kebijakan manajemen **membatasi diskon diskresioner maksimal**
    pada batas tertentu, dibandingkan membiarkan tim sales memberikan diskon tanpa kendali hingga 80%.
    """)
    
    sim_col1, sim_col2 = st.columns([1, 2])
    with sim_col1:
        cap_val = st.slider("Pilih Batas Maksimal Diskon Kebijakan (%)", 0, 50, 20, step=5) / 100.0
        
        # Logika simulasi: transaksi dengan diskon > cap_val dibatasi nilainya menjadi cap_val
        df_sim = df_filtered.copy()
        # Perkiraan biaya pokok = sales - profit
        df_sim['cost'] = df_sim['sales'] - df_sim['profit']
        # Harga katalog asli sebelum diskon = sales / (1 - discount)
        df_sim['list_price'] = df_sim['sales'] / (1.0 - df_sim['discount'].clip(upper=0.99))
        
        # Diskon baru = min(discount, cap_val)
        df_sim['sim_discount'] = df_sim['discount'].clip(upper=cap_val)
        df_sim['sim_sales'] = df_sim['list_price'] * (1.0 - df_sim['sim_discount'])
        df_sim['sim_profit'] = df_sim['sim_sales'] - df_sim['cost']
        
        orig_profit = df_sim['profit'].sum()
        sim_profit = df_sim['sim_profit'].sum()
        recovered = sim_profit - orig_profit
        sim_margin = (sim_profit / df_sim['sim_sales'].sum()) * 100
        
        st.metric("Estimasi Pemulihan Laba", f"+${recovered:,.0f}", delta=f"+{(recovered/abs(orig_profit)*100):.1f}% vs. Laba Awal")
        st.metric("Simulasi Laba Bersih Baru", f"${sim_profit:,.0f}")
        st.metric("Simulasi Margin Laba Baru", f"{sim_margin:.2f}%", delta=f"{sim_margin - margin_pct:+.2f}%")

    with sim_col2:
        st.markdown(f"### Ringkasan Dampak Kebijakan (Batas Diskon = {int(cap_val*100)}%)")
        sim_summary = pd.DataFrame({
            "Skenario": ["Kondisi Riil Saat Ini", f"Kebijakan Dibatasi Maksimal {int(cap_val*100)}%"],
            "Laba Bersih ($)": [f"${orig_profit:,.2f}", f"${sim_profit:,.2f}"],
            "Margin Laba (%)": [f"{margin_pct:.2f}%", f"{sim_margin:.2f}%"],
            "Transaksi Merugi": [f"{(df_sim['profit'] < 0).sum():,}", f"{(df_sim['sim_profit'] < 0).sum():,}"]
        })
        st.dataframe(sim_summary, use_container_width=True, hide_index=True)
        
        st.info(f"""
        **💡 Wawasan Strategis**: Membatasi diskon pada angka **{int(cap_val*100)}%** mencegah pemberian diskon ekstrem pada **{len(df_sim[df_sim['discount'] > cap_val]):,}** transaksi.
        Satu intervensi kebijakan ini saja diproyeksikan mengembalikan **+${recovered:,.0f}** secara langsung ke laba operasional bersih perusahaan!
        """)

    st.divider()
    st.subheader("📋 3 Arahan Bisnis Strategis Utama")
    r1, r2, r3 = st.columns(3)
    with r1:
        st.error("1. Matriks Persetujuan Diskon")
        st.markdown("""
        - **Otomatis Sales Rep**: Hingga 15%
        - **Persetujuan Manajer**: 15,1% - 20%
        - **Pengecualian Direksi**: >20% (wajib bundling margin positif)
        - *Estimasi Manfaat*: **+$95.000/tahun**
        """)
    with r2:
        st.warning("2. Pemisahan Biaya Kirim Barang Berat")
        st.markdown("""
        - Hentikan promo gratis ongkir untuk **Tables & Bookcases**
        - Terapkan biaya tambahan kargo logistik $25-$50 untuk barang berat
        - Delist 20% SKU terbawah yang konsisten merugi
        - *Estimasi Manfaat*: **+$17.700/tahun**
        """)
    with r3:
        st.success("3. Penyelarasan Insentif Regional")
        st.markdown("""
        - Ubah target bonus sales di Texas & Illinois dari **Volume Omzet** menjadi **Kontribusi Margin Kotor**
        - Nonaktifkan kupon diskon otomatis untuk akun bisnis korporat di Central Region
        - *Estimasi Manfaat*: **+$22.900/tahun**
        """)

# ------------------------------------------------------------------------------
# TAB 4: SANDBOX ANALISIS SQL & EKSPOR DATA
# ------------------------------------------------------------------------------
with tab4:
    st.subheader("🗄️ Sandbox Analisis SQL Interaktif")
    st.markdown("Jalankan query SQL analitis secara langsung terhadap tabel database pesanan Superstore di memori browser:")
    
    # Inisialisasi database SQLite in-memory dari dataframe yang telah difilter
    conn = sqlite3.connect(":memory:")
    df_filtered.to_sql("orders", conn, if_exists="replace", index=False)
    
    default_query = """SELECT 
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 2) AS margin_pct,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_pct,
    COUNT(*) AS total_transactions
FROM orders
GROUP BY sub_category
ORDER BY total_profit ASC
LIMIT 10;"""
    
    user_query = st.text_area("Input Query SQL (Sintaks SQLite):", value=default_query, height=180)
    
    col_q1, col_q2 = st.columns([1, 4])
    with col_q1:
        run_btn = st.button("▶️ Eksekusi Query", use_container_width=True)
    
    if run_btn:
        try:
            query_result = pd.read_sql(user_query, conn)
            st.success(f"Query berhasil mengembalikan {len(query_result)} baris data.")
            st.dataframe(query_result, use_container_width=True)
        except Exception as e:
            st.error(f"Kesalahan Eksekusi SQL: {e}")
            
    conn.close()

    st.divider()
    st.subheader("📥 Ekspor Data Hasil Filter")
    csv_bytes = df_filtered.to_csv(index=False).encode('utf-8')
    st.download_button(
        label="Unduh Data CSV yang Difilter",
        data=csv_bytes,
        file_name=f"superstore_terfilter_{datetime.now().strftime('%Y%m%d_%H%M')}.csv",
        mime="text/csv"
    )
