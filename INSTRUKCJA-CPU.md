# Kopanie Quantus (QTC) procesorem: laptop z Windows (WSL2) i zwykłe Ubuntu 24.04

> **Stan na 11.09.2026** (noc, ok. 00:15 UTC). Mainnet działa od 09.09.2026 08:51:57 UTC.
> Wersje: node **v1.0.1**, miner **v4.2.0**, skrypt `quantus-miner.sh` **1.0.0**.
> Trudność, wersje i warunki pul zmieniają się szybko. Jak sprawdzić nowości: rozdział 13.
> **(niezweryfikowane)** oznacza informację, której nie udało się potwierdzić.

## 0. Najważniejsze w 30 sekund

- **Kopanie procesorem to loteria i strata na prądzie.** Ten laptop (Intel Core Ultra 7 255U) zmierzył **1,67 MH/s** (12 wątków).
  To średnio **ok. 0,00014 QTC dziennie**, czyli **1 blok (ok. 0,31 QTC) średnio raz na ok. 6 lat**. Może trafić jutro, może nigdy.
  Prąd za ten czas kosztuje więcej, niż wynosi zarobek (rozdział 8). Kop procesorem dla zabawy albo gdy prąd masz za darmo.
  Prawdziwy zarobek daje karta RTX 4090 (osobna instrukcja `INSTRUKCJA-GPU-RTX4090.md`).
- **Pula na procesorze się nie opłaca.** Na pierwszą wypłatę czekałbyś ok. 2 lata (NurseryPool) albo ok. 5 lat (quanpool).
- **24 słowa (fraza seed) to Twoje pieniądze.** Zapisz je na papierze i nikomu nie podawaj. Admini nigdy nie piszą pierwsi.
- **Masz dwa komputery (laptop + PC z 4090)? Wystarczy JEDNA fraza** i jeden adres nagród (rozdział 5).
- **Telegram psuje polecenia:** zamienia `--` na długą kreskę `—`. Kopiuj polecenia z tego pliku. Jeśli zobaczysz `—`, wpisz ręcznie dwa minusy `--`.

**Najkrócej (wszystko w oknie Ubuntu):**
1. `cd ~/projects/quantus-mining && chmod +x quantus-miner.sh`
2. `./quantus-miner.sh setup --device cpu` → w kreatorze wybierz 1 → przepisz 24 słowa na papier → wpisz `ZAPISAŁEM` → przepisz z kartki 3 słowa, o które poprosi skrypt. (Frazę masz już na drugim komputerze? Wtedy zamiast kroków 2 i 4 wpisz polecenie z pliku `rewards`: `./quantus-miner.sh start --device cpu --inner-hash 0x… --rewards-address qz…` — rozdział 5.)
3. `./quantus-miner.sh benchmark` (zobaczysz swoją moc).
4. `./quantus-miner.sh start --cpu-workers 12`
5. Zostaw co najmniej jedno okno Ubuntu otwarte (może być zminimalizowane) — rozdział 7.1.
6. Co jakiś czas `./quantus-miner.sh status`. Kopie naprawdę, gdy: `peers` > 0, `blok X / sieć Y` równe (albo różnica 1–2), `synchronizacja: zakończona` i `Miner: działa … moc: …`.

## 1. Gdzie wpisywać polecenia

- **Okno Ubuntu (terminal Linuksa).** Otwierasz je tak: menu Start → wpisz „Ubuntu” → Enter. Linia zaczyna się tam od `twojlogin@komputer:~$`. Tu wpisujesz wszystkie polecenia z tej instrukcji, chyba że przy poleceniu jest napisane „PowerShell”.
- **PowerShell (Windows).** Menu Start → wpisz „PowerShell” → Enter. Linia zaczyna się od `PS C:\Users\…>`. Tu wpisujesz tylko polecenia oznaczone „PowerShell” (np. `wsl --shutdown`).
- W oknie Ubuntu wklejasz prawym przyciskiem myszy albo skrótem **Ctrl+Shift+V** (samo Ctrl+V nie działa).
- **Nowe okno Ubuntu zaczyna w katalogu domowym, a nie w folderze skryptu.** Dlatego w każdym nowym oknie najpierw wpisz:
  ```bash
  cd ~/projects/quantus-mining
  ```
  Bez tego `./quantus-miner.sh` odpowie `No such file or directory`. Możesz też zawsze pisać pełną ścieżkę: `~/projects/quantus-mining/quantus-miner.sh status`.
- Każde polecenie z ramki wpisuj osobno i naciśnij Enter. Linie zaczynające się od `#` to komentarze.

## 2. Jak to działa (w minutę)

- **Blok:** co ok. 12–14 s sieć dopisuje nowy blok. Kto pierwszy go znajdzie, dostaje nagrodę (teraz ok. 0,31 QTC).
- **Node (węzeł)** to program `quantus-node`. Pobiera i sprawdza cały łańcuch bloków, rozmawia z innymi komputerami w sieci (to są **peers**), przygotowuje zadania dla minera i ogłasza znaleziony blok.
- **Miner (koparka)** to program `quantus-miner`. Wykonuje miliony prób („hashy”) na sekundę, aż któraś spełni warunek sieci.
- **Synchronizacja:** node musi najpierw pobrać wszystkie bloki od startu sieci. Dopiero potem kopanie ma sens. Blok wykopany na starym stanie łańcucha to **sierota** i nic nie daje. Skrypt włącza minera dopiero po synchronizacji.
- **Trudność:** ile prób potrzeba średnio na jeden blok. Rośnie, gdy w sieci przybywa koparek.
- **Fraza seed (24 słowa):** główny klucz. Powstają z niej adres nagród i Inner Hash. Kto zna frazę, ten może wydać Twoje monety.
- **Inner Hash:** `0x` i 64 znaki, wyliczone z frazy. Node wpisuje go do bloków, żeby nagroda trafiła na Twój adres. Nie da się nim wydać monet (to nie jest sekret), ale nie rozdawaj go bez potrzeby.
- **Adres nagród (wormhole):** adres `qz…` wyliczony z Inner Hash. W aplikacji Quantus nazywa się **„Encrypted Account”** (nie „Account 1”).
- **Solo:** własny node i własny miner, nagroda trafia prosto do Ciebie. **Pula:** wiele osób kopie razem u obcego operatora, który dzieli nagrody i trzyma je do wypłaty.
- **systemd:** mechanizm Linuksa, który sam uruchamia programy przy starcie. W WSL domyślnie jest wyłączony (rozdział 7.2).

## 3. Wymagania

| Co | Wymaganie |
|---|---|
| System | Ubuntu 24.04, 64-bit (x86_64): w WSL2 albo zwykły. **Ubuntu 22.04 jest za stare** dla node'a v1.0.1. |
| glibc (biblioteka systemowa) | 2.38 lub nowsza (Ubuntu 24.04 ma 2.39) |
| RAM | minimum 4 GB |
| Dysk | skrypt ostrzega poniżej 20 GB wolnego miejsca. 11.09 cały łańcuch zajmował ok. 0,5 GB, ale będzie rósł |
| Zegar | zgodny z siecią. Bloki z czasem ponad 15 s „z przyszłości” sieć odrzuca |

Sprawdź w oknie Ubuntu:
```bash
grep PRETTY_NAME /etc/os-release
ldd --version | head -1
nproc
df -h ~
```
Powinieneś zobaczyć `Ubuntu 24.04…`, wersję `2.39`, liczbę wątków (Twój laptop: `14`) i sporo wolnego miejsca.

