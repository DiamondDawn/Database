-- COMP9311 18s2 Assignment 1
-- Schema for the myPhotos.net photo-sharing site
--
-- Written by:
--    Name:  <<LUXIN JIN>>
--    Student ID:  <<z5204617>>
--    Date:  01/09/2018
--
-- Conventions:
-- * all entity table names are plural
-- * most entities have an artifical primary key called "id"
-- * foreign keys are named after either:
--   * the relationship they represent
--   * the table being referenced

-- Domains (you may add more)
create domain URLValue as
    varchar(100) check (value like 'http://%');

create domain EmailValue as
    varchar(100) check (value like '%@%.%');

create domain GenderValue as
    varchar(6) check (value in ('male','female'));

create domain VisibilityValue as 
       varchar(20) check(value in ('private', 'friends', 'family', 'friends+family', 'public'));

create domain SafetyValue as 
    varchar(10) check (value in ('safe', 'moderate', 'restricted'));

create domain GroupModeValue as
    varchar(15) check (value in ('private','by-invitation','by-request'));

create domain ContactListTypeValue as
    varchar(10) check (value in ('friends','family'));

create domain NameValue as varchar(50);

create domain LongNameValue as varchar(100);

create domain RatingValue 
    integer check (value in(1,2,3,4,5));


-- Tables (you must add more)
---------------------------------------------------
-- People and user:
create table People (
    id              serial,
    family_name     NameValue,
    given_names     NameValue,
    displayed_name  LongNameValue NOT NULL,
    email_address   EmailValue NOT NULL,
    primary key(id)
);

create table Users (
    id             integer references People(id),
    password       text,
    gender         GenderValue,           
    birthday       timestamp,
    website        URLValue,
    date_registed  timestamp,
    primary key(id)
);

---------------------------------------------------
-- Contact Lists and Groups:
create table Contact_lists (
    id            serial NOT NULL,
    title         NameValue,
    type          ContactListTypeValue,
    users         integer NOT NULL,
    primary key (id),
    foreign key (users) references Users(id)
);

create table Person_contactlist(
    person         integer,
    contact_lists  integer NOT NULL, 
    primary key (person,contact_lists),
    foreign key (person) references People(id),
    foreign key (contact_lists) references Contact_lists(id)
);

--------------------------
create table Groups (
    id            serial NOT NULL,
    title         NameValue,
    mode          GroupModeValue,
    users         integer NOT NULL,
    primary key (id),
    foreign key (users) references Users(id)
);

create table User_group(
    users         integer,
    groups        integer NOT NULL,
    primary key (users,groups),
    foreign key (users) references Users(id),
    foreign key (groups) references Groups(id)
);


---------------------------------------------------
-- Discussions
create table Discussions(
    id            serial,
    title         NameValue,
    primary key (id)
);

---------------------------------------------------
-- Photos
create table Photos (
       id                  serial,
       title               NameValue,
       description         text,   
       file_size           integer,
       visibility          VisibilityValue,
       safety_level        SafetyValue,
       technical_details   text,
       date_taken          timestamp,
       date_uploaded       timestamp,
       users               integer NOT NULL,
       discussion          integer,
       primary key (id),
       foreign key (users) references Users(id) deferrable,
       foreign key (discussion) references Discussions(id)
);

alter table Users add foreign key (photo) references Photos(id) deferrable;
---------------------------------------------------
--Tags and Ratings
create table Tags (
    id             serial,
    name           NameValue,
    frequency      integer,
    primary key(id)
);

create table Photo_tag (
    photo        integer,
    tag          integer NOT NULL,
    primary key (photo,tag),
    foreign key (photo) references Photos(id),
    foreign key (tag) references Tags(id)
);

create table Rating(
    rating        RatingValue NOT NULL,
    when_rated    timestamp,
    users         integer,
    photo         integer,
    primary key(users,photo), 
    foreign key (users) references Users(id),
    foreign key (photo) references Photos(id)
);

---------------------------------------------------
--Collections:
create table Collections (
    id            serial,  
    title         NameValue,
    description   text,        
    photo         integer NOT NULL,  
    primary key(id),
    foreign key (photo) references Photos(id)
);

--------------------------
create table Photo_in_Collection (
    orders       integer,
    photo        integer ,
    collection   integer,
    primary key (photo,collection),
    foreign key (photo) references Photos(id),
    foreign key (collection) references Collections(id)
);


--------------------------
create table User_collection (
    id           integer references Collections(id),--disjoint
    users        integer NOT NULL,
    primary key(id),
    foreign key (users) references Users(id)
);

--------------------------
create table Group_collection (
    id           integer references Collections(id),--disjoint
    groups       integer NOT NULL,
    primary key(id),
    foreign key (groups) references Groups(id)
);

---------------------------------------------------
--Comments
create table Comments(
    id              serial, 
    when_posted     timestamp,
    content         text,
    discussion      integer NOT NULL,
    users           integer NOT NULL,
    reply           integer,
    primary key (id),
    foreign key (users) references Users(id),
    foreign key (reply) references Comments(id),
    foreign key (discussion) references Discussions(id)
);


create table Group_has_Discussions(
    groups          integer, 
    discussion      integer, 
    primary key (groups,discussion),
    foreign key (groups) references Groups(id),
    foreign key (discussion) references Discussions(id)
);