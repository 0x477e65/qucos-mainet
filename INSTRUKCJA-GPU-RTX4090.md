# Kopanie Quantus (QTC) na karcie NVIDIA RTX 4090 — Ubuntu 24.04

> **Stan na 11.09.2026** (noc, ok. 00:15 UTC). Wersje: node **v1.0.1**, miner **v4.2.0**, biblioteka NVIDIA NVRTC **12.8.93**, skrypt `quantus-miner.sh` **1.0.0**.
> Sieć: **mainnet** (działa od 09.09.2026, pierwszy blok 08:51:57 UTC). Wersje, trudność i warunki pul zmieniają się szybko — jak sprawdzić nowości: rozdział 15.
> Ścieżkę CPU skryptu sprawdziliśmy na prawdziwym mainnecie (pobranie, synchronizacja, kopanie, restart, stop). Ścieżkę GPU sprawdziliśmy tylko na atrapach — laptop do testów nie ma karty NVIDIA.

## 0. Jak czytać tę instrukcję

- Komendy są w szarych ramkach. Wpisuj je w **terminalu Ubuntu** (otwierasz go skrótem **Ctrl+Alt+T** albo: Pokaż aplikacje → „Terminal”). Wklejasz przez **Ctrl+Shift+V**. Każdą komendę wpisuj osobno i naciśnij Enter. Linie zaczynające się od `#` to komentarze.
- **Uwaga na Telegram:** zamienia dwa minusy `--` na długą kreskę `—`. Komenda skopiowana z Telegrama nie zadziała. Popraw ją ręcznie na dwa zwykłe minusy.
- Słowa pisane WIELKIMI literami, np. `qzTWOJ_ADRES`, zastąp swoimi danymi.
- „(niezweryfikowane)” oznacza informację, której nikt z nas nie sprawdził na prawdziwym sprzęcie.

**Najkrócej:** sterownik NVIDIA ≥ 570 (rozdział 3) → skrypt do katalogu domowego i `chmod +x` (rozdział 4) → `./quantus-miner.sh start --device gpu --gpu-power-limit 350` → w kreatorze wybierz `1`, przepisz 24 słowa na papier, wpisz `ZAPISAŁEM`, przepisz z kartki 3 słowa, o które poprosi skrypt (jeśli już kopiesz na laptopie i masz tam frazę — nie twórz nowej: zrób jak w rozdziale 6, czyli `rewards` na laptopie, a tutaj `./quantus-miner.sh start --device gpu --inner-hash … --rewards-address …`) → czekaj, aż node się zsynchronizuje (miner ruszy sam) → `./quantus-miner.sh install-service` (autostart) → `./quantus-miner.sh rewards > moj-klucz-nagrod.txt`, jeśli chcesz kopać też na laptopie (rozdział 6). Spodziewaj się średnio **ok. 0,07 QTC dziennie**, czyli średnio 1 bloku co ok. 4,4 dnia (solo) — i rachunku za prąd ok. 10 zł dziennie (rozdział 9).

## 1. Jak to działa — w minutę

- **Node** (węzeł, program `quantus-node`) pobiera i sprawdza cały łańcuch bloków oraz rozmawia z innymi komputerami sieci. Przy kopaniu solo przygotowuje zadania dla koparki i wysyła znaleziony blok do sieci.
- **Miner** (koparka, program `quantus-miner`) na karcie graficznej wykonuje miliony prób (hashy) na sekundę, szukając rozwiązania zadania. Szybkość mierzymy w **MH/s** (milionach prób na sekundę).
- **Synchronizacja** — node musi najpierw pobrać i sprawdzić wszystkie dotychczasowe bloki. Dopóki tego nie skończy, kopanie jest stratą prądu: bloki wykopane „na starym końcu” łańcucha są odrzucane (to tzw. bloki osierocone). Skrypt włącza koparkę dopiero po synchronizacji.
- **Trudność** — ile prób trzeba średnio wykonać, żeby znaleźć jeden blok (rozdział 10).
- **Fraza seed (24 słowa)** — główny klucz do Twoich nagród. Kto ją zna, ten ma pieniądze. Tylko na papier.
- **Inner Hash** — ciąg `0x` + 64 znaki wyliczony z frazy. Mówi node'owi, dokąd wysyłać nagrody. Nie da się nim wydać pieniędzy (to nie jest sekret), ale lepiej go nie rozsyłać.
- **Adres nagród** zaczyna się od `qz…`. To tzw. adres wormhole — w aplikacji Quantus nazywa się **„Encrypted Account”** (nie „Account 1”).
- **Solo** — kopiesz sam, cała nagroda za blok (ok. 0,31 QTC) jest Twoja, ale bloki trafiają się rzadko i losowo. **Pula** — wiele osób kopie razem i dzieli się nagrodami: dostajesz małe kwoty często, ale pula trzyma Twoje monety do wypłaty.
- **systemd** — mechanizm Ubuntu, który sam uruchamia programy po włączeniu komputera i podnosi je po awarii.

## 2. Czego potrzebujesz

- Komputer z RTX 4090 i **Ubuntu 24.04 zainstalowanym normalnie** (nie w WSL). Node v1.0.1 wymaga biblioteki glibc ≥ 2.38, więc Ubuntu 22.04 jest za stare.
- **Sterownik NVIDIA ≥ 570** (rozdział 3).
- **Dysk:** co najmniej 20 GB wolnego (poniżej skrypt ostrzega), zalecane 100 GB+. 11.09 cały łańcuch zajmował ok. 0,5 GB, ale będzie rósł. Stare zalecenia z testnetu: minimum 4 GB RAM, zalecane 8 GB+ RAM i dysk SSD.
- Stałe łącze internetowe i poprawny zegar (sieć odrzuca bloki z czasem o ponad 15 s „z przyszłości”).
- Zwykłe konto użytkownika z prawem `sudo`. **Nie uruchamiaj skryptu przez `sudo`** — odmówi pracy; sam poprosi o hasło, gdy będzie trzeba.
- Kartka i długopis na frazę.

## 3. Krok 1: sterownik NVIDIA

Sprawdź, co masz:

```bash
nvidia-smi
```

W nagłówku szukaj **Driver Version** (musi być 570 lub wyżej) i **CUDA Version** (12.8 lub wyżej). Jeśli komenda nie działa (`command not found` albo błąd), zgłasza błąd albo wersja jest starsza, zainstaluj sterownik i uruchom komputer ponownie:

```bash
sudo ubuntu-drivers install
sudo reboot
```

Jeśli po restarcie wersja nadal jest niższa niż 570, zainstaluj konkretną serię sterownika (580, tę samą serię mieli twórcy minera w swoich testach):

```bash
sudo apt install nvidia-driver-580
sudo reboot
```

Po restarcie znowu wpisz `nvidia-smi` i sprawdź obie wersje.

**Secure Boot:** jeśli komputer ma go włączonego, instalator może poprosić o hasło, a po restarcie pokazać ekran zarządzania kluczami (MOK), gdzie trzeba zatwierdzić klucz tym hasłem — inaczej sterownik się nie załaduje. Opis: https://documentation.ubuntu.com/server/how-to/graphics/install-nvidia-drivers/ (ogólna procedura Ubuntu, niezweryfikowane na tym komputerze).

**Nie instaluj** pakietu `nvidia-cuda-toolkit` z Ubuntu. Zawiera starą bibliotekę NVRTC 12.0, która psuje miner v4.2.0 (rozdział 5). Skrypt przynosi własną, właściwą wersję.

## 4. Krok 2: skrypt na komputer z kartą

Na laptopie skrypt leży w `~/projects/quantus-mining/quantus-miner.sh` (wewnątrz Ubuntu w WSL). Przenieś go do katalogu domowego na komputerze z RTX 4090 jednym z dwóch sposobów:

- **Pendrive:** na laptopie, w oknie Ubuntu, wpisz poniższą komendę — otworzy się ten folder w Eksploratorze Windows. Przeciągnij plik `quantus-miner.sh` (i tę instrukcję) na pendrive.
  ```bash
  cd ~/projects/quantus-mining && explorer.exe .
  ```
  Na komputerze z kartą otwórz **Pliki** (Files), wejdź na pendrive i skopiuj plik do **Katalog domowy** (Home).
- **Przez sieć (scp):** potrzebny jest serwer SSH na komputerze z kartą (`sudo apt install openssh-server`) i jego adres IP w sieci domowej — sprawdzisz go na tym komputerze poleceniem `hostname -I` (pierwsza liczba, np. `192.168.1.23`). Potem w Ubuntu na laptopie (`user` = Twój login na komputerze z kartą):

```bash
scp ~/projects/quantus-mining/quantus-miner.sh user@192.168.1.23:~/
```

Potem, już na komputerze z kartą:

```bash
cd ~
chmod +x quantus-miner.sh
./quantus-miner.sh help
```

`chmod +x` oznacza plik jako program. Bez tego zobaczysz `Permission denied`. Opcjonalnie porównaj sumy kontrolne: na komputerze z kartą `sha256sum ~/quantus-miner.sh`, a na laptopie (w oknie Ubuntu) `sha256sum ~/projects/quantus-mining/quantus-miner.sh` — wynik musi być identyczny (plik nie uszkodził się po drodze).

## 5. Krok 3: pierwsze uruchomienie (szybka ścieżka)

```bash
cd ~
./quantus-miner.sh start --device gpu --gpu-power-limit 350
```

- `start` — konfiguracja przy pierwszym razie, potem uruchomienie w tle. Samo `./quantus-miner.sh` robi to samo.
- `--device gpu` — kop kartą NVIDIA (skrypt wykrywa kartę sam, jeśli sterownik działa; ta opcja jest dla pewności).
- `--gpu-power-limit 350` — opcjonalny limit mocy 350 W (rozdział 9). Skrypt poprosi o hasło `sudo` przy starcie kopania. Możesz tę opcję pominąć.

Co skrypt robi po kolei:

1. Sprawdza system (Linux x86_64, nie root, potrzebne programy, glibc ≥ 2.38), wolne miejsce i RAM.
2. Pobiera oficjalny miner v4.2.0 z GitHuba i sprawdza jego **sumę SHA-256** (cyfrowy odcisk pliku). Jeśli się nie zgadza — przerywa i usuwa plik, bo mógł zostać podmieniony.
3. Sprawdza sterownik (≥ 570): `GPU: NVIDIA GeForce RTX 4090, sterownik …`. Jeśli sterownika nie ma: `Nie widzę karty NVIDIA … sudo ubuntu-drivers install` (rozdział 3).
4. Sprawdza, czy limit mocy mieści się w zakresie Twojej karty (np. `Limit mocy 350 W mieści się w zakresie karty (… W)`).
5. Pobiera oficjalną bibliotekę NVIDIA **NVRTC 12.8** (bez `sudo`, do `~/quantus-miner-kit/nvrtc`), sprawdza jej sumę i wersję: `NVRTC 12.8 gotowy (CUDA).`
6. Robi **5-sekundowy test CUDA** — karta na chwilę zaszumi. Powinno pojawić się `CUDA działa: Average rate: …`.
7. Pobiera node v1.0.1 (też ze sprawdzeniem sumy).
8. Tworzy klucz sieciowy node'a (`node_key.p2p`) — to NIE jest portfel, tylko „dowód osobisty” node'a w sieci.
9. Pyta, dokąd mają trafiać nagrody (kreator poniżej).
10. Zapisuje ustawienia w `~/quantus-miner-kit/mining.conf` (tylko Ty możesz go czytać), sprawdza zegar i wolne porty, ustawia limit mocy i uruchamia wszystko w tle.

**Kreator nagród** — zobaczysz:

```text
Dokąd mają trafiać nagrody z kopania?
  1) Utwórz NOWĄ frazę 24 słów (zalecane dla mainnetu)
  2) Użyj ISTNIEJĄCEJ frazy 24 słów (fraza z testnetu też zadziała — i tak zachowaj ją do airdropu)
  3) Mam już Inner Hash (0x…) — np. z innego komputera
Wybierz [1/2/3]:
```

**Wybór 1 (zalecany)** — przygotuj kartkę i długopis:
1. Pojawi się ramka `TWOJA NOWA FRAZA DO NAGRÓD (24 słów)` z ponumerowanymi słowami (po 4 w wierszu) i linią `Adres nagród (w aplikacji: Encrypted Account): qz…`. Przepisz wszystkie 24 słowa po kolei, z numerami. Przepisz też adres (po nim sprawdzisz nagrody). Nie rób zdjęcia i nie kopiuj słów myszką.
2. Gdy skończysz przepisywać, wpisz `ZAPISAŁEM` i Enter (wielkość liter i „ł” nie mają znaczenia; `zapisalem` też działa). Nierozpoznana odpowiedź — skrypt zapyta ponownie, ale najwyżej 3 razy, potem przerwie. **Nie odpowiadaj „nie”** — `STOP`, `nie` i `n` od razu przerywają; po przerwaniu ta fraza jest nieważna (punkt 5).
3. Ekran się wyczyści, a skrypt poprosi o **3 słowa o podanych numerach** (np. `Słowo nr 7:`). Przepisz je **z kartki**. Tak skrypt sprawdza, że kartka jest dobra.
4. Błędne słowo? Fraza pokaże się jeszcze raz — popraw kartkę (najwyżej 3 próby). Po sukcesie: `Zapis frazy sprawdzony. Ekran wyczyszczony.`
5. Skrypt nigdzie nie zapisuje frazy. Jeśli przerwiesz, **ta fraza jest nieważna** — przekreśl kartkę; następne uruchomienie pokaże nową. Fraza pokazuje się tylko w zwykłym oknie terminala (przy `| tee` albo `>` skrypt odmówi).

**Wybór 2** — masz już frazę dla mainnetu: wpisz słowa (nie będą widoczne — to celowe). Najlepiej wszystkie w jednej linii, oddzielone spacjami, i jeden Enter; możesz też wpisywać po kilka słów i Enter — skrypt poczeka na 24. Na końcu: `Fraza przyjęta. Adres nagród z tej frazy: qz…` — porównaj z „Encrypted Account” w aplikacji (jeśli na tę frazę przyszła już jakakolwiek nagroda, aplikacja pokazuje kolejny adres odbioru — wtedy różnica jest normalna; sprawdź adres w eksploratorze). Dlaczego zalecamy nową frazę — rozdział 13.

**Wybór 3** — gdy masz już Inner Hash z drugiego komputera. Skrypt pyta tylko o Inner Hash, a adres odczyta od node'a po starcie. Wygodniej jest użyć polecenia z rozdziału 6 (`start --inner-hash … --rewards-address …`), bo wtedy skrypt pilnuje, żeby adres się zgadzał.

Na końcu zobaczysz `Nagrody trafią na adres: qz…`, a po starcie `Wystartowano! Działa w tle (możesz zamknąć ten terminal).`

**Sprawdzenie kartki (opcjonalnie, zalecane):** wpisz `~/quantus-miner-kit/bin/quantus-node key quantus --scheme wormhole --words` i Enter. Program czeka na słowa i ich NIE pokazuje (to celowe). Wpisz wszystkie 24 słowa z kartki w JEDNEJ linii, bez numerów, oddzielone spacjami, i naciśnij Enter tylko raz — na końcu. Nie naciskaj Enter między słowami i nie wklejaj kilku linii: to nie jest kreator skryptu, program czyta tylko jedną linię, a pozostałe słowa trafiłyby do powłoki (widoczne na ekranie i zapisane w historii poleceń). Wypisany `Address: qz…` musi być identyczny z adresem z kreatora. Potem `clear`.