## 4. Bezpieczeństwo: przeczytaj przed startem

1. **Fraza 24 słów** daje pełną władzę nad nagrodami. Zapisz ją na papierze, długopisem, i sprawdź dwa razy. Nie rób zdjęcia. Nie zaznaczaj jej myszką i nie kopiuj Ctrl+C (schowek Windows ją zapamiętuje). Nie wklejaj jej do chmury, czatu, AI, na stronę, do bota ani do puli.
2. **Nowa fraza na mainnet (zalecane).** Oficjalne źródła mówią różnie:
   - admin Nikolaus (Telegram, 09.09, 01:41 UTC): „do not reuse your testnet keys for mainnet”, bez podania powodu;
   - później tego samego dnia dokumentacja (sekcja „Migrating from Planck”) i nowsza aplikacja pozwalają zachować stare klucze.

   Technicznie to działa: ta sama fraza daje ten sam adres `qz…` w obu sieciach. My zalecamy **nową frazę**, zwłaszcza jeśli starą kiedyś wpisałeś w linii poleceń, wkleiłeś do czatu lub AI, zapisałeś w pliku albo używałeś na cudzym komputerze.
3. **Frazę z testnetu też zachowaj.** Zapowiedziano airdrop 10 000 QTC dla osób, które kopały na testnecie (admin Jangle, 10.09: „Make sure you keep the seed phrase you used to mine”). Portalu jeszcze nie ma. Linki pojawią się tylko na oficjalnym kanale Quantus na Telegramie.
4. **Aplikacja Quantus — uwaga na stary portfel.** Zanim wpiszesz do aplikacji nową frazę z kopania, zapisz na papierze frazę portfela, który już jest w aplikacji (zwykle to fraza z testnetu, potrzebna do airdropu). Utworzenie albo import nowego portfela w aplikacji może usunąć stary. 10.09 wersja w sklepach wciąż pokazywała testnet, a aktualizacja czekała na zatwierdzenie. Do tego czasu sprawdzaj saldo na `https://explorer.quantus.com/accounts/TWOJ_ADRES`.
5. **Oszuści:** admini nie piszą ani nie dzwonią pierwsi. Oficjalnego Discorda nie ma. Oficjalne strony: quantus.com, docs.quantus.com, github.com/Quantus-Network, t.me/quantusnetwork, linktr.ee/quantusnetwork, explorer.quantus.com. QTC nie ma oficjalnej ceny ani giełdy. SafeTrade wystawił monetę bez zgody i pod złym symbolem „QUAN”. Oferty „OTC” to częste oszustwa.
6. **Pule są nieoficjalne.** Admin: „Quantus has not validated any public 3rd party mining pool operators”. Pula trzyma Twoje monety do wypłaty.

## 5. Dwa komputery, jedna fraza (laptop + PC z RTX 4090)

Frazę tworzysz **raz**, na tym komputerze, na którym zaczynasz (najlepiej na PC z RTX 4090 — on naprawdę zarabia). Drugi komputer kopie na ten sam adres, bez drugiej frazy:

1. Na pierwszym komputerze, po konfiguracji (rozdział 6.2), zapisz publiczną część klucza do pliku:
   ```bash
   cd ~/projects/quantus-mining
   ./quantus-miner.sh rewards > moj-klucz-nagrod.txt
   cat moj-klucz-nagrod.txt
   ```
   Plik zawiera Inner Hash, adres nagród i gotowe polecenie. Nie ma w nim frazy — nim nie da się wydać monet.
2. Przenieś plik na drugi komputer (pendrive; w WSL okno folderu otworzysz poleceniem `explorer.exe .`).
3. Na drugim komputerze uruchom polecenie z pliku i dopisz urządzenie. Na laptopie:
   ```bash
   cd ~/projects/quantus-mining
   ./quantus-miner.sh start --device cpu --inner-hash 0xINNER_HASH_Z_PLIKU --rewards-address qzADRES_Z_PLIKU
   ```
   Na PC z kartą zamiast `--device cpu` wpisz `--device gpu`.
4. Dzięki `--rewards-address` nadzorca po starcie porówna adres, na który naprawdę kopie node. Jeśli przez literówkę w Inner Hash byłby inny, **zatrzyma kopanie** z komunikatem `BŁĄD: node kopałby na adres …, a oczekiwany adres nagród to …`. Wtedy popraw Inner Hash.

## 6. Szybka ścieżka: skrypt `quantus-miner.sh`

Co robi skrypt:
- pobiera oficjalne programy (node v1.0.1, miner v4.2.0) z GitHuba i sprawdza ich sumy kontrolne SHA-256; przy niezgodności przerywa pracę i usuwa pobrany plik;
- tworzy klucz sieciowy node'a i, przez kreator, klucz do nagród;
- uruchamia w tle **nadzorcę** (program pilnujący pozostałych). Nadzorca startuje node'a, sprawdza, że to mainnet, czeka na pełną synchronizację i dopiero wtedy włącza minera. Każdy proces, który padnie, uruchamia ponownie;
- uruchamia minera z obniżonym priorytetem (`nice 5`), więc Twoje programy mają pierwszeństwo;
- nie potrzebuje `sudo` (hasła administratora), chyba że włączysz autostart. Nie uruchamiaj go przez `sudo` — odmówi pracy.

### 6.1 Przygotowanie
Skrypt leży w `~/projects/quantus-mining/`. Na innym komputerze skopiuj go do takiego samego folderu (albo do katalogu domowego i wtedy zamiast `cd ~/projects/quantus-mining` wpisuj `cd ~`).
```bash
cd ~/projects/quantus-mining
chmod +x quantus-miner.sh
./quantus-miner.sh help
```
`chmod +x` pozwala uruchamiać plik. Bez tego zobaczysz `Permission denied`.

### 6.2 Konfiguracja (jednorazowo)
```bash
cd ~/projects/quantus-mining
./quantus-miner.sh setup --device cpu
```
`--device cpu` wymusza procesor. Bez tej opcji skrypt wybrałby kartę NVIDIA, gdyby ją wykrył.
Skrypt pobierze programy („Suma SHA-256 poprawna”) i utworzy klucz node'a („to NIE jest portfel”). Potem zapyta:
```
Dokąd mają trafiać nagrody z kopania?
  1) Utwórz NOWĄ frazę 24 słów (zalecane dla mainnetu)
  2) Użyj ISTNIEJĄCEJ frazy 24 słów (fraza z testnetu też zadziała — i tak zachowaj ją do airdropu)
  3) Mam już Inner Hash (0x…) — np. z innego komputera
```
**Wybór 1 (zalecany)** — przygotuj kartkę i długopis:
1. Pojawi się ramka `TWOJA NOWA FRAZA DO NAGRÓD (24 słów)` z ponumerowanymi słowami (po 4 w wierszu) i linią `Adres nagród (w aplikacji: Encrypted Account): qz…`. Przepisz wszystkie 24 słowa po kolei, z numerami. Przepisz też adres (po nim sprawdzisz nagrody).
2. Gdy skończysz przepisywać, wpisz `ZAPISAŁEM` i Enter (wielkość liter i polskie „ł” nie mają znaczenia; `zapisalem` też działa). Inna odpowiedź — skrypt zapyta jeszcze raz, najwyżej 3 razy. **Nie odpowiadaj „nie”:** `STOP`, `nie` albo `n` od razu przerywa i ta fraza przepada (przekreśl kartkę).
3. Ekran się wyczyści, a skrypt poprosi o **3 słowa o podanych numerach** (np. `Słowo nr 7:`). Przepisz je **z kartki**, nie z pamięci. Tak skrypt sprawdza, że kartka jest dobra.
4. Błędne słowo? Fraza pokaże się jeszcze raz — popraw kartkę (najwyżej 3 próby). Po sukcesie zobaczysz `Zapis frazy sprawdzony. Ekran wyczyszczony.`
5. Skrypt nigdzie nie zapisuje frazy. Jeśli przerwiesz (STOP, Ctrl+C), **ta fraza jest nieważna** — przekreśl kartkę. Następne uruchomienie pokaże NOWĄ, inną frazę.
6. Fraza pokaże się tylko w zwykłym oknie terminala. Jeśli uruchomisz skrypt z przekierowaniem (`| tee`, `>`), odmówi pokazania frazy.

