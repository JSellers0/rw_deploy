CREATE DATABASE rw_budget_dev;

CREATE TABLE IF NOT EXISTS`account` (
  `accountid` int(11) NOT NULL AUTO_INCREMENT,
  `account_name` varchar(200) NOT NULL,
  `account_type` varchar(100) NOT NULL,
  `rewards_features` varchar(300) DEFAULT NULL,
  `payment_day` varchar(50) DEFAULT NULL,
  `statement_day` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`accountid`)
) ENGINE = InnoDB AUTO_INCREMENT = 9 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
;

CREATE TABLE IF NOT EXISTS `category` (
  `categoryid` int(11) NOT NULL AUTO_INCREMENT,
  `category_name` varchar(200) NOT NULL,
  `insert_date` datetime DEFAULT sysdate(),
  `insert_by` varchar(100) DEFAULT current_user(),
  `update_date` datetime DEFAULT sysdate(),
  `update_by` varchar(100) DEFAULT current_user(),
  PRIMARY KEY (`categoryid`)
) ENGINE = InnoDB AUTO_INCREMENT = 28 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
;

CREATE TABLE `recurring_transaction` (
  `rtranid` int(11) NOT NULL AUTO_INCREMENT,
  `last_transactionid` int(11) DEFAULT NULL,
  `expected_day` int(11) NOT NULL,
  `merchant_name` varchar(200) NOT NULL,
  `categoryid` int(11) DEFAULT NULL,
  `amount` decimal(7, 2) NOT NULL,
  `accountid` int(11) DEFAULT NULL,
  `transaction_type` varchar(200) NOT NULL,
  `note` varchar(1000) DEFAULT NULL,
  `is_monthly` tinyint(1) DEFAULT NULL,
  `insert_date` datetime DEFAULT sysdate(),
  `insert_by` varchar(100) DEFAULT current_user(),
  `update_date` datetime DEFAULT sysdate(),
  `update_by` varchar(100) DEFAULT current_user(),
  PRIMARY KEY (`rtranid`),
  KEY `last_transactionid` (`last_transactionid`),
  KEY `categoryid` (`categoryid`),
  KEY `accountid` (`accountid`),
  CONSTRAINT `recurring_transaction_ibfk_1` FOREIGN KEY (`last_transactionid`) REFERENCES `transactions` (`transactionid`),
  CONSTRAINT `recurring_transaction_ibfk_2` FOREIGN KEY (`categoryid`) REFERENCES `category` (`categoryid`),
  CONSTRAINT `recurring_transaction_ibfk_3` FOREIGN KEY (`accountid`) REFERENCES `account` (`accountid`)
) ENGINE = InnoDB AUTO_INCREMENT = 33 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
;

CREATE TABLE `transactions` (
  `transactionid` int(11) NOT NULL AUTO_INCREMENT,
  `transaction_date` date NOT NULL,
  `cashflow_date` date NOT NULL,
  `merchant_name` varchar(200) NOT NULL,
  `categoryid` int(11) DEFAULT NULL,
  `amount` decimal(7, 2) NOT NULL,
  `accountid` int(11) DEFAULT NULL,
  `transaction_type` varchar(200) NOT NULL,
  `note` varchar(1000) DEFAULT NULL,
  `insert_date` datetime DEFAULT sysdate(),
  `insert_by` varchar(100) DEFAULT current_user(),
  `update_date` datetime DEFAULT sysdate(),
  `update_by` varchar(100) DEFAULT current_user(),
  PRIMARY KEY (`transactionid`),
  KEY `categoryid` (`categoryid`),
  KEY `accountid` (`accountid`),
  KEY `transaction_date_idx` (`transaction_date`),
  KEY `ix_transactions_cashflow_date` (`cashflow_date`),
  KEY `ix_transactions_transaction_date` (`transaction_date`),
  CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`categoryid`) REFERENCES `category` (`categoryid`),
  CONSTRAINT `transactions_ibfk_2` FOREIGN KEY (`accountid`) REFERENCES `account` (`accountid`)
) ENGINE = InnoDB AUTO_INCREMENT = 1198 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
;