**Po co NVRTC 12.8?** Z opcją `--cuda-gpu` miner przy starcie „tłumaczy” swój program kopiący na język Twojej karty. Robi to biblioteka NVRTC, której nie ma w samym sterowniku. Wersja z Ubuntu (12.0) jest za stara: miner v4.2.0 kończy się błędem `an asm operand may specify only one constraint letter`. Gdy NVRTC nie ma wcale, miner **wyłącza się po cichu, bez żadnego komunikatu**. Do tego miner najpierw szuka pliku `libnvrtc.so` (bez numeru wersji), a pakiet Ubuntu `nvidia-cuda-dev` instaluje dokładnie taki plik ze starą wersją 12.0 — może więc „przejąć” nowszą. Skrypt omija to wszystko: używa wersji 12.8 (tej samej, której użyli twórcy minera), zakłada własny `libnvrtc.so` i uruchamia miner ze wskazaniem na swój katalog.

## 6. Dwa komputery, jedna fraza (PC z 4090 + laptop)

Wystarczy **jedna** fraza i jeden adres nagród. Najwygodniej utworzyć frazę tutaj (na PC z 4090 — to on zarabia), a laptop dołączyć do tego samego adresu:

1. Na PC z kartą zapisz publiczną część klucza do pliku (nie ma w nim frazy — nim nie da się wydać monet):
   ```bash
   cd ~
   ./quantus-miner.sh rewards > moj-klucz-nagrod.txt
   cat moj-klucz-nagrod.txt
   ```
2. Przenieś plik `moj-klucz-nagrod.txt` na laptopa (pendrive). Na laptopie w oknie Ubuntu `cd ~/projects/quantus-mining && explorer.exe .` otworzy folder w Eksploratorze — przeciągnij do niego plik z pendrive'a.
3. Na laptopie uruchom polecenie z pliku, dopisując `--device cpu`:
   ```bash
   cd ~/projects/quantus-mining
   ./quantus-miner.sh start --device cpu --inner-hash 0xINNER_HASH_Z_PLIKU --rewards-address qzADRES_Z_PLIKU
   ```
4. Dzięki `--rewards-address` nadzorca po starcie porówna adres, na który naprawdę kopie node. Przy literówce w Inner Hash **zatrzyma kopanie** z komunikatem `BŁĄD: node kopałby na adres …, a oczekiwany adres nagród to …`.

Jeśli frazę utworzyłeś najpierw na laptopie — zrób odwrotnie: `rewards` na laptopie, a tutaj `./quantus-miner.sh start --device gpu --inner-hash … --rewards-address …`. Laptop dokłada niewiele (ok. 1,7 MH/s wobec ok. 820 MH/s karty) — to opcja, nie konieczność.

## 7. Co dzieje się dalej i codzienna obsługa

Node synchronizuje łańcuch. W naszym teście 11.09 trwało to niecałe 2 minuty (24 tys. bloków); z czasem będzie dłużej — skrypt mówi „zwykle od kilkunastu minut do kilku godzin”. W logu nadzorcy widać `Czekam, aż node się zsynchronizuje (miner ruszy automatycznie)…`, `Node na mainnecie (genesis OK).` i `Nagrody idą na adres (według node'a): qz…`. Gdy node dogoni sieć, pojawi się `Node zsynchronizowany — uruchamiam minera.` Nadzorca (część skryptu działająca w tle) sam uruchamia ponownie node albo miner, jeśli któryś się wyłączy.

| Co chcesz zrobić | Komenda |
|---|---|
| Sprawdzić stan | `./quantus-miner.sh status` |
| Oglądać logi na żywo (Ctrl+C kończy podgląd, kopanie działa dalej) | `./quantus-miner.sh logs` (albo `logs node`, `logs miner`, `logs supervisor`) |
| Zatrzymać | `./quantus-miner.sh stop` |
| Uruchomić ponownie | `./quantus-miner.sh restart` |
| Uruchomić po zatrzymaniu (bez autostartu także po restarcie komputera) | `./quantus-miner.sh start` |
| Zmienić ustawienie (np. limit mocy) — skrypt sam uruchomi kopanie ponownie | `./quantus-miner.sh start --gpu-power-limit 300` |
| Zmierzyć moc karty | `./quantus-miner.sh benchmark` |
| Trudność i szacowany zarobek | `./quantus-miner.sh difficulty` |
| Klucz nagród dla drugiego komputera | `./quantus-miner.sh rewards` |

(Najpierw `cd ~`, jeśli terminal jest w innym folderze.)

**Co pokazuje `status`, gdy wszystko działa:** `Nadzorca: działa`, `Node: działa`, linię `Łańcuch: blok … / sieć …   peers: …   synchronizacja: zakończona`, `Miner: działa … moc: …` (ok. 800 MH/s; tuż po starcie `n/d (rozgrzewa się)`), link do Twoich nagród i `Wykopane bloki (łańcuch): …`. Kopie naprawdę, gdy naraz: `peers` > 0, blok ≈ sieć (różnica 0–2), `synchronizacja: zakończona` i `Miner: działa`.
Inne komunikaty: `Miner: nie działa (czeka na synchronizację node'a)` — normalne podczas synchronizacji; `(node gotowy — miner ruszy za chwilę)`; `brak połączeń z siecią (peers: 0)` — sprawdź internet; `Miner: nie działa (wyłącza się i jest uruchamiany ponownie …)` — miner się psuje, zobacz `./quantus-miner.sh logs miner` i rozdział 17.

**Benchmark** (test mocy, nic nie kopie). Najpierw zatrzymaj kopanie, bo inaczej wynik będzie zaniżony:

```bash
./quantus-miner.sh stop
./quantus-miner.sh benchmark --duration 60
./quantus-miner.sh start
```

