use Test::More qw(no_plan);
use ExtUtils::testlib;
BEGIN{ use_ok('WWW::ICRT') }

my $icrt = new WWW::ICRT;

ok($icrt->musiclog());
ok(defined $icrt->rate_current_song(int(1+rand(10))));
ok($icrt->get_eznews_audio());
ok($icrt->get_eznews());
ok($icrt->get_twnews());


__END__
print "----\n";
$icrt->request_song(
		    title => 'blah',
		    artist => 'blah',
		    dedicated_to => 'the entire human race',
		    my_name => 'Yung-chung Lin'
		    );
print "----\n";
$icrt->request_song(
                               text => <<'REQUEST',
Hi,
  I wanna request blah blah song for blah blah man.
Thank you blah blah much.
REQUEST
		    );

