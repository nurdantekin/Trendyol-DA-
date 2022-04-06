--Q1: Promosyon çıkılmış fakat hiç satılmamış ürünleri tespit edebilir miyiz?

WITH promotion AS (SELECT DISTINCT wa.visitId,
  promo.promoName AS Promotion_Name,
  COUNT(hit.promotionActionInfo.promoIsView) AS Promotion_Views,
  COUNT(hit.promotionActionInfo.promoIsClick) AS Promotion_Clicks
FROM
  `data-to-insights.ecommerce.web_analytics` wa,
  UNNEST(hits) AS hit,
  UNNEST(hit.promotion) AS promo
GROUP BY
  wa.visitId,Promotion_Name
HAVING Promotion_Clicks != 0),

product AS (SELECT  DISTINCT wa.visitId, p.v2ProductName AS product_name
FROM `data-to-insights.ecommerce.web_analytics` wa 
    cross JOIN unnest(wa.hits) h
    cross JOIN unnest(h.product) p)

SELECT  DISTINCT p1.product_name  FROM promotion p JOIN product p1 ON p.visitId=p1.visitId JOIN `data-to-insights.ecommerce.products` p2 ON p1.product_name = p2.name
WHERE orderedQuantity = 0;



--Q2: Mart, nisan, mayıs aylarında ziyaretçilerin en çok görüntülediği fakat satın alınmamış ürünlere ihtiyacımız var. Her ayın top 10 ürününü gösterebilir misiniz? (Tarih yıl - ay olarak gösterilmeli.)

with three_month as(SELECT COUNT(a.pageviews) as total_view, a.v2ProductName as nameproduct, EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d',a.date)) as month_
FROM `data-to-insights.ecommerce.all_sessions` as a JOIN `data-to-insights.ecommerce.products` as p1 ON a.v2ProductName  = p1.name
WHERE p1.orderedQuantity  = 0 
GROUP BY nameproduct, month_
HAVING  month_ in (3,4,5)
ORDER BY total_view DESC
limit 30)

(select CONCAT(EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d',a.date)), '-',t.month_) as date_, t.month_, t.nameproduct, t.total_view,
from three_month t JOIN `data-to-insights.ecommerce.products` as p ON t.nameproduct  = p.name join `data-to-insights.ecommerce.all_sessions` a on t.nameproduct = a.v2ProductName 
WHERE  p.orderedQuantity = 0
GROUP BY date_, t.month_, t.nameproduct, t.total_view 
HAVING t.month_ = 3
ORDER BY total_view DESC LIMIT 10)

UNION ALL

(select CONCAT(EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d',a.date)), '-',t.month_) as date_, t.month_, t.nameproduct, t.total_view,
from three_month t JOIN `data-to-insights.ecommerce.products` as p ON t.nameproduct  = p.name join `data-to-insights.ecommerce.all_sessions` a on t.nameproduct = a.v2ProductName 
WHERE  p.orderedQuantity = 0
GROUP BY date_, t.month_, t.nameproduct, t.total_view 
HAVING t.month_ = 4
ORDER BY total_view DESC LIMIT 10)

UNION ALL

(select CONCAT(EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d',a.date)), '-',t.month_) as date_, t.month_, t.nameproduct, t.total_view,
from three_month t JOIN `data-to-insights.ecommerce.products` as p ON t.nameproduct  = p.name join `data-to-insights.ecommerce.all_sessions` a on t.nameproduct = a.v2ProductName 
WHERE  p.orderedQuantity = 0
GROUP BY date_, t.month_, t.nameproduct, t.total_view 
HAVING t.month_ = 5
ORDER BY total_view DESC LIMIT 10);



--Q3: E ticaret sitemiz için günün bölümlerinde, en fazla ilgi gören kategorileri öğrenmek istiyoruz.

WITH category_by_hour as (select a.v2productCategory as category_name, count(a.visitId) as visit_category_, CASE
    WHEN h.hour between 7 and 11 THEN 'morning'
    WHEN  h.hour between 12 and 16 THEN 'afternoon'
    WHEN  h.hour between 17 and 19 THEN 'evening'
    WHEN  h.hour between 20 and 24 THEN 'midnight'
    ELSE 'after midnight'
  END
  AS part_of_day
from `data-to-insights.ecommerce.web_analytics` wa 
    inner join `data-to-insights.ecommerce.all_sessions` a on a.visitId=wa.visitId
    cross join unnest(wa.hits) h
where a.eCommerceAction_type = '6'
group by category_name, part_of_day
order by visit_category_ desc)

(select category_name, part_of_day from category_by_hour where part_of_day = 'morning' ORDER BY visit_category_ LIMIT 5)
UNION ALL
(select category_name, part_of_day from category_by_hour where part_of_day = 'afternoon'  ORDER BY visit_category_ LIMIT 5)
UNION ALL
(select category_name, part_of_day from category_by_hour where part_of_day = 'evening'  ORDER BY visit_category_ LIMIT 5)
UNION ALL
(select category_name, part_of_day from category_by_hour where part_of_day = 'midnight' ORDER BY visit_category_ LIMIT 5)
UNION ALL
(select category_name, part_of_day from category_by_hour where part_of_day = 'after midnight' ORDER BY visit_category_ LIMIT 5);

