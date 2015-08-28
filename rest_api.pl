#!/usr/bin/perl

use Mojolicious::Lite;
use DBI;

plugin 'Config';

app->secrets(app->config->{'secrets'});

app->attr(dbh => sub {
    my $hashref = shift->config;

    return DBI->connect(@{ $hashref->{'dbh'} });
});

get '/' => 'index';

get '/articles/comment' => sub {
    my $self = shift;

    {
        my $validation = $self->validation;
        $validation->required('article_id')->like(qr{^\d+$}x);

        return $self->render(json => {status => 422}, status => 422)
            if $validation->has_error;
    }

    my $sth = $self->app->dbh->prepare(q{
        select
            id, parent_id, user_id, comment
        from
            comments
        where
            article_id = ?
        order by
            parent_id, id
    });
    $sth->execute($self->param('article_id'));

    my %parent = (0 => []);

    while (my $each_comment = $sth->fetchrow_hashref) {
        my ($id, $parent_id) = map { $each_comment->{$_} } qw(id parent_id);

        $each_comment->{'comments'} = [];

        $parent{$id} = $each_comment->{'comments'};

        push @{ $parent{$parent_id} }, $each_comment;
    }

    $self->render(json => {status => 200, comments => $parent{0}});
};

post '/articles/comment' => sub {
    my $self = shift;

    {
        my $validation = $self->validation;
        $validation->optional('parent_id')->like(qr{^\d+$}x);
        $validation->required('comment');
        $validation->required('article_id')->like(qr{^\d+$}x);
        $validation->required('user_id')->like(qr{^\d+$}x);

        return $self->render(json => {status => 422}, status => 422)
            if $validation->has_error;
    }

    my ($comment_id) = do {
        my $parent_id = $self->param('parent_id') // 0;
        my $comment   = $self->param('comment')   // q{};

        my $dbh = $self->app->dbh;

        $dbh->begin_work();

        $dbh->do(q{
            insert into `comments` (`parent_id`, `comment`, `article_id`, `user_id`)
            values (?, ?, ?, ?);
        }, undef, $parent_id, $comment, map { $self->param($_) } qw(article_id user_id));

        my $sth = $dbh->prepare(q{select last_insert_id();});
        $sth->execute();

        $dbh->commit();

        $sth->fetchrow_array();
    };

    $self->render(json => {status => 200, comment_id => $comment_id});
};

app->start;

__DATA__

@@ index.html.ep
% title 'Комментарии';
% layout 'main';

@@ layouts/main.html.ep
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title><%= title %></title>
        <script src="js/jquery-2.1.4.min.js"></script>
        <script src="js/main.js"></script>
    </head>
    <body>
        <%= content %>
    </body>
</html>

