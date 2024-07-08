--Задание 1. Выведите уникальные названия городов из таблицы городов
select distinct 
  city
from city c
order by city;

/*Задание 2. Доработайте запрос из предыдущего задания, чтобы запрос выводил только те города, 
названия которых начинаются на “L” и заканчиваются на “a”, и названия не содержат пробелов.*/
select distinct 
  city
from city c
where city like 'L%a'
  and position(' ' in trim(city)) = 0
order by city;

/*Задание 3. Получите из таблицы платежей за прокат фильмов информацию по платежам, 
которые выполнялись в промежуток с 17 июня 2005 года по 19 июня 2005 года включительно 
и стоимость которых превышает 1.00. Платежи нужно отсортировать по дате платежа.*/
select
  p.*
from payment p
where p.payment_date >= '20050617'::TIMESTAMP WITHOUT TIME ZONE 
  and p.payment_date < '20050620'::TIMESTAMP WITHOUT TIME ZONE
  and p.amount > 1.00
order by p.payment_date;

--Задание 4. Выведите информацию о 10-ти последних платежах за прокат фильмов.
select
  p.*
from payment p
order by p.payment_date desc
limit 10;

/*Задание 5. Выведите следующую информацию по покупателям:
•	Фамилия и имя (в одной колонке через пробел)
•	Электронная почта
•	Длину значения поля email
•	Дату последнего обновления записи о покупателе (без времени)
Каждой колонке задайте наименование на русском языке.*/
select
  c.last_name || ' ' || c.first_name "Фамилия и имя",
  c.email                            "Электронная почта",
  length(coalesce(c.email, ''))      "Длина значения поля email",
  cast(c.last_update as date)        "Дата последнего обновления записи"
from customer c
order by c.last_name;

/*Задание 6. Выведите одним запросом только активных покупателей, 
имена которых KELLY или WILLIE. 
Все буквы в фамилии и имени из верхнего регистра 
должны быть переведены в нижний регистр.*/
select
  lower(c.last_name)  as last_name,
  lower(c.first_name) as first_name
from customer c
where c.active = 1
  and c.first_name in ('KELLY', 'WILLIE')
order by c.last_name;

/*Задание 7. Выведите одним запросом информацию о фильмах, 
у которых рейтинг “R” и стоимость аренды указана от 0.00 до 3.00 включительно, 
а также фильмы c рейтингом “PG-13” и стоимостью аренды больше или равной 4.00.*/
select
  f.*
from film f
where (f.rating = 'R' and f.rental_rate between 0.0 and 3.00)
   or (f.rating = 'PG-13' and f.rental_rate >= 4.00) 
order by f.rating;

--Задание 8. Получите информацию о трёх фильмах с самым длинным описанием фильма.
select
  f.film_id,
  f.title,
  f.description,
  f.release_year,
  f.language_id,
  f.original_language_id,
  f.rental_duration,
  f.rental_rate,
  f.length,
  f.replacement_cost,
  f.rating,
  f.last_update,
  f.special_features,
  f.fulltext
from (select
        dense_rank() over(order by length(coalesce(f.description, '')) desc) as row_rank,
        f.*							   
      from film f) f
where f.row_rank <= 3
order by length(f.description) desc;
		
/*Задание 9. Выведите Email каждого покупателя, разделив значение Email на 2 отдельных колонки:
•	в первой колонке должно быть значение, указанное до @,
•	во второй колонке должно быть значение, указанное после @.*/
select
  substring(c.email from 0 for position('@' in c.email))                 as email_first,
  substring(c.email from position('@' in c.email)+1 for length(c.email)) as email_last
from customer c
order by email_first;

/*Задание 10. Доработайте запрос из предыдущего задания, скорректируйте значения в новых колонках: 
первая буква должна быть заглавной, остальные строчными.*/
select
  substring(email_first from 1 for 1) 
    || lower(substring(email_first from 2 for length(email_first))) as email_first,
  
  upper(substring(email_last from 1 for 1)) 
    || substring(email_last from 2 for length(email_last)) as email_last
from (select
        substring(c.email from 0 for position('@' in c.email))                 as email_first,
        substring(c.email from position('@' in c.email)+1 for length(c.email)) as email_last
      from customer c) c
order by email_first;