**Wybór 2** — masz już frazę i chcesz jej użyć: wpisz słowa (nie będą widoczne — tak ma być). Najlepiej wszystkie w **jednej linii**, oddzielone spacjami, i jeden Enter. Możesz też wpisywać po kilka słów i Enter — skrypt pokaże `(wpisano N/24 słów…)` i poczeka na resztę. Na końcu zobaczysz `Fraza przyjęta. Adres nagród z tej frazy: qz…` — porównaj go z „Encrypted Account” w aplikacji. Uwaga: jeśli na tę frazę przyszła już jakakolwiek nagroda (np. z kopania na testnecie), aplikacja pokazuje w Encrypted Account już kolejny adres odbioru — wtedy adresy się różnią i to jest normalne (saldo nadal liczy adres z kreatora). Porównaj go wtedy z adresem, na który wcześniej kopałeś, albo sprawdź go w explorerze.

**Wybór 3** — frazę masz już na drugim komputerze: wklej Inner Hash (`0x…`). Adres skrypt odczyta od node'a po starcie (pokaże go `status`). Wygodniej jest jednak użyć polecenia z rozdziału 5 (`start --inner-hash … --rewards-address …`), bo wtedy skrypt pilnuje, żeby adres się zgadzał.

Na końcu zobaczysz `Ustawienia zapisane: /home/…/quantus-miner-kit/mining.conf (chmod 600)`.
Kreator nie pyta o nazwę node'a. Nadaje losową nazwę `qtc-…`, widoczną publicznie w telemetrii (mapa telemetry.quantus.com: nazwa, wersja programu, sprzęt, przybliżona lokalizacja). Własną nazwę ustawisz opcją `--name MojaNazwa` (litery, cyfry, `_` i `-`, bez kropek), a telemetrię wyłączysz opcją `--no-telemetry`.

**Sprawdzenie kartki (opcjonalnie, 1 minuta, zalecane):** wpisz słowa z kartki do tego samego programu, którego używa skrypt, i porównaj adres:
```bash
~/quantus-miner-kit/bin/quantus-node key quantus --scheme wormhole --words
```
Wpisz wszystkie 24 słowa z kartki **w jednej linii, bez numerów**, oddzielone spacjami, i naciśnij Enter **tylko raz, na końcu** (słów nie widać — tak ma być). Uwaga: ten program, inaczej niż kreator skryptu, czyta tylko jedną linię — nie naciskaj Enter w środku, bo reszta słów trafiłaby do okna jako polecenie i do historii powłoki. Wypisany `Address: qz…` musi być identyczny z adresem z kreatora. Potem wpisz `clear`.

### 6.3 Zmierz swoją moc (benchmark)
Benchmark tylko liczy. Nie łączy się z siecią i niczego nie kopie. Działa także przed konfiguracją.
```bash
cd ~/projects/quantus-mining
./quantus-miner.sh benchmark
```
Domyślnie test trwa 30 s na 12 wątkach (liczba wątków procesora minus 2). Wynik to linia `Average rate: 1.67M H/s` (tyle zmierzyliśmy na tym laptopie), czyli 1,67 MH/s. Dopisek `K` oznacza tysiące: `982.87K H/s` to ok. 0,98 MH/s.

Pomiar na tym laptopie 11.09 (bezczynny, po 20 s): 4 wątki 0,98 · 8 wątków 1,42 · 10 wątków 1,59 · **12 wątków 1,67** · 14 wątków 1,50 MH/s. Więcej wątków nie zawsze znaczy więcej mocy. Porównaj u siebie (trwa ok. 3 minuty):
```bash
for n in 4 8 10 12 14; do ./quantus-miner.sh benchmark --cpu-workers $n | grep -E 'CPU Workers|Average rate'; done
```
Po 30 s laptop może jeszcze nie zwolnić z gorąca, więc wybraną liczbę sprawdź przez 5 minut:
```bash
./quantus-miner.sh benchmark --cpu-workers 12 --duration 300
```
Twoje szanse (wpisz swój wynik w MH/s, z kropką):
```bash
./quantus-miner.sh difficulty --hashrate 1.67
```
Oficjalne materiały podają „~15 MH/s na wątek”. To błąd: na tym laptopie wychodzi ok. 0,11–0,25 MH/s na wątek (im więcej wątków, tym mniej na jeden).

### 6.4 Start
Wpisz swoją liczbę wątków. Bez `--cpu-workers` skrypt użyje liczby wątków minus 2 (u Ciebie 12). Wybór zapisuje się w ustawieniach, więc następnym razem wystarczy samo `./quantus-miner.sh start`.
```bash
cd ~/projects/quantus-mining
./quantus-miner.sh start --cpu-workers 12
```
Co się dzieje po starcie:
1. Skrypt sprawdza zegar („Zegar zsynchronizowany”) i wolne porty.
2. Zobaczysz `Wystartowano! Działa w tle. NIE zamykaj wszystkich okien Ubuntu — to okno możesz zminimalizować.` (poza WSL: „możesz zamknąć ten terminal”).
3. Node synchronizuje łańcuch. U nas 11.09 trwało to niecałe 2 minuty (24 tys. bloków); z czasem będzie dłużej — skrypt mówi „zwykle od kilkunastu minut do kilku godzin”. Miner w tym czasie czeka.
4. Gdy node dogoni sieć, nadzorca sam włączy minera (w logu: `Node zsynchronizowany — uruchamiam minera.`).

### 6.5 Codzienna obsługa
Najpierw `cd ~/projects/quantus-mining`, potem każde polecenie osobno.

**Stan** (synchronizacja, moc, wykopane bloki):
```bash
./quantus-miner.sh status
```
W trakcie synchronizacji (przykład z testu 11.09):
```
  Nadzorca: działa (pid 85702)
  Node:  działa (pid 85712)
  Łańcuch: blok 11322 / sieć 24210   peers: 6   synchronizacja: w toku
  Miner: nie działa (czeka na synchronizację node'a)
```
Gdy kopie (u nas: 2 wątki, stąd mała moc):
```
  Łańcuch: blok 24221 / sieć 24221   peers: 7   synchronizacja: zakończona
  Miner: działa (pid 27403)   moc: 556 kH/s
  Nagrody: https://explorer.quantus.com/accounts/qz…
  Wykopane bloki (łańcuch): 0   zgłoszone przez ten node (log): 0
```
Inne komunikaty `status`: `brak połączeń z siecią (peers: 0)` — node nie ma połączeń (sprawdź internet); `Miner: nie działa (wyłącza się i jest uruchamiany ponownie …)` — miner się psuje, zobacz `./quantus-miner.sh logs miner`; `? (brak odpowiedzi indeksatora)` — serwer z liczbą bloków chwilowo nie odpowiada.

