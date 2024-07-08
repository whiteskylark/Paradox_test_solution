--Задание 1. Выведите для каждого покупателя его адрес, город и страну проживания.
select
  c.customer_id,
  a.address,
  ci.city,
  co.country
from   customer c
  join address  a  on a.address_id = c.address_id
  join city     ci on ci.city_id = a.city_id
  join country  co on co.country_id = ci.country_id;
  
--Задание 2. С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.
select
  c.store_id,
  count(distinct c.customer_id) as customer_count
from customer c
group by c.store_id;

/*•	Доработайте запрос и выведите только те магазины, 
у которых количество покупателей больше 300. 
Для решения используйте фильтрацию по сгруппированным строкам с функцией агрегации.*/
select
  c.store_id,
  count(distinct c.customer_id)
from customer c
group by c.store_id
having count(distinct c.customer_id) > 300;

/*•	Доработайте запрос, добавив в него информацию о городе магазина, 
фамилии и имени продавца, который работает в нём. */
select
  c.store_id,
  ci.city,
  st.last_name,
  st.first_name,
  count(distinct c.customer_id) as customer_count
from   customer c
  join store    s  on s.store_id = c.store_id
  join address  a  on a.address_id = s.address_id
  join city     ci on ci.city_id = a.city_id
  join staff    st on st.staff_id = s.manager_staff_id
group by c.store_id, ci.city, st.last_name, st.first_name
having count(distinct c.customer_id) > 300;

--Задание 3. Выведите топ-5 покупателей, которые взяли в аренду за всё время наибольшее количество фильмов.
select
  cf.customer_id,
  cf.film_count
from (select
	    dense_rank() over(order by count(distinct i.film_id) desc) as row_rank,
	    r.customer_id,
		count(distinct i.film_id) as film_count
	  from   rental    r 
		join inventory i on i.inventory_id = r.inventory_id
	  group by r.customer_id) cf
where row_rank <= 5
order by cf.film_count desc;

/*Задание 4. Посчитайте для каждого покупателя 4 аналитических показателя:
•	количество взятых в аренду фильмов;
•	общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа);
•	минимальное значение платежа за аренду фильма;
•	максимальное значение платежа за аренду фильма.*/
select
  c.customer_id,
  count(distinct i.film_id) film_count,
  round(sum(p.amount))      amount_sum,
  min(p.amount)             amount_min, 
  max(p.amount)             amount_max
from        customer  c
  left join rental    r on r.customer_id = c.customer_id
  left join payment   p on p.rental_id = r.rental_id and p.customer_id = r.customer_id
  left join inventory i on i.inventory_id = r.inventory_id
group by c.customer_id
order by c.customer_id;

/*Задание 5. Используя данные из таблицы городов, 
составьте одним запросом всевозможные пары городов так, 
чтобы в результате не было пар с одинаковыми названиями городов. 
Для решения необходимо использовать декартово произведение.*/
select
  c1.city_id as c1_city_id,
  c2.city_id as c2_city_id,
  c1.city    as c1_city_name,
  c2.city    as c2_city_name
from       city c1
cross join city c2
where c1.city <> c2.city
order by c1.city;

/*Задание 6. Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) 
и дате возврата (поле return_date), 
вычислите для каждого покупателя среднее количество дней, 
за которые он возвращает фильмы.*/
select
  c.customer_id,
  FLOOR(EXTRACT(epoch from (avg(r.return_date - r.rental_date)))/60/60/24) as frental_days_avg
from        customer c
  left join rental   r on r.customer_id = c.customer_id
where r.return_date is not null
group by c.customer_id
order by c.customer_id
 
/*Задание 7. Посчитайте для каждого фильма, сколько раз его брали в аренду, 
а также общую стоимость аренды фильма за всё время.*/
select
  f.film_id,
  count(distinct r.rental_id) as film_rental_count,
  sum(p.amount)               as rental_amount_sum
from        film      f
  left join inventory i on i.film_id = f.film_id
  left join rental    r on r.inventory_id = i.inventory_id
  left join payment   p on p.rental_id = r.rental_id
group by f.film_id;

/*Задание 8. Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, 
которые ни разу не брали в аренду.*/
select
  f.film_id
from        film      f
  left join inventory i on i.film_id = f.film_id
  left join rental    r on r.inventory_id = i.inventory_id
group by f.film_id
having count(distinct r.rental_id) = 0
order by f.film_id;

/*Задание 9. Посчитайте количество продаж, выполненных каждым продавцом. 
Добавьте вычисляемую колонку «Премия». 
Если количество продаж превышает 7 300, 
то значение в колонке будет «Да», иначе должно быть значение «Нет».*/
select
  s.staff_id,
  count(r.rental_id) as rental_count,
  case when count(r.rental_id) > 7300 then 'Да' else 'Нет' end as "Премия"
from        staff   s
  left join rental  r on r.staff_id = s.staff_id
group by s.staff_id;