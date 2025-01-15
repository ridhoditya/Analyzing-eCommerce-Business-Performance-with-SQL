-- 1. Menampilkan rata-rata jumlah customer aktif bulanan (monthly active user) untuk setiap tahun
SELECT
  EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
  EXTRACT(MONTH FROM o.order_purchase_timestamp) AS bulan,
  COUNT(DISTINCT c.customer_unique_id) / 12 AS AVG_MAU
FROM
  customers_dataset c
INNER JOIN
  orders_dataset o
ON
  c.customer_id = o.customer_id
GROUP BY
  EXTRACT(YEAR FROM o.order_purchase_timestamp),
  EXTRACT(MONTH FROM o.order_purchase_timestamp)
ORDER BY
  tahun, bulan;

-- 2. Menampilkan jumlah customer baru pada masing-masing tahun
WITH FirstOrder AS (
  SELECT
    o.customer_id,
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun
  FROM
    orders_dataset o
  GROUP BY
    o.customer_id, tahun
  HAVING
    COUNT(o.order_id) = 1
)

SELECT
  fo.tahun,
  COUNT(*) AS jumlah_pelanggan_baru
FROM
  FirstOrder fo
GROUP BY
  fo.tahun
ORDER BY
  fo.tahun;

-- 3. Menampilkan jumlah customer yang melakukan pembelian lebih dari satu kali (repeat order) pada masing-masing tahun
WITH CustomerOrders AS (
  SELECT
    c.customer_unique_id,
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
    COUNT(DISTINCT o.order_id) AS jumlah_pesanan
  FROM
    customers_dataset c
  INNER JOIN
    orders_dataset o
  ON
    c.customer_id = o.customer_id
  GROUP BY
    c.customer_unique_id, tahun
),

RepeatCustomers AS (
  SELECT
    tahun,
    COUNT(*) AS jumlah_pelanggan_repeat
  FROM
    CustomerOrders
  WHERE
    jumlah_pesanan > 1
  GROUP BY
    tahun
)

SELECT
  rc.tahun,
  COALESCE(rc.jumlah_pelanggan_repeat, 0) AS jumlah_pelanggan_repeat
FROM
  (SELECT DISTINCT tahun FROM CustomerOrders) t
LEFT JOIN
  RepeatCustomers rc
ON
  t.tahun = rc.tahun
ORDER BY
  t.tahun;

-- 4. Menampilkan rata-rata jumlah order yang dilakukan customer untuk masing-masing tahun
WITH CustomerOrderCounts AS (
  SELECT
    c.customer_unique_id,
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
    COUNT(DISTINCT o.order_id) AS jumlah_pesanan
  FROM
    customers_dataset c
  INNER JOIN
    orders_dataset o
  ON
    c.customer_id = o.customer_id
  GROUP BY
    c.customer_unique_id, tahun
)

SELECT
  tahun,
  AVG(jumlah_pesanan) AS rata_rata_jumlah_pesanan
FROM
  CustomerOrderCounts
GROUP BY
  tahun
ORDER BY
  tahun;

-- 5. Menggabungkan ketiga metrik yang telah berhasil ditampilkan menjadi satu tampilan tabel
WITH MonthlyActiveUsers AS (
  SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS bulan,
    COUNT(DISTINCT c.customer_unique_id) AS jumlah_customer_aktif_bulanan
  FROM
    customers_dataset c
  INNER JOIN
    orders_dataset o
  ON
    c.customer_id = o.customer_id
  GROUP BY
    tahun, bulan
),

NewCustomers AS (
  WITH FirstOrder AS (
    SELECT
      o.customer_id,
      EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun
    FROM
      orders_dataset o
    GROUP BY
      o.customer_id, tahun
    HAVING
      COUNT(o.order_id) = 1
  )

  SELECT
    fo.tahun,
    COUNT(*) AS jumlah_pelanggan_baru
  FROM
    FirstOrder fo
  GROUP BY
    fo.tahun
),

RepeatCustomers AS (
  WITH CustomerOrders AS (
    SELECT
      c.customer_unique_id,
      EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
      COUNT(DISTINCT o.order_id) AS jumlah_pesanan
    FROM
      customers_dataset c
    INNER JOIN
      orders_dataset o
    ON
      c.customer_id = o.customer_id
    GROUP BY
      c.customer_unique_id, tahun
  )

  SELECT
    tahun,
    COUNT(*) AS jumlah_pelanggan_repeat
  FROM
    CustomerOrders
  WHERE
    jumlah_pesanan > 1
  GROUP BY
    tahun
),

AvgOrderCounts AS (
  WITH CustomerOrderCounts AS (
    SELECT
      c.customer_unique_id,
      EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
      COUNT(DISTINCT o.order_id) AS jumlah_pesanan
    FROM
      customers_dataset c
    INNER JOIN
      orders_dataset o
    ON
      c.customer_id = o.customer_id
    GROUP BY
      c.customer_unique_id, tahun
  )

  SELECT
    tahun,
    AVG(jumlah_pesanan) AS rata_rata_jumlah_pesanan
  FROM
    CustomerOrderCounts
  GROUP BY
    tahun
)

SELECT
  mau.tahun,
  mau.bulan,
  mau.jumlah_customer_aktif_bulanan,
  nc.jumlah_pelanggan_baru,
  rc.jumlah_pelanggan_repeat,
  ao.rata_rata_jumlah_pesanan
FROM
  MonthlyActiveUsers mau
LEFT JOIN
  NewCustomers nc
ON
  mau.tahun = nc.tahun
LEFT JOIN
  RepeatCustomers rc
ON
  mau.tahun = rc.tahun
LEFT JOIN
  AvgOrderCounts ao
ON
  mau.tahun = ao.tahun
ORDER BY
  mau.tahun, mau.bulan;
