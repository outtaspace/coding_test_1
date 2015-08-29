#!/usr/bin/perl

use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use FindBin;
use Storable qw(dclone);

require $FindBin::Bin .'/../rest_api.pl';

my $t = Test::Mojo->new;

#########################################################################################
## GET /article/:article_id/comments ####################################################
$t->get_ok('/article/1/comments' => {'Accept' => 'text/html'})
    ->status_is(200)
    ->text_is('head > title' => 'Comments');

$t->get_ok('/article/1/comments' => {'Accept' => 'application/json'})
    ->status_is(200)
    ->json_is('/status' => 200)
    ->json_is('/comments' => all_comments());

#########################################################################################
## POST /article/:article_id/comments ###################################################
$t->post_ok('/article/1/comments' => form => {user_id => 1, comment => 'Hello!'})
    ->status_is(200)
    ->json_is('/status' => 200)
    ->json_like('/comment_id' => qr{^\d+$}x);

#########################################################################################
## done_testing #########################################################################
done_testing();

#########################################################################################
## subroutines ##########################################################################
sub all_comments {
    return [
        {
            id        => '1',
            parent_id => '0',
            user_id   => 1,
            comment   => 'root_0',
            comments => [
                {
                    id        => '2',
                    parent_id => '1',
                    comment   => '1_0',
                    user_id   => 1,
                    comments  => [
                        {
                            id        => '4',
                            parent_id => '2',
                            user_id   => 1,
                            comment   => '2_0',
                            comments  => [],
                        },
                        {
                            id        => '5',
                            parent_id => '2',
                            comment   => '2_1',
                            user_id   => 1,
                            comments  => [],
                        },
                    ],
                },
                {
                    id        => '3',
                    parent_id => '1',
                    comment   => '1_1',
                    user_id   => 1,
                    comments  => [
                        {
                            id        => '6',
                            parent_id => '3',
                            comment   => '3_0',
                            user_id   => 1,
                            comments  => [],
                        },
                        {
                            id        => '7',
                            parent_id => '3',
                            comment   => '3_1',
                            user_id   => 1,
                            comments  => [],
                        },
                    ],
                },
            ],
        },
        {
            id        => '8',
            parent_id => '0',
            user_id   => 1,
            comment   => 'root_1',
            comments  => [],
        },
    ];
}

