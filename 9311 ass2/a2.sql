--    COMP9311 18s2 Assignment 2
--    Written by:
--    Name:  <<LUXIN JIN>>
--    Student ID:  <<z5204617>>
--    Date:  26/09/2018

--1. List all the editors.
create or replace view Q1(Name) as
select distinct(p.Name) from Person p,Proceeding pr
where p.PersonId = pr.EditorId
;

--2. List all the editors that have authored a paper.
create or replace view Q2(Name) as 
select distinct(p.Name)
from Person p
           join Proceeding pr on (pr.EditorId = p.PersonId)
           join RelationPersonInProceeding r on (r.PersonId = p.PersonId)
;


--3. List all the editors that have authored a paper in the proceeding that they have edited.
create or replace view Q3(Name) as 
select distinct(p.Name)
from Person p
           join Proceeding pr on (pr.EditorId = p.PersonId)
           join InProceeding i on (i.ProceedingId = pr.ProceedingId)
           join RelationPersonInProceeding r on (r.PersonId = p.PersonId and r.InProceedingId = i.InProceedingId  )
;


--4. For all editors that have authored a paper in a proceeding that they have edited, list the title of those papers.
create or replace view Q4(Title) as
select i.Title
from Person p
           join Proceeding pr on (pr.EditorId = p.PersonId)
           join InProceeding i on (i.ProceedingId = pr.ProceedingId)
           join RelationPersonInProceeding r on (r.PersonId = p.PersonId and r.InProceedingId = i.InProceedingId  )
;


--5. Find the title of all papers authored by an author with last name "Clark".
create or replace view Q5(Title) as 
select i.Title 
from Person p
           join RelationPersonInProceeding r on (r.PersonId = p.PersonId)
           join InProceeding i on (i.InProceedingId  = r.InProceedingId)
where p.Name like '%Clark'
;    


--6. List the total number of papers published in each year, ordered by year in ascending order. 
--Do not include papers with an unknown year of publication. Also do not include years with no publication.
                                  
create or replace view Q6(Year, Total) as 
select pr.Year,count(pr.ProceedingId) 
from Proceeding pr
           join InProceeding i on(i.ProceedingId = pr.ProceedingId)
where pr.Year is not null
group by pr.Year 
order by pr.Year asc
;


--7. Find the most common publisher(s) (the name). (i.e., the publisher that has published the maximum total
--number of papers in the database).

create or replace view Publisher_and_numbers as 
select pu.Name as publisher,count(i.InProceedingId) as numbers
from Publisher pu
           join Proceeding pr on (pr.PublisherId = pu.PublisherId)
           join InProceeding i on (i.ProceedingId = pr.ProceedingId)
group by pu.Name
;

create or replace view Q7(Name) as 
select publisher
from Publisher_and_numbers
where numbers= (select max(numbers) from Publisher_and_numbers)
;


--8. Find the author(s) that co-authors the most papers (output the name). If there is more than one author with the same maximum number of co-authorships, output all of them.

create or replace view Q8a1 as
select r.InProceedingId,count(r.PersonId) as counts
from RelationPersonInProceeding r
group by r.InProceedingId
;

create or replace view Q8a2 as
select p.Name as author, count(i.title) as numbers
from InProceeding i
    join RelationPersonInProceeding r on (r.InProceedingid = i.InProceedingid)
    join Person p on (p.PersonId = r.PersonId)
    join Q8a1 on (Q8a1.InProceedingId = r.InProceedingid)
where Q8a1.counts <> 1
group by p.PersonId
order by numbers desc
;

create or replace view Q8(Name) as
select author
from Q8a2 
where numbers = (select max(numbers) from Q8a2)
;


--9. Find all the author names that never co-author (i.e., always published a paper as a sole author).


--functions for 9-12
-------------------------------------------------------------
-- f(paperid) = authorsid
create or replace function 
        f10 (integer) returns setof integer
as $$
select r.PersonId as authors
from RelationPersonInProceeding r 
where r.InProceedingId = $1;
$$ language sql
;

-- f(authorid) = papersid
create or replace function 
        f10a (integer) returns setof integer
as $$
select r.InProceedingId as papers
from RelationPersonInProceeding r 
where r.PersonId  = $1;
$$ language sql
;

-- f(authorid) = authorid with coauthorids
create or replace function 
        f10b (integer) returns setof integer
