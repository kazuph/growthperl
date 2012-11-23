create table entry (
    id int(11) PRIMARY KEY AUTOINCREMENT, 
    entry_id varchar(36) binary not null,
    body text not null,
    run_time text NOT NULL,
    result text unsigned NOT NULL,
    timestamp timestamp not null,
) engine=innodb;
