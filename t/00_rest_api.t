#!/usr/bin/perl

use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use FindBin;
use Storable qw(dclone);

require $FindBin::Bin .'/../rest_api.pl';

my $t = Test::Mojo->new;

#########################################################################################
## GET / ################################################################################
$t->get_ok('/')
    ->status_is(200)
    ->text_is('head > title' => 'Комментарии');

#########################################################################################
## GET /articles/comment ################################################################
{
    my $form_hashref = {article_id => 1};

    $t->get_ok('/articles/comment' => form => $form_hashref)
        ->status_is(200)
        ->json_is('/status' => 200)
        ->json_is('/comments' => all_comments());

    my $make_some_bad_decisions = sub {
        my $callback = shift;

        my $bad_form_hashref = $callback->(dclone $form_hashref);

        $t->get_ok('/articles/comment' => form => $bad_form_hashref)
            ->status_is(422)
            ->json_is('/status' => 422);
    };

    $make_some_bad_decisions->(sub {
        my $hashref = shift;
        delete $hashref->{'article_id'};
        return $hashref;
    });
    $make_some_bad_decisions->(sub {
        my $hashref = shift;
        $hashref->{'article_id'} = 'string';
        return $hashref;
    });
}


#########################################################################################
## POST /articles/comment ###############################################################
{
    my $form_hashref = {
        article_id => 1,
        user_id    => 1,
        comment    => 'Hello!',
    };

    $t->post_ok('/articles/comment' => form => $form_hashref)
        ->status_is(200)
        ->json_is('/status' => 200)
        ->json_like('/comment_id' => qr{^\d+$}x);

    my $make_some_bad_decisions = sub {
        my $callback = shift;

        my $bad_form_hashref = $callback->(dclone $form_hashref);

        $t->post_ok('/articles/comment' => form => $bad_form_hashref)
            ->status_is(422)
            ->json_is('/status' => 422);
    };

    $make_some_bad_decisions->(sub {
        my $hashref = shift;
        delete $hashref->{'article_id'};
        return $hashref;
    });
    $make_some_bad_decisions->(sub {
        my $hashref = shift;
        $hashref->{'article_id'} = 'string';
        return $hashref;
    });

    $make_some_bad_decisions->(sub {
        my $hashref = shift;
        delete $hashref->{'user_id'};
        return $hashref;
    });
    $make_some_bad_decisions->(sub {
        my $hashref = shift;
        $hashref->{'user_id'} = 'string';
        return $hashref;
    });

    $make_some_bad_decisions->(sub {
        my $hashref = shift;
        delete $hashref->{'comment'};
        return $hashref;
    });

    $make_some_bad_decisions->(sub {
        my $hashref = shift;
        $hashref->{'parent_id'} = 'string';
        return $hashref;
    });
}


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

