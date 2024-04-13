use schema cricket.consume;

create or replace table data_dim(
    data_id int primary key autoincrement,
    full_dt date,
    day int,
    month int,
    year int,
    quarter int,
    dayofweek int,
    dayofmonth int,
    dayofyear int,
    dayofweekname varchar(3), --to store day names in 3 letters
    isweekend boolean -- to indiacate if it is a weenend or not -- true/false
);

--match references.reserve_umpires.field_umpires
create or replace table referee_dim (
    referee_id int primary key autoincrement,
    referee_name text not null,
    referee_type text not null
);

--afghansithan ,australia, etc...
create or replace table team_dim(
    team_id int primary key autoincrement,
    team_name text not null
)

--player dim table
create or replace table player_dim(
    player_id int primary key,
    team_id int not null,
    player_name text not null
);

--now altering player dim
alter table cricket.consume.player_dim
add constraint fk_team_player_id
foreign key (team_id)
references cricket.consume.team_dim(team_id);


create or replace table venue_dim(
    venue_id int primary key autoincrement,
    venue_name text not null,
    city text not null,
    state text,
    country text,
    continent text,
    end_Names text,
    capacity number,
    pitch text,
    flood_light boolean,
    established_dt date,
    playing_area text,
    other_sports text,
    curator text,
    lattitude number(10,6),
    longitude number(10,6)
);

create or replace table match_type_dim(
    match_type_id int primary key autoincrement,
    match_type text not null
);


--match fact table
create or replace table match_fact (
    match_id int primary key autoincrement,
    date_id int not null,
    referee_id int not null,
    team_a_id int not null,
    team_b_id int not null,
    match_type_id int not null,
    venue_id int not null,
    city text,
    total_overs number(3),
    balls_per_over number(3),

    overs_played_by_team_a number(2),
    balls_played_by_team_a number(3),
    extra_balls_played_by_team_a number(3),
    extra_runs_scored_by_team_a number(3),
    fours_by_team_a number(3),
    sixes_by_team_a number(3),
    total_score_by_team_a number(3),
    wicket_lost_by_team_a number(2),

    overs_played_by_team_b number(2),
    balls_played_by_team_b number(3),
    extra_balls_played_by_team_b number(3),
    extra_runs_scored_by_team_b number(3),
    fours_by_team_b number(3),
    sixes_by_team_b number(3),
    total_score_by_team_b number(3),
    wicket_lost_by_team_b number(2),

    toss_winner_team_id int not null,
    toss_decision text not null,
    match_result text not null,
    winner_team_id int not null,

    constraint fk_date foreign key (date_id) references data_dim (data_id),
    constraint fk_referee foreign key (referee_id) references referee_dim(referee_id),
    constraint fk_team1 foreign key (team_a_id) references team_dim(team_id),
    constraint fk_team2 foreign key (team_b_id) references team_dim(team_id),
    constraint fk_venue foreign key (venue_id) references venue_dim(venue_id),

    constraint fk_toss_winner_team foreign key (toss_winner_team_id) references team_dim(team_id),
    constraint fk_winner_team foreign key (winner_team_id) references team_dim(team_id)
    
);

--now we populate table
--we will extraxt teh dimensoin table data using our table from clean layer
--and it will be based on description field as we don't have any master data set.
--in rest wrld, you may also get master data set as seperate entities.

--let us start with team dim, and for simplicity, it is just team name
--v1
select distinct team_name from(
select first_team as team_name from cricket.clean.match_detail_clean
union all
select second_team as team_name from cricket.clean.match_detail_clean
);

--v2
insert into cricket.consume.team_dim(team_name)
select distinct team_name from(
select first_team as team_name from cricket.clean.match_detail_clean
union all
select second_team as team_name from cricket.clean.match_detail_clean) 
order by team_name;

--v3
select * from cricket.consume.team_dim order by team_name;

------------------
--team player

--v1
select * from cricket.clean.player_clean_tbl limit 10;

--v2 
select country,player_name from cricket.clean.player_clean_tbl group by country, player_name;

--v3
select a.country, b.team_id, a.player_name
from
    cricket.clean.player_clean_tbl a join cricket.consume.team_dim b
    on a.country = b.team_name
group by
    a.country,
    b.team_id,
    a.player_name;

--v4 insert data 
insert into cricket.consume.player_dim(team_id, player_name)
select b.team_id, a.player_name
from 
    cricket.clean.player_clean_tbl a join cricket.consume.team_dim b
    on a.country = b.team_name
group by 
    b.team_id, 
    a.player_name; 

select * from cricket.consume.player_dim;


-- using the Referee Dimension *****************************************************

-- version 1
select * from cricket.clean.match_detail_clean;

-- version 2 here into info we have raw format of referee details available
select info 
from cricket.raw.match_raw_table ; -- limit is optional

-- version 3 
select 
    info:officials.match_referees[0]::text as match_referee,
    info:officials.reserve_umpires[0]::text as reserve_umpire,
    info:officials.tv_umpires[0]::text as tv_umpire,
    info:officials.umpires[0]::text as first_umpire,
    info:officials.umpires[1]::text as second_umpire
    
from cricket.raw.match_raw_table ;

-- using the Venue Dimension *****************************************************

-- version 1
select * from cricket.clean.match_detail_clean limit 10;  -- limit is optional

-- version 2
select venue, city from cricket.clean.match_detail_clean limit 10;  -- limit is optional

-- version 3
select venue, city from cricket.clean.match_detail_clean
group by venue, city;

-- version 4
insert into cricket.consume.venue_dim (venue_name,city)
select venue,city 
from (
    select venue,
        case when city is null then 'NA'
        else city
        end as city
    from cricket.clean.match_detail_clean
)
group by venue, city;

-- version 5
select * from cricket.consume.venue_dim where city = 'Bengaluru';

select city from cricket.consume.venue_dim group by city having count(1)>1;



-- using the Venue Dimension *****************************************************
-- we have only one match type here

-- version 1
select * from cricket.clean.match_detail_clean limit 10;  -- limit is optional

-- version 2
select match_type from cricket.clean.match_detail_clean group by match_type;

-- version 3 
insert into cricket.consumption.match_type_dim (match_type)
select match_type from cricket.clean.match_detail_clean group by match_type;


-- using the Date Dimension *****************************************************

-- just checking min and max date in dataset
select min(event_date), max(event_date) from cricket.clean.match_detail_clean;