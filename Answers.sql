-- Task 1: This will create new table users_enqs_txns based on CTE to show number of enquiries and transactions per user per date, if just want to return the output, please run CTE instead

-- Create new table based of CTE
create table users_enqs_txns as
  
    with users_enqs_txns as (
  
        -- Count enquiries per user per date
        select
            user_id,
            date,
            count(*) AS count_enqs,
            0 AS count_txns
        from enquiries
        group by user_id, date

        union all
  
        -- Count transactions per user per date
        select
            user_id,
            date,
            0 AS count_enqs,
            count(*) AS count_txns
        from txns
        group by user_id, date
  
    )

  -- Final counts per user per date. Here we can also perform aggregation again on count_enqs and count_txns group by user_id, date to avoid multiple rows when user had both enquiries and transactions on the same date
    select
        *
    from users_enqs_txns
    order by user_id, date

-- Task 2: This will create CTE to show array of transactions per enquiry for each date and user where transaction happedned between 30 days of enquiry

with last_30_days_enqs as (
  
    -- Get last 30 days transactions happedned between 30 days of enquiry
    select
        e.enquiry_id,
        e.date,
        e.user_id,
        t.txn_id
    from enquiries e
    left join txns t on t.user_id = e.user_id
    where e.date <= t.date
    and e.date >= DATEADD(day, -30, t.date)

), earliest_enq_per_txn as (
  
    -- Filter out first enquiry for all transaction
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

-- Final query to show list of transactions as array per enquiry for date and user
select
    enquiry_id,
    date,
    user_id,
    isnull('[' + string_agg(txn_id, ', ') + ']', '[]') AS txn_ids
from earliest_enq_per_txn
group by enquiry_id, date, user_id
order by enquiry_id