**Logi na żywo.** Ctrl+C zamyka podgląd, a kopanie działa dalej. Tylko jeden log: dopisz `node`, `miner` albo `supervisor`.
```bash
./quantus-miner.sh logs
```
**Zatrzymanie i ponowne uruchomienie:**
```bash
./quantus-miner.sh stop
```
```bash
./quantus-miner.sh start
```
**Zmiana ustawień** (np. liczby wątków) — skrypt zapisze je i sam uruchomi kopanie ponownie („Ustawienia się zmieniły — uruchamiam kopanie ponownie z nowymi…”):
```bash
./quantus-miner.sh start --cpu-workers 8
```
(`restart --cpu-workers 8` robi to samo.)
**Trudność i szacowany zarobek** (pyta publiczny serwer Quantus, więc liczby są dobre także w trakcie synchronizacji; gdy miner działa, pojawi się wiersz „Twoja koparka”):
```bash
./quantus-miner.sh difficulty
```
**Twój klucz nagród dla drugiego komputera:** `./quantus-miner.sh rewards` (rozdział 5).

Po restarcie Windowsa lub WSL otwórz Ubuntu i wpisz `~/projects/quantus-mining/quantus-miner.sh start`. Wyjątek: jeśli masz autostart z rozdziału 7.2, kopanie ruszy samo.
Gdy kopanie działa w tle, nie przenoś pliku skryptu w inne miejsce. Najpierw wykonaj `stop`.

## 7. WSL2 na laptopie: żeby kopanie nie stawało

W WSL systemd często jest wyłączony (na Twoim laptopie też). Wtedy skrypt działa w **trybie w tle**. Sprawdzisz to w oknie Ubuntu poleceniem `ps -p 1 -o comm=`: wynik `systemd` oznacza, że systemd działa.
Na zwykłym Ubuntu (bez WSL) systemd działa od razu: pomiń 7.1–7.3 i po `setup` włącz autostart poleceniem `./quantus-miner.sh install-service`.

### 7.1 Zostaw jedno okno Ubuntu otwarte
Według dokumentacji Microsoftu Windows wyłącza Ubuntu kilka sekund po zamknięciu ostatniego okna, a całą maszynę WSL po czasie `vmIdleTimeout` (domyślnie 60 s). Node i miner znikają wtedy razem z nią. **Zostaw jedno okno Ubuntu otwarte (może być zminimalizowane).**
Test: zamknij wszystkie okna Ubuntu, odczekaj 2 minuty, otwórz Ubuntu i sprawdź stan. „Nadzorca: nie działa” oznacza, że WSL został wyłączony.
```bash
~/projects/quantus-mining/quantus-miner.sh status
```

### 7.2 Autostart przez systemd (opcjonalnie)
Najpierw sprawdź plik ustawień WSL (w oknie Ubuntu):
```bash
cat /etc/wsl.conf
```
- Widzisz `systemd=true` pod `[boot]` → nic nie dopisuj, przejdź dalej.
- Nie ma w nim `[boot]` (albo pliku nie ma) → dopisz (zapyta o hasło):
  ```bash
  printf '\n[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf
  ```
- Jest `[boot]`, ale bez `systemd=true` (albo z `systemd=false`) → otwórz edytor `sudo nano /etc/wsl.conf`, pod linią `[boot]` wpisz `systemd=true` (a `systemd=false` usuń), zapisz Ctrl+O, Enter i wyjdź Ctrl+X.

Potem w **PowerShell** wyłącz WSL:
```powershell
wsl --shutdown
```
Otwórz Ubuntu ponownie. Pierwsze polecenie musi wypisać `systemd`. Pozostałe instalują usługę (zapyta o hasło):
```bash
ps -p 1 -o comm=
cd ~/projects/quantus-mining
./quantus-miner.sh install-service
```
Zobaczysz `Usługa zainstalowana: kopanie ruszy SAMO przy każdym starcie WSL (np. po otwarciu okna Ubuntu).` Polecenia `start`, `stop`, `status` i `logs` działają jak wcześniej (start i stop mogą pytać o hasło). Logi nadzorcy nadal są w `./quantus-miner.sh logs supervisor`.
Usługa używa kopii skryptu z `~/quantus-miner-kit/bin/`. Po podmianie pliku skryptu na nowszy wpisz `./quantus-miner.sh start` — skrypt sam odświeży kopię i usługę. Autostart usuwa `./quantus-miner.sh remove-service`.
**Uwaga:** zgłoszenie microsoft/WSL#13416 opisuje WSL, który wyłącza się mimo działającej usługi systemd. Dlatego nadal zostaw jedno okno otwarte.

### 7.3 Dłuższe podtrzymanie WSL (niezweryfikowane)
W **PowerShell** otwórz plik ustawień WSL w Notatniku:
```powershell
notepad $env:USERPROFILE\.wslconfig
```
W **Notatniku** wpisz te dwie linie, zapisz plik i zamknij Notatnik:
```ini
[wsl2]
vmIdleTimeout=-1
```
Potem w PowerShell `wsl --shutdown`, otwórz Ubuntu i uruchom kopanie ponownie. Nie wiadomo, czy to wystarczy po zamknięciu wszystkich okien.

### 7.4 Uśpienie laptopa i zegar
- Uśpienie Windowsa zatrzymuje kopanie. Po wybudzeniu node musi dogonić sieć. Ustaw w Windows, żeby laptop podłączony do prądu się nie usypiał. Po wybudzeniu możesz wpisać `./quantus-miner.sh restart`: nadzorca poczeka na synchronizację i dopiero wtedy włączy minera.
- Po uśpieniu zegar w WSL potrafi się rozjechać. `start` sam to sprawdza („Zegar komputera różni się o …s”). Porównanie ręczne (różnica powinna wynosić najwyżej kilka sekund):
  ```bash
  date -u; curl -sI https://rpc1-mainnet.quantus.com | grep -i '^date'
  ```
  Naprawa (niezweryfikowane): `sudo hwclock -s`. Jeśli nie pomoże, w PowerShell `wsl --shutdown` i otwórz Ubuntu ponownie.

### 7.5 Porty i sieć
WSL2 stoi za NAT-em (siecią wewnętrzną Windowsa). Inne komputery nie połączą się z Twoim node'em na porcie 30333. **To nie przeszkadza** — w naszym teście node sam znalazł 6–7 peers. Sprawdź w `status`, czy `peers` jest większe od 0.
Portów 9833 (miner), 9944 (RPC), 9615 i 9900 (metryki) nie otwieraj na zewnątrz. Na zwykłym Ubuntu z publicznym IP wystaw tylko 30333/tcp, np. zaporą `ufw` (ogólna rada, nie od Quantus, niezweryfikowane). Pierwszą linię wpisz **tylko**, jeśli łączysz się z tym komputerem przez SSH (bez serwera SSH pokaże błąd `Could not find a profile matching 'OpenSSH'` — wtedy ją pomiń):
```bash
sudo ufw allow OpenSSH
sudo ufw allow 30333/tcp
sudo ufw deny 9833/udp
sudo ufw deny 9900/tcp
sudo ufw enable
```

