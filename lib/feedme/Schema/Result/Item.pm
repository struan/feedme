use utf8;
package feedme::Schema::Result::Item;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

feedme::Schema::Result::Item

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<items>

=cut

__PACKAGE__->table("items");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'items_id_item_seq'

=head2 feed_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 permalink

  data_type: 'text'
  is_nullable: 1

=head2 content

  data_type: 'text'
  is_nullable: 1

=head2 last_update

  data_type: 'timestamp'
  is_nullable: 1

=head2 md5

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "items_id_item_seq",
  },
  "feed_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "permalink",
  { data_type => "text", is_nullable => 1 },
  "content",
  { data_type => "text", is_nullable => 1 },
  "last_update",
  { data_type => "timestamp", is_nullable => 1 },
  "md5",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 feed

Type: belongs_to

Related object: L<feedme::Schema::Result::Feed>

=cut

__PACKAGE__->belongs_to(
  "feed",
  "feedme::Schema::Result::Feed",
  { id => "feed_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-10-18 23:18:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jpx41F1jCnkhsViV8gSYQg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
