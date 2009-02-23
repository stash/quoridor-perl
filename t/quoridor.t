#!perl
use Test::More tests => 116;
use Test::Exception;
use warnings FATAL => 'all';
use strict;

use_ok 'Quoridor';

local $Quoridor::UNLIMITED_WALLS = 1;

basic: {
    my $q = Quoridor->new();
    isa_ok $q, 'Quoridor';
}


wall_create: {
    my $wall = Quoridor::Wall->new(
        loc => [1,2],
        dir => 'row',
    );
    isa_ok $wall, 'Quoridor::Wall';
    is $wall->placed_by, undef;

    dies_ok {
        Quoridor::Wall->new(
            loc => [1,2],
            dir => 'blarf',
        );
    };
}

wall: {
    my $q = Quoridor->new();

    oob: {
        for my $set (
            [-1,-1], [9,9],
            [-100,0], [0,-100],
            [ 100,0], [0, 100],
        ) {
            $@ = undef;
            eval { $q->wall($set) };
            like $@, qr/out of bounds/, join(',','oob',@$set);
        }

        for my $set (
            [row => -1,-1], [col => -1,-1], 
            [row => 10,10], [col => 10,10],
        ) {
            eval { $q->place_wall(@$set) };
            like $@, qr/out of bounds/, join(',','place oob',@$set);
        }
    }

    place_row: {
        my $wall = $q->wall(1,1);
        ok !$wall;
        lives_ok { $q->place_wall(row => 1,1) };
        $wall = $q->wall(1,1);
        ok $wall;
        is $wall->dir, 'row';
    }

    place_col: {
        my $wall = $q->wall(7,7);
        ok !$wall;
        lives_ok { $q->place_wall(col => 7,7) };
        $wall = $q->wall(7,7);
        ok $wall;
        is $wall->dir, 'col';
    }

    edge: {
        for my $set (
            [col => 0,0], [row => 0,0],
            [col => 0,1], [row => 0,1],
            [col => 0,9], [row => 0,9],
            [col => 9,0], [row => 9,0],
            [col => 9,1], [row => 9,1],
            [col => 9,9], [row => 9,9],
        ){
            eval { $q->place_wall(@$set) };
            like $@, qr/can't place wall on edge of board/,
                "wall edge (".join(',',@$set).")";
        }
    }
}

overlapping: {
    my $q = Quoridor->new();

    cross: {
        $q->place_wall(row => 1,5);
        isa_ok $q->wall(1,5), 'Quoridor::Wall';
        is $q->wall(1,5)->dir, 'row';

        eval { $q->place_wall(col => 1,5) };
        like $@, qr/already a row wall at \(1,5\)/;

        $q->place_wall(col => 7,1);
        isa_ok $q->wall(7,1), 'Quoridor::Wall';
        is $q->wall(7,1)->dir, 'col';

        eval { $q->place_wall(row => 7,1) };
        like $@, qr/already a col wall at \(7,1\)/;
        eval { $q->place_wall(col => 7,1) };
        like $@, qr/already a col wall at \(7,1\)/;

        eval { $q->place_wall(row => 1,5) };
        like $@, qr/already a row wall at \(1,5\)/;
        eval { $q->place_wall(col => 1,5) };
        like $@, qr/already a row wall at \(1,5\)/;
    }

    common: {
        $q->place_wall(row => 3,3);
        isa_ok $q->wall(3,3), 'Quoridor::Wall';
        is $q->wall(3,3)->dir, 'row';

        eval { $q->place_wall(row => 2,3) };
        like $@, qr/wall overlaps/;
        eval { $q->place_wall(row => 4,3) };
        like $@, qr/wall overlaps/;

        $q->place_wall(col => 5,5);
        isa_ok $q->wall(5,5), 'Quoridor::Wall';
        is $q->wall(5,5)->dir, 'col';

        eval { $q->place_wall(col => 5,4) };
        like $@, qr/wall overlaps/;
        eval { $q->place_wall(col => 5,6) };
        like $@, qr/wall overlaps/;
    }
}

run_out_of_walls: {
    local $Quoridor::UNLIMITED_WALLS = 0;
    my $q = Quoridor->new();
    is $q->player->walls_remaining, 10, 'starts out with the right #';

    $q->player->dec_walls for (1..9);

    $q->place_wall(row => 1,1);
    is $q->player->walls_remaining, 0, 'no walls left';

    eval { $q->place_wall(row => 2,2) };
    ok $@;
}

