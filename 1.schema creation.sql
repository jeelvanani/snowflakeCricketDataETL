use role accountadmin;                --select role
use warehouse compute_wh;        --select compute

--creating database named cricket and 4 schemas for transformaing data
create database if not exists cricket;
create or replace schema cricket.land; --data landing schema
create or replace schema cricket.raw; -- data in raw format
create or replace schema cricket.clean;     --cleaned data 3rd step
create or replace schema cricket.consume;    --fully consumable data.

--landing data in cricket.land schema
use schema cricket.land;

--json format is complicated. let us break it down.
create or replace file format my_json_format
 type = json
 null_if = ('\\n', 'null', '')
    strip_outer_array = true
    comment = 'Json File Format with outer stip array flag true'; 

-- creating an internal stage
create or replace stage my_stg; 

-- lets list the internal stage
list @my_stg;

-- check if data is being loaded or not
--list @my_stg/cricket/json/;

-- quick check if data is coming correctly or not
select 
        t.$1:meta::variant as meta, 
        t.$1:info::variant as info, 
        t.$1:innings::array as innings, 
        metadata$filename as file_name,
        metadata$file_row_number int,
        metadata$file_content_key text,
        metadata$file_last_modified stg_modified_ts
     from  @my_stg/1384403.json (file_format => 'my_json_format') t;