### 7.6 Ciepło i prąd
- Kop tylko na zasilaczu. Na baterii laptop szybko się rozładuje i zwolni.
- Postaw laptopa na twardym podłożu i nie zasłaniaj wentylacji. Jeśli jest za gorąco albo za głośno, zmniejsz liczbę wątków (`./quantus-miner.sh start --cpu-workers 8`).
- Skrypt uruchamia minera z `nice 5`, więc przeglądarka i inne programy dostają procesor pierwsze. Ciepło i zużycie prądu zostają jednak takie same.

## 8. Pieniądze: zarobek, prąd, solo czy pula

**Zarobek solo (stan 11.09.2026, trudność D ≈ 3,1·10¹⁴):**

| Moc CPU | QTC / dzień | Średnio 1 blok co | Szansa na ≥1 blok w 30 dni / w rok |
|---|---|---|---|
| 1,0 MH/s | 0,000085 | ok. 9,9 roku | 0,8% / 9,6% |
| **1,67 MH/s (ten laptop, 12 wątków)** | **0,00014** | **ok. 5,9 roku** | **1,4% / 15,5%** |
| 2,0 MH/s | 0,00017 | ok. 5 lat | 1,7% / 18,3% |

**Prąd.** Laptop przy kopaniu bierze ok. 30–45 W (szacunek, niezweryfikowane), czyli ok. 0,7–1,1 kWh na dobę. Przy ok. 1 zł za kWh (sprawdź swoją stawkę na rachunku) to **ok. 1 zł dziennie**, a średni zarobek to ok. 0,00014 QTC — nawet przy nieoficjalnych 50 USD za 1 QTC (niezweryfikowane) to ok. 3 grosze. **Kopanie procesorem przynosi stratę.**

**Solo (domyślnie):** Twój node i Twój miner. Nagroda (ok. 0,31 QTC) trafia od razu na Twój adres i nikt jej nie przechowuje. Wadą jest loteria.
**Pula:** operator zbiera pracę wielu koparek, dzieli nagrody i wypłaca je po przekroczeniu progu. Średnio zarobisz tyle samo co solo, minus prowizja, tylko w małych, regularnych kwotach. Pula trzyma jednak Twoje monety i może zmienić zasady lub zniknąć. W trybie puli skrypt nie uruchamia node'a.

| Pula (10.09.2026, warunki się zmieniają) | Prowizja | Próg wypłaty | Laptop 1,67 MH/s: czas do progu |
|---|---|---|---|
| NurseryPool | 0,5% (0% do 13.09) | 0,1 QTC, wypłata co ok. 10 min | ok. 710 dni (ok. 2 lata) |
| quanpool | 1% | 0,25 QTC, wypłata co ok. 15 min | ok. 1 780 dni (ok. 5 lat) |

Jedna pula (quanpool, adres `qzowWAgbzjc2…`) wykopała ok. 75–88% bloków. 10.09 admin zachęcał, żeby przechodzić do innych pul.
**Wniosek dla procesora:** pula nie ma sensu. Jeśli mimo to chcesz spróbować: jako adres wypłat podaj adres `qz…`, do którego **masz frazę na papierze** — najprościej adres nagród z kreatora (Twój Encrypted Account; `./quantus-miner.sh rewards` go pokaże). Czy pula poprawnie płaci na taki adres, nie sprawdziliśmy na mainnecie (niezweryfikowane). „Account 1” z obecnej aplikacji to adres frazy z testnetu. **Nie** podawaj Inner Hash. Pierwsze polecenie przełącza na pulę, drugie wraca do solo:
```bash
./quantus-miner.sh start --device cpu --mode pool --pool nurserypool --payout-address qzTWOJ_ADRES
```
```bash
./quantus-miner.sh start --mode solo
```

## 9. Trudność: co to jest i jak ją sprawdzić

- **Trudność (D) to średnia liczba hashy potrzebna na jeden blok.** Każda próba ma szansę ok. 1 do D.
- **Stan 11.09.2026 ok. 00:15 UTC:** D ≈ 3,125·10¹⁴. Średni czas bloku z ostatnich 300 wynosił 13,8 s, a moc całej sieci ok. 22,6 TH/s (22,6 biliona hashy na sekundę). Nagroda za blok to 0,3065 QTC plus opłaty. Sieć tworzy ok. 6 200 bloków i ok. 1 900 nowych QTC dziennie (średnia z całej doby bywała wyższa, ok. 2 200, gdy bloki szły co ok. 12 s).
- **Jak się zmienia:** po każdym bloku, według reguły wzorowanej na Ethereum (Homestead).
  - Blok szybszy niż 10 s: D rośnie o ok. 0,05%.
  - Blok 10–20 s: D się nie zmienia.
  - Każde kolejne 10 s: D spada o kolejne ok. 0,05%, najwyżej o 4,8% naraz.

  Kod zakłada 12 s na blok, ale w praktyce bloki ustalają się na ok. 12–14 s (wyliczenie badaczy przy stałej mocy sieci: ok. 14,4 s — to nie jest oficjalna liczba).
- **Zarobek jest odwrotnie proporcjonalny do D.** Bloki dziennie = Twoja moc (H/s) × 86 400 / D. Gdy trudność się podwoi, zarobisz połowę.
- **Szczęście (rozkład Poissona):** bloki trafiają się losowo. Dla porównania karta RTX 4090 (ok. 820 MH/s, test deweloperów) zarabia ok. 0,07 QTC dziennie, ale nawet ona w ok. 20% tygodni nie znajdzie żadnego bloku.

**Aktualne wartości:**
```bash
./quantus-miner.sh difficulty
```
Wynik z 11.09.2026, ok. 00:15 UTC (z `--hashrate 1.67`):
```
Trudność (D): 3.125e+14  (= średnio tyle hashy na 1 blok)
Średni czas bloku (ostatnie 300): 13.84 s   → moc sieci ≈ 22.58 TH/s
Nagroda za blok ≈ 0.3065 QTC (+ opłaty)   bloków/dzień ≈ 6243   emisja ≈ 1913 QTC/dzień
Szacunek dla SOLO (wartość oczekiwana; w praktyce bloki trafiają się losowo):
  Twoja koparka                       1.7 MH/s   0.000142 QTC/dzień  średnio 1 blok co 2166 dni (ok. 5.9 roku)
  CPU laptop (~1.7 MH/s, pomiar)      1.7 MH/s   0.000142 QTC/dzień  średnio 1 blok co 2166 dni (ok. 5.9 roku)
  RTX 4090 (~820 MH/s, CUDA)        820.0 MH/s     0.0695 QTC/dzień  średnio 1 blok co 4.4 dni
W puli zarabiasz tyle samo średnio (minus prowizja), ale drobnymi, regularnymi kwotami.
```
Bez skryptu (wypisuje samą liczbę D):
```bash
curl -s -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"state_call","params":["QPoWApi_get_difficulty","0x"]}' https://rpc1-mainnet.quantus.com | python3 -c "import sys,json;h=json.load(sys.stdin)['result'][2:];print(int.from_bytes(bytes.fromhex(h),'little'))"
```

## 10. Czy to naprawdę kopie?