CREATE VIEW `vw_cashflow` AS
with
  chk as (
    select
      extract(
        month
        from
          `t`.`cashflow_date`
      ) AS `flow_month`,
      extract(
        year
        from
          `t`.`cashflow_date`
      ) AS `flow_year`,
      sum(
        case
          when `t`.`transaction_type` = 'debit'
          and extract(
            day
            from
              `t`.`cashflow_date`
          ) < 15 then `t`.`amount`
          else 0
        end
      ) AS `chk_in_top`,
      sum(
        case
          when `t`.`transaction_type` = 'credit'
          and extract(
            day
            from
              `t`.`cashflow_date`
          ) < 15 then `t`.`amount`
          else 0
        end
      ) AS `chk_out_top`,
      sum(
        case
          when `t`.`transaction_type` = 'debit'
          and extract(
            day
            from
              `t`.`cashflow_date`
          ) > 14 then `t`.`amount`
          else 0
        end
      ) AS `chk_in_bot`,
      sum(
        case
          when `t`.`transaction_type` = 'credit'
          and extract(
            day
            from
              `t`.`cashflow_date`
          ) > 14 then `t`.`amount`
          else 0
        end
      ) AS `chk_out_bot`
    from
      `transactions` `t`
    where
      `t`.`accountid` in (
        select
          `account`.`accountid`
        from
          `account`
        where
          `account`.`account_type` = 'Checking'
      )
      and ! (
        `t`.`categoryid` in (
          select
            `category`.`categoryid`
          from
            `category`
          where
            `category`.`category_name` = 'Card Payment'
        )
      )
    group by
      extract(
        month
        from
          `t`.`cashflow_date`
      ),
      extract(
        year
        from
          `t`.`cashflow_date`
      )
  ),
  card as (
    select
      extract(
        month
        from
          `t`.`cashflow_date`
      ) AS `flow_month`,
      extract(
        year
        from
          `t`.`cashflow_date`
      ) AS `flow_year`,
      sum(
        case
          when `t`.`transaction_type` = 'debit'
          and extract(
            day
            from
              `t`.`cashflow_date`
          ) < 15 then `t`.`amount`
          else 0
        end
      ) AS `card_in_top`,
      sum(
        case
          when `t`.`transaction_type` = 'credit'
          and extract(
            day
            from
              `t`.`cashflow_date`
          ) < 15 then `t`.`amount`
          else 0
        end
      ) AS `card_out_top`,
      sum(
        case
          when `t`.`transaction_type` = 'debit'
          and extract(
            day
            from
              `t`.`cashflow_date`
          ) > 14 then `t`.`amount`
          else 0
        end
      ) AS `card_in_bot`,
      sum(
        case
          when `t`.`transaction_type` = 'credit'
          and extract(
            day
            from
              `t`.`cashflow_date`
          ) > 14 then `t`.`amount`
          else 0
        end
      ) AS `card_out_bot`
    from
      `transactions` `t`
    where
      `t`.`accountid` in (
        select
          `account`.`accountid`
        from
          `account`
        where
          `account`.`account_type` = 'Credit Card'
      )
      and ! (
        `t`.`categoryid` in (
          select
            `category`.`categoryid`
          from
            `category`
          where
            `category`.`category_name` in ('Card Payment', 'Finance Payment')
        )
      )
    group by
      extract(
        month
        from
          `t`.`cashflow_date`
      ),
      extract(
        year
        from
          `t`.`cashflow_date`
      )
  ),
  summary as (
    select
      `chk`.`flow_year` AS `flow_year`,
      `chk`.`flow_month` AS `flow_month`,
      `chk`.`chk_in_top` + `chk`.`chk_in_bot` + ifnull(`card`.`card_in_top`, 0) + ifnull(`card`.`card_in_bot`, 0) + (
        `chk`.`chk_out_top` + `chk`.`chk_out_bot` + ifnull(`card`.`card_out_top`, 0) + ifnull(`card`.`card_out_bot`, 0)
      ) AS `cash_remain_sum`,
      `chk`.`chk_in_top` + `chk`.`chk_in_bot` AS `cash_in_sum`,
      `chk`.`chk_out_top` + `chk`.`chk_out_bot` + ifnull(`card`.`card_out_top`, 0) + ifnull(`card`.`card_out_bot`, 0) AS `cash_out_sum`,
      `chk`.`chk_in_top` + ifnull(`card`.`card_in_top`, 0) + `chk`.`chk_out_top` + ifnull(`card`.`card_out_top`, 0) AS `cash_remain_top`,
      `chk`.`chk_in_top` + ifnull(`card`.`card_in_top`, 0) AS `cash_in_top`,
      `chk`.`chk_out_top` + ifnull(`card`.`card_out_top`, 0) AS `cash_out_top`,
      `chk`.`chk_in_bot` + ifnull(`card`.`card_in_bot`, 0) + `chk`.`chk_out_bot` + ifnull(`card`.`card_out_bot`, 0) AS `cash_remain_bot`,
      `chk`.`chk_in_bot` + ifnull(`card`.`card_in_bot`, 0) AS `cash_in_bot`,
      `chk`.`chk_out_bot` + ifnull(`card`.`card_out_bot`, 0) AS `cash_out_bot`
    from
      (
        `chk`
        left join `card` on (
          `card`.`flow_month` = `chk`.`flow_month`
          and `card`.`flow_year` = `chk`.`flow_year`
        )
      )
  )
