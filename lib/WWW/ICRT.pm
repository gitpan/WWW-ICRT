package WWW::ICRT;

use strict;
our $VERSION = '0.01';

use Text::MicroMason;
use File::Slurp;
use Mail::Mailer;
use WWW::Mechanize;


sub new {
    bless {}, shift;
}

our $base = "http://www.icrt.com.tw/";

sub musiclog {
    (my $mech = WWW::Mechanize->new())->get($base."en/music_log.php");
    my $content = $mech->content;
    die "Couldn't get the log!" unless defined $content;
    my @log;
    while($content =~ m,<tr class='odd'><td bgcolor='.+?'>\s*(\d\d:\d\d:\d\d)\s*</td><td><a title='Vote this song' href='rate_song.php\?song_id=\d+'>\s*(.+?)\s*<small>by</small>\s*(.+?)\s*</a></td></tr>,mgo){
	push @log => { time => $1, title => $2, artist => $3 };
    }
    @log;
}

sub request_song {
    my $self = shift;
    my %arg = @_;

    die "Your email address?" unless $arg{from};
    die "DJ's email address?" unless $arg{to};

    $arg{to} .= '@icrt.com.tw';
    $arg{subject} ||= 'Song Request';
    my $processed = 0;
    my $mailer = new Mail::Mailer;
    $mailer->open(
		  {
		      From => $arg{from},
		      To => $arg{to},
		      Subject => $arg{subject},
		  }
		  );

    if($arg{text}){
	print $arg{text};
	print $mailer $arg{text};
	$processed = 1;
    }
    elsif($arg{title} &&
	  $arg{artist} &&
	  $arg{dedicated_to}
	  ){

	my $template = -r "$ENV{HOME}/.icrt" ? read_file("$ENV{HOME}/.icrt") : <<'TEMPLATE';
Hi,
I wanna request the song "<% $ARGS{title} %>" by <% $ARGS{artist} %>. And I wanna dedicate it to <% $ARGS{dedicated_to} %>.

Thanks
<% $ARGS{my_name} %>
TEMPLATE

	print $mailer Text::MicroMason::execute($template,
			      map{ $_ => $arg{$_} }
			      qw(
				 title
				 artist
				 dedicated_to
				 my_name
				 )
			      );
	print Text::MicroMason::execute($template,
			      map{ $_ => $arg{$_} }
			      qw(
				 title
				 artist
				 dedicated_to
				 my_name
				 )
			      );
	$processed = 1;
    }
    $mailer->close;
    $processed;
}

sub rate_current_song {
    my $self = shift;
    die "score should be from 1 to 10" unless $_[0] >=1 && $_[0] <=10;
    my $mech = WWW::Mechanize->new();

    $mech->get($base."/en/rate_song.php");
    $mech->submit_form(
		       form_number => 1,
		       fields      => {
			   vote_score    => $_[0],
		       }
		       );
    $mech->content =~ m,<tr><th\s*>Average</th><td class='head'>(.+?)</td></tr>,;
    $1;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

WWW::ICRT - ICRT agent

=head1 SYNOPSIS

    my $icrt = new WWW::ICRT;

    @log = $icrt->musiclog();
    foreach (@log) {
        print "$_->{time} => $_->{title} by $_->{artist}\n";
    }
    

    $icrt->request_song(
                        from => 'my.email@domain.org',
                        to => 'buzzzzzz',
			subject => 'Song request',
			text => $text,
                        );

    $icrt->rate_current_song(
			     5
                             );
    

=head1 DESCRIPTION

This module is an agent for accessing information on ICRT (International Community Radio Taipei, L<http://www.icrt.com.tw> ). You can use module to view the music log, request songs and rate them.

=head2 musiclog

It returns the music log up to now today.

See also L<http://www.icrt.com.tw/en/music_log.php>

=head2 request_song

You can call this method to request songs from the DJs. It sends emails to the DJs.

You can write the email in place.

    $icrt->request_song(
                        from => 'my@email.org',
                        to => 'buzzzzzz',   # expands to buzzzzzz@icrt.com.tw
                        subject => 'Song request', # default subject, ignorable
                        text => <<'REQUEST',
    Hi,
      I wanna request blah blah song for blah blah man.
    Thank you blah blah much.
    REQUEST
                        );

Or, give song's name, artist's name, whom you are dedicating this song to, and a text will be automatically generated for you. The default template is embedded in the module's source, but you can override it in file B<$ENV{HOME}/.icrt>. For the template thing, see also L<Text::MicroMason>

    $icrt->request_song(
                        from => 'my@email.org',
                        to => 'buzzzzzz',
			subject => 'Song request',
			my_name => 'my name',
                        song => 'Song Song Song',
                        artist => 'anonymous',
                        dedicated_to => 'the entire human race',
                        );

It will return 1 if the request is processed.

=head2 rate_current_song

You can call this to rate the current song on a scale from 1 to 10. And it returns the current average rating.

See also L<http://www.icrt.com.tw/en/rate_song.php>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Yung-chung Lin (a.k.a. xern) E<lt>xern@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut


__REQUEST__
