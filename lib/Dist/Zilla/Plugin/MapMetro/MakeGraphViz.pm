package Dist::Zilla::Plugin::MapMetro::MakeGraphViz;

use strict;
use warnings;
use 5.14.0;

use Moose;
use namespace::sweep;
use Path::Tiny;
use Types::Standard 'HashRef';
use Map::Metro;
use GraphViz2;

use Dist::Zilla::File::InMemory;
with 'Dist::Zilla::Role::FileGatherer';

has settings => (
    is => 'rw',
    isa => HashRef,
    traits => ['Hash'],
    init_arg => undef,
    handles => {
        set_setting => 'set',
        get_setting => 'get',
    },
);

sub gather_files {
    my $self = shift;

    my @mapclasses = path('lib/Map/Metro/Plugin/Map')->children(qr/\.pm$/);

    return if !scalar @mapclasses;
    my $map = path(shift @mapclasses)->basename;
    $map =~ s{\.pm$}{};

    my $graph = Map::Metro->new($map)->parse;

    my $customconnections = {};
    if(path('share/graphviz.conf')->exists) {
        my $settings = path('share/graphviz.conf')->slurp;
        $settings =~  s{^#.*$}{}g;
        $settings =~ s{\n}{ }g;

        foreach my $custom (split m/ +/ => $settings) {
            if($custom =~ m{^(\d+)->(\d+):([\d\.]+)$}) {
                my $origin_station_id = $1;
                my $destination_station_id = $2;
                my $len = $3;

                $self->set_setting(sprintf ('%s-%s', $origin_station_id, $destination_station_id), $len);
                $self->set_setting(sprintf ('%s-%s', $destination_station_id, $origin_station_id), $len);
            }
            elsif($custom =~ m{^!(\d+)->(\d+):([\d\.]+)$}) {
                my $origin_station_id = $1;
                my $destination_station_id = $2;
                my $len = $3;

                $customconnections->{ $origin_station_id }{ $destination_station_id } = $len;
            }
        }
    }

    my $viz = GraphViz2->new(
        global => { directed => 0 },
        graph => { epsilon => 0.00001 },
        node => { shape => 'circle', fixedsize => 'true', width => 0.8, height => 0.8, penwidth => 3, fontname => 'sans-serif', fontsize => 20 },
        edge => { penwidth => 5, len => 1.2 },
    );
    foreach my $station ($graph->all_stations) {
        $viz->add_node(name => $station->id, label => $station->id);
    }

    foreach my $transfer ($graph->all_transfers) {
        my %len = $self->get_len_for($transfer->origin_station->id, $transfer->destination_station->id);
        $viz->add_edge(from => $transfer->origin_station->id, to => $transfer->destination_station->id, color => '#888888', style => 'dashed', %len);
    }
    foreach my $segment ($graph->all_segments) {
        foreach my $line_id ($segment->all_line_ids) {
            my $color = $graph->get_line_by_id($line_id)->color;
            my $width = $graph->get_line_by_id($line_id)->width;
            my %len = $self->get_len_for($segment->origin_station->id, $segment->destination_station->id);

            $viz->add_edge(from => $segment->origin_station->id,
                           to => $segment->destination_station->id,
                           color => $color,
                           penwidth => $width,
                           %len,
            );
        }
    }
    #* Custom connections (for better visuals)
    foreach my $origin_station_id (keys %{ $customconnections }) {
        foreach my $destination_station_id (keys %{ $customconnections->{ $origin_station_id }}) {
            my $len = $customconnections->{ $origin_station_id }{ $destination_station_id };
            $viz->add_edge(from => $origin_station_id,
                           to => $destination_station_id,
                           color => '#ffffff',
                           penwidth => 0,
                           len => $len,
            );
        }
    }

    my $file = sprintf('static/images/%s.png', lc $map);
    $viz->run(format => 'png', output_file => $file, driver => 'neato');

    $self->add_file($file);

}

1;

__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::MapMetro::MakeGraphViz - Short intro

=head1 SYNOPSIS

  use Dist::Zilla::Plugin::MapMetro::MakeGraphViz;

=head1 DESCRIPTION

Dist::Zilla::Plugin::MapMetro::MakeGraphViz is ...

=head1 SEE ALSO

=cut