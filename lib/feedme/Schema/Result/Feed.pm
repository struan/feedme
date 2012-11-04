use utf8;
package feedme::Schema::Result::Feed;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

feedme::Schema::Result::Feed

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<feeds>

=cut

__PACKAGE__->table("feeds");
__PACKAGE__->load_components(qw( FilterColumn ));

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'feeds_id_feed_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 last_update

  data_type: 'timestamp'
  is_nullable: 1

=head2 headers

  data_type: 'text'
  is_nullable: 1

=head2 failed_updates

  data_type: 'integer'
  is_nullable: 1

=head2 uri

  data_type: 'text'
  is_nullable: 1

=head2 should_fetch

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "feeds_id_feed_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "last_update",
  { data_type => "timestamp", is_nullable => 1 },
  "headers",
  { data_type => "text", is_nullable => 1 },
  "failed_updates",
  { data_type => "integer", is_nullable => 1 },
  "uri",
  { data_type => "text", is_nullable => 1 },
  "should_fetch",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 items

Type: has_many

Related object: L<feedme::Schema::Result::Item>

=cut

__PACKAGE__->has_many(
  "items",
  "feedme::Schema::Result::Item",
  { "foreign.feed_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-10-18 23:18:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:coUy9P+feO3HyQbBrAB9gg

use HTTP::Headers;

__PACKAGE__->filter_column(
    headers => {
        filter_from_storage => sub {
            my $self = shift;
            my $header_string = shift;
            my $headers = HTTP::Headers->new();
            
            my %headers = map { m/([^:]*):\s*(.*)/; $1 => $2; } 
                                                split("\n", $header_string );

            foreach my $header ( keys %headers ) {
                $headers->header($header   =>  $headers{$header});
            }

            return $headers;
        },
        filter_to_storage => sub {
            my $self = shift;
            my $headers = shift;
            return '' unless $headers;
            my $header_string = "";
            
            if ( $headers->header( 'Last-Modified' ) ) {
                $header_string = "If-Modified-Since: " 
                                 . $headers->header('Last-Modified')
                                 . "\n";
            }

            if ( $headers->header( 'Etag' ) ) {
                $header_string .= "If-None-Match: "
                                  . $headers->header('ETag')
                                  . "\n";
            }
            return $header_string;
        }
    }
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
