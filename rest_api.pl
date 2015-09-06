#!/usr/bin/perl

use Mojolicious::Lite;
use DBI;

plugin 'Config';

app->secrets(app->config->{'secrets'});

app->attr(dbh => sub {
    my $hashref = shift->config;

    return DBI->connect(@{ $hashref->{'dbh'} });
});

get '/article/:article_id/comments' => sub {
    my $self = shift;

    $self->stash(user_id => 1);

    $self->respond_to(
        html => {template => 'index'},
        json => sub {
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
        },
    );
} => 'all_comments';

post '/article/:article_id/comments' => sub {
    my $self = shift;

    $self->respond_to(
        json => sub {
            my ($comment_id) = do {
                my $parent_id = $self->param('parent_id') // 0;
                my $comment   = $self->param('comment')   // q{};

                my $dbh = $self->app->dbh;

                $dbh->begin_work;

                $dbh->do(q{
                    insert into comments (parent_id, `comment`, article_id, user_id)
                    values (?, ?, ?, ?)
                }, undef, $parent_id, $comment, map { $self->param($_) } qw(article_id user_id));

                my $sth = $dbh->prepare(q{select last_insert_id()});
                $sth->execute;

                $dbh->commit;

                $sth->fetchrow_array;
            };

            $self->render(json => {status => 200, comment_id => $comment_id});
        },
    );
} => 'create_a_new_comment';

app->start;

__DATA__

@@ index.html.ep
% title 'Comments';
% layout 'main';
<script>
$(document).ready(function() {
    'use strict';

    app.req.user_id                      = '<%= stash 'user_id' %>';
    app.req.article_id                   = '<%= param 'article_id' %>';
    app.req.url_for_all_comments         = '<%= url_for('all_comments') %>';
    app.req.url_for_create_a_new_comment = '<%= url_for('create_a_new_comment') %>';

    app.init_bindings();
    app.reload_comments();
});
</script>
<script type="text/template" id="tmpl_comment_body">
<div class="media panel" data-id="${id}" data-parent-id="${parent_id}">
    <div class="media-body">
        <p class="comment_body">${comment}</p>
        <div class="btn-group btn-group-xs" role="group">
            <button type="button" class="btn btn-default add_comment" aria-label="Left Align">
                <span class="glyphicon glyphicon-comment" aria-hidden="true"></span>
                <span>Comment this</span>
            </button>
        </div>
        <div class="comments"></div>
    </div>
</div>
</script>
<script type="text/template" id="tmpl_comment_form">
<form class="form-horizontal">
    <div class="form-group">
        <div class="col-sm-10">
            <textarea class="form-control"></textarea>
        </div>
    </div>
    <div class="form-group">
        <div class="btn-group-xs col-sm-10" role="group">
            <button type="button" class="btn btn-default submit_comment" aria-label="Left Align">
                <span class="glyphicon glyphicon-ok" aria-hidden="true"></span>
                <span>Submit</span>
            </button>
            <button type="button" class="btn btn-default cancel_comment" aria-label="Left Align">
                <span class="glyphicon glyphicon-remove" aria-hidden="true"></span>
                <span>Cancel</span>
            </button>
        </div>
    </div>
</form>
</script>
<div id="create_a_new_comment" class="panel panel-default">
    <div class="panel-body">
        <button type="button" class="btn btn-default add_comment" aria-label="Left Align">
            <span class="glyphicon glyphicon-comment" aria-hidden="true"></span>
            <span>Create a new comment</span>
        </button>
        <form class="form-horizontal" hidden="true">
            <div class="form-group">
                <textarea class="form-control"></textarea>
            </div>
            <div class="form-group">
                <div class="btn-group" role="group">
                    <button type="button" class="btn btn-default submit_comment" aria-label="Left Align">
                        <span class="glyphicon glyphicon-ok" aria-hidden="true"></span>
                        <span>Submit</span>
                    </button>
                    <button type="button" class="btn btn-default cancel_comment" aria-label="Left Align">
                        <span class="glyphicon glyphicon-remove" aria-hidden="true"></span>
                        <span>Cancel</span>
                    </button>
                </div>
            </div>
        </form>
    </div>
</div>
<div id="all_comments" class="panel panel-default">
    <div class="panel-heading">Comments</div>
    <div class="panel-body"></div>
</div>

@@ layouts/main.html.ep
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title><%= title %></title>
        <link rel="stylesheet" href="/css/bootstrap.min.css">
        <link rel="stylesheet" href="/css/bootstrap-theme.min.css">
        <script src="/js/jquery.min.js"></script>
        <script src="/js/bootstrap.min.js"></script>
        <script src="/js/jquery.tmpl.min.js"></script>
        <script src="/js/main.js"></script>
    </head>
    <body>
        <%= content %>
    </body>
</html>

