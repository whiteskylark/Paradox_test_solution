/*Задание 1. Сделайте запрос к таблице payment 
и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
•	Пронумеруйте все платежи от 1 до N по дате
•	Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате
•	Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, 
сортировка должна быть сперва по дате платежа, а затем по сумме платежа от наименьшей к большей
•	Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к меньшим так, 
чтобы платежи с одинаковым значением имели одинаковое значение номера.
Можно составить на каждый пункт отдельный SQL-запрос, 
а можно объединить все колонки в одном запросе.*/
select distinct
  p.customer_id,
  row_number()  over(order by p.payment_date) total_payment_number,
  row_number()  over(partition by p.customer_id order by p.payment_date) customer_payment_number,
  sum(p.amount) over(partition by p.customer_id order by p.payment_date, p.amount) cusomer_amount_sum,
  dense_rank()  over(partition by p.customer_id order by p.amount desc) customer_payment_rank
from payment p
order by customer_id, total_payment_number, customer_payment_number, cusomer_amount_sum;

/*Задание 2. С помощью оконной функции выведите для каждого покупателя стоимость платежа 
и стоимость платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате.*/
select
  p.customer_id,
  p.amount,
  coalesce(lag(p.amount) over(partition by p.customer_id order by p.payment_date), 0.0) amount_prev 
from payment p;

/*Задание 3. С помощью оконной функции определите, 
на сколько каждый следующий платеж покупателя больше или меньше текущего.*/
select
  p.customer_id,
  p.amount,
  p.amount - coalesce(lead(p.amount) over(partition by p.customer_id order by p.payment_date), 0.0) amount_diff 
from payment p;

/*Задание 4. С помощью оконной функции для каждого покупателя 
выведите данные о его последней оплате аренды.*/
select
  c.customer_id,
  c.payment_id,
  c.staff_id,
  c.rental_id,
  c.amount,
  c.payment_date
from (select
        p.*,
        row_number() over(partition by c.customer_id order by p.payment_date desc) as row_num
      from   customer c
        join payment  p on p.customer_id = c.customer_id) as c
where c.row_num = 1;

/*Задание 5. С помощью оконной функции выведите для каждого сотрудника 
сумму продаж за август 2005 года с нарастающим итогом по каждому сотруднику 
и по каждой дате продажи (без учёта времени) с сортировкой по дате.*/
select
  s.staff_id,
  p.payment_date,
  p.amount,
  sum(p.amount) over(partition by s.staff_id, cast(p.payment_date as date) 
					 order by p.payment_date) amount_sum
from        staff   s
  left join rental  r on r.staff_id = s.staff_id
  left join payment p on p.rental_id = r.rental_id and p.staff_id = r.staff_id
where p.payment_date >= '20050801' and p.payment_date < '20050901' 
order by s.staff_id, p.payment_date;

/*Задание 6. 20 августа 2005 года в магазинах проходила акция: 
покупатель каждого сотого платежа получал дополнительную скидку на следующую аренду. 
С помощью оконной функции выведите всех покупателей, 
которые в день проведения акции получили скидку.*/
select 
  p.customer_id
from (select
        p.customer_id,
        row_number() over(order by p.payment_id) row_num
      from payment p
      where cast(p.payment_date as date) = '20050820') p
where row_num % 100 = 0;

/*Задание 7. Для каждой страны определите и выведите одним SQL-запросом покупателей, 
которые попадают под условия:
•	покупатель, арендовавший наибольшее количество фильмов;
•	покупатель, арендовавший фильмов на самую большую сумму;
•	покупатель, который последним арендовал фильм .*/
select
  co.country_id,
  case when amount_sum = amount_sum_max then customer_id end amount_sum_max_customer_id,
  case when film_count = film_count_max then customer_id end film_count_max_customer_id,
  case when rental_date_last = rental_date_last_max then customer_id end rental_date_last_customer_id
from (select distinct
		country_id,  
		customer_id,
		amount_sum,
		max(amount_sum) over(partition by country_id order by country_id) amount_sum_max, 
		rental_date_last,
		max(rental_date_last) over(partition by country_id order by country_id) rental_date_last_max,
	    max(film_count) over(partition by country_id, customer_id order by country_id) film_count,
		max(film_count) over(partition by country_id order by country_id) film_count_max
	  from (select
			  c.country_id,
			  p.customer_id,
			  sum(p.amount) over(partition by c.country_id, p.customer_id order by c.country_id, p.customer_id) amount_sum,
			  dense_rank() over(partition by c.country_id, p.customer_id order by f.film_id) film_count,
			  max(r.rental_date) over(partition by c.country_id, p.customer_id order by c.country_id, p.customer_id) rental_date_last
			from   country   c
			  join city      ci on ci.country_id = c.country_id
			  join address   a  on a.city_id = ci.city_id
			  join customer  cu on cu.address_id = a.address_id
			  join rental    r  on r.customer_id = cu.customer_id
			  join payment   p  on p.rental_id = r.rental_id and p.customer_id = r.customer_id
			  join inventory i  on i.inventory_id = r.inventory_id
			  join film      f  on f.film_id = i.film_id) c) c
  right join country co on co.country_id = c.country_id
where coalesce(amount_sum, 0) = coalesce(amount_sum_max, 0)
   or coalesce(rental_date_last, '19700101') = coalesce(rental_date_last_max, '19700101')
   or coalesce(film_count, 0) = coalesce(film_count_max, 0)
order by co.country_id, amount_sum_max_customer_id, film_count_max_customer_id, rental_date_last_customer_id;