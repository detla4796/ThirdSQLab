/*
ПРАКТИЧЕСКАЯ РАБОТА №3
TechStore — логическая витрина продаж.

Исходное состояние: корректно завершённая ЛР2.

Перед каждым CREATE VIEW в комментарии зафиксировать:
1) аналитический вопрос;
2) grain — что означает одна строка;
3) используемые measures;
4) используемые dimensions.
*/

USE TechStore_DWH;
GO

/* 
   Шаг 1. Схема mart
*/

if schema_id(N'mart') is null
	exec(N'create schema mart');
go

/* 
   Шаг 2. mart.vw_SalesByMonthCategory
   1) как продажи меняются по месяцам и категориям?
   2) один год + месяц + категория
   3) orderscount, unitssold, revenue, avgrevenueperorder
   4) year, month, category 
*/

create or alter view mart.vw_SalesByMonthCategory as
select 
	d.[year] as [Year],
	d.[month] as MonthNumber,
	d.monthname as MonthName,
	p.category as Category,
	count(distinct f.orderid) as OrdersCount,
	sum(f.quantity) as UnitsSold,
	sum(f.amount) as Revenue,
	sum(f.amount) / nullif(count(distinct f.orderid), 0) as AvgRevenuePerOrder
from dbo.factsales as f
join dbo.dimdate as d on d.datekey = f.datekey
join dbo.dimproduct as p on p.productkey = f.productkey
group by d.[year], d.[month], d.monthname, p.category;
go

/* 
   Шаг 3. mart.vw_ProductPerformance
   1) какие товары приносят больше всего выручки?
   2) один товар
   3) orderscount, unitssold, revenue, avghistoricalunitprice
   4) product, category 
*/

create or alter view mart.vw_ProductPerformance as
select
	p.productid as ProductID,
	p.productname as ProductName,
	p.category as Category,
	count(distinct f.orderid) as OrdersCount,
	sum(f.quantity) as UnitsSold,
	sum(f.amount) as Revenue,
	sum(f.amount) / nullif(sum(f.quantity), 0) as AvgHistoricalUnitPrice
from dbo.factsales as f
join dbo.dimproduct as p on p.productkey = f.productkey
group by p.productid, p.productname, p.category;
go

/* 
   Шаг 4. mart.vw_CustomerValue
   1) какие клиенты самые ценные?
   2) один клиент
   3) orderscount, unitspurchased, totalspent, avgordervalue
   4) customer, city 
*/

create or alter view mart.vw_CustomerValue as
select
	c.customerid as CustomerID,
	c.firstname as FirstName,
	c.lastname as LastName,
	c.city as City,
	count(distinct f.orderid) as OrdersCount,
	sum(f.quantity) as UnitsPurchased,
	sum(f.amount) as TotalSpent,
	sum(f.amount) / nullif(count(distinct f.orderid), 0) as AvgOrderValue
from dbo.factsales as f
join dbo.dimcustomer as c on c.customerkey = f.customerkey
group by c.customerid, c.firstname, c.lastname, c.city;
go

/* 
   Шаг 5. mart.vw_SalesByCity
   1) в каких городах продажи сильнее?
   2) один город клиента
   3) customerscount, orderscount, unitssold, revenue, avgordervalue
   4) city 
*/

create or alter view mart.vw_SalesByCity as
select
	c.city as City,
	count(distinct c.customerkey) as CustomersCount,
	count(distinct f.orderid) as OrdersCount,
	sum(f.quantity) as UnitsSold,
	sum(f.amount) as Revenue,
	sum(f.amount) / nullif(count(distinct f.orderid), 0) as AvgOrderValue
from dbo.factsales as f
join dbo.dimcustomer as c on c.customerkey = f.customerkey
group by c.city;
go

/* 
   Шаг 6. Проверка через системный каталог
*/

select s.name as SchemaName, v.name as ViewName
from sys.views as v
join sys.schemas as s on s.schema_id = v.schema_id
where s.name = N'mart' and v.name in (N'vw_SalesByMonthCategory', N'vw_ProductPerformance', N'vw_CustomerValue', N'vw_SalesByCity')
order by v.name;
go

select
	c.column_id as ColumnId,
	c.name as ColumnName,
	t.name as DataType,
	c.max_length as MaxLength,
	c.precision as [Precision],
	c.scale as Scale
from sys.columns as c
join sys.types as t on t.user_type_id = c.user_type_id
where c.object_id = object_id(N'mart.vw_SalesByMonthCategory')
order by c.column_id;
go

/* 
   Шаг 7. Аналитика только через mart.*
 */

-- top 5 товаров по revenue
select top (5) ProductName, Category, UnitsSold, Revenue
from mart.vw_ProductPerformance
order by Revenue desc, ProductName;
go

-- top 3 клиентов по totalspent
select top (3) FirstName, LastName, City, OrdersCount, TotalSpent
from mart.vw_CustomerValue
order by TotalSpent desc, LastName, FirstName;
go

-- город-лидер по revenue
select top (1) City, OrdersCount, Revenue
from mart.vw_SalesByCity
order by Revenue desc, City;
go

-- год + месяц + категория с максимальной revenue
select top (1) [Year], MonthNumber, MonthName, Category, UnitsSold, Revenue
from mart.vw_SalesByMonthCategory
order by Revenue desc, [Year], MonthNumber, Category;
go

/* 
   Шаг 8. Итоговые проверки
 */

-- После завершения выполнить 90_final_checks_lab03.sql. (все скриншоты в пдф)