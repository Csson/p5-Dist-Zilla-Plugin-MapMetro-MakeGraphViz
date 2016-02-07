use 5.14.0;
use warnings;

package Dist::Zilla::Plugin::MapMetro::MakeGraphViz;

# ABSTRACT: Automatically creates a GraphViz2 visualisation of a Metro::Map map
our $VERSION = '0.1104';

use Moose;
use namespace::autoclean;
use Path::Tiny;
use MooseX::AttributeShortcuts;
use Types::Standard qw/HashRef ArrayRef Str Maybe/;
use Map::Metro::Shim;
use GraphViz2;
use Dist::Zilla::Plugin::MapMetro::MakeGraphViz::Map;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::BeforeBuild
/;

sub before_build {
    my $self = shift;

    if(!$ENV{'MMVIZ'} && !$ENV{'MMVIZDEBUG'}) {
        $self->log('Set either MMVIZ or MMVIZDEBUG to a true value to run this.');
        return;
    }

    my @maps = sort { $a cmp $b } map { $_->basename(qr/\.pm/) } path(qw/lib Map Metro Plugin Map/)->children(qr/\.pm/);
    return if !scalar @maps;

    for my $mapname (@maps) {
        state $counter = 0;
        ++$counter;
        $self->log("Works on $mapname [$counter/@{[ scalar @maps ]}]");
        my $map = Dist::Zilla::Plugin::MapMetro::MakeGraphViz::Map->new(map => $mapname);

        if($map->has_generated_file) {
            $self->log("  Saved in @{[ $map->generated_file ]}");
        }
        else {
            $self->log("! Did not create graphviz");
        }
    }
}

1;

__END__

=encoding utf-8

=head1 SYNOPSIS

  ;in dist.ini
  [MapMetro::MakeGraphViz]

=head1 DESCRIPTION

This L<Dist::Zilla> plugin creates a L<GraphViz2> visualisation of a L<Map::Metro> map, and is only useful in such a distribution.

=head1 SEE ALSO

=for :list
* L<Task::MapMetro::Dev> - Map::Metro development tools
* L<Map::Metro>
* L<Map::Metro::Plugin::Map>
* L<Map::Metro::Plugin::Map::Stockholm> - An example

=cut
