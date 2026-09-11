# Airdrop Quantus z testnetów: wyliczenie nagrody dla dowolnego adresu

- **Stan danych:** 2026-09-11 13:03 UTC. Oficjalne listy górników zespołu Quantus (GitHub) plus indekser Plancka (ostatni blok 2026-09-11 13:03 UTC).
- **Plik jest samowystarczalny.** Ma zasady airdropu, wzór i PEŁNE oficjalne listy górników wszystkich 4 testnetów (sekcja 8), więc do wyliczenia nie trzeba internetu.
- **To SZACUNEK.** Zespół ogłosił zasady, ale nie podał dokładnego wzoru ani kwot na adres. Oficjalnej wyszukiwarki nagród jeszcze nie ma.
- **Etykiety:** OFICJALNE = dane albo słowa zespołu; SZACUNEK = wyliczenie wzorem z ogłoszenia; NIEWIADOMA = nikt tego jeszcze nie wie.

## Jak tego użyć (dla człowieka)

1. Otwórz nową rozmowę z Claude i wklej cały ten plik (albo dodaj go jako załącznik).
2. Dopisz na przykład: „Policz mój airdrop. Moje adresy: qz…, qz…, qz…”. Podaj adresy ze wszystkich testnetów, na których kopałeś, a przy każdym najlepiej też testnet i nazwę maszyny.
3. **Podawaj tylko publiczne adresy `qz…`.** Nigdy nie wklejaj seeda (12 lub 24 słów) ani klucza prywatnego: ani do czatu, ani na żadną stronę.

Adres możesz też znaleźć sam: Ctrl+F w sekcji 8. Kolumna „QTC” to gotowy wynik.

## Instrukcja dla AI (Claude): przeczytaj najpierw

Użytkownik chce oszacować swój airdrop Quantus (QTC) za kopanie na testnetach. Postępuj tak:

1. **Zbierz adresy.** Jeśli ich nie ma, poproś o nie. Potrzebne są tylko publiczne adresy `qz…`. Jeśli użytkownik wklei seed (12/24 słowa) albo klucz prywatny, nie używaj go i nie powtarzaj go. Powiedz mu, że ten klucz trzeba uznać za ujawniony. Nie może go jednak skasować, bo nagroda najpewniej przyjdzie na ten adres (sekcja 2). Niech obserwuje adres na mainnecie i przelewa środki na nowy portfel od razu po wpływie.
2. **Oczyść adresy.** Usuń spacje, cudzysłowy i backticki. Adres Quantus zaczyna się od `qz`; każdy adres na listach ma dokładnie 49 znaków base58. Porównuj dokładnie, bo wielkość liter ma znaczenie. Jeśli adres wygląda na ucięty albo z literówką, powiedz to i poszukaj adresów różniących się 1–2 znakami, ale nie zgaduj po cichu.
3. **Szukaj każdego adresu we WSZYSTKICH czterech tabelach** z sekcji 8 (Resonance, Schrödinger, Dirac, Planck), niezależnie od tego, jaki testnet podał użytkownik. Jeden adres może być na kilku listach: wtedy nagrody się sumują.
4. **Kwoty bierz z kolumny „QTC”.** Są już policzone wzorem z sekcji 3. Nie licz ich od nowa, chyba że użytkownik poprosi o sprawdzenie: wtedy użyj wzoru i stałych z sekcji 3.
5. **Odpowiedz tabelą:** adres (skrócony do pierwszych 8 znaków + „…”) | testnet | bloki | miejsce | top 50% (tak/nie) | QTC. Dla adresu poniżej progu napisz, ilu bloków brakowało. Dla Plancka dodaj wariant „na 09.09” (kolumny po prawej). Pod tabelą podaj sumę QTC i widełki z sekcji 5.
6. **Adresu nie ma w żadnej tabeli?** Znaczy to 0 bloków w oficjalnych snapshotach. Wyjaśnij możliwe przyczyny z sekcji 6: najczęściej to adres z innego testnetu, zwykły adres zamiast wormhole na Plancku, kopanie przez pulę albo bloki wykopane po snapshocie.
7. **Zawsze dodaj zastrzeżenia:** to SZACUNEK, a nie oficjalna kwota. Zespół nie potwierdził, że liczy z tych plików. Sposób odbioru nie jest znany (sekcja 2). Dodaj też checklistę bezpieczeństwa z sekcji 7.
8. **USD** podawaj tylko po cenie, którą poda użytkownik. Oficjalnej ceny nie ma (sekcja 2).
9. **Jeśli masz internet**, możesz sprawdzić, czy zespół nie ogłosił czegoś nowszego. Źródła: kanał ogłoszeń t.me/quantusnetwork (wątek ogłoszeń 2459) i pliki z sekcji 9. Oficjalne kwoty albo nowe pliki mają pierwszeństwo przed tym plikiem; powiedz wtedy użytkownikowi, co się zmieniło.
10. Odpowiadaj po polsku, prosto, bez żargonu.

## 1. Zasady airdropu (OFICJALNE)

Ogłoszenie zespołu, Telegram t.me/quantusnetwork, wątek ogłoszeń 2459, 09.09.2026 04:50 UTC:

> We are awarding testnet miners with an airdrop of 10,000 QTC.
> - 2,500 QTC per testnet.
> - The top 50% of miners by blocks mined on each testnet qualify.
> - Weighted by square root of blocks mined, so small and mid-sized miners don't get crowded out by the top miners.
> - Qualified on more than one testnet? You receive rewards from each.
>
> Snapshot has already been taken.
> THERE IS NO LIVE PORTAL TO CLAIM OR CHECK YOUR REWARDS YET. BEWARE OF SCAMS.
> All future announcements and claim links will be posted in TG announcements channel.
> Admins will never DM you a claim link.

Testnety w airdropie: **Resonance, Schrödinger, Dirac, Planck** (każdy po 2 500 QTC). **Heisenberg się nie liczy.** Nie ma go w ogłoszeniu, a kod node'a v1.0.1 opisuje go jako wewnętrzny testnet zespołu: „Tokens have no monetary value; the network may be reset”.

Tokeny testnetowe (salda na testnetach) **nie przechodzą** na mainnet i nie wpływają na airdrop. Liczą się wyłącznie wykopane bloki. Zespół, 11.09.2026 07:01 UTC: „testnet rewards are based on blocks mined, not testnet tokens acquired”.

## 2. Odbiór nagrody i cena: co wiadomo (stan na 11.09.2026)

- **Adres (OFICJALNE):** „Your accounts and keys stay the same. If you mined on testnet, keep that account. Any testnet-related distribution will go to the same address, so do not delete it.” (ogłoszenie, 11.09.2026 02:26 UTC). Nagroda przyjdzie więc najpewniej na ten sam adres, który kopał, już na mainnecie.
- **Sprzeczne:** aplikacja mobilna 1.6.1 pisze górnikom: „Keep this wallet: you will need it to claim your testnet mining rewards, which are coming soon.” Nie wiadomo, czy nagroda przyjdzie sama, czy trzeba będzie ją odebrać. W obu przypadkach potrzebny jest klucz (seed) do adresu, który kopał.
- **Nie ma portalu, daty ani kwot na adres** (NIEWIADOMA). Zespół zapowiada, że „łatwe sprawdzanie” dopiero zrobi.
- **Linki do odbioru pojawią się tylko w kanale ogłoszeń TG** (wątek 2459 w t.me/quantusnetwork). Admini nigdy nie piszą pierwsi. Fałszywe kanały: t.me/quantusannouncements i t.me/quantustechsupport (proszą o „verify your wallet”).
- **Cena:** oficjalnej ceny nie ma. Jedyny rynek to SafeTrade (para QUAN-USDT), ok. 52 USD za QTC 11.09.2026, ale bardzo płytki i nieuznany przez zespół. „QTC” na SafeTrade, CoinEx i WhatToMine to inna moneta (Qubitcoin).

## 3. Jak liczę (SZACUNEK)

1. Każdy testnet ma swoją pulę: **2 500 QTC**.
2. Listę górników testnetu sortuję malejąco po liczbie wykopanych bloków.
3. **Top 50%** = pierwsze `n ÷ 2` miejsc (zaokrąglone w dół), gdzie `n` to liczba górników na liście.
4. Każdy adres z top 50% dostaje:

   ```
   QTC = 2500 × √(bloki adresu) ÷ S
   S   = suma √(bloki) wszystkich adresów z top 50% tego testnetu (tabela niżej)
   ```

5. Adres poniżej progu dostaje 0. Nagrody z kilku testnetów się sumują. Każdy adres liczy się osobno.

| Testnet | Górników na liście | Top 50% (dostaje nagrodę) | Próg: min. bloków | S = suma √ top 50% | 1 000 bloków daje | Lista z dnia |
|---|---|---|---|---|---|---|
| Resonance | 99 | 49 | 169 | 3 053,332 | 25,89 QTC | 04.11.2025 |
| Schrödinger | 82 | 41 | 634 | 2 483,867 | 31,83 QTC | 04.11.2025 |
| Dirac | 399 | 199 | 290 | 11 439,729 | 6,91 QTC | 15.04.2026 |
| Planck | 205 | 102 | 423 | 7 979,985 | 9,91 QTC | 23.08.2026 |

W żadnej z 4 list nie ma remisu na progu: dokładnie jeden adres ma liczbę bloków równą progowi.

**Przykład:** 1 000 bloków na Diracu → √1000 ≈ 31,623 → 2500 × 31,623 ÷ 11 439,729 ≈ **6,91 QTC**. Pierwiastek sprawia, że 4× więcej bloków daje tylko 2× więcej QTC.

## 4. Skąd są dane

