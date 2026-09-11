# qucos-mainet — kopanie Quantus (QTC) na mainnecie

Nieoficjalny zestaw do kopania kryptowaluty **Quantus (QTC)** w sieci głównej (mainnet): jeden skrypt w bashu i dwie szczegółowe instrukcje po polsku — dla **procesora** (także laptop z Windows przez WSL2) i dla karty **NVIDIA RTX 4090** (CUDA).

> Stan na **11.09.2026** · node **v1.0.1** · miner **v4.2.0** · NVRTC **12.8.93** · skrypt **1.0.0**
> Projekt nie jest związany z zespołem Quantus Network. Używasz na własną odpowiedzialność.

## Co robi skrypt `quantus-miner.sh`

- **Pobiera oficjalne programy** Quantus (node i miner z GitHuba, dla GPU dodatkowo bibliotekę NVIDIA NVRTC 12.8) i **sprawdza ich sumy SHA-256** wpisane na stałe w skrypcie. Przy niezgodności przerywa i usuwa pobrany plik.
- **Prowadzi przez utworzenie klucza nagród**:
  - fraza 24 słów pokazuje się tylko na ekranie terminala, z numerami;
  - po przepisaniu na papier skrypt prosi o 3 losowe słowa z kartki, żeby sprawdzić zapis;
  - skrypt nigdzie nie zapisuje frazy.
- **Uruchamia wszystko w tle** pod okiem nadzorcy:
  - najpierw startuje node i sprawdza, że to mainnet (genesis);
  - czeka na pełną synchronizację i dopiero wtedy włącza koparkę;
  - padnięte procesy uruchamia ponownie.
- **Tryb solo** (domyślny, własny node) albo **pula** (NurseryPool, quanpool albo własna — pule są nieoficjalne).
- **Autostart** po włączeniu komputera przez systemd (`install-service`).
- **Dwa komputery, jedna fraza**: polecenie `rewards` wypisuje Inner Hash i adres nagród z gotowym poleceniem dla drugiej maszyny. Nadzorca pilnuje, żeby node kopał dokładnie na ten adres.
- Nie wymaga uprawnień roota: sam prosi o `sudo` tylko przy autostarcie i limicie mocy GPU.

## Od czego zacząć

| Komputer | Instrukcja |
|---|---|
| Laptop/PC z procesorem — Windows + WSL2 albo Ubuntu 24.04 | [INSTRUKCJA-CPU.md](INSTRUKCJA-CPU.md) |
| PC z kartą NVIDIA RTX 4090 — Ubuntu 24.04 | [INSTRUKCJA-GPU-RTX4090.md](INSTRUKCJA-GPU-RTX4090.md) |

### Szybki start

Pobierz repozytorium do folderu, którego używają instrukcje:

```bash
git clone https://github.com/0x477e65/qucos-mainet.git ~/projects/quantus-mining
cd ~/projects/quantus-mining
chmod +x quantus-miner.sh
./quantus-miner.sh help
```

Albo pobierz sam skrypt:

```bash
curl -fLO https://raw.githubusercontent.com/0x477e65/qucos-mainet/main/quantus-miner.sh
chmod +x quantus-miner.sh
```

Potem:

```bash
./quantus-miner.sh start --device cpu     # procesor (np. laptop w WSL2)
./quantus-miner.sh start --device gpu     # karta NVIDIA (np. RTX 4090)
```

Za pierwszym razem skrypt pobierze programy, przeprowadzi przez klucz nagród i uruchomi kopanie w tle. Koparka ruszy sama, gdy node dogoni sieć.

## Wymagania

- **Ubuntu 24.04**, 64-bit (x86_64), zwykłe albo w WSL2. Node v1.0.1 wymaga glibc ≥ 2.38, więc Ubuntu 22.04 jest za stare.
- Minimum 4 GB RAM i co najmniej 20 GB wolnego dysku. Łańcuch zajmował ok. 0,5 GB 11.09.2026, ale rośnie.
- Poprawny zegar systemowy i stałe łącze.
- Dla GPU: sterownik NVIDIA **≥ 570**. Bibliotekę NVRTC 12.8 skrypt pobiera sam, bez `sudo`.
- Zwykłe konto użytkownika. Nie uruchamiaj skryptu przez `sudo`, bo odmówi pracy.

## Najważniejsze polecenia

| Polecenie | Co robi |
|---|---|
| `./quantus-miner.sh start` | pierwsza konfiguracja i start w tle (później: zwykły start) |
| `./quantus-miner.sh status` | stan: synchronizacja, moc (MH/s), wykopane bloki |
| `./quantus-miner.sh logs` | logi na żywo (`logs node`, `logs miner`, `logs supervisor`) |
| `./quantus-miner.sh stop` / `restart` | zatrzymanie / ponowne uruchomienie |
| `./quantus-miner.sh start --cpu-workers 8` | zmiana ustawień — skrypt sam uruchomi kopanie ponownie |
| `./quantus-miner.sh benchmark` | test mocy (nic nie kopie) |
| `./quantus-miner.sh difficulty` | aktualna trudność, moc sieci i szacowany zarobek |
| `./quantus-miner.sh rewards` | Inner Hash i adres nagród + polecenie dla drugiego komputera |
| `./quantus-miner.sh install-service` / `remove-service` | włączenie / wyłączenie autostartu (systemd) |
| `./quantus-miner.sh help` | wszystkie polecenia i opcje |