setup_players: {
    my $q = Quoridor->new();

    my $players = $q->players;
    my ($a, $b, $c) = @$players;
    isa_ok $a, 'Quoridor::Player';
    isa_ok $b, 'Quoridor::Player';
    is $c, undef, 'just two players';

    is $a->name, 'Player A';
    is $a->symbol, 'A';
    is_deeply $a->loc, [4,0];

    is $b->name, 'Player B';
    is $b->symbol, 'B';
    is_deeply $b->loc, [4,8];

    my $active = $q->player;
    isa_ok $active, 'Quoridor::Player';
    is $active, $a;
    is $active->name, 'Player A';
    is_player_at($q => 4,0);
}

next_player: {
    my $q = Quoridor->new();

    isa_ok $q->player, 'Quoridor::Player';
    is $q->player->name, 'Player A';

    my $next = $q->next_player;
    isa_ok $next, 'Quoridor::Player';
    is $next, $q->player;
    is $next->name, 'Player B';

    is $q->next_player->name, 'Player A';
    is $q->player->name, 'Player A';

    is $q->next_player->name, 'Player B';
    is $q->player->name, 'Player B';
}

player_move: {
    my $q = Quoridor->new();

    $q->_place_player(0,0);
    is_player_at($q => 0,0);

    eval { $q->move_player('up'); };
    like $@, qr/cannot move up; edge of board/;
    is_player_at($q => 0,0);

    eval { $q->move_player('left'); };
    like $@, qr/cannot move left; edge of board/;
    is_player_at($q => 0,0);

    $q->move_player('down');
    is_player_at($q => 0,1);

    $q->move_player('right');
    is_player_at($q => 1,1);


    $q->_place_player(8,8);
    is_player_at($q => 8,8);

    eval { $q->move_player('down'); };
    like $@, qr/cannot move down; edge of board/;
    is_player_at($q => 8,8);

    eval { $q->move_player('right'); };
    like $@, qr/cannot move right; edge of board/;
    is_player_at($q => 8,8);

    $q->move_player('up');
    is_player_at($q => 8,7);

    $q->move_player('left');
    is_player_at($q => 7,7);
}

walls_block_movement: {
    my $q = Quoridor->new();
    $q->place_wall(row => 4,8);
    $q->next_player();
    is_player_at($q => 4,8);

    eval { $q->move_player('down') };
    like $@, qr/cannot move down; edge of board/;
    is_player_at($q => 4,8);

    eval { $q->move_player('up') };
    like $@, qr/cannot move up; wall/;
    is_player_at($q => 4,8);


    $q->_place_player(4,7);

    eval { $q->move_player('down') };
    like $@, qr/cannot move down; wall/;
    is_player_at($q => 4,7);


    $q->place_wall(col => 4,5);
    $q->next_player();

    $q->_place_player(4,4);
    eval { $q->move_player('left') };
    like $@, qr/cannot move left; wall/;
    is_player_at($q => 4,4);

    $q->_place_player(3,4);
    eval { $q->move_player('right') };
    like $@, qr/cannot move right; wall/;
    is_player_at($q => 3,4);
}

walls_in_a_list: {
    my $q = Quoridor->new();
    is_deeply $q->wall_list, [];

    my $w1 = $q->place_wall(row => 4,4);
    isa_ok $w1, 'Quoridor::Wall';
    is $w1->placed_by->symbol, 'A';
    $q->next_player();

    is_deeply $q->wall_list, [$w1];
    is $q->first_wall, $w1;
    is $q->last_wall, $w1;
    is $q->wall_count, 1;

    my $w2 = $q->place_wall(row => 5,5);
    isa_ok $w2, 'Quoridor::Wall';
    is $w2->placed_by->symbol, 'B';
    $q->next_player();

    is_deeply $q->wall_list, [$w1,$w2];
    is $q->first_wall, $w1;
    is $q->last_wall, $w2;
    is $q->wall_count, 2;
}

# TODO: illegal to cut off player from destination
# TODO: jumping pawns
# TODO: jumping pawns, but blocked by wall

ok 1, 'done';

sub is_player_at {
    my ($q, $u, $v) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $p = $q->player->loc;
    my ($player_u, $player_v) = @$p;

    ok($u == $player_u && $v == $player_v)
        or diag("    Player at ($player_u,$player_v) instead of ($u,$v)");
}

exit;