select
  `summary`.`flow_year` AS `flow_year`,
  `summary`.`flow_month` AS `flow_month`,
  `summary`.`cash_remain_sum` AS `cash_remain_sum`,
  `summary`.`cash_in_sum` AS `cash_in_sum`,
  `summary`.`cash_out_sum` AS `cash_out_sum`,
  `summary`.`cash_remain_top` AS `cash_remain_top`,
  `summary`.`cash_in_top` AS `cash_in_top`,
  `summary`.`cash_out_top` AS `cash_out_top`,
  `summary`.`cash_remain_bot` AS `cash_remain_bot`,
  `summary`.`cash_in_bot` AS `cash_in_bot`,
  `summary`.`cash_out_bot` AS `cash_out_bot`
from
  `summary`
;

select 
`t`.`transactionid` AS `transactionid`
,extract(month from `t`.`cashflow_date`) AS `flow_month`
,extract(year from `t`.`cashflow_date`) AS `flow_year`
,'checking' AS `cashflow_account_type`
,case 
	when extract(day from `t`.`cashflow_date`) < 15 then 'top' 
	when extract(day from `t`.`cashflow_date`) > 14 then 'bot' 
	else 'UNCAT' end AS `cashflow_category`
,case 
	when `t`.`transaction_type` = 'debit' then 'income' 
	when `t`.`transaction_type` = 'credit' then 'expens' 
	end AS `cashflow_transaction_type`
	,`t`.`amount` AS `amount` 
from `rw_budget`.`transactions` `t` 
where `t`.`accountid` in (
	select `rw_budget`.`account`.`accountid` 
	from `rw_budget`.`account` 
	where `rw_budget`.`account`.`account_type` = 'Checking'
) 
	and !(`t`.`categoryid` in (
		select `rw_budget`.`category`.`categoryid` 
		from `rw_budget`.`category` 
		where `rw_budget`.`category`.`category_name` = 'Card Payment')
		) 
		or `t`.`accountid` in (
			select `rw_budget`.`account`.`accountid` 
			from `rw_budget`.`account` 
			where `rw_budget`.`account`.`account_type` = 'Credit Card'
		) and !(`t`.`categoryid` in (
			select `rw_budget`.`category`.`categoryid` 
			from `rw_budget`.`category` 
			where `rw_budget`.`category`.`category_name` in ('Card Payment','Finance Payment')
		)
	)
;

