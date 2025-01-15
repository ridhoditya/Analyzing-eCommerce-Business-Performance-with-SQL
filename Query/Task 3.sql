-- 1. Membuat tabel yang berisi informasi pendapatan/revenue perusahaan total untuk masing-masing tahun
SELECT
  EXTRACT(YEAR FROM os.order_purchase_timestamp) AS tahun,
  SUM(oi.price + oi.freight_value) AS total_pendapatan
FROM
  order_items_dataset oi
INNER JOIN
  orders_dataset os
ON
  oi.order_id = os.order_id
WHERE
  os.order_status = 'delivered'
GROUP BY
  tahun
ORDER BY
  tahun;
-- 2. Membuat tabel yang berisi informasi jumlah cancel order total untuk masing-masing tahun
SELECT
  EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
  COUNT(*) AS total_cancel_order
FROM
  orders_dataset o
WHERE
  o.order_status = 'canceled'
GROUP BY
  tahun
ORDER BY
  tahun;
-- 3. Membuat tabel yang berisi nama kategori produk yang memberikan pendapatan total tertinggi untuk masing-masing tahun
WITH ProductRevenue AS (
  SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
    pd.product_category_name,
    SUM(oi.price + oi.freight_value) AS total_pendapatan
  FROM
    order_items_dataset oi
  INNER JOIN
    orders_dataset o
  ON
    oi.order_id = o.order_id
  INNER JOIN
    product_dataset pd
  ON
    oi.product_id = pd.product_id
  WHERE
    o.order_status = 'delivered'
  GROUP BY
    tahun, pd.product_category_name
),

RankedProductRevenue AS (
  SELECT
    tahun,
    product_category_name,
    total_pendapatan,
    RANK() OVER (PARTITION BY tahun ORDER BY total_pendapatan DESC) AS ranking
  FROM
    ProductRevenue
)

SELECT
  tahun,
  product_category_name,
  total_pendapatan
FROM
  RankedProductRevenue
WHERE
  ranking = 1
ORDER BY
  tahun;
-- 4. Membuat tabel yang berisi nama kategori produk yang memiliki jumlah cancel order terbanyak untuk masing-masing tahun
WITH CanceledOrders AS (
  SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
    pd.product_category_name,
    COUNT(*) AS jumlah_cancel_order
  FROM
    orders_dataset o
  INNER JOIN
    order_items_dataset oi
  ON
    o.order_id = oi.order_id
  INNER JOIN
    product_dataset pd
  ON
    oi.product_id = pd.product_id
  WHERE
    o.order_status = 'canceled'
  GROUP BY
    tahun, pd.product_category_name
),

RankedCanceledOrders AS (
  SELECT
    tahun,
    product_category_name,
    jumlah_cancel_order,
    RANK() OVER (PARTITION BY tahun ORDER BY jumlah_cancel_order DESC) AS ranking
  FROM
    CanceledOrders
)

SELECT
  tahun,
  product_category_name,
  jumlah_cancel_order
FROM
  RankedCanceledOrders
WHERE
  ranking = 1
ORDER BY
  tahun;
  
-- 5. Menggabungkan informasi-informasi yang telah didapatkan ke dalam satu tampilan tabel
WITH TotalRevenue AS (
  SELECT
    EXTRACT(YEAR FROM os.order_purchase_timestamp) AS tahun,
    SUM(oi.price + oi.freight_value) AS total_pendapatan
  FROM
    order_items_dataset oi
  INNER JOIN
    orders_dataset os
  ON
    oi.order_id = os.order_id
  WHERE
    os.order_status = 'delivered'
  GROUP BY
    tahun
),

TotalCancelOrders AS (
  SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
    COUNT(*) AS total_cancel_order
  FROM
    orders_dataset o
  WHERE
    o.order_status = 'canceled'
  GROUP BY
    tahun
),

TopCategoryByRevenue AS (
  WITH ProductRevenue AS (
    SELECT
      EXTRACT(YEAR FROM os.order_purchase_timestamp) AS tahun,
      pd.product_category_name,
      SUM(oi.price + oi.freight_value) AS total_pendapatan
    FROM
      order_items_dataset oi
    INNER JOIN
      orders_dataset os
    ON
      oi.order_id = os.order_id
    INNER JOIN
      product_dataset pd
    ON
      oi.product_id = pd.product_id
    WHERE
      os.order_status = 'delivered'
    GROUP BY
      tahun, pd.product_category_name
  ),

  RankedProductRevenue AS (
    SELECT
      tahun,
      product_category_name,
      total_pendapatan,
      RANK() OVER (PARTITION BY tahun ORDER BY total_pendapatan DESC) AS ranking
    FROM
      ProductRevenue
  )

  SELECT
    tahun,
    product_category_name AS top_category_by_revenue
  FROM
    RankedProductRevenue
  WHERE
    ranking = 1
),

TopCategoryByCancel AS (
  WITH CanceledOrders AS (
    SELECT
      EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
      pd.product_category_name,
      COUNT(*) AS jumlah_cancel_order
    FROM
      orders_dataset o
    INNER JOIN
      order_items_dataset oi
    ON
      o.order_id = oi.order_id
    INNER JOIN
      product_dataset pd
    ON
      oi.product_id = pd.product_id
    WHERE
      o.order_status = 'canceled'
    GROUP BY
      tahun, pd.product_category_name
  ),

  RankedCanceledOrders AS (
    SELECT
      tahun,
      product_category_name,
      jumlah_cancel_order,
      RANK() OVER (PARTITION BY tahun ORDER BY jumlah_cancel_order DESC) AS ranking
    FROM
      CanceledOrders
  )

  SELECT
    tahun,
    product_category_name AS top_category_by_cancel
  FROM
    RankedCanceledOrders
  WHERE
    ranking = 1
)

SELECT
  t.tahun,
  COALESCE(t.total_pendapatan, 0) AS total_pendapatan,
  COALESCE(tc.total_cancel_order, 0) AS total_cancel_order,
  COALESCE(tr.top_category_by_revenue, '-') AS top_category_by_revenue,
  COALESCE(tcc.top_category_by_cancel, '-') AS top_category_by_cancel
FROM
  TotalRevenue t
LEFT JOIN
  TotalCancelOrders tc
ON
  t.tahun = tc.tahun
LEFT JOIN
  TopCategoryByRevenue tr
ON
  t.tahun = tr.tahun
LEFT JOIN
  TopCategoryByCancel tcc
ON
  t.tahun = tcc.tahun
ORDER BY
  t.tahun;

