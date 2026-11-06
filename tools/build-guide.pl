use strict; use warnings;
my $NL = chr(10); my $Q = chr(34); my $BS = chr(92);
my @LANGS = qw(en sr hr de fr it es nl pl pt);
my $ARBDIR = '../servisap/lib/core/l10n';

# 1. prevodi iz aplikacije (sirova vrijednost je vec ispravno escapovana za JS)
my %T;
for my $l (@LANGS) {
  open(my $f,'<:encoding(UTF-8)',"$ARBDIR/app_$l.arb") or die "app_$l.arb: $!";
  while (<$f>) { if (/^  "(helpSec[A-Za-z0-9]+)": "(.*)",?$/) { my ($k,$v)=($1,$2); $v =~ s/",?$//; $T{$l}{$k} = $v } }
  close $f;
}
# 2. prevodi koji postoje samo na sajtu
open(my $s,'<:encoding(UTF-8)','tools/site-strings.txt') or die $!;
while (<$s>) { chomp; my ($l,$k,$v) = split /[|]{3}/, $_, 3; next unless defined $v; $T{$l}{$k} = $v }
close $s;

# 3. kostur
my (@secs, $cur);
open(my $p,'<:encoding(UTF-8)','tools/guide-spec.txt') or die $!;
while (<$p>) {
  chomp; next if /^#/ or /^\s*$/;
  my @f = split /[|]/;
  if ($f[0] eq 'S') { $cur = { id=>$f[1], emoji=>$f[2], img=>$f[3], alt=>$f[4], star=>$f[5], kw=>$f[6], items=>[] }; push @secs, $cur }
  elsif ($f[0] eq 'I') { my ($kind,$name) = split /\s+/, $f[1], 2; push @{$cur->{items}}, { kind=>$kind, name=>$name, star=>$f[2] } }
}
close $p;

sub key_of { my ($it,$suf) = @_; return $it->{kind} eq 'arb' ? $it->{name}.$suf : 'site'.ucfirst($it->{name}).$suf }
sub en_of  { my $k = shift; my $v = $T{en}{$k} // die "nema engleskog za $k"; $v =~ s/\Q${BS}n\E/<br>/g; return $v }
my $BADGE = '<span class="premium-note">' . chr(0x2B50) x 5 . ' Premium</span>';

# 4. bocni meni i glavni dio
my (@side, @main);
my $n = 0;
for my $sec (@secs) {
  $n++;
  my $stitle = 'helpSec' . $n . 'Title';
  # Zvjezdica u bocnom meniju je NAMJERNA — oznacava Premium sekciju. Korisnik
  # je 2026 svjesno vratio JEDNU zvjezdicu u meni (komit 157193d), dok u
  # zaglavlju sekcije stoji punih pet. Ne uklanjati. Prelivanje na duzim
  # prevodima rijeseno je sa flex-wrap u .sidebar-link.
  my $sb = $sec->{star} ? ' <span class="premium-note">' . chr(0x2B50) . '</span>' : '';
  push @side, '      <a class="sidebar-link" href="#' . $sec->{id} . '"><span>' . $sec->{emoji} . '</span> <span data-i18n="' . $stitle . '">' . en_of($stitle) . '</span>' . $sb . '</a>';

  my @items; my $i = 0;
  for my $it (@{$sec->{items}}) {
    $i++;
    my ($kt,$kb) = (key_of($it,'Title'), key_of($it,'Body'));
    my $b = $it->{star} ? ' ' . $BADGE : '';
    push @items,
      '          <div class="item">',
      '            <div class="item-header"><span class="item-num">' . $i . '</span><span class="item-title"><span data-i18n="' . $kt . '">' . en_of($kt) . '</span>' . $b . '</span></div>',
      '            <div class="item-body" data-i18n="' . $kb . '">' . en_of($kb) . '</div>',
      '          </div>';
  }
  my $open = $n == 1 ? ' open' : '';
  my $secbadge = $sec->{star} ? ' ' . $BADGE : '';
  push @main,
    '    <div class="guide-section' . $open . '" id="' . $sec->{id} . '" data-section="' . $sec->{kw} . '">',
    '      <button class="section-header-btn" onclick="toggleSection(this)">',
    '        <div class="section-title-row">',
    '          <span class="section-icon">' . $sec->{emoji} . '</span>',
    '          <span class="section-title">' . $n . '. <span data-i18n="' . $stitle . '">' . en_of($stitle) . '</span>' . $secbadge . '</span>',
    '        </div>',
    '        <span class="section-chevron">' . chr(0x25BE) . '</span>',
    '      </button>',
    '      <div class="section-body">',
    '        <div class="guide-screenshot">',
    '          <img src="' . $sec->{img} . '" alt="' . $sec->{alt} . '" loading="lazy">',
    '        </div>',
    '        <div class="clearfix">',
    @items,
    '        </div>',
    '      </div>',
    '    </div>',
    '';
}
push @main,
  '    <div class="no-results" id="no-results" style="display:none" data-i18n="siteNoResults">' . en_of('siteNoResults') . '</div>';

# 5. rjecnik
open(my $js,'>:encoding(UTF-8)','guide-i18n.js') or die $!;
print $js '// GENERISANO: tools/build-guide.pl — ne mijenjati rukom.' . $NL;
print $js 'const T = {' . $NL;
for my $l (@LANGS) {
  print $js '  ' . $l . ': {' . $NL;
  for my $k (sort keys %{$T{$l}}) {
    my $v = $T{$l}{$k};
    $v =~ s/\Q${BS}n\E/<br>/g;
    print $js '    ' . $k . ': ' . $Q . $v . $Q . ',' . $NL;
  }
  print $js '  },' . $NL;
}
print $js '};' . $NL;
close $js;

print "guide-i18n.js: " . scalar(@LANGS) . " jezika, " . scalar(keys %{$T{en}}) . " kljuceva" . $NL;
print "sekcija: " . scalar(@secs) . ", stavki: " . scalar(map { @{$_->{items}} } @secs) . $NL;

open(my $o,'>:encoding(UTF-8)','/tmp/gen_side.html') or die $!; print $o join($NL,@side); close $o;
open(my $m,'>:encoding(UTF-8)','/tmp/gen_main.html') or die $!; print $m join($NL,@main); close $m;

# ── 6. sklapanje guide.html iz predloska ─────────────────────────────────────
open(my $t,'<:encoding(UTF-8)','tools/guide-template.html') or die $!;
local $/; my $H = <$t>; close $t;
$H =~ s/\r\n/\n/g;
$H =~ s/
/
/g;

my $side = join($NL, @side);
my $mainhtml = join($NL, @main);

# CSS za prekidac jezika
open(my $c,'<:encoding(UTF-8)','tools/lang.css') or die $!; my $langcss = <$c>; close $c;
$H =~ s{(\n  </style>)}{$NL . $langcss . $1}e or die 'nema </style>';

# prekidac jezika u navigaciju
my $langhtml = <<'HTMLEOF';
      <div class="lang-wrap">
        <button class="lang-btn" id="lang-btn" aria-label="Language">&#127760; <span id="lang-label">EN</span> &#9662;</button>
        <div class="lang-dropdown" id="lang-dropdown">
          <div class="lang-option" data-lang="en">English</div>
          <div class="lang-option" data-lang="sr">Srpski</div>
          <div class="lang-option" data-lang="hr">Hrvatski</div>
          <div class="lang-option" data-lang="de">Deutsch</div>
          <div class="lang-option" data-lang="fr">Fran&ccedil;ais</div>
          <div class="lang-option" data-lang="it">Italiano</div>
          <div class="lang-option" data-lang="es">Espa&ntilde;ol</div>
          <div class="lang-option" data-lang="nl">Nederlands</div>
          <div class="lang-option" data-lang="pl">Polski</div>
          <div class="lang-option" data-lang="pt">Portugu&ecirc;s</div>
        </div>
      </div>
HTMLEOF
$H =~ s{(\n    <div class="nav-right">\n)}{$1 . $langhtml}e or die 'nema nav-right';

# natpisi sa data-i18n
$H =~ s{<a class="nav-back" href="index.html">[^<]*</a>}
       {'<a class="nav-back" href="index.html" data-i18n="siteBackHome">' . en_of('siteBackHome') . '</a>'}e or die 'nema nav-back';
$H =~ s{<div class="guide-header">.*?</div>}
       {'<div class="guide-header">' . $NL . '  <h1 data-i18n="siteGuideTitle">' . en_of('siteGuideTitle') . '</h1>' . $NL .
        '  <p data-i18n="siteGuideSubtitle">' . en_of('siteGuideSubtitle') . '</p>' . $NL . '</div>'}se or die 'nema guide-header';
$H =~ s{(<input class="search-input" id="search" type="search" )placeholder="[^"]*"}
       {$1 . 'data-i18n-ph="siteSearchPlaceholder" placeholder="' . en_of('siteSearchPlaceholder') . '"'}e or die 'nema search';
$H =~ s{<div class="sidebar-title">[^<]*</div>}
       {'<div class="sidebar-title" data-i18n="siteContents">' . en_of('siteContents') . '</div>'}e or die 'nema sidebar-title';

# generisani dijelovi
$H =~ s{(<div class="sidebar-title"[^>]*>[^<]*</div>\n).*?(\n    </div>\n  </aside>)}{$1 . $side . $2}se or die 'nema sidebar-inner';
$H =~ s{(<main id="guide-content">\n).*?(\n  </main>)}{$1 . $mainhtml . $2}se or die 'nema main';

# skripta za jezik
my $langjs = <<'JSEOF';
<script src="guide-i18n.js"></script>
<script>
  // GENERISANO ugradjeno: prati izbor jezika sa index.html preko localStorage 'sb_lang'.
  const LANG_LABELS = { en:'EN', sr:'SR', hr:'HR', de:'DE', fr:'FR', it:'IT', es:'ES', nl:'NL', pl:'PL', pt:'PT' };
  function applyLang(lang) {
    if (!T[lang]) return;
    document.documentElement.lang = lang;
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const k = el.getAttribute('data-i18n');
      if (T[lang][k] !== undefined) el.innerHTML = T[lang][k];
    });
    document.querySelectorAll('[data-i18n-ph]').forEach(el => {
      const k = el.getAttribute('data-i18n-ph');
      if (T[lang][k] !== undefined) el.placeholder = T[lang][k];
    });
    document.getElementById('lang-label').textContent = LANG_LABELS[lang] || lang.toUpperCase();
    document.querySelectorAll('.lang-option').forEach(o => o.classList.toggle('active', o.dataset.lang === lang));
    localStorage.setItem('sb_lang', lang);
  }
  function detectLang() {
    const saved = localStorage.getItem('sb_lang');
    if (saved && T[saved]) return saved;
    const nav = (navigator.language || '').toLowerCase().slice(0, 2);
    return T[nav] ? nav : 'en';
  }
  const langBtn = document.getElementById('lang-btn');
  const langDrop = document.getElementById('lang-dropdown');
  langBtn.addEventListener('click', e => { e.stopPropagation(); langDrop.classList.toggle('open'); });
  document.addEventListener('click', () => langDrop.classList.remove('open'));
  document.querySelectorAll('.lang-option').forEach(o => {
    o.addEventListener('click', () => { applyLang(o.dataset.lang); langDrop.classList.remove('open'); });
  });
  applyLang(detectLang());
</script>
JSEOF
$H =~ s{(\n</body>)}{$NL . $langjs . $1}e or die 'nema </body>';

open(my $out,'>:encoding(UTF-8)','guide.html') or die $!; print $out $H; close $out;
print "guide.html sklopljen" . $NL;
