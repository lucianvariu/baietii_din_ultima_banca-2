# Proiect ASM - Prelucrare sir de octeti

Salut! Acesta este proiectul nostru pentru laboratorul de Arhitectura Sistemelor de Calcul. Practic, am facut un program in asamblare (8086) care ia niste numere de la tastatura si le proceseaza in fel si chip (sortare, calcule pe biti, rotiri).

## Cine a lucrat (Echipa)
* **Student 1 (Luci):** S-a ocupat de citirea datelor si transformarea din text in numere (ASCII -> Hex).
* **Student 2 (Ionut):** A facut calculele pentru cuvantul de control C si partea de rotire a bitilor.
* **Student 3 (Rares):** A facut sortarea, statistica (gasirea maximului) si a legat totul la final.

## Ce face programul
1. **Citeste:** Iti cere un sir de 8-16 numere hexazecimale.
2. **Calculeaza:** Genereaza un numar "C" pe baza unor operatii logice (XOR, OR) si sume.
3. **Sorteaza:** Aranjeaza numerele descrescator (folosind Bubble Sort).
4. **Analizeaza:** Gaseste care numar are cei mai multi biti de 1 si iti zice pe ce pozitie e.
5. **Roteste:** La final, amesteca bitii fiecarui numar printr-o rotire la stanga.

## Cum il rulezi
Ai nevoie de TASM si DOSBox. Comenzile sunt clasice:

```bash
tasm /zi proiect
tlink /v proiect
td proiect
