-- here we are populating(filling) data and creating relationship with match_fact

use role accountadmin;
use warehouse compute_wh;
use schema cricket.consume;

-- version 1 here we are getting for the particular match
select 
    m.match_type_number as match_id,
    dd.date_id,
    0 as referee_id
from 
    cricket.clean.match_detail_clean m
    join date_dim dd on m.event_date = dd.full_dt
where m.match_type_number = 4696;

-- version 2 here we are getting both the teams
select 
    m.match_type_number as match_id,
    dd.date_id,
    0 as referee_id,
    ftd.team_id,
    std.team_id
from 
    cricket.clean.match_detail_clean m
    join date_dim dd on m.event_date = dd.full_dt
    join team_dim ftd on m.first_team = ftd.team_name
    join team_dim std on m.second_team = std.team_name
where m.match_type_number = 4696;

-- version 3 here we are getting both the teams with match type
select 
    m.match_type_number as match_id,
    dd.date_id,
    0 as referee_id,
    ftd.team_id,
    std.team_id,
    mtd.match_type_id
from 
    cricket.clean.match_detail_clean m
    join date_dim dd on m.event_date = dd.full_dt
    join team_dim ftd on m.first_team = ftd.team_name
    join team_dim std on m.second_team = std.team_name
    join match_type_dim mtd on m.match_type = mtd.match_type
where m.match_type_number = 4668;

-- version 4 here we are getting both the teams with match type along with venue_id
select 
    m.match_type_number as match_id,
    dd.date_id,
    0 as referee_id,
    ftd.team_id,
    std.team_id,
    mtd.match_type_id,
    vd.venue_id
from 
    cricket.clean.match_detail_clean m
    join date_dim dd on m.event_date = dd.full_dt
    join team_dim ftd on m.first_team = ftd.team_name
    join team_dim std on m.second_team = std.team_name
    join match_type_dim mtd on m.match_type = mtd.match_type
    join venue_dim vd on m.venue = vd.venue_name
where m.match_type_number = 4669;

-- version 5 now we will populate the additional information with hard coding

insert into cricket.consumption.match_fact 
select 
    m.match_type_number as match_id,
    dd.date_id as date_id,
    0 as referee_id,
    ftd.team_id as first_team_id,
    std.team_id as second_team_id,
    mtd.match_type_id as match_type_id,
    vd.venue_id as venue_id,
    50 as total_overs,
    6 as balls_per_overs,
    max(case when d.team_name = m.first_team then  d.over else 0 end ) as OVERS_PLAYED_BY_TEAM_A,
    sum(case when d.team_name = m.first_team then  1 else 0 end ) as balls_PLAYED_BY_TEAM_A,
    sum(case when d.team_name = m.first_team then  d.extras else 0 end ) as extra_balls_PLAYED_BY_TEAM_A,
    sum(case when d.team_name = m.first_team then  d.extra_runs else 0 end ) as extra_runs_scored_BY_TEAM_A,
    0 fours_by_team_a,
    0 sixes_by_team_a,
    (sum(case when d.team_name = m.first_team then  d.runs else 0 end ) + sum(case when d.team_name = m.first_team then  d.extra_runs else 0 end ) ) as total_runs_scored_BY_TEAM_A,
    sum(case when d.team_name = m.first_team and player_out is not null then  1 else 0 end ) as wicket_lost_by_team_a,    
    
    max(case when d.team_name = m.second_team then  d.over else 0 end ) as OVERS_PLAYED_BY_TEAM_B,
    sum(case when d.team_name = m.second_team then  1 else 0 end ) as balls_PLAYED_BY_TEAM_B,
    sum(case when d.team_name = m.second_team then  d.extras else 0 end ) as extra_balls_PLAYED_BY_TEAM_B,
    sum(case when d.team_name = m.second_team then  d.extra_runs else 0 end ) as extra_runs_scored_BY_TEAM_B,
    0 fours_by_team_b,
    0 sixes_by_team_b,
    (sum(case when d.team_name = m.second_team then  d.runs else 0 end ) + sum(case when d.team_name = m.second_team then  d.extra_runs else 0 end ) ) as total_runs_scored_BY_TEAM_B,
    sum(case when d.team_name = m.second_team and player_out is not null then  1 else 0 end ) as wicket_lost_by_team_b,
    tw.team_id as toss_winner_team_id,
    m.toss_decision as toss_decision,
    m.match_result as matach_result,
    mw.team_id as winner_team_id
     
from 
    cricket.clean.match_detail_clean m
    join date_dim dd on m.event_date = dd.full_dt
    join team_dim ftd on m.first_team = ftd.team_name 
    join team_dim std on m.second_team = std.team_name 
    join match_type_dim mtd on m.match_type = mtd.match_type
    join venue_dim vd on m.venue = vd.venue_name and m.city = vd.city
    join cricket.clean.delivery_clean_table d  on d.match_type_number = m.match_type_number 
    join team_dim tw on m.toss_winner = tw.team_name 
    join team_dim mw on m.winner= mw.team_name 
    --where m.match_type_number = 4668
    group by
        m.match_type_number,
        date_id,
        referee_id,
        first_team_id,
        second_team_id,
        match_type_id,
        venue_id,
        total_overs,
        toss_winner_team_id,
        toss_decision,
        matach_result,
        winner_team_id
        ;

select * from match_fact where match_id =4668; -- there are duplicate values here so its showing me two rows in this you can use Distinct for now