as $$
select distinct(f10(f10a($1)))
$$ language sql
;

-- f(authorid) = count(authorid with coauthorids)--will have negative
create or replace function 
        CountCoauthors (integer) returns bigint
as $$
(select count(*)-1 from f10b($1))
$$ language sql
;

create or replace view Coauthornumbers(Name, Total) as
select p.Name,CountCoauthors(p.PersonId) as Total 
from Person p
group by p.PersonId
order by total asc
;

create or replace view authornone as--didnt write anything
(select p.PersonId from Person p)
except
(select p.PersonId from Person p
             join RelationPersonInProceeding r on (r.PersonId = p.PersonId))
;


------------------------------------------------------------

--9. Find all the author names that never co-author (i.e., always published a paper as a sole author).

create or replace view Q9(Name) as
select Name from Coauthornumbers
where total= 0
;


--10. For each author, list their total number of co-authors, ordered by the total number of co-authors in descending order
create or replace view Q10(Name, Total) as
select p.Name,f10c(p.PersonId) as Total 
from Person p
where p.PersonId not in (select * from authornone)
group by p.PersonId
order by total desc
;


--11. Find all the author names that have never co-authored with any co-author of Richard (i.e. Richard is the
--author's first name), nor co-authored with Richard himself.
create or replace view Q11a as
select p.Personid as RichardId, p.Name 
from Person p 
where p.Name ilike 'Richard %'
;

create or replace view Q11b as
select distinct(f10b(Q11a.RichardId)) as Ri_co
from Q11a
order by Ri_co asc
;

create or replace view Q11c as
select distinct(f10b(Q11b.Ri_co)) as Ri_co_co
from Q11b
order by Ri_co_co asc
;

create or replace view Q11d as
(select p.PersonId from Person p
where p.PersonId not in (select * from Q11c))
except
(select * from authornone)
;

create or replace view Q11(Name) as
select p.Name from Person p
where p.PersonId in (select * from Q11d)
order by p.PersonId
;

--12. Output all the authors that have co-authored with or are indirectly linked to Richard (i.e. Richard is the
--author's first name). We define that a is indirectly linked to b if there exists a C p 1 , p 1 C p 2 ,..., p n C b,
--where x C y means x is co-authored with y.
create or replace view Q12a as
select distinct(f10b(Q11b.Ri_co)) as Q12a
from Q11b
;

create or replace view Q12b as
select distinct(f10b(Q12a)) as Q12b
from Q12a
;

create or replace view Q12c as
select distinct(f10b(Q12b)) as Q12c
from Q12b
;

create or replace view Q12d as 
select distinct(f10b(Q12c)) as Q12d
from Q12c
;

create or replace view Q12e as 
select distinct(f10b(Q12d)) as Q12e
from Q12d
;


create or replace view Q12f as 
select distinct(f10b(Q12e)) as Q12f
from Q12e
;

create or replace view Q12g as 
select distinct(f10b(Q12f)) as Q12g
from Q12f
;

create or replace view Q12h as 
(select * from Q12g)
except
(select RichardId from Q11a)
;

create or replace view Q12(Name) as
select p.Name 
from Person p
where p.PersonId in (select * from Q12h)
;


--13. Output the authors name, their total number of publications, the first year they published, and the last year
--they published. 

-- f(authorid) = papersid fix with has been published -f10a

create or replace view Q13(Author, Total, FirstYear, LastYear) as
select p.Name as Author, 
       count(r.InProceedingId) as Total,
       min(pr.Year),
       max(pr.Year) 
from Person p
           join RelationPersonInProceeding r on (r.PersonId = p.PersonId)
           join InProceeding i on (i.InProceedingId = r.InProceedingId)     
           join Proceeding pr on (pr.ProceedingId = i.ProceedingId)
group by p.PersonId
order by Total desc, Author asc
;


--14. Suppose that all papers that are in the database research area either contain the word or substring "data" (case insensitive) in their title or in a proceeding that contains the word or substring "data". Find the number of authors that are in the database research area. (We only count the number of authors and will not include an editor that has never published a paper in the database research area).


create or replace view Q14a as
select distinct(p.PersonId) as PersonId
from Person p
           join RelationPersonInProceeding r on (r.PersonId = p.PersonId)
           join InProceeding i on (i.InProceedingId = r.InProceedingId) 
           join Proceeding pr on (pr.ProceedingId = i.ProceedingId)
where pr.Title ILIKE '%data%' 
order by PersonId asc
;

create or replace view Q14b as
select distinct(p.PersonId) 
from Person p
           join RelationPersonInProceeding r on (r.PersonId = p.PersonId)
           join InProceeding i on (i.InProceedingId = r.InProceedingId) 
where i.Title ILIKE '%data%'
order by PersonId asc
;

create or replace view Q14c as
(select * from Q14a)
UNION 
(select * from Q14b)
;

create or replace view Q14(Total) as
select count(*) from Q14c
;


--15. Output the following information for all proceedings: editor name, title, publisher name, year, total number of papers in the proceeding. Your output should be ordered by the total number of papers in the proceeding in descending order, then by the year in ascending order, then by the title in ascending order.
--create or replace view Q15(EditorName, Title, PublisherName, Year, Total) as

create or replace view Q15a as
select pr.EditorId,pr.title,pr.PublisherId,pr.Year,count(i.InProceedingId) as total
from InProceeding i
             join Proceeding pr on (pr.ProceedingId = i.ProceedingId)
group by pr.ProceedingId
;

create or replace view Q15(EditorName, Title, PublisherName, Year, Total) as
select p.Name as EditorName,Q15a.title,pu.Name as PublisherName,Q15a.year,Q15a.total
from Person p,Publisher pu,Q15a
where p.PersonId = Q15a.EditorId and pu.PublisherId = Q15a.PublisherId 
order by total desc, year asc, title asc;
;



--16. Output the author names that have never co-authored (i.e., always published a paper as a sole author) nor
--edited a proceeding.

create or replace view Q16 as
(select name from Q9)
except 
(select * from Q1)
;


--17. Output the author name, and the total number of proceedings in which the author has at least one paper
--published, ordered by the total number of proceedings in descending order, and then by the author name in
--ascending order.

-- f(authorid) = magazinesid that have published at least one of his work


create or replace view Q17(Name, Total) as
select p.Name,count(distinct(pr.ProceedingId)) as total
from Person p
           join RelationPersonInProceeding r on (r.PersonId = p.PersonId)
           join InProceeding i on (i.InProceedingId  = r.InProceedingId)
           join Proceeding pr on (pr.ProceedingId = i.ProceedingId)
group by p.PersonId
--group by p.PersonId
order by total desc, p.Name asc
;


--18. Count the number of publications per author and output the minimum, average and maximum count per
--author for the database. Do not include papers that are not published in any proceedings.

-- f(authorid) = magazinesid that have published at least one of his work

create or replace view Q18a(Name, Total) as
select p.Name,count(distinct(i.InProceedingId ))
from Person p
           join RelationPersonInProceeding r on (r.PersonId  = p.PersonId)
           join InProceeding i on (i.InProceedingId  = r.InProceedingId)
           join Proceeding pr on (pr.ProceedingId = i.ProceedingId)
group by p.PersonId
;


create or replace view Q18(MinPub, AvgPub, MaxPub) as
select min(total),round(avg(total)),max(total)
from Q18a
;

--19. Count the number of publications per proceeding and output the minimum, average and maximum count
--per proceeding for the database.


create or replace view Q19a(Name, Total) as
select pr.ProceedingId,count(distinct(i.InproceedingId))as Total 
from InProceeding i 
           right join Proceeding pr on (pr.ProceedingId = i.ProceedingId)
group by pr.ProceedingId
order by total asc
;

create or replace view Q19(MinPub, AvgPub, MaxPub) as
select min(total),round(avg(total)),max(total)
from Q19a
;


--20. Create a trigger on RelationPersonInProceeding, to check and disallow any insert or update of a paper in
--the RelationPersonInProceeding table from an author that is also the editor of the proceeding in which the
--paper has published.

--20.1. List all the editors.-id
create or replace view Q20a(Name) as
select distinct(p.PersonId) 
from Person p,Proceeding pr
where p.PersonId = pr.EditorId
order by PersonId asc
;

--20.2.the magazines the editor has edited
create or replace function 
        f20a (integer) returns setof integer
as $$
select pr.ProceedingId
from Person p
           join Proceeding pr on (pr.EditorId = p.PersonId)
where $1 = p.PersonId
$$ language sql
;

--20.3.the function to jugde if the inproceeding is in the proceeding the editor edits
create or replace function 
        f20 (integer,integer) returns boolean
--editor,inproceeding
as $$
      select case
             when $1 not in (select * from Q20a) then False
             when (select pr.ProceedingId 
                   from InProceeding i 
                            join proceeding pr on (pr.ProceedingId = i.ProceedingId)
                   where i.InProceedingId = $2)  in (select * from f20a($1)) then True
             else False
             end
$$ language sql
;


create or replace function
  insertRelationPersonInProceeding() returns trigger
as $$
begin
  if f20(new.PersonId,new.InProceedingId)=True then
        raise exception 'Not allowed,you can''t insert or update of a paper in the RelationPersonInProceeding table from an author that is also the editor of the proceeding in which the paper has published.';
        end if;
end;
$$ language plpgsql;


create trigger InsertRelationPersonInProceeding
before insert or update on RelationPersonInProceeding
for each row execute procedure insertRelationPersonInProceeding();



--INSERT INTO RelationPersonInProceeding (PersonId, InProceedingId) VALUES (42,40);
--INSERT INTO RelationPersonInProceeding (PersonId, InProceedingId) VALUES (44,29);


--21. Create a trigger on Proceeding to check and disallow any insert or update of a proceeding in the
--Proceeding table with an editor that is also the author of at least one of the papers in the proceeding.



-- f(authorid) = papersid-f10a($1))
----f(proceedingid) = papersid - f15a

create or replace function 
        f15a (integer) returns setof integer
as $$
select i.InProceedingId 
from InProceeding i
             join Proceeding pr on (pr.ProceedingId = i.ProceedingId)
where pr.ProceedingId   = $1;
$$ language sql
;

create or replace function 
        f21q (integer,integer) returns setof integer
as $$
      (select * from f10a($1) intersect ALL (select * from f15a($2)))
$$ language sql
;

--21.3.the function to jugde if the author is one of at least one of the papers in the proceeding
--f21(editor,proceeding)
create or replace function 
        f21 (integer,integer) returns boolean
as $$
      select case
             when $1 not in (select * from Q20a) then False
             when (select count(*) from f21q($1,$2))>0 then True
             else False
             end
$$ language sql
;

create or replace function
  insertProceeding() returns trigger
as $$
begin
  if f21(new.EditorId,new.ProceedingId)=True then
        raise exception 'Not allowed,you can''t insert or update of a proceeding in the
Proceeding table with an editor that is also the author of at least one of the papers in the proceeding.';
        end if;
        return new;
end;
$$ language plpgsql;


create trigger InsertProceeding
before insert or update on Proceeding
for each row execute procedure insertProceeding();

--22. Create a trigger on InProceeding to check and disallow any insert or update of a proceeding in the
--InProceeding table with an editor of the proceeding that is also the author of at least one of the papers in
--the proceeding.



--22.1. List all the editors--(select * from Q20a)


--22.2.the proceedingid where the editor has wrote papers
-- f(authorid) = papersid - f10a -already

----f(papersid ) = proceedingid - f22a
create or replace function 
        f22a (integer) returns setof integer
as $$
select pr.ProceedingId 
from InProceeding i
             join Proceeding pr on (pr.ProceedingId = i.ProceedingId)
where i.inProceedingId = $1;
$$ language sql
;

-- f(authorsid) = proceedingid -f22b-f22a(f10a())
create or replace function 
        f22b (integer) returns setof integer
as $$
select distinct(f22a(f10a($1)))
$$ language sql
;


--22.3.the function to jugde if the proceedingid is in where the editor has wrote papers
--f22(editor,proceedingid)
create or replace function 
        f22 (integer,integer) returns boolean
as $$
      select case
             when $1 not in (select * from Q20a) then False
             when $2 in (select * from f22b($1)) then True
             else False
             end
$$ language sql
;

-- f(paperid) = authorsid --f10 - already

create or replace function
  insertInProceeding() returns trigger
as $$
declare
  i InProceeding;
begin
  if f22(f10(new.InProceedingId),new.ProceedingId) = True then -- lots of authors
        raise exception 'Not allowed';
        end if;
        return new;
end;
$$ language plpgsql;


create trigger InsertInProceeding
before insert or update on InProceeding
for each row execute procedure insertInProceeding();








