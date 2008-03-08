package MT::Plugin::OMV::GoogleSitemapsPing;
#   MTGoogleSitemapsPing - Google Sitemaps �� URL �̍X�V ping �𑗐M����
#   @see http://www.magicvox.net/archive/2006/05201647.php
#           Programmed by Piroli YUKARINOMIYA (MagicVox)
#           Open MagicVox.net - http://www.magicvox.net/
use strict;
use MT::Util;
use MT::Template::Context;
use LWP::UserAgent;# for ping
;#use Data::Dumper;#DEBUG

use vars qw( $MYNAME $VERSION );
$MYNAME = __PACKAGE__;
$VERSION = '0.10';

;# �v���O�C����o�^
if( MT->can( 'add_plugin' )) {
    require MT::Plugin;
    my $plugin = MT::Plugin->new;
        $plugin->name( "$MYNAME ver.$VERSION" );
        $plugin->description( <<HTMLHEREDOC );
Ping to <a href="http://www.google.com/webmasters/sitemaps/">Google Sitemaps</a> to notify updating of the file.
HTMLHEREDOC
        $plugin->doc_link( 'http://www.magicvox.net/archive/2006/05201647/' );
    MT->add_plugin( $plugin );
}



### $MTGoogleSitemapsPing$
MT::Template::Context->add_tag( GoogleSitemapsPing => \&google_sitemaps_ping );
sub google_sitemaps_ping {
    my( $ctx, $args, $cond ) = @_;
;#
	;# �e���v���[�g
	my $template = $args->{template}
		or return sprintf 'MT%s error: <template> should be specified.',
				$ctx->stash('tag');
	my $file_url = MT::Template::Context::_hdlr_link (
			$ctx, {'template' => $template}, $cond)
		or return sprintf 'MT%s error: a template which named "%s" is not found.',
				$ctx->stash('tag'), $template;

	;# �O��� ping ���M���Ԃ��v���O�C���f�[�^����擾
	my $cur_time = time ();
	my $last_ping_time = load_plugindata ($file_url);# ref

	;# ping ���M�Ԋu [��] �ȓ��ł���΁Aping �͑��M���Ȃ�
	my $period = $args->{period} || 0;
	$period = 60 if $period < 60;# cf. �T�C�g�}�b�v�� 1 ���Ԃ� 2 ��ȏ�đ��M���Ȃ����Ƃ������߂��܂��B
	return sprintf 'MT%s message: You need not to ping for "%s" now.',
			$ctx->stash('tag'), $file_url
		if defined $last_ping_time && $cur_time < $$last_ping_time + $period * 60;

	;# Google Sitemaps �ɍX�V ping �𑗐M����
	MT::Util::start_background_task (sub {
			my $app = MT::App->instance;
			my $ping_url = sprintf 'http://www.google.com/webmasters/sitemaps/ping?sitemap=%s',
					MT::Util::encode_url ($file_url);
			my $ua = LWP::UserAgent->new;
			if ($ua) {
				$ua->timeout (30);
				my $response = $ua->get ($ping_url);
				if (! $response->is_success) {
					$app->log (sprintf 'MT%s error: failed to ping. destination server returns; %s',
							$ctx->stash('tag'), $response->status_line);
				}
			}
			else {
				$app->log (sprintf 'MT%s error: failed to initialize LWP::UserAgent',
						$ctx->stash('tag'));
			}
	});

	;# ping ���M�������X�V
	save_plugindata ($file_url, \$cur_time);
	return sprintf 'MT%s message: Successfully pinged for "%s" at %s.',
			$ctx->stash('tag'), $file_url, scalar localtime ($cur_time);
}



;########################################################################
use MT::PluginData;
sub load_plugindata {
	my ($key) = @_;
	my $plugindata = MT::PluginData->load ({ plugin => __PACKAGE__, key => $key })
			or return undef;
	return $plugindata->data;
}

sub save_plugindata {
	my ($key, $data) = @_;
	my $plugindata = MT::PluginData->load ({ plugin => __PACKAGE__, key => $key });
	if (! $plugindata) {
		$plugindata = MT::PluginData->new;
		$plugindata->plugin (__PACKAGE__);
		$plugindata->key ($key);
	}
	$plugindata->data ($data);
	$plugindata->save;
}

1;
