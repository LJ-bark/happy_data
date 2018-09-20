drop table if exists orders_with_plan_sku;
select so.order_id, p.sku plan_sku
into temp orders_with_plan_sku
from barkbox_copy.subscription_orders so
left join barkbox_copy.subscription_commitments sc on sc.id = so.subscription_commitment_id
left join barkbox_copy.plans p on p.id = sc.plan_id
where so.order_id is not null;


SELECT date_trunc('month',convert_timezone('UTC','US/Eastern', o.created_at)) as order_month
, tags.name as reason_code
, i.sku
, case when op.plan_sku ilike '%superc%' then 'Super Chewer'
when op.plan_sku not ilike '%superc%' then 'Classic'
when o2.origin = 'BarkShop' then 'BarkShop'
else 'Other'
end as Business_Line
, count(distinct case when o.status not ilike '%cancel%' then o.id end) as not_canceled_orders_containing_sku
, count(distinct case when o.status ilike '%cancel%' then o.id end) as canceled_orders_containing_sku
, sum (case when o.status not ilike '%cancel%' then li.quantity end) as not_canceled_orders_total_sku_qty
, sum (case when o.status ilike '%cancel%' then li.quantity end) as canceled_orders_total_sku_qty
FROM barkbox_copy.orders o
Inner join barkbox_copy.line_items li on li.order_id = o.id
Inner join barkbox_copy.items i on i.id = li.source_id --and li.source_type = i.type--and source_type not in ('Plan','ShippingMethod')
left join barkbox_copy.taggings t on t.taggable_id = o.id and t.taggable_type = 'Order' and t.context = 'reason_codes'
left join barkbox_copy.tags tags on tags.id = t.tag_id
left join barkbox_copy.orders o2 on o2.id = o.origin_order_number --and o2.origin = 'Subscription'
left join orders_with_plan_sku op on op.order_id = o2.id and o2.origin = 'Subscription'
WHERE convert_timezone('UTC','US/Eastern', o.created_at) between '01/01/2018' and '09/01/2018'
and o.origin in ('BarkHappy - BarkBox', 'BarkHappy - BarkShop', 'BarkHappy - General')
and li.quantity > 0
and li.source_type not in ('Plan','ShippingMethod')
GROUP BY date_trunc('month',convert_timezone('UTC','US/Eastern', o.created_at))
, tags.name
, i.sku
, case when op.plan_sku ilike '%superc%' then 'Super Chewer'
when op.plan_sku not ilike '%superc%' then 'Classic'
when o2.origin = 'BarkShop' then 'BarkShop'
else 'Other'
end
ORDER BY 1,2;
