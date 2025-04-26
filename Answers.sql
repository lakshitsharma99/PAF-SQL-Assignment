-- Task 1: This will create new table users_enqs_txns based on CTE to show number of enquiries and transactions per user per date, if just want to return the output, please run CTE instead

create table users_enqs_txns as
  
    with users_enqs_txns as (
  
        select
            user_id,
            date,
            count(*) AS count_enqs,
            0 AS count_txns
        from enquiries
        group by user_id, date

        union all

        select
            user_id,
            date,
            0 AS count_enqs,
            count(*) AS count_txns
        from txns
        group by user_id, date
  
    )
  
    select
        *
    from users_enqs_txns
    order by user_id, date

-- Task 2: This will create CTE to show array of transactions per enquiry for each date and user where transaction happedned between 30 days of enquiry

with last_30_days_enqs as (

    select
        e.enquiry_id,
        e.date,
        e.user_id,
        t.txn_id
    from enquiries e
    left join txns t on t.user_id = e.user_id
    where e.date <= t.date
    and e.date > DATEADD(day, -30, t.date)

), earliest_enq_per_txn as (

    select
        *
    from (
            select
                *,
                row_number() over (partition by txn_id order by date asc) AS enquiry_order
            from last_30_days_enqs
        ) as a
    where a.enquiry_order = 1

)

select
    enquiry_id,
    date,
    user_id,
    isnull('[' + string_agg(txn_id, ', ') + ']', '[]') AS txn_ids
from earliest_enq_per_txn
group by enquiry_id, date, user_id
order by enquiry_id
