-- 1. Menampilkan jumlah penggunaan masing-masing tipe pembayaran secara all time diurutkan dari yang terfavorit 
SELECT
  payment_type,
  COUNT(*) AS jumlah_penggunaan
FROM
  payments_dataset
GROUP BY
  payment_type
ORDER BY
  jumlah_penggunaan DESC;
-- 2. Menampilkan detail informasi jumlah penggunaan masing-masing tipe pembayaran untuk setiap tahun
SELECT
  EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
  p.payment_type,
  COUNT(*) AS jumlah_penggunaan
FROM
  payments_dataset p
INNER JOIN
  orders_dataset o
ON
  p.order_id = o.order_id
GROUP BY
  tahun, p.payment_type
ORDER BY
  tahun, jumlah_penggunaan DESC;