Tryb puli, np.: `./quantus-miner.sh start --mode pool --pool nurserypool --payout-address qzTWOJ_ADRES`.

## Ile to zarabia — uczciwie

Dane z 11.09.2026 (trudność ≈ 3,1·10¹⁴, nagroda ok. 0,31 QTC za blok, kopanie solo):

| Sprzęt | Moc | Średnio QTC/dzień | Średnio 1 blok co |
|---|---|---|---|
| RTX 4090 (test deweloperów, limit 350 W) | ok. 820 MH/s | ok. 0,07 | ok. 4,4 dnia |
| Laptop Intel Core Ultra 7 255U (zmierzone, 12 wątków) | ok. 1,67 MH/s | ok. 0,00014 | ok. 6 lat |

- Bloki trafiają się losowo. Nawet jedna karta 4090 w ok. 20% tygodni nie znajdzie żadnego.
- Prąd: RTX 4090 z całym komputerem to ok. 10–11 kWh na dobę. Kopanie opłaca się dopiero, gdy 1 QTC jest wart więcej niż ok. 120–150 zł.
- Kopanie procesorem przynosi stratę na prądzie.
- QTC nie ma oficjalnej ceny ani giełdy (stan 11.09.2026).
- Aktualne liczby pokazuje `./quantus-miner.sh difficulty`.

## Bezpieczeństwo

1. **Frazę 24 słów** zapisz tylko na papierze. Nie rób zdjęcia, nie kopiuj jej do schowka, czatu ani chmury. Kto ma frazę, ten ma nagrody.
2. **Frazę z testnetu też zachowaj**, bo zapowiedziano airdrop dla górników testnetu. Zanim wpiszesz nową frazę do aplikacji Quantus, spisz frazę portfela, który już tam jest. Dodanie nowego portfela może usunąć stary.
3. **Oszuści:** zespół Quantus nie pisze pierwszy. Oficjalne źródła: quantus.com, docs.quantus.com, github.com/Quantus-Network, t.me/quantusnetwork, explorer.quantus.com. **Pule są nieoficjalne** i trzymają Twoje monety do wypłaty.
4. Nagrody sprawdzaj w eksploratorze: `https://explorer.quantus.com/accounts/TWOJ_ADRES`.
5. Nie otwieraj na świat portów 9833 (miner), 9900 (metryki) ani 9944 (RPC). Wolno wystawić najwyżej 30333/tcp.

## Co zostało przetestowane

- **141 testów automatycznych** (bats) na atrapach programów, bez sieci i bez prawdziwych kluczy, plus ShellCheck. Wszystko zielone.
- **Test na żywo na mainnecie**, procesor, laptop z WSL2, 11.09.2026:
  - pobranie i weryfikacja SHA-256;
  - synchronizacja 24 tys. bloków w niecałe 2 minuty;
  - koparka uruchomiona automatycznie („Miner 1 connected”), ok. 540 kH/s na 2 wątkach;
  - `status`, `restart` i `stop` bez procesów pozostawionych w tle.
- **Ścieżka GPU (CUDA) sprawdzona tylko na atrapach.** Przy pierwszym uruchomieniu skrypt robi 5-sekundowy test CUDA i jasno mówi, jeśli coś nie działa. Uwagi z prawdziwej karty są mile widziane.

## Testy

```bash
tests/run-tests.sh            # ShellCheck + wszystkie testy bats
tests/run-tests.sh -f pool    # tylko testy z "pool" w nazwie
```

Potrzebne są `shellcheck` albo Docker (do ShellChecka) oraz `git`. Za pierwszym razem skrypt pobierze bats-core do `tests/.bats-core`. Testy działają w piaskownicy: nie łączą się z siecią, nie uruchamiają prawdziwych programów i nie dotykają Twoich plików.

## Aktualizacje

Skrypt ma wersje programów i ich sumy SHA-256 **wpisane na stałe**. Sam się nie zaktualizuje i nie pobierze niesprawdzonej wersji. Gdy Quantus wyda nowego node'a lub minera, potrzebna jest nowa wersja skryptu z nowymi sumami. Do tego czasu możesz użyć ścieżki ręcznej opisanej w instrukcjach. Nowe wydania znajdziesz na https://github.com/Quantus-Network/chain/releases i https://github.com/Quantus-Network/quantus-miner/releases.

## Pliki

| Plik | Co to jest |
|---|---|
| `quantus-miner.sh` | skrypt do kopania |
| `INSTRUKCJA-CPU.md` | instrukcja: procesor, WSL2 i zwykłe Ubuntu |
| `INSTRUKCJA-GPU-RTX4090.md` | instrukcja: karta NVIDIA RTX 4090 |
| `tests/` | testy automatyczne (bats) i `run-tests.sh` |

---

*To nie jest porada finansowa. Kopanie zużywa prąd i sprzęt, a wartość QTC jest nieznana. Projekt nieoficjalny, bez gwarancji.*
