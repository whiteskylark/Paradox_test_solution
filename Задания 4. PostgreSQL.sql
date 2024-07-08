--Задание 1. Напишите SQL-запрос, который выводит всю информацию о фильмах со специальным атрибутом (поле special_features) равным “Behind the Scenes”.
select 
  f.*
from film f
where 'Behind the Scenes' = any(f.special_features);

/*Задание 2. Напишите ещё 2 варианта поиска фильмов с атрибутом “Behind the Scenes”, 
используя другие функции или операторы языка SQL для поиска значения в массиве.*/
select  
  f.*
from film f
where f.special_features && array['Behind the Scenes'];

select
  f.*
from film f
where array_position(f.special_features, 'Behind the Scenes') != 0;

/*Задание 3. Для каждого покупателя посчитайте, сколько он брал в аренду фильмов со специальным атрибутом “Behind the Scenes”.
Обязательное условие для выполнения задания: используйте запрос из задания 1, помещённый в CTE.*/
with cte_film (film_id)
as (select 
	  film_id
	from film
	where 'Behind the Scenes' = any(special_features))
	
select
  c.customer_id,
  count(distinct cf.film_id)
from        customer  c
  left join rental    r  on r.customer_id = c.customer_id
  left join inventory i  on i.inventory_id = r.inventory_id
  left join cte_film  cf on cf.film_id = i.film_id
group by c.customer_id;
  
/*Задание 4. Для каждого покупателя посчитайте, сколько он брал в аренду фильмов со специальным атрибутом “Behind the Scenes”.
Обязательное условие для выполнения задания: используйте запрос из задания 1, 
помещённый в подзапрос, который необходимо использовать для решения задания.*/
select
  c.customer_id,
  count(distinct f.film_id)
from        customer  c
  left join rental    r on r.customer_id = c.customer_id
  left join inventory i on i.inventory_id = r.inventory_id
  left join (select 
	          film_id
	         from film
	         where 'Behind the Scenes' = any(special_features)) as f on f.film_id = i.film_id
group by c.customer_id;

--Задание 5. Создайте материализованное представление с запросом из предыдущего задания и напишите запрос для обновления материализованного представления.
--drop materialized view if exists film_with_attribute
create materialized view if not exists film_with_attribute
as
  select
  c.customer_id,
  count(distinct f.film_id) film_count
from        customer  c
  left join rental    r on r.customer_id = c.customer_id
  left join inventory i on i.inventory_id = r.inventory_id
  left join (select 
	          film_id
	         from film
	         where 'Behind the Scenes' = any(special_features)) as f on f.film_id = i.film_id
group by c.customer_id; 

create unique index ui_film_with_attribute on film_with_attribute(customer_id); 

refresh materialized view concurrently film_with_attribute;

/*Задание 6. С помощью explain analyze проведите анализ скорости выполнения запросов из предыдущих заданий и ответьте на вопросы:
с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания, поиск значения в массиве происходит быстрее;
какой вариант вычислений работает быстрее: с использованием CTE или с использованием подзапроса.*/
-- Все 3 способа поиска значений в массиве из заданий 1,2 совпадают по производительности(при имеющимся наборе данных).
-- С имеющимся набором данных запросы с использованием CTE и с использованием подзапроса 
-- по производительности не имеют существенных различий, план запроса фактически одинаковый.

--Задание 7. Используя оконную функцию, выведите для каждого сотрудника сведения о первой его продаже.
select
  p.*
from (select
	    p.*, 
        row_number() over(partition by s.staff_id order by p.payment_date) row_num
        from   staff   s
	      join rental  r on r.staff_id = s.staff_id
          join payment p on p.rental_id = r.rental_id and p.staff_id = r.staff_id) p
where row_num = 1;

/*Задание 8. Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
•	день, в который арендовали больше всего фильмов (в формате год-месяц-день);
•	количество фильмов, взятых в аренду в этот день;
•	день, в который продали фильмов на наименьшую сумму (в формате год-месяц-день);
•	сумму продажи в этот день.*/
select 
  store_id, 
  max(case when rental_count = rental_count_max then rental_date end)  rental_count_max_date,
  max(case when rental_count = rental_count_max then rental_count end) rental_count,
  max(case when amount_sum = amount_sum_min then rental_date end)      rental_amount_min_date,
  max(case when amount_sum = amount_sum_min then amount_sum end)       amount_sum
from (select
	    store_id,
	    rental_date,
	    amount_sum,
	    max(rental_count) over(partition by store_id, rental_date order by rental_date) rental_count,
	    max(rental_count) over(partition by store_id order by store_id) rental_count_max,
	    min(amount_sum) over(partition by store_id order by store_id) amount_sum_min
	  from (select 
	  		st.store_id,
	  		cast(r.rental_date as date) rental_date,
	  		dense_rank() over(partition by st.store_id, cast(r.rental_date as date) order by r.rental_id) rental_count,
	  		sum(p.amount) over(partition by st.store_id, cast(r.rental_date as date) order by cast(r.rental_date as date)) amount_sum	
	  	  from        store     st
	  		left join inventory i on i.store_id = st.store_id
	  		left join rental    r on r.inventory_id = i.inventory_id
	  		left join payment   p on p.rental_id = r.rental_id) rd) rd
	  where rental_count = rental_count_max
	     or amount_sum = amount_sum_min
group by store_id;