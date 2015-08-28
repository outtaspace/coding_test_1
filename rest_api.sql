drop database if exists coding_test;
create database coding_test character set=utf8;

use coding_test;

create table articles (
    id integer not null auto_increment,
    primary key (id)
) engine=innodb default charset=utf8 row_format=compact;

create table users (
    id integer not null auto_increment,
    primary key (id)
) engine=innodb default charset=utf8 row_format=compact;

create table comments (
    id integer not null auto_increment,
    parent_id integer not null,
    article_id integer not null,
    user_id integer not null,
    `comment` text not null,
    primary key (id)
) engine=innodb default charset=utf8 row_format=compact;

alter table coding_test.comments
add index fk_comments_to_articles_idx (article_id asc);
alter table coding_test.comments
add constraint fk_comments_to_articles
  foreign key (article_id)
  references coding_test.articles (id)
  on delete cascade
  on update no action;

alter table coding_test.comments
drop foreign key fk_comments_to_articles;
alter table coding_test.comments
add index fk_comments_to_users_idx (user_id asc),
drop index fk_comments_to_articles_idx;
alter table coding_test.comments
add constraint fk_comments_to_users
  foreign key (user_id)
  references coding_test.users (id)
  on delete cascade
  on update no action;

begin;
insert into articles values ();
insert into users    values ();

insert into comments (parent_id, comment, article_id, user_id)
values
(0, 'root_0', 1, 1),
(1, '1_0',  1, 1),
(1, '1_1',  1, 1),
(2, '2_0',  1, 1),
(2, '2_1',  1, 1),
(3, '3_0',  1, 1),
(3, '3_1',  1, 1),
(0, 'root_1', 1, 1);
commit;

