package WWW::ICRT;

use strict;
our $VERSION = '0.02';

use Text::MicroMason;
use File::Slurp;
use Mail::Mailer;
use WWW::Mechanize;
use Regexp::Bind qw(bind global_bind);

sub new { bless {
		 mech => WWW::Mechanize->new(),
		}, shift }

our $base = "http://www.icrt.com.tw/";

our $musiclog_template = qr!<tr class='odd'><td bgcolor='.+?'>\s*(\d\d:\d\d:\d\d)\s*</td><td><a title='Vote this song' href='rate_song.php\?song_id=\d+'>\s*(.+?)\s*<small>by</small>\s*(.+?)\s*</a></td></tr>!mo;

sub musiclog {
    (my $mech = $_[0]->{mech})->get($base."/en/music_log.php");
    my $content = $mech->content;
    die "Couldn't get the log!" unless defined $content;
    my @log;
    @log = global_bind($content, $musiclog_template, qw(time title artist));
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

    $self->{mech}->get($base."/en/rate_song.php");
    $self->{mech}->submit_form(
		       form_number => 1,
		       fields      => {
			   vote_score    => $_[0],
		       }
		       );
    $self->{mech}->content =~ m,<tr><th\s*>Average</th><td class='head'>(.+?)</td></tr>,;
    $1;
}

sub get_eznews_audio {
    my $self = shift;
    $self->{mech}->get($base."/en/eznewsaudiodownload.php");
    $self->{mech}->content;
}

our $news_template = qr,Subject: (.+?)<br>\n.+?<PRE>(.+?)</PRE>,s;

sub convert_newline {
  $_[0]=~s/\r//go;
  $_[0];
}

sub _filter_news {
  my $n = shift;
  $n->{text} =~ s/\n+$//so;
  $n->{subject} = ucfirst $n->{subject};
  $n
}

our %news_url = qw(
		   ez en/eznews.php
		   tw en/twnews.php
		  );
sub _get_news {
  my $self = shift;
  $self->{mech}->get($base.$news_url{shift()});
  map{ _filter_news $_ }
    global_bind(convert_newline($self->{mech}->content),
		$news_template,
		qw(subject text));
  
}

sub get_eznews { shift()->_get_news('ez') }
sub get_twnews { shift()->_get_news('tw') }


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

    $icrt->get_eznews_audio();

    $icrt->get_eznews();
    $icrt->get_twnews();
    

=head1 DESCRIPTION

This module is an agent for accessing information on ICRT (International Community Radio Taipei, L<http://www.icrt.com.tw> ). You can use module to view the music log, request songs, rate songs, and fetch online news.

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

=head2 get_eznews_audio, get_eznews, get_twnews

   # fetch audio file of ez news, and it returns
   # the binary content of audio file
   $audio = $icrt->get_eznews_audio();

   # fetch texts of ez news and taiwan news
   foreach (
            @{$icrt->get_eznews()},
            @{$icrt->get_twnews()}
           ){
      print "$_->{subject} $_->{text};
   }

See also L<http://www.icrt.com.tw/en/eznews.php> and L<http://www.icrt.com.tw/en/twnews.php>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Yung-chung Lin (a.k.a. xern) E<lt>xern@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut


__REQUEST__
