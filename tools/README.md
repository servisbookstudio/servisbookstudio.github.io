# Alat za vodič (`guide.html`)

`guide.html` se **ne mijenja rukom.** Pravi ga skripta iz prevoda same
aplikacije, pa vodič na sajtu ne može da zaostane za pomoći u aplikaciji — a
upravo se to desilo između avgusta i novembra 2026.

## Pokretanje

```
cd C:\APP\servisbookstudio.github.io
perl tools\build-guide.pl
```

Skripta ispiše koliko je jezika, ključeva, sekcija i stavki obradila.

**Traži da `C:\APP\servisap` bude pored** — čita
`../servisap/lib/core/l10n/app_*.arb`.

## Šta ulazi, šta izlazi

| Ulaz | Šta je |
|---|---|
| `../servisap/lib/core/l10n/app_*.arb` | **prevodi iz aplikacije**, 10 jezika — ključevi `helpSec*` |
| `tools/site-strings.txt` | prevodi kojih u aplikaciji nema (zaglavlje stranice i tri stavke samo za sajt) |
| `tools/guide-spec.txt` | redoslijed sekcija i stavki, emoji, snimak ekrana, ključne riječi za pretragu |
| `tools/guide-template.html` | **predložak** — zaglavlje, stilovi, pretraga, harmonika |

| Izlaz | Šta je |
|---|---|
| `guide.html` | gotova stranica |
| `guide-i18n.js` | rječnik, 122 ključa × 10 jezika |

## Kad se šta mijenja

| Promjena | Gdje |
|---|---|
| Tekst pomoći u aplikaciji | **nigdje** — samo pokreni skriptu |
| Nova stavka u pomoći | dodaj red `I\|arb helpSecXIY\|0` u `guide-spec.txt` |
| Stavka samo za sajt | `guide-spec.txt` + prevodi u `site-strings.txt` |
| Izgled, stilovi, navigacija | **`tools/guide-template.html`**, nikako `guide.html` |

## Kako prati jezik sa `index.html`

`index.html` pamti izbor u `localStorage` pod ključem **`sb_lang`**. Vodič je na
istoj adresi, pa čita isti ključ i **sam se prebaci**. U zaglavlju ima i
sopstveni prekidač, pa se jezik može promijeniti i sa vodiča.

## Odluke koje ne treba preispitivati

**Prevodi se NE pišu ovdje.** Tekst stavke dolazi iz aplikacije, pa vodič i
pomoć uvijek govore isto. Ručno se prevodi samo ono čega u aplikaciji nema.

**Nema podebljanja unutar teksta stavke.** Prevod se ubacuje kao sadržaj
elementa; podebljanje bi se izgubilo. Tekst iz aplikacije ionako stavlja nazive
dugmadi pod navodnike.

**Zvjezdica ⭐ ne ide u bočni meni** — na dužim prevodima se prelije van okvira.
Puna oznaka „⭐⭐⭐⭐⭐ Premium" stoji u zaglavlju sekcije.

**Prijelomi `\n` iz ARB-a postaju `<br>`**, zato `applyLang` koristi `innerHTML`,
a ne `textContent`. Sadržaj je naš, ne dolazi od korisnika.

## Zamke

- `tools/guide-template.html` je **CRLF**; skripta ga normalizuje na LF pri
  čitanju. Obrasci koji traže prelom na kraju reda inače ne nađu ništa.
- Sirova vrijednost iz ARB-a je **već ispravno escapovana za JavaScript**, pa se
  prenosi doslovno. Ne dirati escapovanje.
- Poslije svake izmjene provjeriti u pregledaču bez prozora:
  `chrome --headless=new --dump-dom "file:///C:/APP/servisbookstudio.github.io/guide.html"`