Szukaj linii `Average rate:`. Punkt odniesienia: twórcy minera zmierzyli **816–820 MH/s** na RTX 4090 z limitem 350 W (test dewelopera z PR #100, na wynajętej karcie — nie niezależny i nie gwarantowany).

**Gdzie są pliki:** programy, logi, NVRTC i ustawienia — `~/quantus-miner-kit/`; dane łańcucha — `~/.local/share/quantus-node/chains/mainnet/`.

Bez autostartu (rozdział 8) kopanie **nie ruszy samo** po restarcie komputera — trzeba wpisać `./quantus-miner.sh start`.

## 8. Autostart po włączeniu komputera (systemd)

```bash
cd ~
./quantus-miner.sh install-service
```

Skrypt zatrzyma kopanie w tle, skopiuje się do `~/quantus-miner-kit/bin/quantus-miner.sh`, utworzy usługę `/etc/systemd/system/quantus-miner-kit.service` (poprosi o `sudo`) i ją włączy: `Usługa zainstalowana: kopanie ruszy SAMO po każdym włączeniu komputera.` Od teraz kopanie rusza po każdym włączeniu komputera i podnosi się po awarii. Jeśli ustawiłeś `--gpu-power-limit`, usługa ustawia limit mocy przy każdym starcie; gdy karta odrzuci limit, kopanie i tak ruszy.

- `status`, `logs`, `start` i `stop` działają jak wcześniej (start i stop przez systemd — poproszą o hasło). Logi nadzorcy są nadal w `./quantus-miner.sh logs supervisor`. `systemctl status quantus-miner-kit` pokazuje stan usługi.
- `stop` zatrzymuje tylko do następnego włączenia komputera. Żeby całkiem wyłączyć autostart: `./quantus-miner.sh remove-service`.
- **Zmiana ustawień przy usłudze:** po prostu `./quantus-miner.sh start --opcja` (np. `start --gpu-power-limit 300`). Skrypt zapisze ustawienia, sam odświeży plik usługi i uruchomi ją ponownie („Usługa uruchomiona ponownie z nowymi ustawieniami.”).
- Usługa używa **kopii** skryptu. Po podmianie skryptu na nowszy wpisz `./quantus-miner.sh start` — skrypt sam odświeży kopię i usługę.

## 9. Limit mocy, temperatura, hałas, prąd

- RTX 4090 fabrycznie może brać 450 W. Oficjalny wynik 816–820 MH/s zmierzono przy limicie **350 W**. Na starszym minerze 4.1.x różnica między 300 W a 350 W wynosiła tylko ok. 3% (różne komputery, więc przybliżenie). Przy 450 W nikt nie mierzył — więcej ciepła i hałasu, niewiele więcej zysku (niezweryfikowane).
- **Ze skryptem:** `--gpu-power-limit 350` (albo 300). Wartość jest zapamiętywana i ustawiana przy każdym `start` (a z usługą — przy każdym włączeniu komputera). Skrypt sprawdza, czy mieści się w zakresie Twojej karty (`Limit mocy … W jest poza zakresem tej karty (…)` → podaj wartość z zakresu). Zakres karty pokaże `nvidia-smi -q -d POWER` (Min/Max Power Limit). Usunięcie limitu z ustawień: `./quantus-miner.sh start --gpu-power-limit off` (karta wróci do fabrycznego limitu po restarcie komputera).
- **Ręcznie** (ogólne narzędzie NVIDIA; limit znika po restarcie komputera):

```bash
sudo nvidia-smi -pm 1 && sudo nvidia-smi -pl 350
```

- `nvidia-smi` pokazuje aktualny pobór mocy, limit i temperaturę. Karta pracuje 24 godziny na dobę — zadbaj o przewiew w obudowie. Jeśli jest za gorąco albo za głośno, zejdź do 300 W.
- Gdy karta kopie, praca na tym komputerze (gry, wideo) może się przycinać. Najprościej zatrzymać kopanie na ten czas (`./quantus-miner.sh stop`).
- **Prąd kontra zarobek:** przy 350 W sama karta zużywa ok. 8,4 kWh na dobę (350 W × 24 h), cały komputer ok. 10–11 kWh. Przy ok. 1 zł za kWh (sprawdź swoją stawkę na rachunku) to **ok. 10 zł dziennie, ok. 300 zł miesięcznie**. Zarobek to ok. 0,07 QTC dziennie. Kopanie się opłaca dopiero, gdy 1 QTC jest wart więcej niż ok. **120 zł (licząc samą kartę) – 150 zł (cały komputer)**, czyli ok. 30–40 USD. Oficjalnej ceny QTC nie ma (nieoficjalne OTC 10–50 USD, niezweryfikowane).

## 10. Trudność, zarobek i szczęście

**Co to jest trudność (D)?** To średnia liczba prób (hashy), którą cała sieć musi wykonać, żeby znaleźć jeden blok. Każda pojedyncza próba ma szansę ok. 1 do D. Na starcie sieci D wynosiła 1×10¹¹, a 11.09 w nocy ok. **3,125×10¹⁴** (312 bilionów prób na blok).

**Stan na 11.09.2026 ok. 00:15 UTC** (komenda `difficulty`): trudność ≈ 3,125×10¹⁴; średni czas bloku z ostatnich 300 bloków 13,8 s; moc całej sieci ≈ 22,6 TH/s (22,6 miliona MH/s); nagroda za blok ≈ 0,3065 QTC + opłaty (w praktyce zwykle 0,30 lub 0,31 QTC); ok. 6 200 bloków i ok. 1 900 QTC na dobę (średnia z całej doby bywała wyższa, ok. 2 200, gdy bloki szły co ok. 12 s). Jedna pula (quanpool, adres `qzowWAgbzjc2…`) znajdowała ok. 75–88% wszystkich bloków.

**Jak trudność się zmienia?** Po każdym bloku, według reguły podobnej do dawnego Ethereum („Homestead”): blok szybszy niż 10 s → trudność rośnie o ok. 0,05%; blok 10–20 s → bez zmian; blok 20–30 s → spada o ok. 0,05%, i o kolejne 0,05% za każde następne 10 s (maksymalnie o 4,8% naraz). Gdy przybywa koparek, bloki są szybsze i trudność rośnie. Bloki przychodzą średnio co 12–14 s; przy stałej mocy sieci ta reguła prowadzi do średnio ok. 14 s (wyliczenie badaczy: 14,4 s — to nie jest oficjalna liczba). Nagroda za blok powoli maleje w miarę wydobycia: (21 000 000 − dotychczasowa podaż) / 50 000 000.

**Ile zarobi RTX 4090 (solo)?** Wzór: QTC/dzień = moc (H/s) × 86 400 / D × nagroda. Dla 820 MH/s przy D = 3,125×10¹⁴ wychodzi ok. **0,23 bloku dziennie ≈ 0,07 QTC/dzień**, czyli ok. 2,1 QTC w 30 dni. Zarobek jest **odwrotnie proporcjonalny do trudności**: gdy D się podwoi, zarabiasz połowę.

| Trudność D | 3,125×10¹⁴ (teraz) | 3,35×10¹⁴ | 4,5×10¹⁴ | 6×10¹⁴ |
|---|---|---|---|---|
| RTX 4090, 820 MH/s (nagroda 0,3065) | ok. 0,0695 QTC/dzień | 0,065 | 0,048 | 0,036 |

**Szczęście (losowość).** Bloki trafiają się jak losowanie (rozkład Poissona). Dla jednej karty 4090 solo:

| Okres | Szansa na co najmniej 1 blok |
|---|---|
| 1 dzień | ok. 20% |
| 7 dni | ok. 80% (czyli ok. **20% szansy na zero bloków przez cały tydzień**) |
| 30 dni | ok. 99,9% — średnio ok. 7 bloków (zwykle 4–10) |

Średnio 1 blok co ok. 4,4 dnia; w połowie przypadków pierwszy blok przyjdzie w ciągu ok. 3 dni.

**Sprawdzanie na żywo** (pyta publiczny serwer Quantus, więc liczby są dobre także w trakcie synchronizacji; `--hashrate` to Twoja moc w MH/s):

```bash
./quantus-miner.sh difficulty
./quantus-miner.sh difficulty --hashrate 816
```

Tak wyglądał wynik 11.09.2026 ok. 00:15 UTC:

```text
Trudność (D): 3.125e+14  (= średnio tyle hashy na 1 blok)
Średni czas bloku (ostatnie 300): 13.84 s   → moc sieci ≈ 22.58 TH/s
Nagroda za blok ≈ 0.3065 QTC (+ opłaty)   bloków/dzień ≈ 6243   emisja ≈ 1913 QTC/dzień
Szacunek dla SOLO (wartość oczekiwana; w praktyce bloki trafiają się losowo):
  CPU laptop (~1.7 MH/s, pomiar)      1.7 MH/s   0.000142 QTC/dzień  średnio 1 blok co 2166 dni (ok. 5.9 roku)
  RTX 4090 (~820 MH/s, CUDA)        820.0 MH/s     0.0695 QTC/dzień  średnio 1 blok co 4.4 dni
W puli zarabiasz tyle samo średnio (minus prowizja), ale drobnymi, regularnymi kwotami.
```

## 11. Solo czy pula?

| | **SOLO** (domyślnie) | **PULA** (opcja, nieoficjalna) |
|---|---|---|
| Średni zarobek | ok. 0,07 QTC/dzień | ok. 0,07 QTC/dzień minus prowizja 0,5–1% |
| Jak przychodzi | cały blok ok. 0,31 QTC naraz, średnio co ok. 4,4 dnia | małe kwoty co 10–15 minut, po uzbieraniu minimum |
| Kto trzyma monety | Ty — idą prosto na Twój adres | pula, aż do wypłaty |
| Czy potrzebny node | tak (dysk, synchronizacja) | nie |
| Główne ryzyko | pech (tydzień bez bloku to ok. 20% szans) | pula może nie wypłacić, zmienić warunki albo zniknąć |

Quantus **nie sprawdził żadnej puli**. Admin (Telegram, 09.09): „It is possible for mining pool operators to fail to payout QTC that you mine, or scam you in other clever ways”.

Dwie pule działające z oficjalnym minerem (dane z ich stron, 10.09.2026):

- **NurseryPool** — `162.19.84.16:2255`, odcisk TLS `e21265920ae09417de61b68705e36357f697d17f8eadb2b04ba620019b291ffe`. Prowizja 0,5% (0% do 13.09.2026 12:30 UTC), wypłata od 0,1 QTC, co 10 minut. Bardzo mała (2 bloki od startu według stanu na 10.09), anonimowy operator, 10.09 miała awarię. Strona: https://quan.nurserypool.com
- **quanpool** — `37.187.143.115:9834`, odcisk TLS `87dc37af6096a3ddc860b94368ca087775f3ad3e0c4e9bcff3b07ea08d8abef6`. Prowizja 1%, wypłata od 0,25 QTC, ok. co 15 minut (po 105 potwierdzeniach). Kopie większość bloków sieci — to groźna centralizacja. Admin 10.09: „it would be helpful for miners to shift to other pools”. Strona: https://quanpool.com

Przy 0,07 QTC/dzień minimum wypłaty uzbierasz średnio w ok. 1,4 dnia (NurseryPool) albo ok. 3,6 dnia (quanpool).

**Pula przez skrypt** (node nie jest wtedy potrzebny ani uruchamiany; działające kopanie skrypt sam uruchomi ponownie w nowym trybie):

```bash
./quantus-miner.sh start --mode pool --pool nurserypool --payout-address qzTWOJ_ADRES --worker rtx4090
```

Dla quanpool wpisz `--pool quanpool`. Powrót do solo:

```bash
./quantus-miner.sh start --mode solo
```

- **Adres wypłat** to adres `qz…`, do którego **masz frazę 24 słów na papierze**. Najprościej adres nagród z kreatora (Twój Encrypted Account; pokaże go `./quantus-miner.sh rewards`). Czy pula poprawnie płaci na taki adres, nie sprawdziliśmy na mainnecie (niezweryfikowane). „Account 1” z obecnej aplikacji to adres frazy z testnetu. **Nie** podawaj Inner Hash.
- Oficjalny miner przyjmuje tylko **IP:port**, nie nazwy typu `quan.nurserypool.com` (błąd `invalid socket address syntax`). Odcisk TLS musi mieć dokładnie 64 znaki. IP i odciski mogą się zmienić — sprawdź je na stronie puli (odcisków nie sprawdzaliśmy połączeniem).
- Pule reklamują własne, zamknięte programy (np. quanpool-miner: 5% prowizji, deklarowane 1,1–1,2 GH/s na 4090 — niezweryfikowane). **Nie uruchamiaj ich na komputerze, na którym masz klucze.**

**Zalecenie:** zacznij od **solo** — Twoje monety są od razu Twoje, nie płacisz prowizji i nie wzmacniasz dominującej puli. Jeśli tydzień bez bloku jest dla Ciebie nie do przyjęcia, spróbuj małej puli i najpierw potwierdź pierwszą wypłatę w eksploratorze.

## 12. Jak sprawdzić, że naprawdę kopiesz

1. `./quantus-miner.sh status` — node i miner `działa`, `synchronizacja: zakończona`, peers > 0, moc ok. 800 MH/s.
2. Log nadzorcy (`./quantus-miner.sh logs supervisor`): `Node na mainnecie (genesis OK).`, `Nagrody idą na adres (według node'a): qz…` (musi być Twój), `Node zsynchronizowany — uruchamiam minera.`
3. Log node'a (`./quantus-miner.sh logs node`):
   - `⛏️ Rewards wormhole address: qz…` — musi być równy Twojemu adresowi.
   - `⛏️ Miner server listening on port 9833` — node czeka na koparkę.
   - `⚙️ Syncing …` (synchronizacja trwa) → `💤 Idle (N peers)` (node dogonił sieć).
   - `⛏️ Miner 1 connected (total: 1)` — koparka połączona; `⛏️ Broadcasting job …` — node rozdaje zadania.
   - `🥇 Successfully mined and submitted a new block via external miner …` — **znalazłeś blok!**
4. Log minera (`./quantus-miner.sh logs miner`): `Compiled CUDA mining kernel PTX for compute_89 (device sm_89)…` (CUDA działa), `🌐 Connecting to node at 127.0.0.1:9833`, `⛏️ Received job: id=…`, a od czasu do czasu `🎯 … found solution! Nonce: …` (rozwiązanie znalezione — ale to jeszcze nie pewny blok).
5. **Eksplorator** — tylko to się naprawdę liczy (znaleziony blok może jeszcze zostać osierocony): `https://explorer.quantus.com/accounts/qzTWOJ_ADRES`
6. Telemetria (jeśli jej nie wyłączyłeś): https://telemetry.quantus.com/#list/0xfb5487c0be6ae4ade2d41d16e50465129861636c2b8d61fa94d7a19631626fba — nazwę swojego node'a znajdziesz komendą `grep NODE_NAME ~/quantus-miner-kit/mining.conf`.

Aplikacja mobilna Quantus w wersji na mainnet była 10.09 w recenzji sklepów, a wersja w sklepie wciąż pokazywała testnet. Do czasu aktualizacji sprawdzaj nagrody w eksploratorze. Po aktualizacji nagrody zobaczysz pod **Encrypted Account**. Po pierwszej nagrodzie aplikacja pokaże nowy adres odbioru — to normalne, saldo dalej obejmuje stary.

## 13. Bezpieczeństwo

- **Nowa fraza dla mainnetu (zalecane).** Oficjalne źródła są niespójne: admin Nikolaus napisał 09.09 (01:41 UTC) „do not reuse your testnet keys for mainnet”, a dokumentacja (09.09 wieczorem) i nowsza aplikacja pozwalają zachować stare klucze. Technicznie ta sama fraza daje ten sam adres na obu sieciach. Nowa fraza nic nie kosztuje i chroni Cię, jeśli stara kiedykolwiek „wyciekła” — była wpisana w komendę, wklejona do czatu lub AI, zapisana w pliku albo użyta na cudzym komputerze.
- **Frazę z testnetu zachowaj bezpiecznie.** Zapowiedziano airdrop 10 000 QTC dla górników testnetu (admin 10.09: „Make sure you keep the seed phrase you used to mine”). Portalu jeszcze nie ma; linki pojawią się tylko na oficjalnym kanale ogłoszeń. Kto ma tę frazę, może odebrać airdrop przed Tobą.
- **Aplikacja Quantus — uwaga na stary portfel.** Zanim wpiszesz do aplikacji nową frazę z kopania, zapisz na papierze frazę portfela, który już jest w aplikacji (zwykle z testnetu — potrzebna do airdropu). Utworzenie albo import nowego portfela w aplikacji może usunąć stary.
- **Nigdy nikomu nie podawaj frazy** — ani „supportowi”, ani puli, ani stronie internetowej, ani botowi. Zespół nigdy nie pisze pierwszy i nie dzwoni. Nie ma oficjalnego Discorda. Oficjalne adresy: quantus.com, docs.quantus.com, github.com/Quantus-Network, t.me/quantusnetwork, linktr.ee/quantusnetwork, explorer.quantus.com.
- **Pule są nieoficjalne** i trzymają Twoje monety do wypłaty. Każdą wypłatę (i każdy blok solo) sprawdzaj w eksploratorze https://explorer.quantus.com, a nie na stronie puli.
- Inner Hash i adres nie są sekretami (plik z `rewards` możesz przenosić), ale plik `~/quantus-miner-kit/mining.conf` zachowaj dla siebie. Plik `miner-auth-token` w katalogu łańcucha traktuj jak hasło.
- **Telemetria:** domyślnie node pokazuje się na publicznej mapie (nazwa, wersja, sprzęt, przybliżona lokalizacja). Nie chcesz? Dopisz `--no-telemetry` do `start`.
- **Brak oficjalnej ceny.** Na czacie krążyły nieoficjalne oferty OTC po ok. 10–50 USDT za 1 QTC (niezweryfikowane) — wśród nich znane oszustwa, a rozmowy o OTC zakazano. Giełda SafeTrade wystawiła monetę bez zgody, pod złym symbolem QUAN. Uwaga: skrót „QTC” ma też inna moneta (Qubitcoin).
- **Kopia zapasowa:** do odzyskania nagród wystarczy fraza. Programy, ustawienia i klucz node'a da się odtworzyć.
- **Zapora (firewall).** Node wystawia port dla minera `9833/udp`, a miner port statystyk `9900/tcp` — oba na wszystkich interfejsach sieci. Nie otwieraj ich na świat i nie przekierowuj na routerze. Jedyny port, który wolno otworzyć, to `30333/tcp` (połączenia z siecią); porty 9944 i 9615 są domyślnie dostępne tylko lokalnie. Kopanie działa także bez otwierania czegokolwiek (w naszym teście na laptopie node sam znalazł 6–7 peers). Przykład ogólny dla zapory `ufw` (nie od Quantus, niezweryfikowane). Pierwszą linię wpisz tylko, jeśli łączysz się z tym komputerem przez SSH — wtedy jest obowiązkowa, inaczej odetniesz sobie dostęp; bez serwera SSH pokaże błąd `Could not find a profile matching 'OpenSSH'` i można ją pominąć:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 30333/tcp
sudo ufw deny 9833/udp
sudo ufw deny 9900/tcp
sudo ufw enable
```

## 14. Ręcznie, bez skryptu (dla chcących zrozumieć)

Ta ścieżka nie ma nadzorcy ani autostartu: zamknięcie terminala zatrzymuje kopanie. Do pracy 24/7 używaj skryptu. **Nie uruchamiaj ręcznej wersji równocześnie ze skryptem** (użyją tych samych portów).

**A. Katalog, node i miner.** Każde uruchomienie jest połączone `&&` ze sprawdzeniem sumy SHA-256 — jeśli pojawi się `FAILED`, nic się nie rozpakuje ani nie uruchomi (usuń wtedy plik i pobierz ponownie):

```bash
mkdir -p ~/quantus && cd ~/quantus
curl -fLO https://github.com/Quantus-Network/chain/releases/download/v1.0.1/quantus-node-v1.0.1-x86_64-unknown-linux-gnu.tar.gz
echo '5880937c2a933b97d9916c5c9e78425d9918c6d7b68abe69de43680f62c13c93  quantus-node-v1.0.1-x86_64-unknown-linux-gnu.tar.gz' | sha256sum -c && tar -xzf quantus-node-v1.0.1-x86_64-unknown-linux-gnu.tar.gz && ./quantus-node --version
curl -fL -o quantus-miner https://github.com/Quantus-Network/quantus-miner/releases/download/v4.2.0/quantus-miner-linux-x86_64
echo 'a929e11ee1fd4fe291d743f373041bc280620376f5084620db3b0f82d9a2a276  quantus-miner' | sha256sum -c && chmod +x quantus-miner && ./quantus-miner --version
```

Ma być: `quantus-node 1.0.1-f1176cea6a6` i `miner-cli 4.2.0`.

**B. NVRTC 12.8.** Wariant bez `sudo` (tak robi skrypt; na prawdziwej karcie niezweryfikowane):

```bash
cd ~/quantus
curl -fLO https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-nvrtc-12-8_12.8.93-1_amd64.deb
echo '0b97fd1c36434f55292ca1c069247cd38a8709750820214c3aa45deac168db60  cuda-nvrtc-12-8_12.8.93-1_amd64.deb' | sha256sum -c && mkdir -p ~/quantus/nvrtc && dpkg-deb -x cuda-nvrtc-12-8_12.8.93-1_amd64.deb ~/quantus/nvrtc && ln -sfn libnvrtc.so.12 ~/quantus/nvrtc/usr/local/cuda-12.8/targets/x86_64-linux/lib/libnvrtc.so
export LD_LIBRARY_PATH=$HOME/quantus/nvrtc/usr/local/cuda-12.8/targets/x86_64-linux/lib
```

Wariant z `sudo` (instalacja w systemie; drugi pakiet dokłada plik `libnvrtc.so`). Instalacja ruszy tylko wtedy, gdy obie sumy się zgadzają:

```bash
cd ~/quantus
curl -fLO https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-nvrtc-12-8_12.8.93-1_amd64.deb
curl -fLO https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-nvrtc-dev-12-8_12.8.93-1_amd64.deb
echo '0b97fd1c36434f55292ca1c069247cd38a8709750820214c3aa45deac168db60  cuda-nvrtc-12-8_12.8.93-1_amd64.deb' | sha256sum -c && echo 'cf993245b236e731c5e358dfe394466a17962c3883fb7ebf4be24500d862a35c  cuda-nvrtc-dev-12-8_12.8.93-1_amd64.deb' | sha256sum -c && sudo apt install ./cuda-nvrtc-12-8_12.8.93-1_amd64.deb ./cuda-nvrtc-dev-12-8_12.8.93-1_amd64.deb
export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64
```

Linię `export LD_LIBRARY_PATH=…` trzeba powtórzyć **w każdym nowym terminalu**, w którym uruchamiasz miner. Nie instaluj pakietów `cuda` / `cuda-toolkit` od NVIDIA (dają wersję 13.x, zbyt nową dla sterownika 570/580) ani `nvidia-cuda-toolkit` z Ubuntu (12.0). Sprawdzenie, którą wersję miner załaduje — ma pokazać 12.8, nigdy 12.0:

```bash
python3 - <<'EOF'
import ctypes
for n in ("libnvrtc.so", "libnvrtc.so.12"):
    try: l = ctypes.CDLL(n); break
    except OSError: l = None
if l is None: raise SystemExit("NO libnvrtc -> miner would abort")
a, b = ctypes.c_int(), ctypes.c_int(); l.nvrtcVersion(ctypes.byref(a), ctypes.byref(b)); print(n, "NVRTC %d.%d" % (a.value, b.value))
EOF
```

**C. Test CUDA / benchmark** (nic nie kopie). `--cpu-workers 0` jest ważne — bez tego benchmark doliczy procesor i wynik będzie zafałszowany:

```bash
./quantus-miner benchmark --cuda-gpu --gpu-devices 1 --cpu-workers 0 --duration 30
```

Dobre objawy: `CPU Workers: 0 (…)`, `GPU Devices: 1`, `Compiled CUDA mining kernel PTX for compute_89 (device sm_89)…`, na końcu `Average rate: …M H/s` (odniesienie: 816–820 MH/s przy 350 W). **Zawsze używaj `--cuda-gpu`** — bez niej miner używa silnika Vulkan, ok. 5 razy wolniejszego (4090: ok. 167–178 MH/s zamiast ok. 816–820). **Nigdy nie ustawiaj `MINER_CUDA_GPU=1`** — miner od razu się wyłączy (kod wyjścia 2, `invalid value '1' for '--cuda-gpu'`).

**D. Klucz node'a i Inner Hash:**

```bash
cd ~/quantus
./quantus-node key generate-node-key --file $HOME/quantus/node_key.p2p
chmod 600 $HOME/quantus/node_key.p2p
./quantus-node key quantus --scheme wormhole
```

Ostatnia komenda tworzy **nową** frazę i wypisuje `Secret phrase:` (24 słowa — na papier!), `Address: qz…` i `Inner Hash: 0x…`. Po zapisaniu wpisz `clear`, żeby wyczyścić ekran. Jeśli masz już frazę dla mainnetu, zamiast tego użyj `./quantus-node key quantus --scheme wormhole --words` — program poprosi o słowa i nie pokaże ich na ekranie. Wpisz wszystkie w **jednej linii, bez numerów**, oddzielone spacjami, i jeden Enter (nie wklejaj tekstu w kilku liniach — reszta trafiłaby do powłoki i jej historii). **Nie dodawaj** `--wallet-index` ani `--no-derivation` i nie pomijaj `--scheme wormhole` (bez tego nie dostaniesz Inner Hash). Zanotuj `Address` i `Inner Hash`.

**E. Start node'a** (terminal nr 1 — zostaw go otwartego; Ctrl+C zatrzymuje node). Zamień `MOJA-NAZWA` (litery, cyfry, `_`, `-`; bez kropek; widoczna publicznie w telemetrii — możesz dopisać `--no-telemetry`) i `0xTWOJ_INNER_HASH`:

```bash
cd ~/quantus
./quantus-node \
  --name MOJA-NAZWA \
  --validator \
  --chain mainnet \
  --base-path $HOME/.local/share/quantus-node \
  --node-key-file $HOME/quantus/node_key.p2p \
  --rewards-inner-hash 0xTWOJ_INNER_HASH \
  --miner-listen-port 9833 \
  --max-blocks-per-request 64 \
  --sync full 2>&1 | tee -a $HOME/quantus/node.log
```

`--chain mainnet` jest obowiązkowe (bez niego node wczyta inną sieć). **Nie dodawaj** `--force-authoring` ani `--bootnodes` — to stare komendy z dnia startu sieci. Gdy node długo ma 0 peers, w tej ręcznej ścieżce możesz spróbować innego portu P2P, dopisując `--port 30334` (niezweryfikowane; skrypt tej opcji nie ma).

**F. Synchronizacja** (terminal nr 2). Szukaj `"isSyncing":false` i `"peers"` większego od 0; w drugiej komendzie `currentBlock` musi zrównać się z `highestBlock`; trzecia musi zwrócić `0xfb5487c0be6ae4ade2d41d16e50465129861636c2b8d61fa94d7a19631626fba` (to znaczy: mainnet). Uwaga: przy 0 peers node też pokazuje `"isSyncing":false` — liczy się komplet warunków.

```bash
curl -s -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"system_health","params":[]}' http://127.0.0.1:9944
curl -s -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"system_syncState","params":[]}' http://127.0.0.1:9944
curl -s -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"chain_getBlockHash","params":[0]}' http://127.0.0.1:9944
```

**G. Start minera** — dopiero po pełnej synchronizacji (terminal nr 2). Najpierw sprawdź, czy node utworzył pliki logowania minera:

```bash
ls -l ~/.local/share/quantus-node/chains/mainnet/miner-auth-token ~/.local/share/quantus-node/chains/mainnet/miner-tls-cert-sha256
cd ~/quantus
export LD_LIBRARY_PATH=$HOME/quantus/nvrtc/usr/local/cuda-12.8/targets/x86_64-linux/lib   # przy wariancie sudo: /usr/local/cuda-12.8/lib64
CHAIN_DIR="$HOME/.local/share/quantus-node/chains/mainnet"
./quantus-miner serve \
  --node-addr 127.0.0.1:9833 \
  --auth-token-file "$CHAIN_DIR/miner-auth-token" \
  --tls-cert-sha256-file "$CHAIN_DIR/miner-tls-cert-sha256" \
  --cuda-gpu --gpu-devices 1 --cpu-workers 0