W `status` szukaj czterech rzeczy naraz: `peers` > 0, `blok X / sieć Y` równe (albo różnica 1–2), `synchronizacja: zakończona`, `Miner: działa … moc: …`. Ważne linie w logach (`./quantus-miner.sh logs`):

| Log | Linia | Znaczenie |
|---|---|---|
| supervisor | `Node na mainnecie (genesis OK).` | node jest w prawdziwej sieci |
| supervisor | `Nagrody idą na adres (według node'a): qz…` | adres nagród; musi być Twój |
| node | `⛏️ Rewards wormhole address: qz…` | to samo, z logu node'a |
| node | `💤 Idle (N peers)` | node zsynchronizowany |
| node | `⛏️ Miner server listening on port 9833` | node czeka na minera |
| node | `⛏️ Miner 1 connected (total: 1)` | miner podłączony |
| miner | `⛏️ Received job: id=…` | miner dostaje zadania |
| miner | `🎯 … found solution!` | miner znalazł rozwiązanie. To jeszcze nie pewny blok |
| node | `🥇 Successfully mined and submitted a new block via external miner …` | blok wysłany do sieci |
| node | `Mining paused: no connected peers for 30s (node is offline)` | brak połączenia z siecią |

Wysłane bloki w logu node'a (w ścieżce ręcznej log leży w `~/quantus/node.log`):
```bash
grep -a 'Successfully mined' ~/quantus-miner-kit/logs/node.log
```
**Wiążąca jest tylko sieć,** bo wysłany blok może jeszcze zostać sierotą. Otwórz w przeglądarce `https://explorer.quantus.com/accounts/TWOJ_ADRES`. Możesz też zapytać oficjalny indeks bloków (nagroda jest w najmniejszych jednostkach: `310000000000` = 0,31 QTC):
```bash
curl -s -H 'Content-Type: application/json' -d '{"query":"{ block(where:{mined_by_id:{_eq:\"qzTWOJ_ADRES\"}}, order_by:{height:desc}, limit:10){ height timestamp reward } }"}' https://sqm.quantus.com/v1/graphql
```
Swój node znajdziesz po nazwie na https://telemetry.quantus.com (chyba że wyłączyłeś telemetrię). Nazwę pokaże `grep NODE_NAME ~/quantus-miner-kit/mining.conf`.

## 11. Ścieżka ręczna (bez skryptu)

Potrzebujesz trzech okien Ubuntu: 1 dla node'a, 2 do sprawdzania, 3 dla minera. Zamknięcie okna zatrzymuje program. Ta ścieżka nie ma nadzorcy ani autostartu. **Nie uruchamiaj jej równocześnie ze skryptem** (te same porty).

### 11.1 Pobierz i sprawdź programy
Każde uruchomienie jest połączone `&&` z kontrolą sumy: jeśli pojawi się `FAILED`, nic się nie rozpakuje ani nie uruchomi. Wtedy usuń plik i pobierz go ponownie.
```bash
mkdir -p ~/quantus && cd ~/quantus
curl -fLO https://github.com/Quantus-Network/chain/releases/download/v1.0.1/quantus-node-v1.0.1-x86_64-unknown-linux-gnu.tar.gz
echo "5880937c2a933b97d9916c5c9e78425d9918c6d7b68abe69de43680f62c13c93  quantus-node-v1.0.1-x86_64-unknown-linux-gnu.tar.gz" | sha256sum -c && tar -xzf quantus-node-v1.0.1-x86_64-unknown-linux-gnu.tar.gz && ./quantus-node --version
curl -fL -o quantus-miner https://github.com/Quantus-Network/quantus-miner/releases/download/v4.2.0/quantus-miner-linux-x86_64
echo "a929e11ee1fd4fe291d743f373041bc280620376f5084620db3b0f82d9a2a276  quantus-miner" | sha256sum -c && chmod +x quantus-miner && ./quantus-miner --version
```
Musisz zobaczyć dwa razy `: OK` oraz wersje `quantus-node 1.0.1-f1176cea6a6` i `miner-cli 4.2.0`.

### 11.2 Klucz sieciowy node'a
```bash
cd ~/quantus
./quantus-node key generate-node-key --file $HOME/quantus/node_key.p2p
```
To tożsamość node'a w sieci, a nie portfel. Musi istnieć przed pierwszym startem, inaczej zobaczysz błąd `NetworkKeyNotFound`. Podawaj pełną ścieżkę do pliku.

### 11.3 Klucz nagród (Inner Hash)
Nowa fraza (zalecane):
```bash
./quantus-node key quantus --scheme wormhole
```
Albo istniejąca fraza. Wpisujesz ją po uruchomieniu polecenia, **wszystkie słowa w jednej linii, bez numerów**, oddzielone spacjami, i jeden Enter (nie widać ich na ekranie; nie wklejaj tekstu w kilku liniach — reszta linii trafiłaby do powłoki i jej historii):
```bash
./quantus-node key quantus --scheme wormhole --words
```
Wynik:
```
Secret phrase: <24 słowa>     ← tylko przy nowej frazie: przepisz NA PAPIER
Address: qz…                  ← Twój adres nagród (do sprawdzania w explorerze)
Inner Hash: 0x…               ← 64 znaki po 0x: podasz go node'owi
```
Nie dopisuj `--wallet-index` ani `--no-derivation`. Nie pomijaj `--scheme wormhole`: bez tej opcji wynik nie zawiera Inner Hash. Po zapisaniu frazy wpisz `clear`, żeby wyczyścić ekran.

