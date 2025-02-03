-- Query untuk menampilkan semua tabel dalam dataset
SELECT * FROM `rakamin-kf-analytics-449808.kimia_farma.INFORMATION_SCHEMA.TABLES`;

-- Query untuk menampilkan isi tabel utama
SELECT * FROM `rakamin-kf-analytics-449808.kimia_farma.kf_final_transaction`;
SELECT * FROM `rakamin-kf-analytics-449808.kimia_farma.kf_inventory`;
SELECT * FROM `rakamin-kf-analytics-449808.kimia_farma.kf_kantor_cabang`;
SELECT * FROM `rakamin-kf-analytics-449808.kimia_farma.kf_product`;

-- Membuat tabel analisa berdasarkan hasil agregasi dari dataset yang telah diimpor
CREATE OR REPLACE TABLE `rakamin-kf-analytics-449808.kimia_farma.analisa_transaksi` AS SELECT 
    t.transaction_id,
    t.date,
    c.branch_id,
    c.branch_name,
    c.kota,
    c.provinsi,
    c.rating AS rating_cabang,  -- Menggunakan rating dari kantor cabang
    t.customer_name,
    p.product_id,
    p.product_name,
    p.price AS actual_price,  -- Menggunakan price sebagai actual_price
    t.discount_percentage,

    -- Hitung Persentase Gross Laba Berdasarkan Harga Produk
    CASE 
        WHEN p.price <= 50000 THEN 10
        WHEN p.price > 50000 AND p.price <= 100000 THEN 15
        WHEN p.price > 100000 AND p.price <= 300000 THEN 20
        WHEN p.price > 300000 AND p.price <= 500000 THEN 25
        WHEN p.price > 500000 THEN 30
        ELSE 0
    END AS persentase_gross_laba,

    -- Hitung Harga Setelah Diskon
    p.price * (1 - (t.discount_percentage / 100)) AS nett_sales,

    -- Hitung Keuntungan Setelah Diskon
    (p.price * (1 - (t.discount_percentage / 100))) * (
        CASE 
            WHEN p.price <= 50000 THEN 0.1
            WHEN p.price > 50000 AND p.price <= 100000 THEN 0.15
            WHEN p.price > 100000 AND p.price <= 300000 THEN 0.2
            WHEN p.price > 300000 AND p.price <= 500000 THEN 0.25
            WHEN p.price > 500000 THEN 0.3
            ELSE 0
        END
    ) AS nett_profit,

    t.rating AS rating_transaksi  -- Menggunakan rating dari transaksi

FROM `rakamin-kf-analytics-449808.kimia_farma.kf_final_transaction` t
JOIN `rakamin-kf-analytics-449808.kimia_farma.kf_kantor_cabang` c 
    ON t.branch_id = c.branch_id
JOIN `rakamin-kf-analytics-449808.kimia_farma.kf_product` p
    ON t.product_id = p.product_id;

-- Perbandingan pendapatan Kimia Farma (2020-2023)
SELECT 
    EXTRACT(YEAR FROM date) AS tahun,
    SUM(nett_profit) AS total_pendapatan
FROM `rakamin-kf-analytics-449808.kimia_farma.analisa_transaksi`
WHERE EXTRACT(YEAR FROM date) BETWEEN 2020 AND 2023
GROUP BY tahun
ORDER BY tahun;

-- Total Transaksi per Provinsi
SELECT 
    provinsi, 
    COUNT(transaction_id) AS total_transaksi
FROM `rakamin-kf-analytics-449808.kimia_farma.analisa_transaksi`
GROUP BY provinsi
ORDER BY total_transaksi DESC;

-- Top 10 Nett Sales per Provinsi
SELECT 
    provinsi, 
    SUM(nett_sales) AS total_nett_sales
FROM `rakamin-kf-analytics-449808.kimia_farma.analisa_transaksi`
GROUP BY provinsi
ORDER BY total_nett_sales DESC
LIMIT 10;

-- Top 5 Cabang dengan Rating Tertinggi & Terendah
-- Cabang dengan Rating Tertinggi
SELECT 
    branch_name, 
    AVG(rating_cabang) AS avg_rating
FROM `rakamin-kf-analytics-449808.kimia_farma.analisa_transaksi`
GROUP BY branch_name
ORDER BY avg_rating DESC
LIMIT 5;

-- Cabang dengan Rating Terendah
SELECT 
    branch_name, 
    AVG(rating_cabang) AS avg_rating
FROM `rakamin-kf-analytics-449808.kimia_farma.analisa_transaksi`
GROUP BY branch_name
ORDER BY avg_rating ASC
LIMIT 5;

-- Geo Map Total Profit per Provinsi
SELECT 
    provinsi, 
    SUM(nett_profit) AS total_profit
FROM `rakamin-kf-analytics-449808.kimia_farma.analisa_transaksi`
GROUP BY provinsi
ORDER BY total_profit DESC;