```

Adres to zawsze `127.0.0.1:9833` — słowo `localhost` miner odrzuca. Moc w H/s odczytasz z trzeciego terminala: `curl -s http://127.0.0.1:9900/metrics | grep -E '^miner_(hash_rate|gpu_hash_rate)'`.

**H. Pula ręcznie** (bez node'a; kroki A–C wystarczą). Dla quanpool zmień IP:port na `37.187.143.115:9834` i odcisk na `87dc37af6096a3ddc860b94368ca087775f3ad3e0c4e9bcff3b07ea08d8abef6`:

```bash
cd ~/quantus
export LD_LIBRARY_PATH=$HOME/quantus/nvrtc/usr/local/cuda-12.8/targets/x86_64-linux/lib   # przy wariancie sudo: /usr/local/cuda-12.8/lib64
./quantus-miner serve \
  --node-addr 162.19.84.16:2255 \
  --auth-token qzTWOJ_ADRES.rtx4090 \
  --tls-cert-sha256 e21265920ae09417de61b68705e36357f697d17f8eadb2b04ba620019b291ffe \
  --cuda-gpu --gpu-devices 1 --cpu-workers 0
```

## 15. Nowsze wersje

Sprawdź, jakie wersje są „najnowsze” (11.09.2026 było to `v1.0.1` i `v4.2.0`):

```bash
curl -s https://api.github.com/repos/Quantus-Network/chain/releases/latest | grep '"tag_name"'
curl -s https://api.github.com/repos/Quantus-Network/quantus-miner/releases/latest | grep '"tag_name"'
```

Albo w przeglądarce: https://github.com/Quantus-Network/chain/releases i https://github.com/Quantus-Network/quantus-miner/releases. Dwie oczekujące poprawki node'a (PR #699 i #700) mogą wyjść jako v1.0.2. Skrypt ma wersje i sumy kontrolne **na sztywno** — sam się nie zaktualizuje. Nie pobieraj „na ślepo” innych plików: poczekaj na zaktualizowany skrypt albo przejdź ścieżkę ręczną z sumą ze strony wydania (node publikuje plik `sha256sums-<wersja>-x86_64-unknown-linux-gnu.txt`). Node i miner muszą do siebie pasować: `./quantus-node --help | grep miner-auth-token-file` i `./quantus-miner serve --help | grep auth-token-file` muszą coś wypisać. Ogłoszenia: https://t.me/quantusnetwork

## 16. Pliki

| Ścieżka | Co zawiera |
|---|---|
| `~/quantus-miner.sh` | skrypt (tu go skopiowałeś) |
| `~/quantus-miner-kit/bin/` | programy `quantus-node`, `quantus-miner` (i kopia skryptu dla usługi) |
| `~/quantus-miner-kit/nvrtc/` | biblioteka NVIDIA NVRTC 12.8 |
| `~/quantus-miner-kit/logs/` | `node.log`, `miner.log`, `supervisor.log` (duże logi są automatycznie przycinane) |
| `~/quantus-miner-kit/mining.conf` | ustawienia (chmod 600, nie udostępniaj) |
| `~/.local/share/quantus-node/chains/mainnet/` | dane łańcucha oraz `miner-auth-token` i `miner-tls-cert-sha256` |
| `/etc/systemd/system/quantus-miner-kit.service` | usługa autostartu (tylko po `install-service`) |

Jeśli zmienisz katalog opcją `--dir`, podawaj ją przy **każdym** poleceniu (skrypt jej nie zapamiętuje).

## 17. Problemy i rozwiązania

| Objaw | Przyczyna | Co zrobić |
|---|---|---|
| `Permission denied` przy `./quantus-miner.sh` | plik nie jest oznaczony jako program | `chmod +x quantus-miner.sh` (albo `bash quantus-miner.sh …`) |
| `No such file or directory` przy `./quantus-miner.sh` | terminal jest w innym folderze | `cd ~` (tam skopiowałeś skrypt) |
| `Nie uruchamiaj jako root ani przez sudo` | komenda wpisana z `sudo` | wpisz ją bez `sudo` |
| `Nie widzę karty NVIDIA` | brak sterownika | rozdział 3, restart, `nvidia-smi`; potem `./quantus-miner.sh start --device gpu` |
| Skrypt kopie procesorem (w `status`: `Urządzenie: cpu`) | przy pierwszym uruchomieniu sterownik nie działał | napraw sterownik (rozdział 3), potem `./quantus-miner.sh start --device gpu` — skrypt sam przełączy i uruchomi kopanie ponownie |
| `Sterownik NVIDIA … jest za stary (potrzeba >= 570)` | stary sterownik | `sudo apt install nvidia-driver-580`, restart |
| `Limit mocy … W jest poza zakresem tej karty` | wartość spoza zakresu karty | podaj wartość z zakresu (`nvidia-smi -q -d POWER`) albo `--gpu-power-limit off` |
| `Test CUDA nie przeszedł`; miner znika bez komunikatu (kod 134) | nie znaleziono biblioteki NVRTC lub libcuda | sprawdź `nvidia-smi`; uruchom skrypt ponownie; ręcznie: `export LD_LIBRARY_PATH=…` (rozdz. 14 B) |
| `an asm operand may specify only one constraint letter` | załadowano starą NVRTC 12.0 z Ubuntu | użyj 12.8 (skrypt robi to sam); ewentualnie `sudo apt remove nvidia-cuda-toolkit nvidia-cuda-dev libnvrtc12` |
| `CUDA_ERROR_UNSUPPORTED_PTX_VERSION` | NVRTC nowsza niż sterownik (np. CUDA 13.x) | używaj NVRTC 12.8 i sterownika ≥ 570 |
| Moc ok. 170 MH/s zamiast ok. 800 | brak `--cuda-gpu` (wolny silnik Vulkan) | dodaj `--cuda-gpu` (skrypt dodaje sam) |
| `invalid value '1' for '--cuda-gpu'` | ustawiona zmienna `MINER_CUDA_GPU=1` | `unset MINER_CUDA_GPU`; skrypt sam ją pomija |
| `invalid socket address syntax` | w `--node-addr` jest nazwa albo `localhost` | wpisz IP:port, np. `127.0.0.1:9833` |
| `Miner: nie działa (wyłącza się i jest uruchamiany ponownie …)` | miner się psuje (CUDA po aktualizacji sterownika, zajęty port 9900) | `./quantus-miner.sh logs miner`; port metryk zmienisz: `start --metrics-port 9911` |
| Miner kończy pracę tuż po starcie; `no application protocol` (ścieżka ręczna) | brak plików logowania, zły token/odcisk albo niepasujące wersje | poczekaj na `Miner server listening`; sprawdź pliki (rozdz. 14 G); używaj node v1.0.1 z minerem v4.2.0 |
| Długo `Miner: nie działa (czeka na synchronizację node'a)` | synchronizacja trwa | porównaj `blok X / sieć Y` w `status` (różnica > 2 → czekaj); `./quantus-miner.sh logs node`; peers musi być > 0 |
| `brak połączeń z siecią (peers: 0)` / `Idle (0 peers)` | brak internetu, stary node albo zła sieć | sprawdź internet; node v1.0.1 i `--chain mainnet`; ścieżka ręczna: ewentualnie `--port 30334` (niezweryfikowane) |
| `Verification failed` i 0 peers | wersja node'a nie pasuje do sieci | sprawdź nowe wersje (rozdz. 15) i ogłoszenia |
| `BŁĄD: node kopałby na adres …` (w `logs supervisor`) | Inner Hash nie pasuje do `--rewards-address` | skopiuj Inner Hash z pliku `rewards` jeszcze raz (rozdział 6) |
| `BŁĄD: node odrzuca Inner Hash z ustawień` | wklejony Inner Hash nie jest poprawnym kluczem | jeśli Inner Hash jest z drugiego komputera — skopiuj go jeszcze raz z pliku `rewards` i wpisz `./quantus-miner.sh start --device gpu --inner-hash 0x… --rewards-address qz…` (rozdział 6); w przeciwnym razie `./quantus-miner.sh start --key new` (albo `--key import`) — ustawi nowy klucz i od razu uruchomi kopanie |
| `tylko na ekranie terminala` przy nowej frazie | skrypt uruchomiony z `| tee` / `>` | uruchom zwykle, w terminalu |
| `Using LOCAL mining only` / `--rewards-inner-hash is required` / `NetworkKeyNotFound` (ścieżka ręczna) | brak `--miner-listen-port 9833` / brak Inner Hash / brak klucza node'a | dodaj brakującą opcję; klucz: `key generate-node-key --file` (pełna ścieżka) |
| `GLIBC_2.38 not found` | za stary system (np. Ubuntu 22.04) | Ubuntu 24.04 |
| `Zajęte porty: …` | działa już inny node lub miner (np. ręczny albo oficjalny skrypt) | zatrzymaj go |
| `Zegar komputera różni się o …s od sieci` | zły czas systemowy | `sudo timedatectl set-ntp true` |
| `Mining paused: best block timestamp is …s old` / `no connected peers for 30s` | node jest w tyle albo bez internetu | poczekaj na `Tip is fresh again, resuming mining`; sprawdź internet |
| Aplikacja pokazuje 0 lub „testnet” | wersja w sklepie wciąż na testnecie | sprawdzaj eksplorator; czekaj na aktualizację |
| Adres w aplikacji inny niż adres z kreatora | patrzysz na „Account 1” zamiast „Encrypted Account” albo aplikacja pokazuje już kolejny adres odbioru | nagrody są w Encrypted Account; sprawdzaj adres w eksploratorze |
| Obraz się przycina podczas kopania | karta w 100% zajęta | zatrzymaj kopanie na ten czas albo zmniejsz limit mocy |

**Zmiana klucza nagród:** `./quantus-miner.sh start --key new` (albo `--key import`). Skrypt zapyta, czy zastąpić obecny klucz, i sam uruchomi kopanie ponownie. Nowa fraza to nowy adres; nagrody na starym adresie zostają pod starą frazą.

## 18. Słowniczek

Podstawowe pojęcia (node, miner, synchronizacja, trudność, fraza seed, Inner Hash, pula, systemd) wyjaśnia rozdział 1.

- **Blok** — paczka transakcji dopisywana do łańcucha mniej więcej co 12–14 s. Kto ją „wykopie”, dostaje nagrodę.
- **Blok osierocony (orphan)** — blok, który przegrał wyścig z innym blokiem. Nie daje nagrody.
- **CUDA / NVRTC** — technologia NVIDIA do obliczeń na karcie / biblioteka, która w locie przygotowuje program kopiący dla Twojej karty.
- **Eksplorator** — strona z wglądem w łańcuch (https://explorer.quantus.com).
- **Hash, MH/s, GH/s, TH/s** — pojedyncza próba; miliony / miliardy / biliony prób na sekundę.
- **Mainnet / testnet** — prawdziwa sieć z wartościowymi monetami / sieć testowa (np. Planck), bez wartości.
- **Nadzorca** — część skryptu działająca w tle: uruchamia node i miner, pilnuje ich.
- **Peers** — inne komputery sieci, z którymi połączony jest Twój node.
- **Port** — numerowane „drzwi” w komputerze, przez które program łączy się z siecią.
- **PPLNS** — sposób dzielenia nagród w puli: według Twojego udziału w ostatniej pracy puli (w NurseryPool to ok. 2 godziny).
- **Suma SHA-256** — odcisk pliku; jeśli się zgadza, plik jest dokładnie tym oryginalnym.
- **Telemetria** — publiczna mapa node'ów (nazwa, wersja, sprzęt, przybliżona lokalizacja); wyłączysz ją opcją `--no-telemetry`.
- **Wormhole / Encrypted Account** — rodzaj adresu, na który sieć płaci nagrody za kopanie.

## 19. Źródła

- Node (łańcuch), wydanie v1.0.1: https://github.com/Quantus-Network/chain/releases/tag/v1.0.1
- Miner, wydanie v4.2.0: https://github.com/Quantus-Network/quantus-miner/releases/tag/v4.2.0 (test RTX 4090: PR #100, plik `docs/benchmarks/2026-09-10-vast-pr100.json`)
- Oficjalny przewodnik kopania: https://docs.quantus.com/guides/mining/
- Eksplorator: https://explorer.quantus.com · Telemetria: https://telemetry.quantus.com
- Publiczny serwer RPC mainnetu: https://rpc1-mainnet.quantus.com · indeks bloków: https://sqm.quantus.com/v1/graphql
- Oficjalny Telegram: https://t.me/quantusnetwork · linki: https://linktr.ee/quantusnetwork
- Pakiety NVRTC od NVIDIA: https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/
- Sterowniki NVIDIA w Ubuntu: https://documentation.ubuntu.com/server/how-to/graphics/install-nvidia-drivers/
- Pule (nieoficjalne): https://quan.nurserypool.com/help.html · https://quanpool.com (warunki: https://quanpool.com/api/terms)