### 11.4 Uruchom node'a (okno 1)
Zamień `NAZWA` (litery, cyfry, `_`, `-`; bez kropek; widoczna publicznie) i `0xTWOJ_INNER_HASH`:
```bash
cd ~/quantus
./quantus-node \
  --name NAZWA \
  --validator \
  --chain mainnet \
  --base-path $HOME/.local/share/quantus-node \
  --node-key-file $HOME/quantus/node_key.p2p \
  --rewards-inner-hash 0xTWOJ_INNER_HASH \
  --miner-listen-port 9833 \
  --max-blocks-per-request 64 \
  --sync full 2>&1 | tee -a $HOME/quantus/node.log
```
Co robią opcje:
- `--validator`: tryb kopania, node tworzy bloki. `--chain mainnet`: sieć główna. **Bez tej opcji node wczyta inną sieć.**
- `--base-path`: folder na dane łańcucha. `--rewards-inner-hash`: Twój Inner Hash, czyli dokąd trafia nagroda.
- `--miner-listen-port 9833`: node czeka na zewnętrznego minera. Bez tej opcji włącza wolne kopanie lokalne („LOCAL mining only”).
- `--max-blocks-per-request 64 --sync full`: pobieranie wg oficjalnej dokumentacji; node sprawdza wszystkie bloki. `tee -a` zapisuje log do pliku.
- Opcjonalnie, jeśli nie chcesz, żeby node był widoczny w publicznej telemetrii, dopisz w poleceniu osobną linię `  --no-telemetry \` zaraz pod linią `  --name NAZWA \` (nie na końcu, za `tee`).

Nie dodawaj `--force-authoring` ani `--bootnodes`. Pochodzą ze starych poleceń z 09.09 i są przestarzałe.
Na starcie szukaj linii `⛏️ Rewards wormhole address: qz…` (adres musi się zgadzać z Twoim `Address:`) i `⛏️ Miner server listening on port 9833`.

### 11.5 Sprawdź synchronizację (okno 2)
```bash
curl -s -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"system_health","params":[]}' http://127.0.0.1:9944; echo
curl -s -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"system_syncState","params":[]}' http://127.0.0.1:9944; echo
curl -s -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"chain_getBlockHash","params":[0]}' http://127.0.0.1:9944; echo
```
Node jest gotowy, gdy spełnia cztery warunki:
- `"peers"` wynosi co najmniej 1;
- widać `"isSyncing":false`;
- `currentBlock` równa się `highestBlock` (albo jest mniejszy o 1–2);
- trzecia odpowiedź to `0xfb5487c0be6ae4ade2d41d16e50465129861636c2b8d61fa94d7a19631626fba` (dowód, że jesteś na mainnecie).

Uwaga: przy 0 peers node też pokazuje `"isSyncing":false`, nawet na bloku 0 — dlatego liczy się komplet warunków. W logu zobaczysz zmianę z `⚙️ Syncing…` na `💤 Idle (N peers)`. Porównanie z oficjalnym serwerem (numery bloków są szesnastkowe; `printf` zamienia przykładowy numer na zwykłą liczbę):
```bash
for u in http://127.0.0.1:9944 https://rpc1-mainnet.quantus.com; do curl -s -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"chain_getHeader","params":[]}' $u | grep -o '"number":"0x[0-9a-f]*"'; done
printf '%d\n' 0x5e99
```

### 11.6 Uruchom minera (okno 3), dopiero po synchronizacji
```bash
cd ~/quantus
CHAIN_DIR="$HOME/.local/share/quantus-node/chains/mainnet"
ls -l "$CHAIN_DIR/miner-auth-token" "$CHAIN_DIR/miner-tls-cert-sha256"
nice -n 5 ./quantus-miner serve \
  --node-addr 127.0.0.1:9833 \
  --auth-token-file "$CHAIN_DIR/miner-auth-token" \
  --tls-cert-sha256-file "$CHAIN_DIR/miner-tls-cert-sha256" \
  --cpu-workers 12 \
  --gpu-devices 0 2>&1 | tee -a $HOME/quantus/miner.log
```
- Oba pliki (hasło minera i odcisk certyfikatu) node tworzy sam przy pierwszym starcie.
- `--node-addr`: zawsze adres IP `127.0.0.1:9833`, nigdy słowo `localhost` (miner go odrzuci).
- `--cpu-workers`: liczba wątków. `--gpu-devices 0` wyłącza grafikę; bez tego miner może próbować użyć zintegrowanej grafiki. `nice -n 5` obniża priorytet minera.

Zatrzymanie: Ctrl+C, najpierw w oknie minera, potem node'a.
Benchmark bez skryptu (`--gpu-devices 0` jest konieczne):
```bash
cd ~/quantus
for n in 4 8 10 12 14; do ./quantus-miner benchmark --cpu-workers $n --gpu-devices 0 --duration 30 | grep -E 'CPU Workers|Average rate'; done
```
Moc na żywo podczas kopania (wartość w H/s):
```bash
curl -s http://127.0.0.1:9900/metrics | grep -E '^miner_(hash_rate|cpu_hash_rate|hashes_total)'
```

## 12. Problemy i rozwiązania

| Objaw | Przyczyna | Co zrobić |
|---|---|---|
| `No such file or directory` przy `./quantus-miner.sh` | jesteś w innym folderze (nowe okno zaczyna w katalogu domowym) | `cd ~/projects/quantus-mining` albo pełna ścieżka `~/projects/quantus-mining/quantus-miner.sh` |
| `Permission denied` przy `./quantus-miner.sh` | plik nie ma prawa uruchamiania | `chmod +x quantus-miner.sh` (6.1) |
| `Nieoczekiwany argument: —cpu-workers` albo inne polecenie nie działa po skopiowaniu | Telegram zamienił `--` na `—` | wpisz ręcznie dwa minusy |
| `Nie uruchamiaj jako root ani przez sudo` | polecenie wpisane z `sudo` | wpisz je bez `sudo`; skrypt sam poprosi o hasło, gdy trzeba |
| `wymaga glibc >= 2.38` albo `GLIBC_2.38 not found` | za stary system (np. Ubuntu 22.04) | użyj Ubuntu 24.04 |
| `Brakuje programów: …` | brak narzędzi systemowych | `sudo apt install -y curl tar coreutils util-linux procps python3` |
| `Suma kontrolna się NIE zgadza` | plik uszkodzony lub podmieniony | skrypt przerwał i usunął plik; spróbuj później; zgłoś, jeśli się powtarza |
| `tylko na ekranie terminala` przy nowej frazie | skrypt uruchomiony z `| tee` / `>` albo nie w oknie terminala | uruchom zwykle, w oknie Ubuntu (albo użyj `--inner-hash`) |
| `Przerwano — nic nie zapisano` | przerwany kreator frazy | przekreśl kartkę; uruchom `setup` jeszcze raz (będzie nowa fraza) |
| `Zajęte porty: …` | działa inny node lub miner (np. oficjalny `quantus-mining.sh`) | zatrzymaj go albo wykonaj `./quantus-miner.sh stop` |
| Miner długo „czeka na synchronizację” | node jeszcze pobiera bloki | porównaj `blok X / sieć Y` w `status`; różnica > 2 → czekaj |
| `Miner: nie działa (wyłącza się i jest uruchamiany ponownie …)` | miner się psuje (np. zajęty port 9900) | `./quantus-miner.sh logs miner`; port metryk zmienisz: `start --metrics-port 9911` |
| `peers: 0` / `brak połączeń z siecią (peers: 0)` / `Idle (0 peers)` | brak internetu, zła wersja lub zła sieć | sprawdź internet; node v1.0.1 i `--chain mainnet` |
| `Verification failed` i 0 peers | wersja node'a nie pasuje do sieci | sprawdź nowe wydania (rozdział 13) |
| `Zegar komputera różni się o …s` | zegar rozjechał się (w WSL zwykle po uśpieniu) | WSL: `sudo hwclock -s` albo `wsl --shutdown` (7.4); zwykłe Ubuntu: `sudo timedatectl set-ntp true` |
| „Nadzorca: nie działa” po zamknięciu okien | Windows wyłączył WSL | zostaw okno otwarte (7.1), ustaw autostart (7.2), potem `start` |
| `BŁĄD: node kopałby na adres …` (w `logs supervisor`) | Inner Hash nie pasuje do `--rewards-address` (literówka) | skopiuj Inner Hash z pliku `rewards` jeszcze raz (rozdział 5) |
| `BŁĄD: node odrzuca Inner Hash z ustawień` | wklejony Inner Hash nie jest poprawnym kluczem | Inner Hash z pliku `rewards` z drugiego komputera? Nie twórz nowej frazy: skopiuj go z pliku jeszcze raz i uruchom `./quantus-miner.sh start --device cpu --inner-hash 0x… --rewards-address qz…` (rozdział 5). W przeciwnym razie `./quantus-miner.sh start --key new` (albo `--key import`) — ustawi nowy klucz i od razu uruchomi kopanie |
| `Nazwa node'a: tylko litery/cyfry/_-` | w `--name` jest kropka, spacja lub inny znak | np. `--name Laptop-1` |
| Miner od razu się wyłącza (ścieżka ręczna) | node jeszcze nie nasłuchuje, brak plików `miner-auth-token`, niezgodne wersje, zajęty port 9900 albo nazwa zamiast IP w `--node-addr` (`invalid socket address syntax`) | poczekaj na `Miner server listening`; sprawdź pliki i `127.0.0.1:9833` (11.6) |
| `--rewards-inner-hash is required…`, `NetworkKeyNotFound` albo `Using LOCAL mining only` | brak Inner Hash, klucza node'a lub `--miner-listen-port` (ścieżka ręczna) | kroki 11.2–11.4 |
| Moc dużo niższa niż w benchmarku, laptop gorący | przegrzanie, praca na baterii | zasilacz, chłodzenie, mniej wątków (7.6) |
| Nie widzę nagród w aplikacji | aplikacja wciąż na testnecie albo patrzysz na „Account 1” | sprawdź explorer i „Encrypted Account” (rozdział 4) |
| `Nadzorca nie wystartował` | błąd przy starcie w tle | `./quantus-miner.sh logs supervisor` |