- Listy górników to oficjalne pliki zespołu z GitHuba: `Quantus-Network/task-master`, katalog `testnet_data_snapshots` (https://github.com/Quantus-Network/task-master/tree/main/testnet_data_snapshots). README zespołu: „This folder contains snapshot data from different testnets to figure out rewards”. Wszystkie commity ma Nikolaus Heger z zespołu.
- Arkusz `miners_by_blocks.xlsx` z tego katalogu zgadza się z plikami JSON co do adresu i liczby bloków: Resonance 99/99, Schrödinger 82/82, Dirac 399/399, Planck 205/205.
- Zespół **nie potwierdził**, że airdrop policzy właśnie z tych plików, ani nie podał daty snapshotu (NIEWIADOMA).
- Planck „na 09.09” (sekcje 5 i 8.4) to moje zapytanie do oficjalnego indeksera Plancka (`sub2.quantus.com`, z niego korzysta explorer): bloki każdego górnika do chwili ogłoszenia, 09.09.2026 04:50 UTC.

## 5. Niepewności i widełki

| Co | Wpływ |
|---|---|
| Resonance: top 50% zaokrąglone w górę (99 górników jest nieparzyste) | do nagrody wchodzi miejsce 50 (167 bloków); wszystkie inne kwoty × 0,9958 (−0,42%) |
| Dirac: top 50% zaokrąglone w górę (399 górników jest nieparzyste) | do nagrody wchodzi miejsce 200 (273 bloki); wszystkie inne kwoty × 0,9986 (−0,14%) |
| Planck: top 50% zaokrąglone w górę (205 górników jest nieparzyste) | do nagrody wchodzi miejsce 103 (406 bloków); wszystkie inne kwoty × 0,9975 (−0,25%) |
| Planck liczony na chwilę ogłoszenia (09.09.2026 04:50 UTC), a nie z pliku z 23.08.2026 | 278 górników zamiast 205, próg 131 bloków zamiast 423. Wynik dla każdego adresu jest w kolumnach „09.09” w sekcji 8.4 |
| Schrödinger: lista jest z 04.11.2025, a sieć działała jeszcze kilka dni | bloki z ostatnich dni sieci najpewniej się nie liczą. Zespół może mieć nowszy snapshot (NIEWIADOMA) |
| Podział między wszystkich górników zamiast top 50% | wbrew ogłoszeniu, tylko dla porównania: `2500 × √bloki ÷ suma √ wszystkich` (Resonance 3 284,6, Schrödinger 2 974,5, Dirac 12 722,0, Planck 8 654,1) |
| Zespół może łączyć adresy jednej osoby albo mieć inny, finalny snapshot | NIEWIADOMA |

W wariancie Plancka na 09.09 na progu jest remis: 2 adresy mają po 131 bloków, a miejsc jest 139. Rozstrzygam to alfabetycznie po adresie; zespół może zrobić inaczej.

## 6. Adresu nie ma na liście: dlaczego?

Na listach są wszyscy górnicy, którzy mieli choć 1 blok w snapshocie (także ci poniżej progu). Brak adresu oznacza więc 0 bloków w oficjalnym snapshocie. Najczęstsze przyczyny:

1. **Adres z innego testnetu albo z innego schematu kluczy.** Między testnetami zmieniał się sposób generowania kluczy: ten sam seed dawał INNY adres na Resonance, Schrödingerze, Diracu i Plancku. README zespołu: „addresses between resonance and schrodinger have changed, and will change again”. Szukaj więc adresów, które faktycznie kopały: z logów node'a, notatek, starych plików kluczy i zrzutów ekranu. Nie wyprowadzaj ich z seeda dzisiejszym programem.
2. **Planck: nagrody szły na adres wormhole** („encrypted account”, wyliczony z `--rewards-inner-hash`), a nie na zwykły adres portfela. Na liście Plancka są adresy wormhole. Node wypisywał go przy starcie jako adres nagród („Rewards wormhole address”).
3. **Kopanie przez pulę.** Blok przypisano adresowi, który go znalazł, czyli puli, a nie Tobie. Czy zespół uwzględni górników z pul, nie wiadomo (NIEWIADOMA).
4. **Bloki po snapshocie.** Listy są z dni podanych w sekcji 3. Planck działał dalej: sprawdź kolumny „09.09” i dodatkowe wiersze na końcu sekcji 8.4.
5. **Literówka w adresie.** Porównaj adres znak po znaku.

## 7. Co zrobić teraz (bezpieczeństwo)

- [ ] **Nie kasuj żadnych seedów ani plików kluczy** z testnetów (Resonance, Schrödinger, Dirac, Planck), także tych z adresów poniżej progu. Zespół: „keep that account … do not delete it”.
- [ ] Zachowaj stare wersje programów (node, CLI, aplikacji), którymi robiłeś klucze: dzisiejszy program może z tego samego seeda wyliczyć inny adres.
- [ ] Zapisz przy każdym seedzie, jaki adres `qz…` z niego wyszedł i na jakim testnecie.
- [ ] **Seeda nie wpisuj nigdzie** poza oficjalnym narzędziem zespołu: ani na stronach, ani w portfelach stron trzecich, ani w czacie z AI. Każdy „checker” albo „claim” spoza kanału ogłoszeń TG to oszustwo.
- [ ] Jeśli seed był kiedyś zapisany jawnym tekstem albo komuś pokazany, obserwuj adres na mainnecie i przelej nagrodę na nowy portfel od razu po wpływie.
- [ ] Obserwuj kanał ogłoszeń TG (wątek 2459) i czekaj na oficjalną instrukcję.

## 8. Oficjalne listy górników (pełne dane)

Kolumny: **Miejsce** (ex aequo: 1 + liczba górników z większą liczbą bloków) · **Adres** · **Bloki** · **Top 50%** (✅ tak / ❌ nie) · **QTC** = szacowana nagroda (SZACUNEK, wzór z sekcji 3). Każda tabela sumuje się do 2 500 QTC.

### 8.1 Resonance

Plik `resonance_network_miners.json` z 04.11.2025: 99 górników, 49 w top 50%, próg 169 bloków. Rodzaj adresu: adres ze starego schematu kluczy (Resonance).

| Miejsce | Adres | Bloki | Top 50% | QTC |
|---|---|---|---|---|
| 1 | `qzmu2UxAm4JH9CjMLx3yVnPJGrwbq6iJmKq6ZominTXjmSDEN` | 53704 | ✅ | 189,74 |
| 2 | `qzmc7PZeKBhFPF2eUfcGgSqSLafPCjVXW8qTjMpNu7gQB3iTj` | 31889 | ✅ | 146,21 |
| 3 | `qzoJT7eJRBG44EWRuL8MsZGvXKALkzykkfy7AmYYPbGWWNpe6` | 27659 | ✅ | 136,17 |
| 4 | `qznBscoqfgchvYUUYCY6o8f8HsJWNvU9SC3DKMvoLu438Hrmu` | 27337 | ✅ | 135,38 |
| 5 | `qznrsyqc3HEkGy93HxZttNbBtia1nd9UDy5D8HrgfTTqRRnHv` | 26204 | ✅ | 132,54 |
| 6 | `qzq13T533TiW4esoLg7ZRrsiVeGS9k8pKHERiJTAAuj4uJdvJ` | 23319 | ✅ | 125,03 |
| 7 | `qzmre1UiD9iAzP1fHZq3DyXprfDupoVNFDAJRF6edPDmwjEbR` | 15792 | ✅ | 102,89 |
| 8 | `qzoRp2XbwmtP6cb1khkd8gSzp88XLWQnwUHcghX8PtRALSB5U` | 15159 | ✅ | 100,81 |
| 9 | `qzo84V7Ssq7Z3GS1oLVwQ59cByk6bCGvK15EjWrt85AMNqYNt` | 11863 | ✅ | 89,18 |
| 10 | `qzoye6zPEeJz8mxCar3Q1oiN2xpjFf47jvCVoMjjzuFTw9Dsp` | 10404 | ✅ | 83,52 |
| 11 | `qzoQf4od1mzuTa5AT9R8cbEUxQkyEiqGJyKfq8ZWcK9fTLCmh` | 9408 | ✅ | 79,42 |
| 12 | `qznhpVShWsRqhp4g4KVnD82AGdwQo5EVZp9fqdmUAJBLSyCeW` | 8412 | ✅ | 75,10 |
| 13 | `qzn6C9EKUpuNPm5qbe5jSq7uiCHV7ruixuzNM4DQQQGZxe2du` | 8035 | ✅ | 73,39 |
| 14 | `qzprTjCZMGh9P76yJBKWFv5QeAdJ1buqmMtsmCS3uTXpoopWS` | 6312 | ✅ | 65,05 |
| 15 | `qzo8VqpTojHapSvjwdLqze3GebmfAGS4Nq6rTnRsjR2S8u9mA` | 6296 | ✅ | 64,97 |
| 16 | `qzmNCqKCCLk51kY5dHkuMHrK89pdTLWspnxodoVX3ETMGaXUQ` | 5751 | ✅ | 62,09 |
| 17 | `qzjxCJfheVUxLEZto56T6v4cKT5i4PTqHWYssDE6Sfyy6xwcS` | 4275 | ✅ | 53,53 |
| 18 | `qznJ6gdt21ezvLxdYw3iAUjqHEW1FAWMT3U8PtDtnhgPG21nB` | 4124 | ✅ | 52,58 |
| 19 | `qzpJfFKE5ByDBqjcRgYBieKedPrhivsmH13VRUCrdXtsPLdFK` | 3527 | ✅ | 48,63 |
| 20 | `qzpxE7g7vRq8hGxbD7rESVGGvM5Q7CJypTwzvoEoeDEGB2azL` | 3503 | ✅ | 48,46 |
| 21 | `qzotCmuA9SRD5aqWzYnFAeSE9N8FhhhgnKQG4mu4h66kc1YYm` | 3122 | ✅ | 45,75 |
| 22 | `qzkKG6BoZdXG4MYTVEmjAumrSoja2MZ6gFNm9C9e354wmtEsh` | 1902 | ✅ | 35,71 |
| 23 | `qzngmjcJaBFwWQQEHCZP5VUudKGmSS89tXX5WGHK9cGoTZYhA` | 1574 | ✅ | 32,48 |
| 24 | `qzjcfckdrUxQPjR91qEwYgEzu7rYDcfQTXy8gyddAoPnQqs4g` | 1545 | ✅ | 32,18 |
| 25 | `qzm99pG17NMSEF81Vmbt7dohv4rECY2cuNA6sJYhgQ24V6pGk` | 1399 | ✅ | 30,62 |
| 26 | `qzkiLYEGwcobt6ogFEzi3stiSGy16KUPEwTbRLxL4AWr4oZvN` | 1310 | ✅ | 29,63 |
| 27 | `qzomTLVbRsnPgvBiNvLuTHtgQyhEkeePfVjo2zhhBZUKwbUxb` | 1031 | ✅ | 26,29 |
| 28 | `qzjn7bCMVceeJu3hp6cVwKZEJUoPWa3MMCsP53NL1hkYiwSLh` | 1024 | ✅ | 26,20 |
| 29 | `qzpu6CPrW4Mr6zYaeHj35DPybCr2d5DBN5eeq5e5RJ9KPkJWG` | 932 | ✅ | 25,00 |
| 30 | `qzm8CnymCRcPffm1kANqHEJh957AHh35pZUGziy1so2CF6oPy` | 922 | ✅ | 24,86 |
| 31 | `qzpQzhLXucwBenDb28t8mo6eh2CtFuhJTHw41oVWUwq5TNzp8` | 781 | ✅ | 22,88 |
| 32 | `qzozH5LezSn1XQ9k7Ezci6p4xK9J8GcjjeXPG8DwvFRzqKzaf` | 756 | ✅ | 22,51 |
| 33 | `qzoyznFQSeNY5BGvVfUYjwB2s2QSYEDsQjxTWvNHCCq6x98Mt` | 678 | ✅ | 21,32 |
| 34 | `qzmZjkjgi34cba1892dthL38R3JGn9aVEJsDwnbSSwuEs338v` | 670 | ✅ | 21,19 |
| 35 | `qznJvq82Ggw3WrF9jMvc7FJoefUGgYuf6isztg9o6dZSFHd6Y` | 631 | ✅ | 20,57 |
| 36 | `qzpVVgF1MDnTpK1h1QrcwKD4raFrVuC3GKApKqkr5TWQFBVaW` | 621 | ✅ | 20,40 |
| 37 | `qzqCwUhocvzFG2jPFGvnAve5o5CHmsRfTaxszuxqvyhapQrCE` | 570 | ✅ | 19,55 |
| 38 | `qznd1YWbgQrviV76psu5n8d24mHSuHtAc9JmJLB42gTELksvQ` | 511 | ✅ | 18,51 |
| 39 | `qzmjyKbuq7vzwSAu23BhSwTzLe3DDfjWK56Q4EfnFmeuV6rw2` | 426 | ✅ | 16,90 |
| 40 | `qzmzbkwmcPzNnGrTxUdWw2wqKK6AwEdwTfeEXbsLd64NApyDR` | 424 | ✅ | 16,86 |
| 41 | `qzokF78eWPn8WbzmkMpWRYr9ZYxtsDKvLtxQMyDrjcqjjMqng` | 386 | ✅ | 16,09 |
| 42 | `qzkM2uGCcpMBu9WsFRbTJWAv2RoJr1BNoUEzNauhFTQD57iYg` | 378 | ✅ | 15,92 |
| 43 | `qznxQ9gQ7ryCusigg8ymTo6PW6SM99NF9zZVhCXEabgWCb5ze` | 360 | ✅ | 15,54 |
| 44 | `qzoAS8uWhKUMbJG7mJfwBScAXhkG8SUpcBGE4nRP634w6d5cY` | 332 | ✅ | 14,92 |
| 44 | `qzp84JYcwf5vhAK6nKAQ1AEqXAb71i1qm7QYBLd4xzwuaoKkN` | 332 | ✅ | 14,92 |
| 46 | `qzmb7zkTNRg3koUdcAuJxaUREm7T6dQwxm6oBqX2kZjPzfLsE` | 276 | ✅ | 13,60 |
| 47 | `qzmiN6K6FoYzuroPKzfr8bLTbZBpHfmnsGm3EXNEAdPD57qon` | 230 | ✅ | 12,42 |
| 48 | `qzmYASZdMiitqjY4DzeaTg4pKh4GCg63VF7oUthGMEEq1BejD` | 209 | ✅ | 11,84 |
| 49 | `qzmHLozQpHFMxuqv7wJFvzres4LfNSJQ6xKU3vRFAttFw7EkY` | 169 | ✅ | 10,64 |
| 50 | `qzjxpUHFK2uS9VMwQduyAVMAduWQviJ2ACbeLHKc8yhQFZYTD` | 167 | ❌ | 0,00 |
| 51 | `qzjYjaTQZSz41QYRyf58LtR1RSqktkwwQdvDbb5d2kDG7HNMv` | 153 | ❌ | 0,00 |
| 52 | `qzn4BajdypPBSoGYCKJvMV1w8ggUgQvhekay1hkiTpiYWjtD1` | 132 | ❌ | 0,00 |
| 53 | `qzqAEqE34ZYg7sC5b7Y5kKaRkcYhYDSGfgBtBjTJeizuy3wBH` | 106 | ❌ | 0,00 |
| 54 | `qzmZkaiQKnfSAPkn8dekCFWisHtCCuZTYWaZmUD87t126ehLW` | 97 | ❌ | 0,00 |
| 55 | `qzjfz14hQTAcv4ErDgKuhYbUdXGqvN5gYCARwvA5hKQzM4nJZ` | 95 | ❌ | 0,00 |
| 56 | `qzmB2SKjunKRcQzYzecf4xbFjRHWpc6euWBj6qVCqMi1quEPm` | 80 | ❌ | 0,00 |
| 57 | `qzkgaH2uFc9n1ZMHGZ2NxELBeJxp62tktsnX2s6LDZxjtSiSC` | 75 | ❌ | 0,00 |
| 58 | `qzpsMcVZLViR2Zr3RywU6wPPQrz5CU2R92buHNatuaqyMRran` | 65 | ❌ | 0,00 |
| 59 | `qzpkgwF83WrNb2rM7WXUTG6V5SZLGUzN4QLVXi2dDcuuBsxYU` | 61 | ❌ | 0,00 |
| 60 | `qzmRxHJSv5v8U9AjhcKQw6snjmLY2ZaJ5Bxr72iYYXWi1xT9e` | 51 | ❌ | 0,00 |
| 61 | `qzjvS5v1YYZ18f3SfeMrjMBUJgRTn48fzcLdPst94J4Q2J7hz` | 49 | ❌ | 0,00 |
| 62 | `qzjWn2JcqBs4ttYWrtmZFS4jpkXgfa876TRrA1uscyU6YeLwT` | 46 | ❌ | 0,00 |
| 63 | `qzmimGidKhhszaVeVhnNufcKQQU1QTieya1AzL8xSMHNAY7G4` | 38 | ❌ | 0,00 |
| 64 | `qzmrdGsRW6WpEr8iHgdhxcYo7FvPrU9mH9WJf8qZ2VUZHDYHJ` | 37 | ❌ | 0,00 |
| 65 | `qzka5PoygCZ6U8XH71hnGi3sUeqZya3BvJUALbAT3zSKoykiz` | 32 | ❌ | 0,00 |
| 65 | `qzniXds4ZVN66LfKrrqQmrNLe2S8UraqiwiF1F5x7CykpeLFy` | 32 | ❌ | 0,00 |
| 65 | `qzo7xakq5DVCNdUTudPgAR71W1onYSjQuStoNJnKev6FwxT1L` | 32 | ❌ | 0,00 |
| 68 | `qznhaQE7tJZtrMhAKWXbzrRnskfakNBNYgVoMVYc8mNkHCSMk` | 28 | ❌ | 0,00 |
| 69 | `qzpAK583igoJbAFGjVKMF2GW8piywbkQDSDYXbZ2mnmjj1WPs` | 21 | ❌ | 0,00 |
| 70 | `qzkZytUkY41CCJ38epkZ8ekAvbqrqibLTWxWy7FHAMvJTB9Ei` | 19 | ❌ | 0,00 |
| 70 | `qzn6iLjTGrSwHsafAK7pRdcLnz3FR9nivW6sz2D9BscxMnpok` | 19 | ❌ | 0,00 |
| 72 | `qzoBUt2hhkYTv4q5kwWApstheRqrDxfuzZpgte9W6L4h4GpmL` | 16 | ❌ | 0,00 |
| 73 | `qznQ7MPYioe2ohtPN6EWpKa89UAt8bZ8SHwjyAMe51SCXZK4n` | 12 | ❌ | 0,00 |
| 73 | `qzoz5SYKo5BJbeQSNqWHEiNJ23XTs5qNqxVyC8Ua4tx56F7Rn` | 12 | ❌ | 0,00 |
| 75 | `qzoXUT2nF4kRShWquywxay57SQwMr9n78aUn2j8Eg1NeW3rDe` | 11 | ❌ | 0,00 |
| 76 | `qzmqfu2zk1ef6GeFnS8aNHvYuFhi62YXXt86nunYNxj433pv1` | 10 | ❌ | 0,00 |
| 77 | `qznwx81CwCNomZy8jC8M95kfEtxCv9oosUhmD2BbyLKMCspN5` | 9 | ❌ | 0,00 |
| 77 | `qzo6KH3v6tujBYcmZ39PfEzA8Q2qX1j9r4u5b5L7yse7k7pJs` | 9 | ❌ | 0,00 |
| 79 | `qzmBAHgFaqHMCrSEPtJg7PcnvAjjyZmcCzPfTuQJqTKSsgETp` | 8 | ❌ | 0,00 |
| 80 | `qzk4s4DdWzQMjaYg2p1cAtjPJxQQW1cWKFXjo1rae4xWR2pfd` | 7 | ❌ | 0,00 |
| 80 | `qzng3GPNkC9aq7qQhBKNEAnjdtq6QWQDVpRmXvbkU6eRyhT3Z` | 7 | ❌ | 0,00 |
| 82 | `qzjh6EaaA3PEQZF6HRmLrxQRDA4FDJweP5wYEYTQjWx7rWN5v` | 5 | ❌ | 0,00 |
| 82 | `qzjjifC2KMrYMFVjUoAwjvURRNoudZFMD9XCbfRvGeyK5dDiH` | 5 | ❌ | 0,00 |
| 82 | `qzmBB9bheoaW5AkruaEhVSPRAgxnu9Wfq4FwFGnJnTLHt9a7b` | 5 | ❌ | 0,00 |
| 82 | `qzo7wGwtVYVeZ9LEgiA94gH3JbWfgr1ZqDQdEuoR9iN9k3vm7` | 5 | ❌ | 0,00 |
| 82 | `qzp5d9h4Cjv6kBFQ5HXnHXVqSCVceMpXkp1E1qvRayo344Yi4` | 5 | ❌ | 0,00 |
| 82 | `qzpzyGesbhY7G5n1pXq1mhSc1qs5K23oBLzHST4U85zPw9P7N` | 5 | ❌ | 0,00 |
| 88 | `qzm21sP93FbrYCtTp1LrQDfs6quxBebPg495AZKa1ZRRfnszh` | 4 | ❌ | 0,00 |
| 88 | `qznKMfamaZcnqumUWYyRaNSCWkryPk1GMC5NtTrzwqwAwa7cZ` | 4 | ❌ | 0,00 |
| 90 | `qzmrw5DXoBE6LBvXGRRTdAHobGBTXGjitLw6wCXEuQE8a3fgi` | 3 | ❌ | 0,00 |
| 90 | `qzoEVkv7YwtA1FfqgTVi3shAeXwF4bCZm6jxYMkvjjDjhsG2y` | 3 | ❌ | 0,00 |
| 90 | `qzpAb6dsFo2UXREMEvFL3ZLFmi5WoeJEq28m3HDVwsfBrzviR` | 3 | ❌ | 0,00 |
| 93 | `qzm84pWDU2AtnVTHpVDC7mD2qTRxC3Q1zYuYDEEHTyW1sjjSF` | 2 | ❌ | 0,00 |
| 93 | `qzpj4w2G2jmVGTb5UuiZ6TVvJtaQpJsbQ14o4AEUHt6vjJrQo` | 2 | ❌ | 0,00 |
| 93 | `qzq3VLu6DHcWDtWRAqWXtTkDMPqz4BdJNvy3e7SYaqhZX49PQ` | 2 | ❌ | 0,00 |
| 96 | `qzjWXQK7tV1zVxW3XaKNsK5HdJUteLXZuGC2o3i2X3kVJ2zqJ` | 1 | ❌ | 0,00 |
| 96 | `qzmGYbF9Qm3yykU1MR3nXQDyhHaS8SnXwk8Fd2y8UkM2aWTbG` | 1 | ❌ | 0,00 |
| 96 | `qzpXEJTTtSvWMqKVLhfwVXW9qkXEftZBdzz92hf5QnxVvtqV1` | 1 | ❌ | 0,00 |
| 96 | `qzpjuAv3XbYjiW8Lw6RjxCFwkZzypr5TaMLvkQfuNVEigTAns` | 1 | ❌ | 0,00 |
| | **Razem** | 328067 | 49 | **2 500,00** |

### 8.2 Schrödinger

Plik `schrodinger_miners.json` z 04.11.2025: 82 górników, 41 w top 50%, próg 634 bloki. Rodzaj adresu: adres ze starego schematu kluczy (Schrödinger).

| Miejsce | Adres | Bloki | Top 50% | QTC |
|---|---|---|---|---|
| 1 | `qzpShigRwEfoqWefYkCxCyHyyNMFV2rZtq7zgLQoN5JbwbWhE` | 32585 | ✅ | 181,69 |
| 2 | `qzn1a6f3ttc3NzkXLgKUJ1DD1GmVQ7W7C4bpjLaqDG8cVG3Jb` | 23273 | ✅ | 153,55 |
| 3 | `qzot2brxs5s468XbYh9D3NoYxpmnp8xkmWzibsqBPrFmqC6FJ` | 21309 | ✅ | 146,92 |
| 4 | `qzjuqy6MyJRV9fW87fb34VYXYhyEMqyaEtiWNnf3g9yoZdfmP` | 18043 | ✅ | 135,20 |
| 5 | `qznFyQNkVEqWM13sEq9E4qjT75s6Rfazi9Jq1pNaPpciJvyde` | 17291 | ✅ | 132,35 |
| 6 | `qznbFq2GaFvRC45d67FcU2e86SRu32ks6bqBfo4ofwjJUNR2d` | 14616 | ✅ | 121,68 |
| 7 | `qzoCszTr12UqAQUPmJU4UuVf98cpkWKEbiDdpZTG3WyYr73JS` | 11507 | ✅ | 107,97 |
| 8 | `qzmRRr2ZYMRJhP4BJtR5LeGt4atYGUjdq6pJ2YdwjLboTmhFn` | 6929 | ✅ | 83,78 |
| 9 | `qzjfz5bEM1ty3LcXoh1SfHgPWHbpx1n7SZ6ykEDd4e9wfw7XK` | 5621 | ✅ | 75,46 |
| 10 | `qznJ4dHSXqWw112iqxU3F8ZLV7kvTB7myut9r2DKnYfnrggEA` | 5266 | ✅ | 73,04 |
| 11 | `qzpffwT52TxEg2G8hmZ4NcJ1vjw788kyXX329VJzSSNuREkVU` | 4984 | ✅ | 71,06 |
| 12 | `qzp3cP18hQatXezUdyfgzL8JrogmJZzd8zi3HufzCXfXZe8a1` | 3782 | ✅ | 61,90 |
| 13 | `qzq6AsTmxoaTANy3mETvEKDHhFGjxLN9SPgi2rmcxttQfJenn` | 3554 | ✅ | 60,00 |
| 14 | `qzoqBe31EaycT5bp7V9nx686Fr255GvP2xa8XWjDRANFFsmeX` | 3496 | ✅ | 59,51 |
| 15 | `qzjgWhh2jhRFgD8fQnxp9HJXE34dx5XbPCXFUs6VnXFu8xHBj` | 3337 | ✅ | 58,14 |
| 16 | `qzn2fVfnQsb5TX1uQhfK1c1d6E6bR3BoHuynXADGi6KeGCkiM` | 2758 | ✅ | 52,86 |
| 17 | `qzocKmN2SvGyw1pmCwtnTSncfBkevxFfghqPsn9k6gzzQtVCV` | 2527 | ✅ | 50,60 |
| 18 | `qzn2CBXmMorWepWR6DVtpjXE1KwH21nuuoyHUExJEBptQ3k5A` | 2407 | ✅ | 49,38 |
| 19 | `qzpLQViE39bzEfnhuYdx5zUvgY4RJEmcdzTTrVmaovNQA9KrX` | 2296 | ✅ | 48,23 |
| 20 | `qzoAgZv6Qa9LK6sRA2FL6gdRdgcnkSW1MjFq4sUrmQssmrCvn` | 2045 | ✅ | 45,52 |
| 21 | `qzotCmuA9SRD5aqWzYnFAeSE9N8FhhhgnKQG4mu4h66kc1YYm` | 1780 | ✅ | 42,46 |
| 22 | `qzpgbvDxercT56sd9UyBwiGwEqH2igJniJGC8Y9J3K9kBkta9` | 1726 | ✅ | 41,81 |
| 23 | `qzkDSKxYbjpY51FjEkAFMbzpsm8THhnCXLubiKTdx3RfNYcGW` | 1647 | ✅ | 40,85 |
| 24 | `qzovQrRgRg29FYyh6aCjK1cHgjxiSQMwED6RjyLcHXnoHC45E` | 1637 | ✅ | 40,72 |
| 25 | `qzp9MgRYKtW3FEioPbmYb7D4D44R2AdqjQcU5kCCBGyREFfKw` | 1623 | ✅ | 40,55 |
| 26 | `qzjTMPKfiHxHepHUJgHpxxS61fULxTypp6ZruAMrd4jMVhugC` | 1617 | ✅ | 40,47 |
| 27 | `qzpp6Qze6kmfVHTECrcF3uBsdd6yKrTyf9fUe2xKUCxYYngdB` | 1611 | ✅ | 40,40 |
| 28 | `qznkYEdGrwLHWtyPFxSFjgzSBCSDiEwWYA4viEf59u1EcAKyc` | 1568 | ✅ | 39,86 |
| 29 | `qzkr2yeiTZsfbtwMaAx3wyPZtDhLo6TtZhGETynbsMQTP38VY` | 1522 | ✅ | 39,27 |
| 30 | `qzmbGP4bHDVZtPj5v6kYE9EJBxtZZ62edFz7bQKw7ZESxzaqp` | 1267 | ✅ | 35,83 |
| 31 | `qzjbKNCuikFtMYzGzQVcqWdMXtKAD5GmqWLkbSHRngVuddWrG` | 1250 | ✅ | 35,58 |
| 32 | `qzkwZ47Eusy8QsjnetvNXtJoPs8TtviP8Lceg2vErvLacHxQh` | 1209 | ✅ | 35,00 |
| 33 | `qzopaRR8MTRyQHh591rhEPZFZ39Ho6x8CZFji4YfKb6nq3C4i` | 998 | ✅ | 31,80 |
| 34 | `qzpQiSa39BUXmtnwNQYnaRCbx9L11yxXo1vhSZBYDQqmJGDVb` | 989 | ✅ | 31,65 |
| 35 | `qzkS7pAjzsqRW4qmq69PnGMHG89wZoEv5xPv9MxM2CfZCNZRi` | 982 | ✅ | 31,54 |
| 36 | `qzkpRnJwhowJ5dgBeNouESyaybQzcj5fRCBKwX2UP4CqbW7zU` | 976 | ✅ | 31,44 |
| 37 | `qzpqieMvB9uhiNJErsuyZbMozHUEbDBeCuZyQ3sVo8VRVZTvd` | 775 | ✅ | 28,02 |
| 38 | `qzp9qKHA33rLTfE17qSRkZiknDZy6ZJvhGSBHymkcZoGBigq1` | 697 | ✅ | 26,57 |
| 39 | `qzpb4YQqPLRL4Lg9VZWTnbcpBmyhxmqY1MmPSDjpwufkU4wJ6` | 692 | ✅ | 26,48 |
| 40 | `qznpFToYGPVuL7a1eKfuzT1zNa5Df7tXspjT4wrv4HzGb8HKb` | 644 | ✅ | 25,54 |
| 41 | `qzpdk2cFzawAFUd2xsRFDc4f9NPy6r5G7awWgniN1AiQxbAxA` | 634 | ✅ | 25,34 |
| 42 | `qzjXqoS5PAiJc1etGy2J257ncAJkELKW2oLTAUdiJn9VGUgyc` | 595 | ❌ | 0,00 |
| 43 | `qzn2WjBfpWW27vNjQLd759CeGZxLBHdypKHttFJEzB1n81DNG` | 594 | ❌ | 0,00 |
| 44 | `qzokWJfFjAqmaq8dENsP3esBLK64v9yhL5dHJ5AJqQhjq4ruP` | 564 | ❌ | 0,00 |
| 45 | `qzkQMv73GWFfLTus1QofEkbBHrh58e4TJihoEFL1HKvRLKsRy` | 484 | ❌ | 0,00 |
| 46 | `qzpTSJyj6Agt7Pui1L6RyxgLn2NqNw3ZqLYAP7u8nfUrgRnVM` | 316 | ❌ | 0,00 |
| 47 | `qzpoTFEvSgUwYpR3ePQz5K4rDwmTE46XoCDd1xefSfakZhMYd` | 313 | ❌ | 0,00 |
| 48 | `qzkXtGpBppBbjcJHWTfBj1uHLrBzWAo7PpbhC5j5pm483dWpb` | 310 | ❌ | 0,00 |
| 49 | `qzp5BiKYQTjeNudCT35NiJGDkB955yq7cSA4BRdivvYLB7r2m` | 306 | ❌ | 0,00 |
| 50 | `qznStFEBvfuwmVqJwLgEcDVfWg4rqGzmUampuGtvDSUfFAG7e` | 272 | ❌ | 0,00 |
| 51 | `qzopwzx6CtgsmdqBj8w3LMsTAjtWfBdSd1RoiSDrcQ35Weor2` | 236 | ❌ | 0,00 |
| 52 | `qzkhZnQmk1hBwfo3cb61amw294Vy3G5uK6BubpgVgfKALmb2P` | 230 | ❌ | 0,00 |
| 53 | `qzk8taXT3PPJJp87M4PbrMJa8vQG53QqShrFiJuiriJRgcwC3` | 224 | ❌ | 0,00 |
| 54 | `qzpg4T1Y37paXvNCYbvTsEEkkbnyX5KCujFfXo8hbgYT9arP7` | 222 | ❌ | 0,00 |
| 55 | `qzpnWUo1sYJsFV8tUjDAQ3und34XWAEVsgHnEvCXT9ZaQrpZu` | 216 | ❌ | 0,00 |
| 56 | `qzojGPxE7TPsyJztr5iQUA42CD6VrC3uyusj9K9xbH19br15z` | 211 | ❌ | 0,00 |
| 57 | `qzn57cH4DSFgeny98Mwgvt6N2oyniAbEA6nwG5XZj3nPh7rTc` | 166 | ❌ | 0,00 |
| 58 | `qzk1d27R76qRMJk4tHQHqaAsgww52MQapV7qXHMHTGJ8MJ5wy` | 164 | ❌ | 0,00 |
| 59 | `qzmaFUXhmE43YGCAZKLbC885GXmsVnbpRxT1174emvW4ujsha` | 149 | ❌ | 0,00 |
| 60 | `qzoDtmBWVbdyuMJp8ejuR855r5V6CokcfG1TmemAzsyEeZvnP` | 142 | ❌ | 0,00 |
| 61 | `qzpCkSFyjAXdHdRAUbRoPHKeFiG9srSewsceic1KwiBaQQZ9p` | 141 | ❌ | 0,00 |
| 62 | `qznvJC3UaskjTDgb5PxxofDaYmYVJA661tDwuAPQiFGNg1KPw` | 131 | ❌ | 0,00 |
| 63 | `qzmg1qhH59h5CgCT9JHDbJbDt7XSVoY9kdgkHYJrsYxxjkArk` | 127 | ❌ | 0,00 |
| 63 | `qzpwjY2CW8HSHW2bD2bnoCFTg3Ce1vfNE8SZBnauSD2zVr1jn` | 127 | ❌ | 0,00 |
| 65 | `qzjmpXSbCoUBcuEDaEK79tDcB44jghY2NZQTAgSmgEpUWvYzH` | 124 | ❌ | 0,00 |
| 66 | `qzkz8Hs7HoaB5qM2bCjrU17AR9SVn27wAZsAd5dpC3gWy1djx` | 115 | ❌ | 0,00 |
| 66 | `qzozTFK9guP1EUCkYnJCS2C4XHJHSrEVY4WxpoBUTKHBGpzEF` | 115 | ❌ | 0,00 |
| 68 | `qznMAKy1imKixFjJrLYgPAHUqEGzmuwSTDmaVRpnF2usvEwQv` | 111 | ❌ | 0,00 |
| 69 | `qzkgUmAJ2nJYvinnLhyXWsSzDC1yhmzm9sGoQduNdnXhVvvB5` | 110 | ❌ | 0,00 |
| 70 | `qzoSPiicYPizQYKvEJ37Gn2FajWFH1yoMTzccCZVvod1c8isv` | 107 | ❌ | 0,00 |
| 71 | `qzpj3m5o4AseZA9QY5XmNqcuDpUfgkVrETQWs9P93bhQ5zsnS` | 104 | ❌ | 0,00 |
| 72 | `qzjx4SHvfvHvC1CL2om1HFm5f7kFweRKpGCaEcWw4Px4phaSE` | 82 | ❌ | 0,00 |
| 73 | `qzmr82yTMQTcVbUtJj9fEfFUi3oCVsBjXc8tuThDV1DdFKaXw` | 64 | ❌ | 0,00 |
| 74 | `qznx4px2UTMrKYfg1BHAE6Y9jgh4nuujz7mLMA4V9FzKViZ19` | 40 | ❌ | 0,00 |
| 75 | `qzoSiFZtJSBu55p4kFZNsyAntA5o8QZgi8xyZUFmdws9Nhd7t` | 33 | ❌ | 0,00 |
| 76 | `qzpL6PmovJaHb6h6vbpQawEjf18o1X6gMVCqMZkBzALgyQvue` | 24 | ❌ | 0,00 |
| 77 | `qznd1YWbgQrviV76psu5n8d24mHSuHtAc9JmJLB42gTELksvQ` | 13 | ❌ | 0,00 |
| 78 | `qzq5Ui4a7zSeFhNTmixuYBkUDC8oRQAN12fysXXK92LTzksHF` | 11 | ❌ | 0,00 |
| 79 | `qzmkhojzgAyXu28fRGCwNvZExbYTTrGAUAsjPYAKaasjQGs9S` | 8 | ❌ | 0,00 |
| 80 | `qzpBGycREoVSFyopdsH6n2XAaVyKvZTBkSf3c9AGnJhwQ5YUb` | 6 | ❌ | 0,00 |
| 81 | `qzoAovtRCni4t3PwgnjmiBm5hfYEui5jQ5cxWBVB2xnBLiHbt` | 4 | ❌ | 0,00 |
| 82 | `qzp7coYcyvNNrt7BiqhyD61ubcxoHBKtsC688zz7Hmotuetuw` | 2 | ❌ | 0,00 |
| | **Razem** | 220783 | 41 | **2 500,00** |

### 8.3 Dirac

Plik `dirac_miners.json` z 15.04.2026: 399 górników, 199 w top 50%, próg 290 bloków. Rodzaj adresu: zwykłe konto (Dirac).

| Miejsce | Adres | Bloki | Top 50% | QTC |
|---|---|---|---|---|
| 1 | `qzmssQyhfreQ7t41spcPP2vv1XBUsC1A4915ogJW4bXfCvx4D` | 89778 | ✅ | 65,48 |
| 2 | `qzjfAe19wbQStkPuCZxiST4dy5ghtXBNgyNiBRu7N9RdEpZuA` | 75806 | ✅ | 60,17 |
| 3 | `qzngDmhUrTbdCUUMyzoWFTVer4dVEqxEGJbMwDzgq1vtFDnYu` | 47456 | ✅ | 47,61 |
| 4 | `qzkVESSdXeQ8Jb6wYC7CtCj5hQqPqzFgUjgvDjc9E1gQ7LHoK` | 41450 | ✅ | 44,49 |
| 5 | `qzpsKarxVcw79pH1zKpRHeX2tiBZdqpJxbFBiDuo3ocRvd5MT` | 40121 | ✅ | 43,77 |
| 6 | `qzpdQxGyLBtNC4hYE4XzH96KAqyfBBEbSAMGvLAZta4KMWNqx` | 38785 | ✅ | 43,04 |
| 7 | `qzqAn1M81bJ4BThz2BfRRhNhX82hhBnYbs65wAnh6re9kyo33` | 31392 | ✅ | 38,72 |
| 8 | `qzkUpykcRNm4R5T4jQELTP7WDNkMJ557yHKYgpLqobdbBETcp` | 27954 | ✅ | 36,54 |
| 9 | `qzk4ECfeSFbQfJ9zNsAweryn46TttfkMwDmDEw97w4cJoTGzu` | 22887 | ✅ | 33,06 |
| 10 | `qzpffwT52TxEg2G8hmZ4NcJ1vjw788kyXX329VJzSSNuREkVU` | 22265 | ✅ | 32,61 |
| 11 | `qzjykZBSbNb6JUE4gSamRXbPReSSJi2Jc6Y8M51ALJLBs8odt` | 22146 | ✅ | 32,52 |
| 12 | `qzjabKoiGqb2EQKgjadKdcPXeXER7ad3C41ChdWP5YkMiYPBP` | 21635 | ✅ | 32,14 |
| 13 | `qzoa1vPquWNDpZckmSu8b3rp2S7KNbMrtMJ7NWkucfV48vTcF` | 20389 | ✅ | 31,20 |
| 14 | `qzod6rwhRxPVjueF2EZ46iKAWMHdgYLeATdgSPtKG8bJ3i7tr` | 19624 | ✅ | 30,61 |
| 15 | `qzkMLLy5HaHcUfCHfdEoeiFEAieP2RfKQLcjiTnwCTuiP3kFg` | 19440 | ✅ | 30,47 |
| 16 | `qzoAcbQXeGT4LZXdZPcT8qkBJGU8jkDWFiMrodvcUzPDEbumz` | 16182 | ✅ | 27,80 |
| 17 | `qznvwUzPoZ72bDwaoQyYbabME6dZCQSz1WoY6DtcY7NYv6MQH` | 15093 | ✅ | 26,85 |
| 18 | `qzq2NpQ4YEM8UedKmT6grZFJCwBtcfZWfnNNACZRtLr5oFn9J` | 13642 | ✅ | 25,52 |
| 19 | `qzm1ezdaBRnevMFanLZt9fRTZ7kBMxBeHABQ4ZWuQ7hVocECY` | 12730 | ✅ | 24,66 |
| 20 | `qznsWNgxqNFqNGJHproQZEZm89oih1AebS8dZSFfGTLVspbEf` | 11929 | ✅ | 23,87 |
| 21 | `qzmReSdCef1efdr8cyoqiCqRKd16LGgyLm6do2Ssgv35YhZYm` | 11446 | ✅ | 23,38 |
| 22 | `qzkRPsN9EcqGh5YBY9ZtYWKENTe1wyjsF8ETXdXRLg8cUmMip` | 11272 | ✅ | 23,20 |
| 23 | `qznsgpVYgbmySquQpRWCNWwLotYLcVN4GNPECxfhfTmESjPeu` | 11262 | ✅ | 23,19 |
| 24 | `qzoRj4BB9yZU592N39bVDaihtRTD3dGSVHuf5B7VB4ogTwDSG` | 10944 | ✅ | 22,86 |
| 25 | `qznuv4ayRPVmsQP1YAuSdRFyraHgk5JUV59GhokWY4tJNLpMX` | 9865 | ✅ | 21,71 |
| 26 | `qzpxVNHtbHLCT4p8bCdMsoN59y1Nk5ohrTBJL2CqBMHahzz9T` | 9788 | ✅ | 21,62 |
| 27 | `qzmjL8bskGfg99oyjz3EzaoZQGUdkuC1PQUFpbvkzHmsavaad` | 9563 | ✅ | 21,37 |
| 28 | `qznnipanj2hXNrTfa6UUaPkQRX3mxtFkF1FKiNFokKgCTFQsv` | 9463 | ✅ | 21,26 |
| 29 | `qzn9vq9RmqLTke7rgWhSooFXCTF1c37xqqogQh2Skx8TAwkCn` | 9408 | ✅ | 21,20 |
| 30 | `qzpR14A35zqXJvZwv7ELpjyiaKgeJ9VY3yU1618Z8TLwWJjzU` | 9346 | ✅ | 21,13 |
| 31 | `qzqDVTrpK1iB1r4fDmaDt17kReGere5S7QTJnw7e9d6avsfi1` | 8967 | ✅ | 20,69 |
| 32 | `qzjuRcQLRnipu9foN527EmNYwgBrsKzDHLmpJY5dv7muU14qc` | 8779 | ✅ | 20,48 |
| 33 | `qznYQKUeV5un22rXh7CCQB7Bsac74jynVDs2qbHk1hpPMjocB` | 8688 | ✅ | 20,37 |
| 34 | `qzjV3hAsSpehwEH7ufz8CSS9nDjB5BqSirYhNTcZUzsHmZn7Y` | 8455 | ✅ | 20,09 |
| 35 | `qzoVJ5Ptbw8udqmB2BdqWqUy2zKhbSPHqn4tjevabMBKWqVgH` | 7431 | ✅ | 18,84 |
| 36 | `qznfAogbxPq6HBesBUgrehTAXPs7D4JMJ4ZKGGjq6pVsozCkY` | 7222 | ✅ | 18,57 |
| 37 | `qzm4THzkiamY4WAEWBRQvSHNnuF1646QHcLCWWfQkPx8G4spW` | 6682 | ✅ | 17,86 |
| 38 | `qzjou3gFoc43pNcj7di1LRVBnbeRGtS3YHuzH3ansrxM7uNjJ` | 6660 | ✅ | 17,83 |
| 39 | `qzp6hcZtKGMh7rAmkwis6TaumBB8Ejaf6E4MGbxeNTT84yGe4` | 6597 | ✅ | 17,75 |
| 40 | `qzkstn8F4jNj43Q7xYHERVM2xJKNjqc4HEDfkstajAsNFGomM` | 5666 | ✅ | 16,45 |
| 41 | `qzoF1k2refbU5jqLNJ63ETmEyUC6ddhcbmwbz8KQF5p7KjEn5` | 5502 | ✅ | 16,21 |
| 42 | `qzmdSNDcuWexG7Cz19taf3XfT6fCRX12qDQU69vNzdDpRgjJv` | 5477 | ✅ | 16,17 |
| 43 | `qzoKAaM69LJqXhBHB5pBroW2H8jRaFt7tu7rrLFGypMacpsiM` | 5320 | ✅ | 15,94 |
| 44 | `qzmj2vv3dxRXvQQEBp5crY2AQe6DwbNQ7ww7m5p17BXv9sxV7` | 5269 | ✅ | 15,86 |
| 45 | `qzm34PtyvSroN8Y1Ewn9rRWEPpXAn68TBaXEJMFpqSwxLn4wh` | 5202 | ✅ | 15,76 |
| 46 | `qzpf27tsP8fBRRgGGyAnDc4qc4T6EBQ7FHE198E9BQhwBfXNG` | 5182 | ✅ | 15,73 |
| 47 | `qzoXu7mBS3hVPuBSWpg5vMbAmqC21k6D6JZMTAgATJFwnmv4a` | 5166 | ✅ | 15,71 |
| 48 | `qzq5jpZzkD1g6S8q8do8YXEH5kbLJxr5ZH8iLC1fRMH1cDCwr` | 4711 | ✅ | 15,00 |
| 49 | `qzpPXV9GBTPNZt5ykFT2ccSdXVgtU2DeUWtFnFnmzKeQBZVpd` | 4671 | ✅ | 14,94 |
| 50 | `qzq9iYKZ32ymzRXQAdWq6dj1wzYgLi4pcbahkUQE8hURzqmJf` | 4621 | ✅ | 14,86 |
| 51 | `qzjtKf8PuSQKssmaJBrKzF8NqXxNgiWoABuwn2xazbx5Qx5Wh` | 4601 | ✅ | 14,82 |
| 52 | `qzoXFFL5N6jPuH8A4wm8tFT3WKecSXdHUPtvSkQcbMSVGKiQF` | 4587 | ✅ | 14,80 |
| 53 | `qzq8TijbtG5eV9Z6RDfQf8Mr2pzFWV5PT6YDuaehHD4TX5vfo` | 4516 | ✅ | 14,69 |
| 54 | `qzoSU3H1AfoCXaP2Jwqghz2PsBssxbmQkD8vNvs4w1ng9PtDx` | 4464 | ✅ | 14,60 |
| 55 | `qzmFxRvMgBN2DhcwTyoYdt4DWm6ygqkym89pVY8c4J1Hh9TZz` | 4437 | ✅ | 14,56 |
| 56 | `qzjckpfCNf78VKLTdBAi4qmLXVdq7wR4i8cFgJikAYHvLHDe7` | 4429 | ✅ | 14,54 |
| 57 | `qzmRgTnJ6XNFCKheSrnzKiaW34ubPENCX7MqSreQKgTsZkEBQ` | 4427 | ✅ | 14,54 |
| 58 | `qzp2iCiP2eiMrT3evvYRSBUNX1hh7rbwUokchqDg69kzjgPBy` | 4399 | ✅ | 14,49 |
| 59 | `qzq7P4bPaptUpY3F6YC1RvWFS7Ee7MfGmzoi2yaSYWqWahZUR` | 4303 | ✅ | 14,34 |
| 60 | `qzkqpVQfNPJdtLy11Lipq7S4FweRWfhCMrfVUohDgaKifUQAZ` | 4234 | ✅ | 14,22 |
| 61 | `qzo92RobTAxfxz6fFNQZ3qqRCkkHt28oJiHMgz2bHyMHBE78S` | 4220 | ✅ | 14,20 |
| 62 | `qzmZzKgzPHZFpJ4pT3NW68rN4rD6xj9GdaTMHVkDywwdgdb1M` | 4197 | ✅ | 14,16 |
| 63 | `qzoTppcZM2nZg2qBNhXCe2KbiGiCFXpXFyMkzu8qy9qDRuNhx` | 4193 | ✅ | 14,15 |
| 64 | `qzodyHDA4JPnTVCYp9CPczHLTyvV2cg5wwSDzgNnedkehaAaG` | 4122 | ✅ | 14,03 |
| 65 | `qzmoeZ7nMVib4WPmktLCsAN4kNNCEdgWynK2Du5XUWXA4QZ94` | 4065 | ✅ | 13,93 |
| 66 | `qzmxL7QnoRc7U13dYhYxGHajNCW5rci9QsBhEckVSc7Jm1XU5` | 3758 | ✅ | 13,40 |
| 67 | `qznjwpAM7oy51RwwRMMagrvyy5zHEbpEiDu27akw4STmA1zbN` | 3610 | ✅ | 13,13 |
| 68 | `qzpXyYw3WYhQW4WHY6xUrWWA3K29jd8khQdhAre2AWBkZWyAW` | 3578 | ✅ | 13,07 |
| 69 | `qznNa4SgboRRYChe3rUKJgFu9vyrBsWa62X7KrWwgAnJLVLmN` | 3524 | ✅ | 12,97 |
| 70 | `qzkvYuYFPgJMwve9RSgLeEC3qKpQ81Mn1BiHWuX1k2yaAUzoq` | 3509 | ✅ | 12,95 |
| 71 | `qzmswvR98p3fLfTnCUqXR5rMex9Pn8xVjjyFLSYCLtrs6dUwP` | 3508 | ✅ | 12,94 |
| 72 | `qzp4abhZ4xh7MYXvDu5zFUg9wjG8Lcd1MSzyDYChVFok91xxV` | 3491 | ✅ | 12,91 |
| 73 | `qzpZBpnnQXRgTE6DvpbMHm8etUi1Bxxdy9VmW5GuvqzEEWTMC` | 3481 | ✅ | 12,89 |
| 74 | `qzjfz5bEM1ty3LcXoh1SfHgPWHbpx1n7SZ6ykEDd4e9wfw7XK` | 3466 | ✅ | 12,87 |
| 75 | `qzodyzosc3Kow9GV3oqXivj8Q8LQ7dM9T5wnDp5sFcjXQR1HX` | 3434 | ✅ | 12,81 |
| 76 | `qzpKJ8wBLVE2JkCwqQpWARN9GbQ4yptDTinfMkdE9QzqK7BRz` | 3372 | ✅ | 12,69 |
| 77 | `qzkRCmmoQbVqvGEQshYi6FUYdwxVJ5ES65Dss7NJWuR65YrJV` | 3315 | ✅ | 12,58 |
| 78 | `qzp3TrxcsLLK3r7ymgwDcuksk8KkZXjYw7mUphv7kL67ZqYDN` | 3239 | ✅ | 12,44 |
| 79 | `qzmyMvHGK9xvbWTaFaV7nCuHAaKXEWWx2oy2qPpK8t35G2GmV` | 3147 | ✅ | 12,26 |
| 80 | `qzqBeoPMd275pnrNAeQhmhyu5QJ8SeYNAVA5xZTEdGFTWBAxR` | 3039 | ✅ | 12,05 |
| 81 | `qznbC2n3nbKidee6ekWJQjfoUWbDvmrK81rWf8djuuJfQABd6` | 2972 | ✅ | 11,91 |
| 82 | `qznWLG11DULsQFjo1bvH57RpambhRcS6tFG6DspX4GkvWH8y2` | 2860 | ✅ | 11,69 |
| 83 | `qzoAgZv6Qa9LK6sRA2FL6gdRdgcnkSW1MjFq4sUrmQssmrCvn` | 2848 | ✅ | 11,66 |
| 84 | `qznBrw539t2GXwuoN6hqniNy378Uhoxod1dn247B1bu3qSMwL` | 2841 | ✅ | 11,65 |
| 85 | `qzjjSUA6ByxufGRHm5hKSoaz9gGdhBZkVB6QF57nHvQhXfQVS` | 2759 | ✅ | 11,48 |
| 86 | `qzjd3JcWomUPHNLZ3wev3u1qdaJWFngpq8q1uz7tYv2Rvk2MJ` | 2723 | ✅ | 11,40 |
| 87 | `qzpBwzzKoLUJLC4DRN3yFu3yChg973ZXzG3BGdD8RQUhgXqiU` | 2699 | ✅ | 11,35 |
| 88 | `qzkHXEf1jYEceSyQYEcx5AsPpeySzME791wW6w3SXhwDFooSZ` | 2696 | ✅ | 11,35 |
| 89 | `qzkXpTw5oLkeBwn9SzUbu3jug6VJ5oD4QeRaoqet98eJxPxVi` | 2616 | ✅ | 11,18 |
| 90 | `qzocUbGTXDMWojfxpXiqcxG1JHqBkbKaSAXAzfUAdKaHuCHK6` | 2598 | ✅ | 11,14 |
| 91 | `qzk8e8TrLh4pZHYBad76BWcZxDmhDgvH8EHsFskCiE56HGQ4n` | 2505 | ✅ | 10,94 |
| 92 | `qzobD8H4SacS1ueFA5h1TvupB9MbArDjk4q1ENtWn34y1s5rm` | 2467 | ✅ | 10,85 |
| 93 | `qznXCP2sU8gcKa74XTD1UsiqW8UWBoAH18KH8p5w1sUPD57G4` | 2388 | ✅ | 10,68 |
| 94 | `qzoUyJBrQvAEL3yFpmDEJA4jLyYpMGrNjX28qmZ7Cvmt9TqjT` | 2231 | ✅ | 10,32 |
| 95 | `qzknsLGszSZUa5NnkLzymGm6u4iQ9DDQbBUYuVgLixEwzB9g5` | 2180 | ✅ | 10,20 |
| 96 | `qzmZ7Gpbtu2z4J55AnjqKZCfNfbuoWUmGCANsrRPZgFgb21Ya` | 2150 | ✅ | 10,13 |
| 97 | `qznGci976xEyHroGWm6fCAEm9AUEq38AMDu8zYohcxmU2QUsS` | 2109 | ✅ | 10,04 |
| 98 | `qzo7pUCHfcEhxUuxuafcixv7WU8WvBAMRjR1uCfhym4DHFe6Q` | 1981 | ✅ | 9,73 |
| 99 | `qzkFwmNAVrRKsZ7277jVfUDH4SLy8c88u4pmggc7Wwn2jdsRw` | 1793 | ✅ | 9,25 |
| 100 | `qzk3KyUyvVHXv4K26j2ePTZhr8qgRYqpL5RasN5xELYutRrys` | 1790 | ✅ | 9,25 |
| 101 | `qzjeLJHgufAz3UvAAkN7mtqgesUdwSP4sBdBJYfuFa2wu4Y9j` | 1573 | ✅ | 8,67 |
| 102 | `qzp46dLKdevu6Cn9jzvBSPivSZqTECwFohfx9xr2u86Rhbf9A` | 1445 | ✅ | 8,31 |
| 103 | `qzp7UiUh343dPDjsqQ4ki6gYyRtJw2gL7mLYkkmqsXsDkwZSv` | 1354 | ✅ | 8,04 |
| 104 | `qzpHJECPLDqWc1NHL6ySN7Ts8q7kJXiJGXGRYTHX7egTVkxX6` | 1347 | ✅ | 8,02 |
| 105 | `qzkMW1vkVWCKPaGoNoG1xi4zk9y8mE1rftV5wr4ajoegf6w92` | 1342 | ✅ | 8,01 |
| 106 | `qzjVVTwX6xi8Z7x5qRAidYkxisfjiLuZZUo5VvzUsSYzCH5Pj` | 1330 | ✅ | 7,97 |
| 107 | `qznDuX3cD7T4fj2rFfZCXRpGna29B1ytuHfbWSkLzBGr9tujG` | 1309 | ✅ | 7,91 |
| 108 | `qzpAMvnKaMBrUQMpdkX4JsQFS1peJkSnASvY1yw7CY1uyZod4` | 1295 | ✅ | 7,86 |
| 109 | `qzqBsCm7DVSVW7NUqtk2yJT2SoC2jmroFQ9keHTvRrpQHLRaZ` | 1285 | ✅ | 7,83 |
| 110 | `qzmJbB2PtT6Yn2csnweiHgP5AuYWqHpjSWqYuw5hjvu6V6Ewu` | 1283 | ✅ | 7,83 |
| 111 | `qzq43L99r93FuamJkKTqqg1pWu1xmRB41GSW3ZEhGo6aCMLxP` | 1265 | ✅ | 7,77 |
| 112 | `qznuEeDCfp9wWScQtho9Lp5UVnRoNC1WCCJugtBxBrvJbDSUQ` | 1259 | ✅ | 7,75 |
| 113 | `qzp2vMweB9mkQKypjQ2MCYgEzSSSnkxFb6ZLmpGBAqpwfraCd` | 1224 | ✅ | 7,65 |
| 114 | `qzocZMwjQXbpJPybqwM3RByokpAqXcAzzxe7xzAUwniuG3KkR` | 1212 | ✅ | 7,61 |
| 115 | `qzjuFfppNevtjh1DNNFUSuLqVQZodrjdh5qiG3tkVKvmCcMZz` | 1211 | ✅ | 7,60 |
| 116 | `qzkz9HDb8wNfUMQ6izsrTLuqPssY6vMG37SosmhHtKuvevD47` | 1207 | ✅ | 7,59 |
| 117 | `qzjXFVBj7WmamW8Bi7to2uqfrGh7nmebafYVrZat4Bn2Ufohe` | 1184 | ✅ | 7,52 |
| 118 | `qzkhabqtpLwnzRdwzYaoiVxg1AYDDPz2ZXkvAJqoN6n5yPd8g` | 1181 | ✅ | 7,51 |
| 118 | `qzpHnzRvAyPdFqBi8Raay2EjvS532gmBJDseDB7SHA5eS7sb1` | 1181 | ✅ | 7,51 |
| 120 | `qzpG1aBJwUsxB5LszistDabf8odyDRA6zDWSjYwnDiLY7eEMN` | 1175 | ✅ | 7,49 |
| 121 | `qzov49ugwidabvCnTwfyB9cWV57UH7gCiTrkt74Y9S2ha9bYA` | 1172 | ✅ | 7,48 |
| 122 | `qznJML73SHRr9oH24Ehzv8Xxkg7S8P2yxH5neSYbovNw9Sf6y` | 1168 | ✅ | 7,47 |
| 123 | `qzq8kWW618bHYQigjf4F6qmzHPvANpQCvnM4CAuVj76xcfAPu` | 1161 | ✅ | 7,45 |
| 124 | `qzpFKP7ufpBZmep9Ai24RfFvuBv4katPEQNyehSw2fMFVUNSZ` | 1142 | ✅ | 7,39 |
| 125 | `qznz772YbXNeDBqG9du3rUrW96atu4aM3iMUqhZTCrhSNzxyc` | 1131 | ✅ | 7,35 |
| 126 | `qznhYxqMiqioJosXE6d1Su9eczAuemC8kdDuo6UeMQEbPr9U4` | 1118 | ✅ | 7,31 |
| 127 | `qzjjzBaeGGo2NTvRpZjeCarzCJs8SwRbehPamKZaj43fgCr4b` | 1113 | ✅ | 7,29 |
| 128 | `qzooVku3dWWzSVCgu4Deifvk5WYWSDnZm7cuK6HKG4VZ9iMqE` | 1080 | ✅ | 7,18 |
| 129 | `qzkCku4BbZ2tNtFWyswpWDS1nP4ZkVbAFSQJE4woiYRPwPuQZ` | 1063 | ✅ | 7,13 |
| 130 | `qzp4XnbWTHwNaDoPb6GYmDxRH4yjG5JhAkRRCJFrPKmwChWC5` | 1061 | ✅ | 7,12 |
| 131 | `qzm4SNCVRQMpLrns1RZiBw6kNjzdSXQxMYQ9pcm6Gw1U5jPfF` | 1032 | ✅ | 7,02 |
| 132 | `qzocBuPC4htQ7TusY6RPfDuvxZW76tMciJ4rNGXMFsMgcxra8` | 1027 | ✅ | 7,00 |
| 133 | `qznpLBTmpowK3uH1zajqrCP9Ms81w4MvhLEgQ1wc7jGMHqyiZ` | 1009 | ✅ | 6,94 |
| 134 | `qzp2NKfUKpUGiPmEzXL1SrxyXPHrfWaN7k8szT3Jyv2QNiDzN` | 973 | ✅ | 6,82 |
| 135 | `qzmMnY6RURWJBhJ9dZE7nJ6NxmiG3soA8ksKPyEc44MLRdNdD` | 940 | ✅ | 6,70 |
| 136 | `qzpxfsNZJvqiKJJeaahCMFNc25EbtcAH1v8VsPuV9wPETBGZt` | 888 | ✅ | 6,51 |
| 137 | `qzjnhnm6B843ctXR9okYY5yr2wLCJ9bwTLBVp9whkDB2mM6bc` | 880 | ✅ | 6,48 |
| 138 | `qzmVGCXECMw743XNz2exq7HWGQF5MyxyDjZh3StUK5u9qeD98` | 842 | ✅ | 6,34 |
| 138 | `qzpyutoZE1DTpP9MdLa6JHxAUL63munZByRLAaZuLDWqKSczH` | 842 | ✅ | 6,34 |
| 140 | `qzo49YQ3Du3rCNMg1c4jvq74V2nCSYkvtg2FgcPgSJjGWby5D` | 814 | ✅ | 6,24 |
| 141 | `qzorzTjTDfgF2aWSjpb7X8j2cFLMfnbPokP74vnVzKiDQwJ4n` | 806 | ✅ | 6,20 |
| 142 | `qzm4mRPSvbCBP3365Mm4aAFTK8pzVeNeCvWKEFzupxG5AnE6R` | 800 | ✅ | 6,18 |
| 143 | `qzn5St24cMsjE4JKYdXLBctusWj5zom67dnrW22SweAahLGeG` | 781 | ✅ | 6,11 |
| 144 | `qzo8Nynu1zHsL4Kv3KauzGyKsNnbHraMFULAdixG27UqtEzbJ` | 779 | ✅ | 6,10 |
| 145 | `qzkueR6bJTaPhme2AQJVM79J3tCHV5Y3MxUyG1WkMZEwUWZn1` | 775 | ✅ | 6,08 |
| 146 | `qzmvqBvd3G3Zhko8C3NmP1hRHnYR8xH6z5eXDqTsPj4ujnVHz` | 764 | ✅ | 6,04 |
| 147 | `qznjf2vHZsqLsRom9rJYYphFmUCH238dPAbvwRfb1Rb55gx4Y` | 753 | ✅ | 6,00 |
| 148 | `qzpYbpDas1mtHqibGvmi1sDv6aqQibiNhXihasMpCSYPraQUJ` | 741 | ✅ | 5,95 |
| 149 | `qznD41x7RFCzuyhCDsaCxriNM8SbPbTbwPqH8Hfn3ipojLyoK` | 716 | ✅ | 5,85 |
| 150 | `qzkzyez9vMXtG9zti4Y8yzH2z1hU2UQhYAVnyt7mGJHUi4yhp` | 686 | ✅ | 5,72 |
| 151 | `qzqET4W49fXJyJYM7NSxqmYDQbZ8BuUXtn57CxRogtskJyDuG` | 685 | ✅ | 5,72 |
| 152 | `qznGVokAH4LBTiTveYCFkD2o1w13JNsckYmtWiLR6sPGdwrWu` | 670 | ✅ | 5,66 |
| 153 | `qznQL9mXJ9EogqAyHcx6HdLbqrxbyBKLxiiXVKbqB3vcqrbye` | 659 | ✅ | 5,61 |
| 154 | `qzpDySz2ADQ8oTRWzHrG34F6L8SzVzoci82V2vYxBj2p7GdJL` | 640 | ✅ | 5,53 |
| 155 | `qzmHs95q5JRHEqFgVEAK9QNkRUQP1rQiApJFtvkTHgMC6Ch7S` | 635 | ✅ | 5,51 |
| 156 | `qzm1Z8QJFoJxnmAapezaqjqkV4CH41RGBv4EbNSuENaeozCX9` | 611 | ✅ | 5,40 |
| 157 | `qznx1bjDQgdXkz8YLNx5MyvpeiQFZPbHHn71fq4WsJ5MAjxTV` | 609 | ✅ | 5,39 |
| 158 | `qzpWDnCsmeyKwrTqZra75CcS7YByaXXtmoLrZJNcsMKJbQhSh` | 578 | ✅ | 5,25 |
| 159 | `qzo8YG85VgfweuQMEsJrSLNCo55ogqTKX1MtcyYJ2gi5cXQxf` | 565 | ✅ | 5,19 |
| 160 | `qzpyuWuMJ7c4qcFBedQj3kXvuPbbPJ6qSNognPrnrr1vFs8WT` | 549 | ✅ | 5,12 |
| 161 | `qzoSb6NaAZBT89u6RGN4uzm5y5hJqo6ggc3wbWrF2zQCafjhc` | 542 | ✅ | 5,09 |
| 162 | `qzq2aKiqcBm2YRKhdVfeNu44j7TV2mbWw5NudAE971WJGEmqg` | 539 | ✅ | 5,07 |
| 163 | `qzomoDa4mmawDUuGt89iV9M1m1Tsma4aVEfQ1FQ3zLNFsxrLS` | 534 | ✅ | 5,05 |
| 164 | `qzpDo3FRVpdK1chHgLBpHceinmeNySRfHxRzbNnRfBmxcop8v` | 525 | ✅ | 5,01 |
| 165 | `qzo5UDS3o2XuQiV1KoGJhYteanMAtLS1mkh2KXSdpyncumazL` | 521 | ✅ | 4,99 |
| 166 | `qzoxZo4xxcn9FjbL57Ha9tk5PQd6PheLM66gUABa2eb8Pp8qD` | 520 | ✅ | 4,98 |
| 167 | `qzkdbhMKkVm3uKXwW8Z4mnKggDddhXvVCt2XueV5BytqhA2QV` | 512 | ✅ | 4,94 |
| 168 | `qzmrbWbyEuFi7oc8P7ZQby4imxdn5rpQr2256tD352yDM5Sim` | 500 | ✅ | 4,89 |
| 169 | `qznJY8Hx5mXMweeBxZaLs5HouwViviVDg2iBxecDzfosuy6LC` | 495 | ✅ | 4,86 |
| 170 | `qzosgeCQ3gjB9WLmKRSx4Pj9NF6YZw68c2fhzYU898ro2pMkW` | 482 | ✅ | 4,80 |
| 171 | `qzkBpmFyDU3MkAv1bTg9VB5M9mg33Vw8MDGAeZdrjWvWvt6BV` | 476 | ✅ | 4,77 |
| 172 | `qzkgu6putwW9RkVGAxaTmjGez721MpPdnn9dXHvVHYhrnAy6a` | 453 | ✅ | 4,65 |
| 173 | `qzpGY5qfaS1tFfbUxmybS9ecSikR6rPhn81dgYUfheocjXwJi` | 436 | ✅ | 4,56 |
| 174 | `qzkxen9n28qjMjujX2SEEVphQ2UdPzrHqYjDkHeVvdtPLjEgP` | 435 | ✅ | 4,56 |
| 175 | `qzmheMGf8A1F37WudRkuqDZBQ4q5XWaaqS9jzucJh8LczuqAp` | 409 | ✅ | 4,42 |
| 176 | `qzo2VufVhC6bJwdg2XYkUD2DQqjzQew2m3giz7jJMtxv5SYwS` | 392 | ✅ | 4,33 |
| 177 | `qzpoTFEvSgUwYpR3ePQz5K4rDwmTE46XoCDd1xefSfakZhMYd` | 390 | ✅ | 4,32 |
| 178 | `qzkXTv6v185mvpW7ioXpy3jkJqLS8AMqNdJxqkJid7MGATz3U` | 384 | ✅ | 4,28 |
| 179 | `qznE4LfStdckoGKE3E94kmzNAjkLy28SuNJCfGchy3oo8ZM2X` | 366 | ✅ | 4,18 |
| 179 | `qzqE22pZ2GSJpMmAr7uezPcb62ZmKd8RR846q6S3jaFQcM6V2` | 366 | ✅ | 4,18 |
| 181 | `qzmdKHkqRpus2WMDx8KraGwQpKdEHcjBxnKhFptzLdCSFMWao` | 363 | ✅ | 4,16 |
| 182 | `qzk7gD4DatoxhdPeU82EvAEmeyv92Kfna4oxaKxp3q57iN1nZ` | 358 | ✅ | 4,13 |
| 183 | `qzmwniuZJ8paNbQ2XTGAnCHv7KqqZaBZ81CRqKembsYdqQsBn` | 351 | ✅ | 4,09 |
| 184 | `qzov7trcVu8mAF32dJmdWBhCg1JjFiSSCQUbsYRkjRq6pXiPc` | 344 | ✅ | 4,05 |
| 184 | `qzpFoSokNpM2BKDanS636PWDu9WJBsTsuK7yctpKiZ9m8C58y` | 344 | ✅ | 4,05 |
| 186 | `qzkWs5u6F1Qgf885UB8sREoobtsqq9rzCocnNGDBnTQRSDx7Z` | 336 | ✅ | 4,01 |
| 187 | `qznrDYi7T1BmnW5jPA6VqQhLEDwLZrhv1vssfdPA4tNKS29Lr` | 321 | ✅ | 3,92 |
| 188 | `qzmzEaD7TBYhrQFgMNdqBgkm588p6fkb1deXUGhqy6r1BjRFe` | 320 | ✅ | 3,91 |
| 189 | `qzoippr2KfV49MzLJgp9ea4GaPdXdNtshWhyhStm7ptTKDWwe` | 318 | ✅ | 3,90 |
| 190 | `qzowjRbNQaU1QfhGWsworhQNdi6zEuxFiNQrDfp9ufanXLPfL` | 312 | ✅ | 3,86 |
| 191 | `qznLHZWWGsHqPCKWWi8jTKM7HxkEaxfmKqJVdTC4mkrQZxZGs` | 306 | ✅ | 3,82 |
| 192 | `qzmDVGDm9sXz6VnWP4GvhbPdAyWBGKPxSG5DigEwM8Q4KwZbJ` | 305 | ✅ | 3,82 |
| 192 | `qzo3MQuQtoueVnz57EHMyujwaSM2LB1PfSUos1w9pX2LUH76o` | 305 | ✅ | 3,82 |
| 194 | `qzkE8fGYRYYLqt2bgHW3gUsdLc4GtanMHtEsEskQNEyaBcqpf` | 299 | ✅ | 3,78 |
| 195 | `qzn87mjedhZrBtpadPXZGLfhBkhjda1AhqqjzVKsx4bUG93Ym` | 297 | ✅ | 3,77 |
| 196 | `qznHMb8wtT7r5HBTjgCECLCgJPYsnCB9t7BxKivZEgFq6Swkt` | 295 | ✅ | 3,75 |
| 197 | `qzmB4keFoJeiGHkYFPFbrT2PgcuXnEmaduFCE74n68aDJi1pT` | 293 | ✅ | 3,74 |
| 198 | `qzpwK6747tjFAzNSCS3gekJLBctADVnGRKSYBmfHL5bXshGzu` | 292 | ✅ | 3,73 |
| 199 | `qzpaqTLSqGL61txYjzWUhVDt8LpSK7NRsEPmZVk31o1uCGg7G` | 290 | ✅ | 3,72 |
| 200 | `qzmqR5qhpTDjKDaiRHdNUxpn2Kc1R8MN79Ri4CbBsPR2JU79C` | 273 | ❌ | 0,00 |
| 201 | `qzjvmw9761GuqAoRhsZ2eCBqq7VmNzAfNQGGkGmEjozynMyDF` | 269 | ❌ | 0,00 |
| 202 | `qzkG9ekjCtkPDvLmLGn1cgwWBr1udzRFHGahM4sCFmPdtCneD` | 261 | ❌ | 0,00 |
| 203 | `qzmXZcX3B75WgYWqfaGukQbaDQvEunZTz6A6ERP8Cj24xdHPo` | 249 | ❌ | 0,00 |
| 204 | `qzoEBqbG3ASAmzJakhUoCxdKr2zdAJd4ECnFnuPM6StdD6KyW` | 248 | ❌ | 0,00 |
| 205 | `qzo2Qo4jhPcKsjZsdr9oUY5YHpRX5sMefDX94atW1VYpyg77o` | 223 | ❌ | 0,00 |
| 205 | `qzpFWsgxV7BswcVwUkV3YidNRydFYRu3FtkSgGZptswHitwU2` | 223 | ❌ | 0,00 |
| 207 | `qzkCqZuRiJPqsWnNsWTFHxmvA8K4ZzwobtRGVLMCgyCRfSyDD` | 214 | ❌ | 0,00 |
| 208 | `qzkzo32jERRgWUA2ydbw7F2VbSuyej194K5SyfHgwoEWWoAaM` | 209 | ❌ | 0,00 |
| 209 | `qzpBGycREoVSFyopdsH6n2XAaVyKvZTBkSf3c9AGnJhwQ5YUb` | 202 | ❌ | 0,00 |
| 210 | `qzkT1GgB6dVEnLUJ2jzc7MhJRNMytU2wdEyq4cqBhwb4zcZHD` | 198 | ❌ | 0,00 |
| 211 | `qzkojMR4K6fG3yQF8fz2Cyg3es9nzcnDdDpG6J2G3yfUH9o8J` | 195 | ❌ | 0,00 |
| 212 | `qzngust61yHYBxg8rKq3bkhdYf1BZ2wn1w52X5Gxhk3u5LCmC` | 186 | ❌ | 0,00 |
| 213 | `qzkFJ6MbLjp6iwdpBV5ZfwZqcqeMnTgmryNK1SbH6Vw5ZWLpt` | 184 | ❌ | 0,00 |
| 214 | `qzmR5ZnswAqvhHNiL8edJUG2pvLJx4MUSgEvXjQfw1kAF1kap` | 169 | ❌ | 0,00 |
| 215 | `qzpApMk71Pfz994b9Tvm5VJSYDUwkRDwtHCywxueTyJg8u5Bb` | 164 | ❌ | 0,00 |
| 216 | `qzpW9S2WAKdFRXGg4Ys54fYAXZft5ovpbd7abtGcyFiZTpuUZ` | 161 | ❌ | 0,00 |
| 217 | `qzkhppk9Xuukgpxx6RCp7ngLNhgEHQcGGwPmXpqVbPnjnDmUQ` | 156 | ❌ | 0,00 |
| 218 | `qzkmEmPP5Tr8cmMWKjyQhF9dG5VodFWRHTw1DTAnZz2omPdyq` | 153 | ❌ | 0,00 |
| 219 | `qzkAtFu6LVY7bUGtQFH8LSgwuZmH94SCCuvwpj28ZwoxHwyS5` | 143 | ❌ | 0,00 |
| 220 | `qzkb6MjWY1CKUdBTKm9RKBXTovQA3PuqnHNEUoPutzau8DNo8` | 140 | ❌ | 0,00 |
| 221 | `qzmLaBxdg8ZPk7eMKf2Ez5US9g1JTabZ3LaYm9sKMiac8Br8y` | 137 | ❌ | 0,00 |
| 222 | `qzmHx4Wt4Ymxj6B5q2yEtbK9d1DCogczgcB4JaR3RVwEubPvg` | 135 | ❌ | 0,00 |
| 223 | `qzmUtcJHBbdUBMVxMTbqZDytEX4URhueMZGnyVRQB6u8NQ7V3` | 134 | ❌ | 0,00 |
| 223 | `qzpoMEn6uLMybVqoEdPaxV76GtCmLGqWXMvSUP2HpJ4LazLBs` | 134 | ❌ | 0,00 |
| 225 | `qzobguJdkmujDe2HxMYQL59chMDKitWFjRyd4HyaWD3dbD35F` | 126 | ❌ | 0,00 |
| 226 | `qzja9XWqYYwaeJeeCxcs36yq7WjU1Lw197MhSjX6ntWMtQFRN` | 125 | ❌ | 0,00 |
| 226 | `qzpGU15cAxXgi2WsjL71yxz4Ack6jcbZMAUiHTAcwigmkmrBw` | 125 | ❌ | 0,00 |
| 228 | `qzpwZJt8wSyVLTXJe28rRuFBYBar2iAcU2J6CCa58PdVed9WT` | 124 | ❌ | 0,00 |
| 229 | `qzpK6YNygfbbh5d4xsjiBMS6k9mVSGkLgx25LiGARnzuHw2ha` | 123 | ❌ | 0,00 |
| 230 | `qznti68ayntXygP8CRPJCvt2ppKZ4QzidC6PevvAh4RQPaReM` | 121 | ❌ | 0,00 |
| 230 | `qznxEXFjN3wDxU1S247F9nc58y8c4QWyXRQBQjbysFBtmqjKx` | 121 | ❌ | 0,00 |
| 232 | `qzmmjMGJnzJC3Ey485mR6uLf8Suw7bMP2ps1xyTpoU3CgTTrW` | 120 | ❌ | 0,00 |
| 232 | `qzpyhv3GBQyH2XabDcbEDzYrxMzgn5f9NJGKdv6XcfnmYZX6M` | 120 | ❌ | 0,00 |
| 234 | `qzmXTTfAzhw8rCUbfrdq6ZLCqBCbsXBNyuF92mrtC1umBNNgD` | 119 | ❌ | 0,00 |
| 234 | `qzpQkQpofEkv7Kh5WYgsaxG5o2Sx6yvf44FM5kgbRCF5ftTpQ` | 119 | ❌ | 0,00 |
| 236 | `qzjgQZYb2ASjtZ4oEojNNHSybmBqJDDgTXvRGyMDAaroaPqVf` | 118 | ❌ | 0,00 |
| 237 | `qzpS2fu7AqMP49gEfCp8s8GKexvkFuvzQ9CAngrGVywtSrkb7` | 115 | ❌ | 0,00 |
| 238 | `qzk7PyK5kpKbWaVWPSe3QkGyUzwZww2u2SWxmNbWyGdXeMWM8` | 114 | ❌ | 0,00 |
| 239 | `qzjmWF8mSSATTxbub5TUgf3eALsasejKLBbwyb1xVoDGdbmmW` | 113 | ❌ | 0,00 |
| 240 | `qzpZ2BmcWWwdSKEj8puvoyyMzaPSpEtGY51Cva9j9TE7qS8EW` | 110 | ❌ | 0,00 |
| 241 | `qzoBKTFdcWpoDstmQ6K4fLcuAj3vEKLkiZY9jXw4yXUrKm6zS` | 108 | ❌ | 0,00 |
| 242 | `qzknghmWM1bSU2eBJQSCX8WiiPKXQtQw5xWzoxYEYYtPS4Mk9` | 107 | ❌ | 0,00 |
| 242 | `qzmMkBGg5Pkfc8dYPFMUq5WFQge2K9tCDw7FzYjxNHP9LPz8d` | 107 | ❌ | 0,00 |
| 242 | `qzpwecobeg67qddtpgwXftC2WEHYigUrYjG8YQyeXJFdG1nz5` | 107 | ❌ | 0,00 |
| 242 | `qzq48k3inPqJbwXQVx5QUh2psZSHCg69BnedL3YZ2B6nUSzGz` | 107 | ❌ | 0,00 |
| 246 | `qzmL6e9Xsc6XMPYkDBcjEYhCwMSriCP4ZZM8oAwZai4BsRhTE` | 106 | ❌ | 0,00 |
| 247 | `qzm7CMTimgiasJbGUehtJtpnEVedyouadMukATzNkEL4QEdLh` | 105 | ❌ | 0,00 |
| 248 | `qzktDXj9r4XrUVQy57F4SSBbUXMTc9FXu9s2SgTXhgcUAHjpB` | 104 | ❌ | 0,00 |
| 249 | `qzkSpKUTsBWpgarLRfiih3VMqZaKG1Bs5R64MmwsuTPuDaezo` | 103 | ❌ | 0,00 |
| 250 | `qzoLfnGmBXg2ZhG9nRu3DXyA6c2oTLE24PEP3tmZSUe6itWSw` | 97 | ❌ | 0,00 |
| 251 | `qzpr8TAhvjwVpNQybE55areXndS8cLMGxMgTphQrc7oMHf7GK` | 95 | ❌ | 0,00 |
| 252 | `qzjVnNEPrLBjq3TXTnsRApspbUnWV519Fwb1jg7mAtdrT61Kn` | 94 | ❌ | 0,00 |
| 253 | `qzjmaa96nMaqg4T8NMUkzbCAdyoEHALftf6m5piB6La8AEyyu` | 93 | ❌ | 0,00 |
| 254 | `qznm1xFMwnNmUZEyBYRnizaZ8HqMjHZ7EnZnbZvtD1ZZFB7Jm` | 90 | ❌ | 0,00 |
| 255 | `qznVgCeyGJvcoGRkXUgxsq7hJpEbcFNQuZrc5Mrtg56hpBNDT` | 88 | ❌ | 0,00 |
| 256 | `qzpisbjK5jJvxmcmPkoYUw1FWdpwFyy1WagoUi7WLQP29hLn8` | 82 | ❌ | 0,00 |
| 257 | `qzjvv48q9jHVn9syMCmUtNXeZPsuWFkbbYme2gP3poiySG2YV` | 78 | ❌ | 0,00 |
| 258 | `qzpqnnSG2ajZKJXYu2DgXY8xgadHgr2mTgiBZSfhfTrbdZ5ho` | 76 | ❌ | 0,00 |
| 259 | `qzmhM5v7P3GiAs6psjSbvu2UcQ1R8Hn85wAzE4Lxtbew53oSV` | 75 | ❌ | 0,00 |
| 260 | `qzkM4mC554a2g82fUEp9DtmAHwf46YCv4dA7u6nMg6wA4BKgf` | 74 | ❌ | 0,00 |
| 261 | `qzjkCBdLdjxtkMh2rHhqQcY9k9v8TygcnfQcJAeczYvfhoa1m` | 73 | ❌ | 0,00 |
| 261 | `qzpH8xWWXYfVxVt3a28PuzgrPXxKH8hCgoPm23i5eoemcJrjE` | 73 | ❌ | 0,00 |
| 263 | `qzmX4NAJ7vuQa9Z54yfyXrzPceUNQarLbJaCsQBdreUcPmer3` | 71 | ❌ | 0,00 |
| 263 | `qzoSomx616M6SNWx4ws3pZka7WQ1Q7FfSg8JYqFz2oPH8ifoG` | 71 | ❌ | 0,00 |
| 265 | `qzky2MecccS6zrpxEAgtUTsvaS9StH8Nj7QhCq2P7vuydtYCP` | 70 | ❌ | 0,00 |
| 266 | `qzmYBoaaz26weRiYfYPm3qjaemVxq9rJrcpdZQV8rmpUV55AZ` | 68 | ❌ | 0,00 |
| 267 | `qznvi1ZszyuAifiTVz91L5LsDAsCnBQ9XUcpUpqAQ3PV7Fjs1` | 66 | ❌ | 0,00 |
| 268 | `qzooDs3ZYEVkhNw7hRp7gYDPBpzX46yqdo2xposqd2v6xD6yF` | 65 | ❌ | 0,00 |
| 269 | `qzm3SnHXf693tmr6rUzmNJgV25yygczRpVfm1BvTYZebVCAJd` | 64 | ❌ | 0,00 |
| 270 | `qzmHZ8cndFnX53jMM3dxoeFWvf17MeU8Fg8u4aQUxM4Dka689` | 59 | ❌ | 0,00 |
| 270 | `qzmzjVzAe7foBDmDS26LR3vyxP8pzHKogRxYZwyUN61ZWZkcM` | 59 | ❌ | 0,00 |
| 272 | `qzkso2u15i1SvK3JqKw7QmFsRh5JCQZjoBjSvgsiDVgM5QNzY` | 58 | ❌ | 0,00 |
| 273 | `qznUKnV1ujA9NMXdHMnQ8Hpo4hz7t9o4a2NyHsLnYX1tPCazy` | 57 | ❌ | 0,00 |
| 274 | `qzmNaLjPU7hcvkjHpGmrVDPD9y12vdAFimCSrP1GkhVFJMaUq` | 56 | ❌ | 0,00 |
| 275 | `qznViVkAhoBgCfyov5CjvV6nBgTZq4v6fEPkAcXZbKeFgU5y5` | 54 | ❌ | 0,00 |
| 276 | `qzkCLxcwHK5nwTA75gT6PUk4iZnBBrvMyihDGGNdeZSd6Dt3M` | 53 | ❌ | 0,00 |
| 276 | `qzkeXrD69KNvKjQoi8fDyvdZgD89K3mGH5jJPSmxtVMAZesy5` | 53 | ❌ | 0,00 |
| 278 | `qznMDpa9dcRH1FQT5xQPGsVus9eGDUTK15ZBnLHjnJw7T2UUQ` | 51 | ❌ | 0,00 |
| 279 | `qzq8TiLA49RXi1JpoUbqmGsCR3P2yuyg2AXgLaybFdqP7vSXG` | 47 | ❌ | 0,00 |
| 280 | `qznSj35WSE658tqovSS3ogDfyM2sZtRcJQUndj7y5m7dqEJCj` | 46 | ❌ | 0,00 |
| 281 | `qzkHaFAwxn5oCbTEHXyJXgKQubPFJk4r3S52mSkATeXBtE8xY` | 45 | ❌ | 0,00 |
| 281 | `qzo7F79w2iUmJ3TJu1A5SVMshSa83gLzxVBPnCS5Jc8m2J5QU` | 45 | ❌ | 0,00 |
| 283 | `qzn1a6f3ttc3NzkXLgKUJ1DD1GmVQ7W7C4bpjLaqDG8cVG3Jb` | 43 | ❌ | 0,00 |
| 283 | `qzp9xuqd7i2QqFSwQQziL65eJyvjWYyZMwCEes4uuRNkRVBKi` | 43 | ❌ | 0,00 |
| 285 | `qzka7HSgtxVAKvmVG4keyW9iEzbX6hKtAAuY4ZCVMMBKXTgQq` | 41 | ❌ | 0,00 |
| 285 | `qzqEXTmaSg3PayZZFBCFfqrkPCTu4SM9B2gBmsUVpWWGZc8To` | 41 | ❌ | 0,00 |
| 287 | `qzjhjRKqFpPW6vGtBboTcby1kDYqPF29jXotNxhyxJ4dMMWsr` | 39 | ❌ | 0,00 |
| 287 | `qzmHMJjbzJFMKRZJ4TXmT8tpUmouybFhKmAdMg6hR6pp9JtLx` | 39 | ❌ | 0,00 |
| 289 | `qzozKd2Y8Lpk5hDTFXHjDJaaQvAt6vpXHdephiNaNSA6yfR9T` | 36 | ❌ | 0,00 |
| 290 | `qzmj1Fm3gPdyYTYYki4Th3LTKJTdYf8JyknpPGf6HNtxm5wS5` | 35 | ❌ | 0,00 |
| 291 | `qzkn3j8b5SgdAQ6U7ES5fakASghRhbaM2XJeE425fPa4kxUFT` | 34 | ❌ | 0,00 |
| 291 | `qzo86VbsZSBEuhV7Aaxh9rnZSEPkRmVPNG48vyiFRAeHZufeE` | 34 | ❌ | 0,00 |
| 291 | `qzownhvXskhkRG37Ssyy3SjW18G5DZB4bwqdqMCQLfuqt7M4z` | 34 | ❌ | 0,00 |
| 294 | `qzn1Xp6wRpfzbAEocdrDKTSdofmYVp49ZMfj4aQPjTiSu3Fih` | 33 | ❌ | 0,00 |
| 295 | `qzkqB3NhqNMesamnhFfdxr3kHyUY5tPPGcs6fT8m36ChoBxHj` | 32 | ❌ | 0,00 |
| 296 | `qzq3YbsdtfKthY7wX3MYTBEu425Z9KkMaXNFEERYRYAvD4hqq` | 31 | ❌ | 0,00 |
| 297 | `qzjdDe4BCKLm81xRyKcQT61z3hxLbZDhZ2e1NozerGtqMfYLy` | 30 | ❌ | 0,00 |
| 297 | `qzkAQ3V6M3MfCU9WAZUTfQCMMPaFpMiAdGFbo5RK6BpWP4zxT` | 30 | ❌ | 0,00 |
| 297 | `qzpby3fUMgTu2ZLXtHEEfC9xk9xg8fd6xmrzTiYh2o6tiAbJW` | 30 | ❌ | 0,00 |
| 300 | `qzjhL9ujfiVEAFaSU3JkLnMGKCJpK1G4dNmKMC11kjq36NiTQ` | 29 | ❌ | 0,00 |
| 301 | `qzjnSoYj7zroEVXam3H3n88mCSNWpkb1CPcnXRzXoNgcqeMn4` | 28 | ❌ | 0,00 |
| 301 | `qzjpNgMDzQLeEtw1wA51LHCik8UsxmrEMERSCqc7pRVWTkmjM` | 28 | ❌ | 0,00 |
| 301 | `qzovQrRgRg29FYyh6aCjK1cHgjxiSQMwED6RjyLcHXnoHC45E` | 28 | ❌ | 0,00 |
| 304 | `qzn2CBXmMorWepWR6DVtpjXE1KwH21nuuoyHUExJEBptQ3k5A` | 27 | ❌ | 0,00 |
| 305 | `qzmUxhfxGVy3eJVn4du2KYXHpwNg34dUcYnGvLVSC4nixKJJh` | 26 | ❌ | 0,00 |
| 305 | `qzo3AqSb1WhQZiibbofB3PEhwyMQYMEki5N6zUgrsZCNp4kx7` | 26 | ❌ | 0,00 |
| 305 | `qzpqK52fRQZWxPcwKjaVMwtLc9zh5H5fMhTk81ygfVSPKjHN3` | 26 | ❌ | 0,00 |
| 308 | `qzndHPkVwAPYj3QdWFjmmTdTbeojXyLwN62TW3ddWtMH5kpHj` | 24 | ❌ | 0,00 |
| 308 | `qzo9Z1Eq7AXjy8nCNSBwwt7jCh2Dwx3YAMkeJ118BF4aq6wqo` | 24 | ❌ | 0,00 |
| 310 | `qznKqLKZJrenFFr2xyg12fPwUSwNPgiLfnAoZUHoQwtE7YqHS` | 23 | ❌ | 0,00 |
| 310 | `qzoXJVd83djk2qVMUM9FEwatEcauk2gy7fibcLouGmKnxJMph` | 23 | ❌ | 0,00 |
| 310 | `qzpyUUR4izgVZnJuQvF36yKfbSN4No25FLrukSAfxAUYGE95c` | 23 | ❌ | 0,00 |
| 313 | `qzkhjMrw8SUw4GPMC3o4NXsb9SiCwjQMnFyCLtBTwn8o9FV6g` | 22 | ❌ | 0,00 |
| 313 | `qzpeEaDx2bLz49jgzpfYxWwYwVpGLWmWP767AfHmx3xU8ZqWy` | 22 | ❌ | 0,00 |
| 315 | `qzmkx9JNgxkDm2oB4GBEvWH9Kh9RhCv6cri6URXgxKrwG9z5E` | 21 | ❌ | 0,00 |
| 315 | `qznDdf8grx5u7B85oreVY1BTu3BD2Cm6J4d412eZsEUNZD98J` | 21 | ❌ | 0,00 |
| 315 | `qzpBbBTvpYRRQndz76mwQS1RrPU9qFTzGotZ5nyhzMhyh3wgh` | 21 | ❌ | 0,00 |
| 318 | `qzk6n5Y8mfzTTX62YK2iXW6XKJ56b6Vm4eJEPUK5v94vyrzSV` | 20 | ❌ | 0,00 |
| 318 | `qznRiMp9942wpgRTqKWpVifye4R1s4uzXdWcTb5Yh4uBbC8kx` | 20 | ❌ | 0,00 |
| 318 | `qzoFduCWiF3t8MCiqb2N16NRUEvBxvQw3HMbPzgWaRQPvVZsD` | 20 | ❌ | 0,00 |
| 318 | `qzpHxBPuCB5xvCwx1ZMb6RsynTPMBSezhhdYvESBU69Fxit1c` | 20 | ❌ | 0,00 |
| 322 | `qzje8ZWLZD6wvpQWE9rW6ggXbbvL5zn3mT2eyEFJkWPQTwnvu` | 19 | ❌ | 0,00 |
| 322 | `qzjkhmhCQgp3R7ykyx24TzJThSE7C6nzDASBK7KQ5ZnZNXHyG` | 19 | ❌ | 0,00 |
| 322 | `qzkanfY4hsTWqR42JS7R5e3WPHrsRQxZhtrarpGUUGugZBd3x` | 19 | ❌ | 0,00 |
| 322 | `qzoj91JQYor112B1YyteJumyXzLViw5HriZyqitHhGN5oKETN` | 19 | ❌ | 0,00 |
| 326 | `qzkjUKnQAjfwQBcnKrZjA3gKdiPnm6pT75JQ2DCybKhNFNcbk` | 18 | ❌ | 0,00 |
| 326 | `qzokF9ygQhxm39rrZXW633shdMyVu6ctBnEpnuBpPThMCR19C` | 18 | ❌ | 0,00 |
| 328 | `qzmag6LzBdDuMQx1TCYPFVb4ibif8VgbgHcj5m7HsnAybyzbH` | 17 | ❌ | 0,00 |
| 328 | `qzo5QiGmaMUUYY5oTL3MXEmRLrXjhstkYRVtqz7PDVy2EoCfq` | 17 | ❌ | 0,00 |
| 330 | `qznwNY4H4nDnjL3ASfd4PMf4ZgPc4Cnz4uhzxpePbUncti3Bx` | 16 | ❌ | 0,00 |
| 331 | `qzmFGkXnQLedPFMFE8Cc6sMoqx5c67dv1pcdWxvHR7bbrmRun` | 15 | ❌ | 0,00 |
| 331 | `qzpmE8dUhPKcmAns6jH1CDNQauoRd8qMJpcVZYcSvbmeAG45W` | 15 | ❌ | 0,00 |
| 333 | `qzkQ1rmDvcjizT2SnLnB24VTRy6NoMWWyFunUEffmKfXbBggV` | 14 | ❌ | 0,00 |
| 333 | `qzkvVQpXZE4MvfEcHwDp7Z83UdjNpELZShqC65aSpiCoMFkad` | 14 | ❌ | 0,00 |
| 333 | `qznest3Dw31BVx1K454YnZz2MXmzX3tDXXxwNiimNrHwpB1ed` | 14 | ❌ | 0,00 |
| 333 | `qzpf41SAD6EpYRAPrdPp6xAnAJjmwyNUQjN3WwKS3RbkDVZA7` | 14 | ❌ | 0,00 |
| 337 | `qzjdEb8W8bSvK2pdy44rYvht2oyMvwvnpdRLS25RUtCSiD4DT` | 13 | ❌ | 0,00 |
| 337 | `qzqELNV36vRkd6WLKEk29tJgzt9PWYs8suv97dkqqeQGugBoG` | 13 | ❌ | 0,00 |
| 339 | `qzjXxp5pqxgRPtokWhq3Q3CaNpFvtRAQvgNuqp3DxsF2UmgWM` | 12 | ❌ | 0,00 |
| 339 | `qznxZnexEwtD8ocY6v2qNAB98fPMWrJ6eTDgEYQVQP7BPCWH2` | 12 | ❌ | 0,00 |
| 339 | `qzpPiJ1fDZDAdPmQq2xR54o51wbm9HFzFnpAeyDSBM1QVJ6Vp` | 12 | ❌ | 0,00 |
| 339 | `qzpVZUR8b5xtywQR23MBuKPBDRsfRn4whFJNNomw9n4SN3czj` | 12 | ❌ | 0,00 |
| 343 | `qzkQomVDZF9EvRreXjaTfAwsoH5x3HnJZEzrZ5a8uVAPNGjnk` | 10 | ❌ | 0,00 |
| 344 | `qzk4v3k6Zo6t6wrHFgUrPP4JFyPwsTazMBMAvymT8pu8BDieW` | 9 | ❌ | 0,00 |
| 344 | `qzkFRmUrg2MFdhTsSr2isTezePYbuvv8YZSTep1i9mzVRiGVY` | 9 | ❌ | 0,00 |
| 344 | `qzkfhFDtDJNLhPSrKNZbqL2TWNPVhx9iM3mwJSztaz9oNSNLT` | 9 | ❌ | 0,00 |
| 344 | `qzpr6axnjhKZq2A3mLUofxn5bYGEkE8T2jnxUDj2mLgJjuF5N` | 9 | ❌ | 0,00 |
| 348 | `qzjgNjPfg931rE6LNuhj6ChN3yeGRQMfNVxr9hDz1s3ZkfStW` | 8 | ❌ | 0,00 |
| 348 | `qzkayX8KN8CEjkUDqTAArut7bH6UgDHLAsXaiMWJEhjcoWGoZ` | 8 | ❌ | 0,00 |
| 348 | `qzku31NauuNcF9cX7tZLbVRfBhtXWzmyi9CwZoWSH1bujhpKP` | 8 | ❌ | 0,00 |
| 348 | `qzn847Y6b4h1Dff2xbjATrL9aho1bCDWpxrzSbtgyGaAPusET` | 8 | ❌ | 0,00 |
| 348 | `qzoipFcQwRGzyxj9ydCSvdY2nYVwiwuVoLujie2o2U7J1wPBF` | 8 | ❌ | 0,00 |
| 348 | `qzojBmWZ7LripgpyTiENmGuX39xKdTCNYgmzhQiHhJFc5qnca` | 8 | ❌ | 0,00 |
| 348 | `qzpehC9ZjRUggL9pPpe25bbTTKLiL2LjcnGZznhU41E5a878c` | 8 | ❌ | 0,00 |
| 348 | `qzptJkW8LycLN2swTWYZcpSZEJhm7HxkwSoJ2V7wZ9aY8JeBx` | 8 | ❌ | 0,00 |
| 356 | `qzkPoj8w2qX6MGGBdttAwmsVwRQDrrkSfQcvATLsDW6k2ZkyM` | 7 | ❌ | 0,00 |
| 356 | `qzmWatjuJuHjNyJ4m8VPJScNf4cyv1hXiWghxq2oydomDg7oR` | 7 | ❌ | 0,00 |
| 356 | `qzmXmBDQma6WUmr4Sh87s7T59X59L77ciYpfv7K1CidHFxk2H` | 7 | ❌ | 0,00 |
| 356 | `qznAxZLmxAeHNgT5M6RZWjd1vWp299onStfNN5pPXh82TrWRH` | 7 | ❌ | 0,00 |
| 356 | `qzorXSPdUzCKtP9NMjuZRFvn6eCS1aphgFgf9LeSC6YB2hxBs` | 7 | ❌ | 0,00 |
| 361 | `qzkdFU7QNXq4rMMHZaT5xD2mUMjZSxuBPi2qDhEY7XoYq5rua` | 6 | ❌ | 0,00 |
| 361 | `qzktLW8fzzVLUfmFkvDWFKPH86Eejf6AuKyNmpVxZR91VZjr7` | 6 | ❌ | 0,00 |
| 363 | `qzjX4rhtDvic2ZSERVb4bEu1BDSjcz5ucDd4nyfiwzU1qVRd4` | 5 | ❌ | 0,00 |
| 363 | `qzkPkfY6vQfmwXto2W8dKqg7RpCLSL5DNT7NjfJNz7iQjwuPg` | 5 | ❌ | 0,00 |
| 363 | `qznjAswMVC9ASZYuA3KBhU6bRmRMYgF66JrcfbtNYyJRgiTfg` | 5 | ❌ | 0,00 |
| 363 | `qzoVjftG5NLdEYzCGsa4XTMoYTzaRBmoPq2vBTwf76sQkd82y` | 5 | ❌ | 0,00 |
| 367 | `qzp5FNZDaGTHgw8RA2k1R1z2Qyccw6hz8z1FnRhEAdf6tPFnv` | 4 | ❌ | 0,00 |
| 367 | `qzp8afZ5GXNfbCJeVztWzF568ZMmVKT6G9HPtSD5gVZFdktSV` | 4 | ❌ | 0,00 |
| 367 | `qzppUuknLM2VExkeQummtLHpeCsbSvws3Fo4z1LK1BA5m6QmB` | 4 | ❌ | 0,00 |
| 370 | `qzmXZVNPEkyNoNrj1rewRCPamWQP6YsVM6xt5pzueEEx1SEDC` | 3 | ❌ | 0,00 |
| 370 | `qznK378TgU5v6oRai7UgutqV81hGaFoAoXn4DPBfiPcZnM2rz` | 3 | ❌ | 0,00 |
| 370 | `qzoHKouoRDeno1E1UftGKSVhmjoxZAfJBAUKRHQjnpp7wdBdt` | 3 | ❌ | 0,00 |
| 370 | `qzp378k33doZHi6gvvFCUN4auTEmQgWqrLDZEZrTPXs4opcRo` | 3 | ❌ | 0,00 |
| 370 | `qzp4nS2szKTcb31pk7nZeFwL6Qr3GTRcwdMAAZAvbkh1cdVc5` | 3 | ❌ | 0,00 |
| 370 | `qzpdJRGxfNnby7ue3PcSJZZTiwZVdyXJTRfXgAyv8U3gCRoE9` | 3 | ❌ | 0,00 |
| 370 | `qzpfmVckguhytKse6VwYXFdpdM4BDgjmp9jB6q3ovbGmUNmVT` | 3 | ❌ | 0,00 |
| 377 | `qzjUZ9wS8wwLqdiRQW3cn31ZiZRxdD2uqTLrFoCoi3j5FwXom` | 2 | ❌ | 0,00 |
| 377 | `qzkRf4gKmSMXZ1a7K467Fya5XkSv5uhfdt5BoebZSnuRNVFmM` | 2 | ❌ | 0,00 |
| 377 | `qzkcPZa7MJHzCHPi8xUbsoM2aDmwmMmzQ7yHRvSoUhw4GoKaK` | 2 | ❌ | 0,00 |
| 377 | `qzkrJDzQuyZ92KTdwG718tQzZUCL4hd1m6ibmHaKox6tnJEXL` | 2 | ❌ | 0,00 |
| 377 | `qzktZGjX3ALJrEzFiSS8MvZNF3rgFyURLh9eGgFLgNNCWqwYU` | 2 | ❌ | 0,00 |
| 377 | `qzmmSu8dfJ6ww6Rp8iHrN7Q2xBPKS4E6kxM2kdGfozSk4EL8c` | 2 | ❌ | 0,00 |
| 377 | `qznQ5i181r87Lw1C8wcp9qRFBEC8CEjhBqYspdSFv12R917NS` | 2 | ❌ | 0,00 |
| 377 | `qznpoqYmpSrypih4epbyMRp1cFuv7T2pzwqhrc4NccZr8WZB5` | 2 | ❌ | 0,00 |
| 377 | `qznscbHurRmmJLVBKn3SgUD3KwXNKZiLFjSsvrjtk1m73c35T` | 2 | ❌ | 0,00 |
| 377 | `qznySY3GQ9dhK5GXjt1jJQN13NRZRLnwW8rgifDNpMsbKESKn` | 2 | ❌ | 0,00 |
| 377 | `qzo5LUKwEHe7C66WLen9tcTdRx6rqNkSVyrRWXZGzVNGuQzYH` | 2 | ❌ | 0,00 |
| 377 | `qzpZ457u4UcKAtCHNskiNRyFgX2L3pngm2fL72WqgjWLz8N8z` | 2 | ❌ | 0,00 |
| 377 | `qzq8dkx6Zqg3a6ZN1Pbmrhd1jwow2fNNh6SbWrqYD8M1CMuNB` | 2 | ❌ | 0,00 |
| 390 | `qzk366wmwXDNz1XJmcmgfWYd3ZsaTSWShzZdwZC7Er7LgmWih` | 1 | ❌ | 0,00 |
| 390 | `qzkAV2SXEMJe9um2zH2E4KCf2oqiZjrBZHEpGBKMJ5QAqVboP` | 1 | ❌ | 0,00 |
| 390 | `qzkSEr8NkswvTC8vdpKtdfquH9a1AGnLZhk1v7aK8rnwuhX1o` | 1 | ❌ | 0,00 |
| 390 | `qznTeZW9c9ted7HZikNuiM28czaRFJ1QXpSHg2ekxomqKqYwJ` | 1 | ❌ | 0,00 |
| 390 | `qzneQjBF9FuaFEp54xzcasEx65koWny85Ks1HEEhwbwN9SPdu` | 1 | ❌ | 0,00 |
| 390 | `qznu5dm3S2yVJHTRxWpezNLa3jnDgYLLESrnxfZnAF7hi1DTm` | 1 | ❌ | 0,00 |
| 390 | `qznv5u1NrSWddzWFbFoVFpyBkSwpY3XiQxQHUcT46ueGcdvSN` | 1 | ❌ | 0,00 |
| 390 | `qzoayTaF13Y5aC61z5gugijhgiDpz65KxTzvLuyJcMeV5ySM4` | 1 | ❌ | 0,00 |
| 390 | `qzomkQ1h8eVx3kKSKnytHSWcavLaBmXKFZVxJAfQiCXXs29PU` | 1 | ❌ | 0,00 |
| 390 | `qzp6aPeDG9tMTMWAtougwZVcqd8k8ZDbVgzQegWE9Srzxqyqd` | 1 | ❌ | 0,00 |
| | **Razem** | 1092014 | 199 | **2 500,00** |

### 8.4 Planck

Plik `planck_miners.json` z 23.08.2026: 205 górników, 102 w top 50%, próg 423 bloki. Rodzaj adresu: adres wormhole, czyli „encrypted account” (Planck).

Kolumny „09.09” to wariant: bloki z indeksera do 09.09.2026 04:50 UTC i nagroda liczona z tych liczb (278 górników, próg 131 bloków, S = 9 184,689).

| Miejsce | Adres | Bloki | Top 50% | QTC | Bloki do 09.09 | Top 50% 09.09 | QTC 09.09 |
|---|---|---|---|---|---|---|---|
| 1 | `qzpJKjDzv9DDbB3fzWJJg3XpMJLaJRT2aUBRHJV3iKb9KAse1` | 107650 | ✅ | 102,79 | 132983 | ✅ | 99,26 |
| 2 | `qzjVZ8E957sD3cp8XS8Cf3bD4qLZPjYsdm6NSm5ZbA2o5BDZj` | 102505 | ✅ | 100,30 | 103321 | ✅ | 87,49 |
| 3 | `qzksv17vRTvSs3jTC2UsPPQ4LbiTRaHM3Y4ALT5AHd7azyZkh` | 41550 | ✅ | 63,86 | 59895 | ✅ | 66,61 |
| 4 | `qzjtwGuPGLy1C8mkpc7hp4ZyiK3WxaPJ5yg2dZtUnGprqZ84r` | 38457 | ✅ | 61,44 | 38457 | ✅ | 53,38 |
| 5 | `qzoqy3pcLsBcPpGFqj9BTv3UyvRB9o8ScnKqcQfSbQTR6odnu` | 37339 | ✅ | 60,54 | 48728 | ✅ | 60,08 |
| 6 | `qzpciM4tLqLHhiRczjKd2kSwSWAncCYkuU6PdDyjZE37cbyMv` | 34140 | ✅ | 57,89 | 34574 | ✅ | 50,61 |
| 7 | `qznaZcifLXCN9M6cWeJ91XsGQ7NCbkiZCwaLouUSP5YMiMzyQ` | 26614 | ✅ | 51,11 | 26614 | ✅ | 44,40 |
| 8 | `qzjYMpbcejXW1d26G8MGVo9hAVWhc29EgwK8rQhZvQQUfvKcE` | 25477 | ✅ | 50,00 | 28139 | ✅ | 45,66 |
| 9 | `qznZttca6MzPdsEaSC289BjqpxZzs4tpa7TWQ9xzzMZBNWc3W` | 21820 | ✅ | 46,28 | 31349 | ✅ | 48,19 |
| 10 | `qzq3yzbR7iXgkAEWdANe7WkvCvHqZVsmTJVQ9qkWax28wKQ1d` | 21033 | ✅ | 45,43 | 21033 | ✅ | 39,48 |
| 11 | `qzneChhG2NKkVycgweCDuBvksh4mvwNn58ySTcD6GYBHW5yLZ` | 20984 | ✅ | 45,38 | 20984 | ✅ | 39,43 |
| 12 | `qzqDMhonEncjXczzbaxXYTsFkh2MMDVSpCQXamVvK7EE6NSpY` | 19992 | ✅ | 44,30 | 19992 | ✅ | 38,49 |
| 13 | `qzkJ4DehqdMcBFHqVWPsZ7o6DpW5vJWNmsSs123vc9zCgjTod` | 18705 | ✅ | 42,85 | 18705 | ✅ | 37,23 |
| 14 | `qzozjfZd8vfVFdoKbtmezfMWV21ngt2Qc429Df1uT8u5CMeWZ` | 17123 | ✅ | 40,99 | 17123 | ✅ | 35,62 |
| 15 | `qznjf7KKWr3XMdqUS2FnNh4eo69FWQALYvyd46RKvnkX8fZKf` | 17083 | ✅ | 40,95 | 17154 | ✅ | 35,65 |
| 16 | `qzjYXKnZa4hNfQwFy4GmFNnVANi1xgGsqiXuLw4FgRYq18Kd1` | 16878 | ✅ | 40,70 | 18817 | ✅ | 37,34 |
| 17 | `qzmkLmZ8L8pQCZhYqVsYrwjeNWt2aw8BCBAzP9YGbKCWtQrjj` | 15573 | ✅ | 39,10 | 15573 | ✅ | 33,97 |
| 18 | `qznCPRrjQPCcB731eKhCP6pocUki982zbkgCY1dvCE2pzeM3D` | 15511 | ✅ | 39,02 | 15511 | ✅ | 33,90 |
| 19 | `qzogGp7Wf1UJn9gWNr6qbEhHtyvVPFXq4ResHiCRnTNVX73Yy` | 15120 | ✅ | 38,52 | 15120 | ✅ | 33,47 |
| 20 | `qzoGZBgSuPqRLLHe5E3MWR2Az3bLXdiobDJN56KdMoF5tyKhc` | 14862 | ✅ | 38,19 | 14947 | ✅ | 33,28 |
| 21 | `qzoe6nFgmXGwHA5zyUKwwGaiwFZjUBCvmXWCvZsnVA1LHEuHt` | 14493 | ✅ | 37,72 | 14493 | ✅ | 32,77 |
| 22 | `qzq92jufqAi6mq6NejVjbnFSHmWGp2btEz7jyCbqW2t2NAYZw` | 13361 | ✅ | 36,21 | 13361 | ✅ | 31,46 |
| 23 | `qzk5T5k7XV5UwErhdCadnr5YG12rd7ZwXXMdQ9jKU8j1Qs8z6` | 13149 | ✅ | 35,92 | 13173 | ✅ | 31,24 |
| 24 | `qzoUXSq3JiS3FNWLT1sX93orRW8iub9jijuKNs162oYf7gcmH` | 12655 | ✅ | 35,24 | 12655 | ✅ | 30,62 |
| 25 | `qzjfjzcmfeZ8Gmx3TRJQHA6Z7ps4LdKBSxJ86FXW6CYM4PhkX` | 11286 | ✅ | 33,28 | 11995 | ✅ | 29,81 |
| 26 | `qzpkSBJZ2seaisouXx5r9HnhMzFUNrx8FdLTQLcE27veKurTc` | 10821 | ✅ | 32,59 | 10821 | ✅ | 28,31 |
| 27 | `qzptQjWMTh95vs4w8fp6Mp3nvBc6LNJLpdPNXGPi9xRbLWraX` | 9100 | ✅ | 29,89 | 9100 | ✅ | 25,97 |
| 28 | `qzoh8Nvauqx6fHiFftu8UU3vJncL23sZY9sP9PjxX8NtbbU71` | 9098 | ✅ | 29,88 | 9125 | ✅ | 26,00 |
| 29 | `qznf9mQwGAX7oqmyiNQ4cAm68d2S9Ayx8oV5dirMFPHFYgNPf` | 8968 | ✅ | 29,67 | 8968 | ✅ | 25,78 |
| 30 | `qzk8ik4XDs99LechSUQ7X4UcsEn3x5G2K6HVAh12VGaeLKCaE` | 8839 | ✅ | 29,45 | 8839 | ✅ | 25,59 |
| 31 | `qzn7Rs7Ze6DuYM23XuDxRG2g7tQWksvRPhVosmr5oWSwkK5Eh` | 8673 | ✅ | 29,18 | 9124 | ✅ | 26,00 |
| 32 | `qzkkAjRoQckvDiHHVod21JBK9VwAHDxqACD44PUyhqckGokaD` | 8194 | ✅ | 28,36 | 8194 | ✅ | 24,64 |
| 33 | `qzphpYvryvfgPhykRHGA6dfNJggCyuWkLqrtbVG2fL7UMd2s3` | 8193 | ✅ | 28,36 | 8193 | ✅ | 24,64 |
| 34 | `qzntXFHNziRKXNRKDke7eugWHfGbsAdLY76MnpmPpq6GfnSsL` | 7930 | ✅ | 27,90 | 8750 | ✅ | 25,46 |
| 35 | `qzk7HyC72tCngnsZa8eR5CfH9VombFG2xA7YBSKE1P5KD5Ui6` | 7298 | ✅ | 26,76 | 7298 | ✅ | 23,25 |
| 36 | `qzpHtHnyo4kPoFrsrjCNeLTTUeKxxe4bJXLbGLzBFkx56r4vF` | 7248 | ✅ | 26,67 | 7248 | ✅ | 23,17 |
| 37 | `qzpo2n7PByDUB8MP5jyqVh5NqRdCPQ418xB1ywEKFcShD7bPu` | 6739 | ✅ | 25,72 | 6739 | ✅ | 22,34 |
| 38 | `qzje34gHt9vcddjFSeRRpyo9zy3HVg7QjTUFvEkUzmxXRtfeo` | 6660 | ✅ | 25,57 | 6660 | ✅ | 22,21 |
| 39 | `qzpvavZmrYcDtpK4wuz4T9FE336FZoPbTVKAwS8SiLTH5JuuR` | 6279 | ✅ | 24,82 | 6279 | ✅ | 21,57 |
| 40 | `qzn7QqFMK1Jrq932oEdqUgg1i5rgxh1tdJmnLrVYk2H9CfZGM` | 5915 | ✅ | 24,09 | 5915 | ✅ | 20,93 |
| 41 | `qzmBUdwKPZtkNMpUZTcuTdAgxzumJ3VBSrK2Z3jq3Wiv4fpNM` | 5704 | ✅ | 23,66 | 5704 | ✅ | 20,56 |
| 42 | `qzmyJZ6rpZ7ia27SPMKJkBBZsSxvtbwNDkYVcCfNE7W5bSqCJ` | 5687 | ✅ | 23,63 | 5758 | ✅ | 20,65 |
| 43 | `qzkXsiDa8wssERPRv24gQ8NJSsWqrKy2YbpFJAfLPPAbS75ot` | 5453 | ✅ | 23,13 | 5453 | ✅ | 20,10 |
| 44 | `qznaH1f7pzGjRLo3GVwJdvtxJibUfHStGYcvEao3hYCy8CtTY` | 5296 | ✅ | 22,80 | 5296 | ✅ | 19,81 |
| 45 | `qzotFdURyYYVE8PxtvZYPae79XDVZb2mupjwxUzuAp5zbxF2x` | 5199 | ✅ | 22,59 | 5199 | ✅ | 19,63 |
| 46 | `qzkpjqTqAkt7khy1QF1xophcFRMvEvnoC2P3cTD13yXjTxnL4` | 4980 | ✅ | 22,11 | 7152 | ✅ | 23,02 |
| 47 | `qznWNcF4qvGzMrFQNCxpUpG5wQqbyhi479QTVrsjjywSSKacC` | 4391 | ✅ | 20,76 | 4391 | ✅ | 18,04 |
| 48 | `qzkxev6EzBfPY8ehVoesywRqcYQzR3WA3WaXDUHhX6F9AkEJ7` | 4230 | ✅ | 20,38 | 4230 | ✅ | 17,70 |
| 49 | `qzoA7nYHPcDgoh5CoS6yokCjBbS4Krxgock8WACw3di9fhfMR` | 4141 | ✅ | 20,16 | 4141 | ✅ | 17,52 |
| 50 | `qzptaSQXLSxePPywtRCvBVLA3pYkaEJZxegZKBxSUfXANVjmz` | 4063 | ✅ | 19,97 | 4100 | ✅ | 17,43 |
| 51 | `qzopMBD3EGQWoQR1oHJc6BfaLUVijSN2qgr4mt9CGr7pbAWvK` | 4055 | ✅ | 19,95 | 4055 | ✅ | 17,33 |
| 52 | `qzoX6XtRGJupjikS6JdRvrRtzxeCQrbbV1XKbdxgahs2vZbUh` | 3999 | ✅ | 19,81 | 3999 | ✅ | 17,21 |
| 53 | `qzngBkeSDRAU4aE4YzNSMBhgi6L6HoWVNopgpeDUWz7xZF3Yr` | 3793 | ✅ | 19,29 | 3793 | ✅ | 16,76 |
| 54 | `qznAFkJZAFTWeLx7uszSRUMdEoSSE2fbXCfcEZSXLngE2sVyw` | 3527 | ✅ | 18,61 | 3527 | ✅ | 16,17 |
| 55 | `qzmMixDP4ZsZgXEKEzMjLoLLRhJkupyjHBv8AUwB4eTGDZDfg` | 3463 | ✅ | 18,44 | 3470 | ✅ | 16,03 |
| 56 | `qzkArpDcgYXXBHjo1KC8gdcPCqa1mey39hV3ikmGT1Q773Hoi` | 3391 | ✅ | 18,24 | 3391 | ✅ | 15,85 |
| 57 | `qzk3KCaU8HJhmyz1CEFFko6Sjtr5xD9sNRYms7DYM4MDpYPFm` | 3107 | ✅ | 17,46 | 3107 | ✅ | 15,17 |
| 58 | `qzk3fjVeG9MHEfU9SVzAmUyb8yeDAwANyCzexqz8RQaHDLkV4` | 3005 | ✅ | 17,17 | 3005 | ✅ | 14,92 |
| 59 | `qzjoz66pjWcd4vvLAZ3pvfgUs3NhpJvdRFjr7ogCkDfEqdzyj` | 2970 | ✅ | 17,07 | 2970 | ✅ | 14,83 |
| 60 | `qznFyjC5J8rev3q38Uq6AgmZZaz6pwVsNGYLY18o33dpQ82UC` | 2887 | ✅ | 16,83 | 2887 | ✅ | 14,63 |
| 61 | `qzpWaNzLvKGa28HUT4WZfRZ9mR3CmzGeKTLZWUAaGY2hZ5N4h` | 2789 | ✅ | 16,54 | 2789 | ✅ | 14,37 |
| 62 | `qzmzKoUTJeRRrHc1YheH289k96wR66Xyo6scgiJMwuk6GqcuB` | 2570 | ✅ | 15,88 | 2570 | ✅ | 13,80 |
| 63 | `qznx2N2imqyyD8RwRv4LQaiH7Y25TJ6apBU9U9DbycixoqzRs` | 2507 | ✅ | 15,69 | 17765 | ✅ | 36,28 |
| 64 | `qzkhJXmG9MaC5aF3A7WF2hr8hLzCjyqAYYUwvUWXzKuaXXSSv` | 2498 | ✅ | 15,66 | 2498 | ✅ | 13,60 |
| 65 | `qzkES36rs5AJSgo9cVuYhqeDXPZrYwtVyP1QVfZCVNhVBvLuq` | 2346 | ✅ | 15,17 | 2346 | ✅ | 13,18 |
| 66 | `qzmTQ8LNbx6XhHmzXH3hNBqWVokPZcfq65c944JgQkx1jS5sJ` | 2149 | ✅ | 14,52 | 2734 | ✅ | 14,23 |
| 67 | `qzmDt1Nwq2L776DPH2czsfSpTvGZzGoTtsT5Xec1Lvt4U1uyL` | 1936 | ✅ | 13,78 | 1936 | ✅ | 11,98 |
| 68 | `qznGJeNb8SmTKc8j4MveHRUDzFbxzJfpbwA1xXbVu88gQ81cG` | 1921 | ✅ | 13,73 | 1921 | ✅ | 11,93 |
| 69 | `qzkDgZmFdoJQcUwT9yMFwZXwk6BQ8yjSJzkqbmWyz47hspjr1` | 1904 | ✅ | 13,67 | 1904 | ✅ | 11,88 |
| 70 | `qznJU9ha9Pr71KZuocLfQTg85XmTLV9B4ookUdwumHH8Sx2Bw` | 1793 | ✅ | 13,27 | 1793 | ✅ | 11,53 |
| 71 | `qzoAWNYxGSvurncNDmLraamni2rh2xztbj9pfBRRxtxpJy9kR` | 1760 | ✅ | 13,14 | 1777 | ✅ | 11,47 |
| 72 | `qzmX7W95uX4LS1Eoe7qJ2ffpvXt9zyeuBDDDAxELJrnJ5LAAh` | 1736 | ✅ | 13,05 | 1736 | ✅ | 11,34 |
| 73 | `qznjVeZD28Z3Vo8dkb2o95si7pEgQ6PgdjczmiWZHHSk7zQZv` | 1577 | ✅ | 12,44 | 1577 | ✅ | 10,81 |
| 74 | `qzk6kUXgqo2mg3FYp7HejWzN2y89ZTUWxY1JfSghv7pJ25ZiJ` | 1564 | ✅ | 12,39 | 1596 | ✅ | 10,87 |
| 75 | `qzjZfskbfWNH7AzHCQfCWia1wai1KDz1kynfufQDWqf7wZqER` | 1508 | ✅ | 12,17 | 1526 | ✅ | 10,63 |
| 76 | `qzppKy8m9ETWMV8TUWmE3P5AuFTxka3ocKZ2wdg4whgHHigP5` | 1482 | ✅ | 12,06 | 1482 | ✅ | 10,48 |
| 77 | `qzoFgxG8X5CvDFeZva9CtxYG3xqufvhojzJQvCymHGbxjop5P` | 1405 | ✅ | 11,74 | 1405 | ✅ | 10,20 |
| 78 | `qznw3G1kr78fBPBAE7kEM9xBZXgi2F5pmBoC1Bt9NbcsUzPru` | 1390 | ✅ | 11,68 | 1390 | ✅ | 10,15 |
| 79 | `qzkJkWnqX6vQ9dvAWVkkooKM5fsSx2DfzYhJV2b1mfehroDoB` | 1380 | ✅ | 11,64 | 1380 | ✅ | 10,11 |
| 80 | `qzpyCwTJqfCVUVRSXC7S4oN6EvigvuETv5nqsSE442inytaNW` | 1379 | ✅ | 11,63 | 1428 | ✅ | 10,29 |
| 81 | `qzowe2f4RP29RQChSvhMeSZVq1j2JeuzM2aVurTY2Vqx3WZuj` | 1198 | ✅ | 10,84 | 1198 | ✅ | 9,42 |
| 82 | `qzoV5wbHXENvywkCLNoVAZd7KzxxH2eREyZNbVRYNbaoh6jiT` | 1091 | ✅ | 10,35 | 1091 | ✅ | 8,99 |
| 83 | `qzpcuyNw8yNqTBnRzA7vQ5Uz4iCXWmGXKfCpn5qRjcM5uQ7gF` | 1050 | ✅ | 10,15 | 1050 | ✅ | 8,82 |
| 84 | `qznGw9v9cdVzL3neuLjdTtCMHZAnP5GoDdRXZw84B7DHQ85bQ` | 1000 | ✅ | 9,91 | 1000 | ✅ | 8,61 |
| 85 | `qzoL1nn28VqPZy6kUvpe1mC3gW393bDjMBFVLwG2ka8Bn3uhY` | 987 | ✅ | 9,84 | 987 | ✅ | 8,55 |
| 86 | `qzjVXZ4jz2PsFyJo11PoSp793QJAkpHCKk4sCxo48DFSQ7sfY` | 922 | ✅ | 9,51 | 930 | ✅ | 8,30 |
| 87 | `qzoZNdMYBPLNegmhf1zk6JsbbfQzitgB8ZTSnx7dwBydEzvcz` | 904 | ✅ | 9,42 | 904 | ✅ | 8,18 |
| 88 | `qzk53pm2A7qVMaeHpbEptPKfURadMnW95uyK3YjhX34Enjwx5` | 878 | ✅ | 9,28 | 878 | ✅ | 8,07 |
| 89 | `qzkgH7zXgRmH94viJPwmZCEDirtCsKchd9ycMaLaMryjdsdwQ` | 780 | ✅ | 8,75 | 784 | ✅ | 7,62 |
| 90 | `qznRv1Rs4SmSroEDGW8yfLELrUnSCesDF5vkBatasUpqY64Fg` | 691 | ✅ | 8,24 | 691 | ✅ | 7,16 |
| 91 | `qzpW7oZydqZGGacSiQ96Jw7fzhRbQiCynt1LGhYSqHAsyehLv` | 690 | ✅ | 8,23 | 690 | ✅ | 7,15 |
| 92 | `qzmAmnxxYyq3fqBP55eHPXiNWMCmvVe2YEx5o9H7M9xFm6hET` | 610 | ✅ | 7,74 | 610 | ✅ | 6,72 |
| 93 | `qznaqHS3FQEVdsKRi9nc9JUFuCXoKcwE49cL8SF8mKGLHrLKs` | 589 | ✅ | 7,60 | 589 | ✅ | 6,61 |
| 94 | `qzoomLZaNLK84UmcaxjiLXmPhwE5X3eETC1YNyAe55qe379S4` | 555 | ✅ | 7,38 | 555 | ✅ | 6,41 |
| 95 | `qzjV98C5Wsf3AFp5GuSypPVBqZ2b98T61CnW2ua5ABCULv14W` | 532 | ✅ | 7,23 | 532 | ✅ | 6,28 |
| 96 | `qznJJmLc72y56wLzKjopYVwY2oa8jSodCfmxtqU2VjCs1jZXZ` | 492 | ✅ | 6,95 | 492 | ✅ | 6,04 |
| 97 | `qzmUZW2Aghghw6TsSCgPmqEdbg1Nr5rvbQAKZFgkqPGNYTBEz` | 471 | ✅ | 6,80 | 2477 | ✅ | 13,55 |
| 98 | `qzoWfxg9D7SkmsxfZxMJg8ZDS4GfJMtuNVjfcp92WAffSaokD` | 453 | ✅ | 6,67 | 453 | ✅ | 5,79 |
| 99 | `qzoe56Gzrt1NtwsmoUkEwL4UbXaRPNUJyhivzJBAJ2gewfJvo` | 451 | ✅ | 6,65 | 451 | ✅ | 5,78 |
| 100 | `qzoU827dmqjZWxcLkV8JEPHbjk7nVxVTuAphZJE5ouKCi9i3d` | 446 | ✅ | 6,62 | 446 | ✅ | 5,75 |
| 101 | `qzpt132WSFK7oDAZMWNhLaTJDkBEoSuYMp18eTCP3WMcPtvwa` | 439 | ✅ | 6,56 | 439 | ✅ | 5,70 |
| 102 | `qzn6Am3Xn3JBFDoESUc6pBiAo5eQHEiRZgmnBv3w29UsAb8xK` | 423 | ✅ | 6,44 | 440 | ✅ | 5,71 |
| 103 | `qzpKpUGF8PzRwdYAJ9nJdytSTNs3za9WiCqZRnvkXczcDXfFB` | 406 | ❌ | 0,00 | 406 | ✅ | 5,48 |
| 104 | `qzjkZuoCUFzFWcSC4XGoVAkN6X797bLFB2tJAHbMJCrDrWgtW` | 393 | ❌ | 0,00 | 393 | ✅ | 5,40 |
| 105 | `qzkjftZ5PLzzhjxTyp9byWVxWaaHFE4jDQJ9tXnJa2fLmVXTh` | 386 | ❌ | 0,00 | 386 | ✅ | 5,35 |
| 106 | `qzo5Rt6taAj74KmzWGXH4Wz8aSAoUHmJzUn8NZFaufxE3XwDu` | 373 | ❌ | 0,00 | 373 | ✅ | 5,26 |
| 107 | `qzk6Bdtc1h93BGKkaYV8URjhs3cYgmzBVTGtE9RposguauoNt` | 351 | ❌ | 0,00 | 351 | ✅ | 5,10 |
| 108 | `qzoZ45rs5UTkM4MLiM4tDfE9RLFwGvutqyHm3vUk2cqQSqyRN` | 342 | ❌ | 0,00 | 342 | ✅ | 5,03 |
| 109 | `qzmQnLkom6SspzDKsABJQmqa2yRRpUzDsvi1gQHGZNd3dfcQT` | 338 | ❌ | 0,00 | 338 | ✅ | 5,00 |
| 110 | `qzkV4WNDjjPhBjHj8fU1DeXjQykuUVFY9mbMJaardkvxGQGVn` | 299 | ❌ | 0,00 | 304 | ✅ | 4,75 |
| 111 | `qznPW63tUQfEvSPNDQvrcACzbYvD9UY7XGSzeg1BhTYcW1AXQ` | 278 | ❌ | 0,00 | 278 | ✅ | 4,54 |
| 112 | `qzkZZKyU5f85w5texCMYtLnG4wn7XmP6LbJPheJ1B4mYQiTdS` | 263 | ❌ | 0,00 | 263 | ✅ | 4,41 |
| 113 | `qzoQigUph8v4bmNNSsFXLtCju1JLcLrySYwSjLvtJnPd59Tyd` | 205 | ❌ | 0,00 | 205 | ✅ | 3,90 |
| 114 | `qzpPZywsNZY4BhajHqDuL7SEkPQfJCJDcuPMQzosPX5bQmHFd` | 204 | ❌ | 0,00 | 204 | ✅ | 3,89 |
| 115 | `qzncaYTNReUpKQTV8oPn9V12dswi1NxrqQnmSjxNnv1dZFAdc` | 190 | ❌ | 0,00 | 190 | ✅ | 3,75 |
| 116 | `qzkfsjmauTtbEgAsX8hLYoWKkZUgn5E8HGd8Ra7uceUMAwa9D` | 182 | ❌ | 0,00 | 182 | ✅ | 3,67 |
| 117 | `qzmkuZHCkSxKsdiLft6itvokgcoVGY4LCEnHTqrqDLE5LW8ST` | 180 | ❌ | 0,00 | 180 | ✅ | 3,65 |
| 118 | `qzmNtekgxmMnWtMDyQuDjTio3iK4tvf1g9GCLnbDHZutdNyfq` | 145 | ❌ | 0,00 | 145 | ✅ | 3,28 |
| 119 | `qzknJzK1mxj4BPfJfevxuWtKnabogCp52ESnUEK1n7HY6iejs` | 143 | ❌ | 0,00 | 143 | ✅ | 3,25 |
| 119 | `qznWni9oj1YhEQWmwxH6EN6G9AH5Mor8qexsFWhjqysH77Hpq` | 143 | ❌ | 0,00 | 143 | ✅ | 3,25 |
| 121 | `qzk1q2cpsRTG9xR27YTJjpq6wkSrxj8EFydhy8XVQRNoVztkZ` | 135 | ❌ | 0,00 | 135 | ✅ | 3,16 |
| 122 | `qzmzQ3fZJPtj2fCkTFk1rGCtL4RWfiMVhvMg19yPfGiL7THC5` | 131 | ❌ | 0,00 | 131 | ✅ | 3,12 |
| 122 | `qznCWPicHavhx5RV2R79EcHDio9y2baWjYYN4pKYQgiWJQHSx` | 131 | ❌ | 0,00 | 131 | ❌ | 0,00 |
| 124 | `qznf6AqnX41rbUcAZw37gAma4KT3SzXRQ479xn66QWmfMX4jM` | 116 | ❌ | 0,00 | 116 | ❌ | 0,00 |
| 125 | `qzkcVJYgPhRofvmx8j5G3Ao8xGibn5uTxK9HJBL432a2VEeM6` | 99 | ❌ | 0,00 | 99 | ❌ | 0,00 |
| 126 | `qzp5rk1EYR4nXXmgXVSZC21jxmrKUkezpuFCvJq2YBaJMmEA7` | 95 | ❌ | 0,00 | 95 | ❌ | 0,00 |
| 127 | `qzpjRZgATwh8YX8RNGdVxkEJH3HbP6uANBfDzv16emghLNc1d` | 89 | ❌ | 0,00 | 89 | ❌ | 0,00 |
| 128 | `qzpyGFtvdwb6PEX8engvx6a1Fr34ynJ95mRCk79A7rMhEbsYd` | 83 | ❌ | 0,00 | 83 | ❌ | 0,00 |
| 129 | `qzmeLpn3zpnr6qByEkezHTxkWbfzHyUazFgXnMzzgWxc1mW1d` | 82 | ❌ | 0,00 | 82 | ❌ | 0,00 |
| 130 | `qzoQkwWyRKdPCDrkXnMVvfaJhFd8swnhHeejXwSrkrz4SF2FT` | 79 | ❌ | 0,00 | 79 | ❌ | 0,00 |
| 131 | `qzkdFgYDxFuA4e7CWCn6UAG51ZqPwbZgRLFGmTHMtr49hrqCf` | 72 | ❌ | 0,00 | 72 | ❌ | 0,00 |
| 132 | `qzmNdACGAF8juNpKwpeVx9kw6PNVX73m7g7RveLouoeDQ9MDp` | 71 | ❌ | 0,00 | 71 | ❌ | 0,00 |
| 133 | `qzokw2pZLzagChLZ4AzXQ8URmLSSTKGUpAcFsjg8sCQiAeBcv` | 69 | ❌ | 0,00 | 69 | ❌ | 0,00 |
| 134 | `qzoDZEJoJremk9FdshfPfquRkex7KGSdS62mrCMVqkzFPAkcf` | 68 | ❌ | 0,00 | 68 | ❌ | 0,00 |
| 135 | `qzpayjBTErGZbhQ3D5YUcyCP1PVwUSiWFRdyXjr1dT3sysCDo` | 62 | ❌ | 0,00 | 62 | ❌ | 0,00 |
| 136 | `qznL9CQFbtCn54m6QQQxNPsf2qsAGJCe6AtKwZ6rUWkLjxJVA` | 61 | ❌ | 0,00 | 61 | ❌ | 0,00 |
| 137 | `qzox4ZXRpoVt4CNbewQ6aRUApLuqxtAsNNxVeZFM8hJSL4kbN` | 56 | ❌ | 0,00 | 56 | ❌ | 0,00 |
| 138 | `qzjaRu9aYYktAg99brEpAfVd2CLeLrPnTESfes4jfvwPd12um` | 54 | ❌ | 0,00 | 55 | ❌ | 0,00 |
| 138 | `qzmJZfma5ZAkBD9PLBSpBVi8WYpdzvhpJzsGoHH9Jq3PzZLFJ` | 54 | ❌ | 0,00 | 54 | ❌ | 0,00 |
| 140 | `qzpWtmSg6C63cxhwC7ddxVpkmeCFRmXb85ZHFFXqV2e9B1ENq` | 53 | ❌ | 0,00 | 53 | ❌ | 0,00 |
| 141 | `qzoSismfMrpcoyDCPRwFrvo6sAFC5nHFSixgPd45swjN1xzkc` | 51 | ❌ | 0,00 | 51 | ❌ | 0,00 |
| 142 | `qzoxLXW767UZJNs52YezTgCNYy8nNMZ4fT1c6FPjDbeV3FucF` | 49 | ❌ | 0,00 | 49 | ❌ | 0,00 |
| 143 | `qzptLC9Aqb8g93Ap1G4phuzvTSYX9uLcY5eUfPrMRK2jeQq4r` | 44 | ❌ | 0,00 | 54 | ❌ | 0,00 |
| 144 | `qzkvBYvP2xJBnghVx7kfSdKAcn3Ugji4A8DwQ9GDrd9u2ukKZ` | 37 | ❌ | 0,00 | 37 | ❌ | 0,00 |
| 145 | `qzmezXnGAqfFMxVVSP9mQLDQ9iVfFCbhVHfcDLgeEfdqD2BWH` | 36 | ❌ | 0,00 | 36 | ❌ | 0,00 |
| 146 | `qzn2Fz86yYmoMYQ5PQs2GW862874Z8UAwSJJcT91CaxByPJsX` | 35 | ❌ | 0,00 | 38 | ❌ | 0,00 |
| 147 | `qzjqhCKahhXRpLuzBefjT57m6C33CPfJcBtizDFk76vgcAKFv` | 33 | ❌ | 0,00 | 33 | ❌ | 0,00 |
| 148 | `qzjcjgUJpc7AdJyE4JFJCvsWUp2cjoNYjL6Aov52NqV5CmuFE` | 32 | ❌ | 0,00 | 32 | ❌ | 0,00 |
| 148 | `qzoo2z1erAV6UrWvstEYSL5aeTcFH9XK5fk9JyHa8WXt5gF7z` | 32 | ❌ | 0,00 | 32 | ❌ | 0,00 |
| 150 | `qznaQrd9qQcaUYo53HNMvr3KzGhWk4VWh3WPs8HDuFLQ3goK3` | 31 | ❌ | 0,00 | 31 | ❌ | 0,00 |
| 151 | `qzpyGemzsZvXRihgZg1uAGqnQLXBsy213WQGBLDD17hKJ3zpM` | 28 | ❌ | 0,00 | 28 | ❌ | 0,00 |
| 152 | `qzosnG6CiepSxanKYe2jKHoj5DEqkGyXbghYaWKxznTqhWQax` | 27 | ❌ | 0,00 | 27 | ❌ | 0,00 |
| 152 | `qzpqHg6mJ89HkcmoKYmWNfAX5GhNZW1PfqaApJ9cTryKzxW5M` | 27 | ❌ | 0,00 | 27 | ❌ | 0,00 |
| 154 | `qzjtdBwdhUVKtJVi2hatJ3H6XCuEmNxkYCKem5k8se64mz3mE` | 26 | ❌ | 0,00 | 26 | ❌ | 0,00 |
| 155 | `qzocCRD4qnkNXDw44jh46Daw6s76z8PXiwAZvY7Uddc8aKFDr` | 24 | ❌ | 0,00 | 24 | ❌ | 0,00 |
| 156 | `qzmvZ2HK6bEhBpfBhp6hoF9kFJuzWcTzha8UEdsFsXFS7GBHK` | 23 | ❌ | 0,00 | 23 | ❌ | 0,00 |
| 157 | `qznVVeqLCFGbSAhuX44djxRgjxMtVvAsRbNvcmorDAr7izyfW` | 22 | ❌ | 0,00 | 22 | ❌ | 0,00 |
| 158 | `qzjtJj2KQeCYrwqav8uj8WyA3waFxTTf3KMq7kxH12M8YZ6Db` | 21 | ❌ | 0,00 | 21 | ❌ | 0,00 |
| 159 | `qzkwCS3Upayzo7w7r4pHBfvXpR4N4Rn2HjPGFafTidRsqabwT` | 20 | ❌ | 0,00 | 20 | ❌ | 0,00 |
| 160 | `qzmeNN3Ut3nbzMTgUyqZZQFLUMboNtregUYS1y8JXB5P26UQ7` | 18 | ❌ | 0,00 | 18 | ❌ | 0,00 |
| 161 | `qzoFcKVewDKGFMbGVkXNrNoPU4kWw7j67pDjYs9EM3z1o3iN7` | 16 | ❌ | 0,00 | 16 | ❌ | 0,00 |
| 161 | `qzoHLnyZgjfLnGsFnP9uSEL2gMZZDFzkimQyrxm88Z4aw2K97` | 16 | ❌ | 0,00 | 16 | ❌ | 0,00 |
| 161 | `qzpRWSWuWhpsFKyu25XS9VGroZGvntCERUg6TbpF6Ra562nsJ` | 16 | ❌ | 0,00 | 16 | ❌ | 0,00 |
| 164 | `qzkUuwqEMxxGSwfZyrnYveXiMufyMrCsiBzqq8ziGAWcnfU2b` | 15 | ❌ | 0,00 | 15 | ❌ | 0,00 |
| 164 | `qznYt31QkD9wxRfSu1rDBR8qEvr5NyxKTWmYpYtAXCsE1YsCq` | 15 | ❌ | 0,00 | 15 | ❌ | 0,00 |
| 164 | `qzpMoKSt7cD5xQAqAeHk3ezq2t7JCZG3EVFzvHEtXqn5eHn7E` | 15 | ❌ | 0,00 | 15 | ❌ | 0,00 |
| 167 | `qzpA91p9XtvsWLSVufXABgBJded89385xDw7DdGQi7uJcH8ce` | 12 | ❌ | 0,00 | 12 | ❌ | 0,00 |
| 168 | `qzjgL9qpt1QiDQQ1mh2Wkj1YJqs8H4SdYJReuQzTcgwu1aFF6` | 10 | ❌ | 0,00 | 10 | ❌ | 0,00 |
| 168 | `qzoT2pMfp35nzuQDanx1D81eCv6LoKSu8i7vSHRXHQxgLTccR` | 10 | ❌ | 0,00 | 10 | ❌ | 0,00 |
| 170 | `qzpqxLHBnWSit8tPB4pWqr5f1R6dVGrbGaxFkj48gXPRzqA9C` | 9 | ❌ | 0,00 | 9 | ❌ | 0,00 |
| 171 | `qzoL8QqWzpJhSkRfK59FYrKtcsfNUxQ9tXEQWtznKAn64xpje` | 8 | ❌ | 0,00 | 8 | ❌ | 0,00 |
| 171 | `qzpTdiu1jfTHPVqif1b5Vu6GDqUuy81Jxm76oiNQ16f5KZkBQ` | 8 | ❌ | 0,00 | 8 | ❌ | 0,00 |
| 173 | `qzjaWjqE8uocSjv7RaiGRbTeCi9APoHrwPGMS7vPnMtDiuEZ8` | 7 | ❌ | 0,00 | 7 | ❌ | 0,00 |
| 173 | `qzpcRZmNX4suvzHRWcwbj2kqtGrgxTP8n8cPvQYDswsL1Hrtj` | 7 | ❌ | 0,00 | 7 | ❌ | 0,00 |
| 173 | `qzputQrk7ZUQkGNRXBNCCDxrdb8ACQq8xqWrEy433bv3f6CVt` | 7 | ❌ | 0,00 | 7 | ❌ | 0,00 |
| 176 | `qzjwF7pKyWfBcurxx5qtEB7UZyzTrYJvud1BfnamLb6grQX4p` | 5 | ❌ | 0,00 | 5 | ❌ | 0,00 |
| 176 | `qzkjVnqExQRK3SLndRbfi1GT4VdHuroZLeZuuKwnRuAhdmJpg` | 5 | ❌ | 0,00 | 5 | ❌ | 0,00 |
| 178 | `qzm8wqeZgZm7HGYvPFMA8VmgcZq42EVss81H3pRVm7nFcB4An` | 4 | ❌ | 0,00 | 4 | ❌ | 0,00 |
| 178 | `qznA4vcMujFgJdog7CxMsiAhKBr5QdhJh6G2sg6zFkp68oPjJ` | 4 | ❌ | 0,00 | 4 | ❌ | 0,00 |
| 178 | `qzpZMCYUGWX8WC1Fxta3wS9Dm1rGTGbEPHZRtgLmfkeMZqamT` | 4 | ❌ | 0,00 | 4 | ❌ | 0,00 |
| 181 | `qzk8LDsLdUAiCm9sd3nTu444FYhHf2Ho7PUPZLowycRUUru86` | 3 | ❌ | 0,00 | 3 | ❌ | 0,00 |
| 181 | `qzkEd1jkBkoYCnpYkxdwBWfzizVV2txTNtFaZFaKPo86fZkUq` | 3 | ❌ | 0,00 | 3 | ❌ | 0,00 |
| 181 | `qzkHaujm7Y69xc1nd5aMVT7JrTjjX61PQBmtaiNG5849vdQc3` | 3 | ❌ | 0,00 | 3 | ❌ | 0,00 |
| 181 | `qznKrw41msVGkP5VCCBVxzgzTwXVYtiSPMg5ky2re6VF7MLTE` | 3 | ❌ | 0,00 | 3 | ❌ | 0,00 |
| 181 | `qznbtSyvbBezyRyo3P2E3t5aN5pGS36k2wyaYM3SsBX5J4t3v` | 3 | ❌ | 0,00 | 3 | ❌ | 0,00 |
| 181 | `qzndN6KuuwErhK1SHud86KiC9yN16KqNbZj67ZbN3Jbdr4Y8H` | 3 | ❌ | 0,00 | 3 | ❌ | 0,00 |
| 181 | `qzpcj5GQKCTrDj5rJEJQoiQqYtMpui3u87TzWreBNtvtDP1F2` | 3 | ❌ | 0,00 | 3 | ❌ | 0,00 |
| 181 | `qzpxKxU9R9Wr1PTtaby6vw7EPoTxQTShPKmWJWAv3aLrmU7wV` | 3 | ❌ | 0,00 | 3 | ❌ | 0,00 |
| 189 | `qzjpNsNa4ieb8x4i7CixThW6wZE981K9WeLkangcND2mbzJ9d` | 2 | ❌ | 0,00 | 2 | ❌ | 0,00 |
| 189 | `qzk7RfwAxPHAczVqzajyt7upzMLi5UJ85uqaC8eWch3dpQCN9` | 2 | ❌ | 0,00 | 2 | ❌ | 0,00 |
| 189 | `qzmBrewm56oZiQgotE4UKPJohDkneGdBDwH9q36rYmagEwdjj` | 2 | ❌ | 0,00 | 2 | ❌ | 0,00 |
| 189 | `qznokNSfTTmbQFxdMgZAi18oZa4LAFg9p5ENdQqiQHb8Jzxvg` | 2 | ❌ | 0,00 | 2 | ❌ | 0,00 |
| 189 | `qzo1VJSvmRHa547Gamx4HoQT9JeBrgFRTUWghAZWfHqeky1Yq` | 2 | ❌ | 0,00 | 2 | ❌ | 0,00 |
| 189 | `qzo87ZwuKz13ayPzDFQcdzpRK8gArkTWdG7dx3yKQgLxkC4kG` | 2 | ❌ | 0,00 | 2 | ❌ | 0,00 |
| 189 | `qzpEYGQmZ3t6Wovy6eXXiRBAXDvSry5vqGZWP7QhyDsMECNps` | 2 | ❌ | 0,00 | 2 | ❌ | 0,00 |
| 196 | `qzjpv7vUsyBD6qFu4qu8M4beoDdMf242Kqaobz2TJWK6KQSnv` | 1 | ❌ | 0,00 | 1 | ❌ | 0,00 |
| 196 | `qzkMjWpxw1zq3dABct4xCpJjJUdVidoUvpJXAfKaYQqt1ZHex` | 1 | ❌ | 0,00 | 1 | ❌ | 0,00 |
| 196 | `qzkSDCHg2H2neFHNijk6y83Nk7eufKALeu6eLgxp1knVyeb2h` | 1 | ❌ | 0,00 | 1 | ❌ | 0,00 |
| 196 | `qzkwZ8y7TXR8hw4dKsng9YqypR6buTfFtN6y7NRkDgyf6KujU` | 1 | ❌ | 0,00 | 1 | ❌ | 0,00 |
| 196 | `qzmB4sirTy9SbtjG61DvNY5yiW8px9XLHGxo6f9MSLiWyp913` | 1 | ❌ | 0,00 | 1 | ❌ | 0,00 |
| 196 | `qznE1MGLKBzbHnnndbEQ6xSn3XkjMQzyRF6Rm5mrd5mhQN1hT` | 1 | ❌ | 0,00 | 1 | ❌ | 0,00 |
| 196 | `qzp9Wa6EYVMv8fNY2BbegmGAJsP4N3wteqbUF8sgLqkRCSdtj` | 1 | ❌ | 0,00 | 1 | ❌ | 0,00 |
| 196 | `qzpZjBNMYfBMDTQSwP65S5L5q2ZfDZkJLvuH7P8chuN2Xx5X5` | 1 | ❌ | 0,00 | 1 | ❌ | 0,00 |
| 196 | `qzq2XqBesLK7NjPmqputmf7SRuYW7RPL6UCZZAHUYcZc7kbUy` | 1 | ❌ | 0,00 | 1 | ❌ | 0,00 |
| 196 | `qzq591f2rJ7fpf1HCamPdsCDyY7fVhGffMvQXEeWkKbGsrpvn` | 1 | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzm6CnwJ9TzbUgNYz96KuPn8uhPX88iVcuzq4BDS5MXFyWSrw` | 0 (brak w pliku) | ❌ | 0,00 | 10382 | ✅ | 27,73 |
| – | `qznQfUuqj6Thba2E7BmuwDpm3p3kvKP3TH67TP1JbUyuY5WPQ` | 0 (brak w pliku) | ❌ | 0,00 | 8990 | ✅ | 25,81 |
| – | `qzp2AxZw8szXc5qDe1aU8P5kt1dkf1JFYktvV7N6cVbFZrs8L` | 0 (brak w pliku) | ❌ | 0,00 | 6415 | ✅ | 21,80 |
| – | `qzjgD8r9Y7pcCMDofsfxTNns324jYfVkXJX8tfcNcioXC6UGV` | 0 (brak w pliku) | ❌ | 0,00 | 2550 | ✅ | 13,75 |
| – | `qzmacgyM4dsH6bNGMH1Uj9FeBjt8aiUKvpLPfDnujzbT8yv2v` | 0 (brak w pliku) | ❌ | 0,00 | 1694 | ✅ | 11,20 |
| – | `qzjtBnegpL6Z7wZfVbDvaa4yTUmSTveG7yPy4Fmr5oKacTKBW` | 0 (brak w pliku) | ❌ | 0,00 | 1047 | ✅ | 8,81 |
| – | `qzkkdvhKeXA3n7Pz25nXCnemCSokSW2FS3Y37Lok49iY6TXJs` | 0 (brak w pliku) | ❌ | 0,00 | 563 | ✅ | 6,46 |
| – | `qzjY54D5ZKCB2x7pD8mEWpDXiSNh7LqVHKWLC7DdZPTRLCYoX` | 0 (brak w pliku) | ❌ | 0,00 | 533 | ✅ | 6,28 |
| – | `qzneGErbecknvTXMit6D6VMgRuBociBv4zARZqBBmJSHKPgkZ` | 0 (brak w pliku) | ❌ | 0,00 | 424 | ✅ | 5,60 |
| – | `qznfRB1g6G7b3R5tcoEVKE8gL4gNAWeFt3EAqoZXBUuYxb1JN` | 0 (brak w pliku) | ❌ | 0,00 | 355 | ✅ | 5,13 |
| – | `qzjqWhaHUBpoNEpDvKJNijj2g3wQwQNLZ4QFPFi6jsoSSJ4Ji` | 0 (brak w pliku) | ❌ | 0,00 | 352 | ✅ | 5,11 |
| – | `qzoXStD2KSX4FVSdGifx5Mh7xX3AMTb88NMrDsa7Yij3tHAqM` | 0 (brak w pliku) | ❌ | 0,00 | 319 | ✅ | 4,86 |
| – | `qzoGLgUVAp3D44v6uyW9rCXE66PvZGp212UCMJC4TDfqQbZn3` | 0 (brak w pliku) | ❌ | 0,00 | 293 | ✅ | 4,66 |
| – | `qzomKPLex4yGadrC5QWN5tE8g6pmz2yhC6xtK8mgnaGAbFKRv` | 0 (brak w pliku) | ❌ | 0,00 | 200 | ✅ | 3,85 |
| – | `qzjsd5H2stZe471Je5ggNNVvkS3JNpUSKBN9kdWWtVZgMemP6` | 0 (brak w pliku) | ❌ | 0,00 | 179 | ✅ | 3,64 |
| – | `qzoRS1MmqxpNsNX3n5xtKvzm3crT92cUor4rohEYFsyr2X9Z1` | 0 (brak w pliku) | ❌ | 0,00 | 175 | ✅ | 3,60 |
| – | `qzpY7FXvoWiydxjnNr5nVMsXnKRScHV1TaU3axQcxQ9y4Mgwx` | 0 (brak w pliku) | ❌ | 0,00 | 160 | ✅ | 3,44 |
| – | `qzpuU9aLCY4ADvTJUcKYSekciJKSAAS1iTWo6ojrPstiT8njd` | 0 (brak w pliku) | ❌ | 0,00 | 124 | ❌ | 0,00 |
| – | `qzoLVdW7F5ctXwRctfADKUwHUX2qrrLcurSfgKphmLNhx452b` | 0 (brak w pliku) | ❌ | 0,00 | 122 | ❌ | 0,00 |
| – | `qzop6UXMAV7iHjxqKN15FphZhCfMP3agrTmY81LunDi2cPe8R` | 0 (brak w pliku) | ❌ | 0,00 | 113 | ❌ | 0,00 |
| – | `qzmcVNoLNnntGMNFZdqFmCepGG8cMaSyx3x6KRDjgdosrKXfc` | 0 (brak w pliku) | ❌ | 0,00 | 109 | ❌ | 0,00 |
| – | `qzocMXLMfCE4BgLRSm3F3wvxwGQVp2mZKDYLoz4HnmZv5mM9C` | 0 (brak w pliku) | ❌ | 0,00 | 84 | ❌ | 0,00 |
| – | `qzpHtTEYP1aN2uU7L8tLrYEEr2M2jQvw6iTYptFC5c2CJ4DFi` | 0 (brak w pliku) | ❌ | 0,00 | 73 | ❌ | 0,00 |
| – | `qzjd4dnfgngLt6SYYXtSew2ShDE4pbQwVTjG846KXqPR7cHJd` | 0 (brak w pliku) | ❌ | 0,00 | 69 | ❌ | 0,00 |
| – | `qzq9guwguct4nk2ZLjYEoSewngRjQWzaycLCcMcFREkpF6BF1` | 0 (brak w pliku) | ❌ | 0,00 | 64 | ❌ | 0,00 |
| – | `qzjqAgJjNQNPiYGkME3ckZUBPJQzaQ6NuGBeWcycy4hgAbhLa` | 0 (brak w pliku) | ❌ | 0,00 | 62 | ❌ | 0,00 |
| – | `qzkGv6ZPjk7Ud8xRJMoVkWCe1z7yLRm9Xr8Lm8CJtF6gpMnrj` | 0 (brak w pliku) | ❌ | 0,00 | 62 | ❌ | 0,00 |
| – | `qzkScyr5TnSzPqk9swhdkDxnR9GfLauuPrM7m4VwzeXKMEeyi` | 0 (brak w pliku) | ❌ | 0,00 | 58 | ❌ | 0,00 |
| – | `qzo8by8xzwMXtiM5EdXJkVCHWZaRUAAeW9a4wBjMd2bhXd66K` | 0 (brak w pliku) | ❌ | 0,00 | 51 | ❌ | 0,00 |
| – | `qzjgLHKXcmQ8ymqydqV5mLy78Zrh5WMttmNaTJ57E6RNg7S59` | 0 (brak w pliku) | ❌ | 0,00 | 46 | ❌ | 0,00 |
| – | `qznNLnqTs29NULy2hcARG7jKiR9dBE9dQUHDUW8NcCFawybSc` | 0 (brak w pliku) | ❌ | 0,00 | 45 | ❌ | 0,00 |
| – | `qzpueccpWwqZCR29d3KEZcFDJrjej714oKAeJKfdkSKpegd93` | 0 (brak w pliku) | ❌ | 0,00 | 36 | ❌ | 0,00 |
| – | `qzpDs49F2e3MGh37qJtVcJjYAM4w72N16qb6Sbmuxg8qvidPv` | 0 (brak w pliku) | ❌ | 0,00 | 32 | ❌ | 0,00 |
| – | `qzkzD3K2MGRMBgAsdn6kLEi8UyqJPkwHEukxRqydLizQYTjRA` | 0 (brak w pliku) | ❌ | 0,00 | 26 | ❌ | 0,00 |
| – | `qzoqEina5fM8xjZDngxvMwDKTThe6LF3PKstkMfxrAbEyfaEK` | 0 (brak w pliku) | ❌ | 0,00 | 18 | ❌ | 0,00 |
| – | `qzkuH9eaVYFvBoo1KRxmjv8Fdm4kktfStF1NhJCC6Hwdi8mQ1` | 0 (brak w pliku) | ❌ | 0,00 | 15 | ❌ | 0,00 |
| – | `qzmhhFZgG8uVX3eYAK1bepQrjM2nNrb3K8KoWeWkckCQPXT5k` | 0 (brak w pliku) | ❌ | 0,00 | 15 | ❌ | 0,00 |
| – | `qzp36YHutqrinyRMcchk1FULvjEsxBHxnkPgxs5igZZMddYdJ` | 0 (brak w pliku) | ❌ | 0,00 | 13 | ❌ | 0,00 |
| – | `qzjkbA89UvXoK2aTs8bC5faFYfxbuSEtCLKu1aMPBhj5dWEQq` | 0 (brak w pliku) | ❌ | 0,00 | 11 | ❌ | 0,00 |
| – | `qzkwVZWXNmfTqDQVbWi4nfX6MGXR2rPQNuz1bYK47sLSjP8EE` | 0 (brak w pliku) | ❌ | 0,00 | 9 | ❌ | 0,00 |
| – | `qzowUYcSDJY4bmrC6pntbxYnLBLjg4HMw8xbDS2GJ6Jp3WPVH` | 0 (brak w pliku) | ❌ | 0,00 | 9 | ❌ | 0,00 |
| – | `qzpBJ1cfoNRHsGYZ64vD8tCq2qpe465EDgNjYWstmLv9DvhVs` | 0 (brak w pliku) | ❌ | 0,00 | 9 | ❌ | 0,00 |
| – | `qzoqK6e5ioKnyAMvhPTkE1G74yg9he8GCkFQUj8KvxBSazzyu` | 0 (brak w pliku) | ❌ | 0,00 | 8 | ❌ | 0,00 |
| – | `qzph3a9kfWvMsCRPmSZNxtRL13HcA672TtjquKwAkG4j8vUwT` | 0 (brak w pliku) | ❌ | 0,00 | 8 | ❌ | 0,00 |
| – | `qzmv3nzYnPn15PCeaHpiLYPrjNRghS3LMVLSknLyBXsc7QADd` | 0 (brak w pliku) | ❌ | 0,00 | 5 | ❌ | 0,00 |
| – | `qzmKAuEDhBsn6TyQxW4Rz8DJt2cQxcbk5pKLvzPx3Y8weRnpC` | 0 (brak w pliku) | ❌ | 0,00 | 4 | ❌ | 0,00 |
| – | `qzpWh4AEtsgCyEbv4WBgFWnB9bcdF2L2jVDuyjXP9mSTyBaeU` | 0 (brak w pliku) | ❌ | 0,00 | 4 | ❌ | 0,00 |
| – | `qzjcjKHUNpXWEwvDFN4GmWv7XCBTN9MSvFxJ7FKKuB16aZkUf` | 0 (brak w pliku) | ❌ | 0,00 | 3 | ❌ | 0,00 |
| – | `qznh4DpCj4SxEqBmQ7D7ET4sXBKKKP9erCKBjuHvhCRkemoie` | 0 (brak w pliku) | ❌ | 0,00 | 3 | ❌ | 0,00 |
| – | `qzo2imFf14Lj2LAVBASdBDZjNqkwQ8LY4JVxysGDZdt9ifzFe` | 0 (brak w pliku) | ❌ | 0,00 | 3 | ❌ | 0,00 |
| – | `qzoN5xTqqdGZoEiCw8vcdCQP34yGJ34yiv3rwKTGJDLZfRDfb` | 0 (brak w pliku) | ❌ | 0,00 | 3 | ❌ | 0,00 |
| – | `qzoyvDv6NAEMF4vvrxKuBqs3SUzVX5EqSqhLR14F9irPCYnwL` | 0 (brak w pliku) | ❌ | 0,00 | 3 | ❌ | 0,00 |
| – | `qzpMSujbKswqji22m2mUADwcg8aXBmFYNH8hAdcNQYzj9Gsqf` | 0 (brak w pliku) | ❌ | 0,00 | 3 | ❌ | 0,00 |
| – | `qzkQ9gACNnHTxxxcS3gtAQqLQgzs3jW7KDVhdGthzHbRMLg5U` | 0 (brak w pliku) | ❌ | 0,00 | 2 | ❌ | 0,00 |
| – | `qzkwo11o6q6hmrwtLLSEMqMpwDEiZ3crRMPs6UqtBnXCCzhWz` | 0 (brak w pliku) | ❌ | 0,00 | 2 | ❌ | 0,00 |
| – | `qzmRGyGtrUoV7s9zGR48ktQPhv1EZQ8hLLQHseecsbW3rKzWM` | 0 (brak w pliku) | ❌ | 0,00 | 2 | ❌ | 0,00 |
| – | `qznaK69ZYPxcQPWk7TjHxXYZFW1wZUW72DXZ3hDqN9PryrTcZ` | 0 (brak w pliku) | ❌ | 0,00 | 2 | ❌ | 0,00 |
| – | `qzoJsk6JA2DoScNVV8uBu9DXb2jyLAGpZcJdSgFt6ofyeYLj8` | 0 (brak w pliku) | ❌ | 0,00 | 2 | ❌ | 0,00 |
| – | `qzor66NoNda8JV9fMWseqLwerXxzvwyrnw76mu3ZFZc6tbtAY` | 0 (brak w pliku) | ❌ | 0,00 | 2 | ❌ | 0,00 |
| – | `qzpCtRDY4bUVbZbqPkxvEDtTZyMvW99Bj7dBEPLx46PeGDbgn` | 0 (brak w pliku) | ❌ | 0,00 | 2 | ❌ | 0,00 |
| – | `qzphJiGVx7v5Met71QRmnjTzyNKqZdH5kAmSgCAjK7mLuEBps` | 0 (brak w pliku) | ❌ | 0,00 | 2 | ❌ | 0,00 |
| – | `qzk9WB2VZTo68WTrxH92Yq7xzkgT5Xb1WgXRFWmSCK76vq81o` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzkLhFaPi9jUKSEogaqsiCP7SKWY7srTpr9DTHs1TDrSPMpd7` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzkdXpWnHBRHtfKjNtpo8z9sqrZJi5EcqiS8bB8ESeyEJMgVQ` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzkpPJ9aQdMJ5E3q6HE4jwU4GuoTsSkJLSMVC3WQSsfgM9Q47` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzksmWB5RS9iiHnK6ib4DvL9Jnnrp6mng67bC2G3h31LfFLBR` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzktf6z3bvaUy2rpzH8M98xApzJMgbb6ZZ3DjSdcn4iwX1bEJ` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzoWsrEiqi6B5J2LMv21V8voGWYsJ3EyoMLmCJsUx9x5KyLjU` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzoxgePFRns3JiCuuJrfesytEttr2rA2aVR1oTR6MSfXTv9dT` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzp1JHEUCtRWwWEn2FRJS1Qh6BLeXGZVreH6VyBsV8vJisma6` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzp4hMveNcHCRrP3tEKCsU32gMXQfZNmSoPXBnuJaqf98suNt` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzpycqZHBaMk6MvnF5sPGUYcYdqrtqMsP4zYLb8brsAYsVRvG` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| – | `qzq1UjpTiqZHdu5fpivHL5ZTCCzemK7yC7uRzp5af45WBANSH` | 0 (brak w pliku) | ❌ | 0,00 | 1 | ❌ | 0,00 |
| | **Razem** | 957240 | 102 | **2 500,00** | 1086155 | 139 | **2 500,00** |

Wiersze z miejscem „–” na końcu tabeli (73) to adresy, których nie ma w pliku z 23.08.2026: zaczęły kopać Plancka później. Liczą się tylko w wariancie „09.09”.

## 9. Źródła i samodzielne sprawdzenie

| Testnet | Plik (surowy) | Ostatni commit | git blob SHA-1 |
|---|---|---|---|
| Resonance | https://raw.githubusercontent.com/Quantus-Network/task-master/main/testnet_data_snapshots/resonance_network_miners.json | 2025-11-04 07:21 UTC | `c5fadaffcb56c625a54a7a1316a21f19bc836888` |
| Schrödinger | https://raw.githubusercontent.com/Quantus-Network/task-master/main/testnet_data_snapshots/schrodinger_miners.json | 2025-11-04 07:21 UTC | `34b472d93e837713ea5570ffe330a77b35884b24` |
| Dirac | https://raw.githubusercontent.com/Quantus-Network/task-master/main/testnet_data_snapshots/dirac_miners.json | 2026-04-15 02:54 UTC | `61395f476084cd5009445479adb6bcff7b250910` |
| Planck | https://raw.githubusercontent.com/Quantus-Network/task-master/main/testnet_data_snapshots/planck_miners.json | 2026-08-23 08:56 UTC | `174ab14eb19a6e7b3d494dbe6567d588cc9a985b` |

Jeśli git blob pliku na GitHubie (API: `GET /repos/Quantus-Network/task-master/contents/testnet_data_snapshots`, pole `sha`) jest inny niż w tabeli, zespół zmienił dane i ten plik jest nieaktualny.

Poniższy skrypt (Python 3, bez dodatkowych bibliotek) pobiera oficjalne pliki i liczy nagrodę dla podanych adresów tym samym wzorem. Nie potrzebuje żadnych kluczy.

```python
#!/usr/bin/env python3
# Użycie: python3 airdrop_check.py qzADRES1 qzADRES2 ...
import json, math, sys, urllib.request
RAW = "https://raw.githubusercontent.com/Quantus-Network/task-master/main/testnet_data_snapshots/"
PLIKI = {"Resonance": "resonance_network_miners.json", "Schrödinger": "schrodinger_miners.json", "Dirac": "dirac_miners.json", "Planck": "planck_miners.json"}
adresy, razem = sys.argv[1:], 0.0
for tn, plik in PLIKI.items():
    with urllib.request.urlopen(RAW + plik, timeout=60) as r:
        bloki = {g["id"]: g["totalMinedBlocks"] for g in json.load(r)["data"]["minerStats"]}
    lista = sorted(bloki.items(), key=lambda kv: (-kv[1], kv[0]))
    k = len(lista) // 2                               # top 50%, zaokrąglone w dół
    s = sum(math.sqrt(n) for _, n in lista[:k])        # S z sekcji 3
    top = {a for a, _ in lista[:k]}
    for a in adresy:
        if a in bloki:
            qtc = 2500 * math.sqrt(bloki[a]) / s if a in top else 0.0
            razem += qtc
            print(f"{tn:12} {a} bloki={bloki[a]:>6} top50={a in top} QTC={qtc:.2f} (próg {lista[k-1][1]})")
print(f"Razem: {razem:.2f} QTC")
```

Plik wygenerowany skryptem `build_wyliczenia.py` z publicznych danych pobranych 2026-09-11 13:03 UTC. Nie zawiera żadnych seedów, kluczy ani danych osobowych.