CREATE VIEW `vw_cashflow_chart` AS
with
  chart_base as (
    select
      `vw_cashflow_base`.`flow_year` AS `flow_year`,
      `vw_cashflow_base`.`flow_month` AS `flow_month`,
      cast(
        concat(
          `vw_cashflow_base`.`flow_year`,
          '-',
          `vw_cashflow_base`.`flow_month`,
          '-01'
        ) as date
      ) AS `tran_month_start`,
      `vw_cashflow_base`.`cashflow_category` AS `cashflow_category`,
      sum(`vw_cashflow_base`.`amount`) AS `amount`
    from
      `vw_cashflow_base`
    group by
      `vw_cashflow_base`.`flow_year`,
      `vw_cashflow_base`.`flow_month`,
      `vw_cashflow_base`.`cashflow_category`
    union
    select
      `vw_cashflow_base`.`flow_year` AS `flow_year`,
      `vw_cashflow_base`.`flow_month` AS `flow_month`,
      cast(
        concat(
          `vw_cashflow_base`.`flow_year`,
          '-',
          `vw_cashflow_base`.`flow_month`,
          '-01'
        ) as date
      ) AS `tran_month_start`,
      'total' AS `total`,
      sum(`vw_cashflow_base`.`amount`) AS `amount`
    from
      `vw_cashflow_base`
    group by
      `vw_cashflow_base`.`flow_year`,
      `vw_cashflow_base`.`flow_month`
  )
select
  monthname(
    concat(
      `chart_base`.`flow_year`,
      '-',
      `chart_base`.`flow_month`,
      '-01'
    )
  ) AS `tran_month_name`,
  `chart_base`.`tran_month_start` AS `tran_month_start`,
  `chart_base`.`cashflow_category` AS `cashflow_category`,
  `chart_base`.`amount` AS `amount`
from
  `chart_base`
;

CREATE VIEW `vw_cashflow_summary` AS
select
  `vw_cashflow_base`.`flow_year` AS `flow_year`,
  `vw_cashflow_base`.`flow_month` AS `flow_month`,
  concat(
    `vw_cashflow_base`.`cashflow_transaction_type`,
    '_',
    `vw_cashflow_base`.`cashflow_category`
  ) AS `cashflow_grp`,
  sum(`vw_cashflow_base`.`amount`) AS `amount`
from
  `vw_cashflow_base`
group by
  `vw_cashflow_base`.`flow_year`,
  `vw_cashflow_base`.`flow_month`,
  `vw_cashflow_base`.`cashflow_category`,
  `vw_cashflow_base`.`cashflow_transaction_type`
union
select
  `vw_cashflow_base`.`flow_year` AS `flow_year`,
  `vw_cashflow_base`.`flow_month` AS `flow_month`,
  concat('remain_', `vw_cashflow_base`.`cashflow_category`) AS `cashflow_grp`,
  sum(`vw_cashflow_base`.`amount`) AS `amount`
from
  `vw_cashflow_base`
group by
  `vw_cashflow_base`.`flow_year`,
  `vw_cashflow_base`.`flow_month`,
  `vw_cashflow_base`.`cashflow_category`
union
select
  `vw_cashflow_base`.`flow_year` AS `flow_year`,
  `vw_cashflow_base`.`flow_month` AS `flow_month`,
  concat(
    `vw_cashflow_base`.`cashflow_transaction_type`,
    '_sum'
  ) AS `cashflow_grp`,
  sum(`vw_cashflow_base`.`amount`) AS `amount`
from
  `vw_cashflow_base`
group by
  `vw_cashflow_base`.`flow_year`,
  `vw_cashflow_base`.`flow_month`,
  `vw_cashflow_base`.`cashflow_transaction_type`
union
select
  `vw_cashflow_base`.`flow_year` AS `flow_year`,
  `vw_cashflow_base`.`flow_month` AS `flow_month`,
  concat('remain_sum') AS `cashflow_grp`,
  sum(`vw_cashflow_base`.`amount`) AS `amount`
from
  `vw_cashflow_base`
group by
  `vw_cashflow_base`.`flow_year`,
  `vw_cashflow_base`.`flow_month`
;

GRANT ALL PRIVILEGES ON rw_budget_dev.* TO USER `svc_rw_budget`@'%';
FLUSH PRIVILEGES;