**Zmiana klucza nagród w skrypcie** (nowa fraza albo inna istniejąca). Skrypt zapyta, czy zastąpić obecny klucz, i sam uruchomi kopanie ponownie. Nowa fraza to nowy adres; nagrody na starym adresie zostają pod starą frazą.
```bash
./quantus-miner.sh start --key new
```

## 13. Aktualizacje, pliki, odinstalowanie

**Nowe wersje.** Sprawdź najnowsze wydania (11.09.2026 były to `v1.0.1` i `v4.2.0`):
```bash
curl -s https://api.github.com/repos/Quantus-Network/chain/releases/latest | grep '"tag_name"'
curl -s https://api.github.com/repos/Quantus-Network/quantus-miner/releases/latest | grep '"tag_name"'
```
Śledź też github.com/Quantus-Network (Releases), docs.quantus.com/guides/mining i kanał t.me/quantusnetwork. Czekają poprawki node'a (PR #699 i #700), więc możliwa jest wersja v1.0.2.
Skrypt ma wersje i sumy kontrolne wpisane na stałe i sam się nie zaktualizuje. Nowa wersja programów wymaga nowej wersji skryptu albo ścieżki ręcznej. W ścieżce ręcznej sumy kontrolne nowego wydania wypiszesz tak (zmień `v4.2.0` na nowy numer, a dla node'a wpisz `chain` zamiast `quantus-miner`):
```bash
curl -s https://api.github.com/repos/Quantus-Network/quantus-miner/releases/tags/v4.2.0 | python3 -c 'import sys,json; [print(a["name"], a["digest"]) for a in json.load(sys.stdin)["assets"]]'
```
Node i miner muszą do siebie pasować. Pierwsze polecenie musi pokazać `--miner-auth-token-file`, drugie `--auth-token-file` i `--tls-cert-sha256-file`:
```bash
cd ~/quantus
./quantus-node --help | grep miner-auth-token-file
./quantus-miner serve --help | grep -E 'auth-token-file|tls-cert-sha256-file'
```

**Gdzie są pliki:**

| Ścieżka | Co zawiera |
|---|---|
| `~/projects/quantus-mining/quantus-miner.sh` | skrypt |
| `~/quantus-miner-kit/bin/` | programy `quantus-node`, `quantus-miner` (i kopia skryptu dla usługi) |
| `~/quantus-miner-kit/logs/` | `node.log`, `miner.log`, `supervisor.log` (duże logi są automatycznie przycinane) |
| `~/quantus-miner-kit/mining.conf` | ustawienia: Inner Hash, adres nagród, wątki (chmod 600, nie udostępniaj) |
| `~/quantus-miner-kit/node_key.p2p` | klucz sieciowy node'a (to nie portfel) |
| `~/.local/share/quantus-node/chains/mainnet/` | dane łańcucha oraz `miner-auth-token` i `miner-tls-cert-sha256` |
| `/etc/systemd/system/quantus-miner-kit.service` | usługa autostartu (tylko po `install-service`) |
| `~/quantus/` | pliki ze ścieżki ręcznej |

Jeśli zmienisz katalog opcją `--dir`, podawaj ją przy **każdym** poleceniu (skrypt jej nie zapamiętuje). Ile miejsca zajmuje łańcuch:
```bash
du -sh ~/.local/share/quantus-node/chains/mainnet
```
**Odinstalowanie.** Najpierw upewnij się, że fraza 24 słów jest na papierze. Monety są w sieci, nie w tych plikach. Uwaga: z folderu `~/.local/share/quantus-node` korzysta też oficjalny skrypt `quantus-mining.sh`.
```bash
cd ~/projects/quantus-mining
./quantus-miner.sh stop
./quantus-miner.sh remove-service
rm -rf ~/quantus-miner-kit
rm -rf ~/.local/share/quantus-node
```

## 14. Słowniczek

Podstawowe pojęcia (node, miner, synchronizacja, trudność, fraza seed, Inner Hash, pula, systemd) wyjaśnia rozdział 2.
- **Peer:** inny komputer w sieci, z którym łączy się Twój node.
- **Sierota (orphan):** blok, który przegrał z innym i nic nie daje.
- **Hash, hashrate:** jedna próba i liczba prób na sekundę. 1 kH/s to tysiąc, 1 MH/s milion, 1 TH/s bilion prób na sekundę.
- **Adres wormhole / Encrypted Account:** adres `qz…`, na który przychodzą nagrody z kopania.
- **Próg wypłaty:** kwota, od której pula wysyła pieniądze.
- **Nadzorca:** część skryptu, która pilnuje node'a i minera i uruchamia je ponownie po awarii.
- **WSL2:** Linux (Ubuntu) uruchomiony wewnątrz Windowsa.
- **RPC:** „okienko” node'a do zadawania pytań, adres `127.0.0.1:9944`, dostępne tylko z Twojego komputera.
- **Explorer:** strona, na której widać bloki i salda (explorer.quantus.com).
- **Telemetria:** publiczna mapa node'ów (nazwa, wersja, sprzęt, przybliżona lokalizacja); wyłączysz ją opcją `--no-telemetry`.
- **Testnet (Planck i kolejne):** stare sieci testowe. Ich monety nie przechodzą na mainnet; zapowiedziano osobny airdrop dla górników testnetu.

## 15. Oficjalne źródła

- Dokumentacja kopania: https://docs.quantus.com/guides/mining/
- Node (wydania): https://github.com/Quantus-Network/chain/releases (v1.0.1: https://github.com/Quantus-Network/chain/releases/tag/v1.0.1)
- Miner (wydania): https://github.com/Quantus-Network/quantus-miner/releases (v4.2.0: https://github.com/Quantus-Network/quantus-miner/releases/tag/v4.2.0)
- Explorer: https://explorer.quantus.com
- Telemetria: https://telemetry.quantus.com
- Publiczny serwer RPC: https://rpc1-mainnet.quantus.com. Indeks bloków: https://sqm.quantus.com/v1/graphql
- Telegram: https://t.me/quantusnetwork. Linki do aplikacji: https://linktr.ee/quantusnetwork. Strona: https://quantus.com
- WSL (Microsoft): https://learn.microsoft.com/en-us/windows/wsl/wsl-config, https://learn.microsoft.com/en-us/windows/wsl/systemd, zgłoszenie https://github.com/microsoft/WSL/issues/13416
- Pule (nieoficjalne, niesprawdzone przez Quantus): https://quan.nurserypool.com, https://quanpool.com
