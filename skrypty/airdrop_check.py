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
