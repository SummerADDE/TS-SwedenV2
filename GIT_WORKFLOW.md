# Git Workflow för TS-SwedenV2

## Branch-struktur

- `main`
  - Produktionsklar kod.
  - Ska alltid vara stabil och refaire.
- `develop`
  - Utvecklingsgren för integration av nya funktioner.
  - Används som bas för feature branches.
- `feature/<beskrivning>`
  - Enskilda arbetsgrenar för specifika ändringar, t.ex. `feature/sync-setup`.
  - Skapas från `develop` och slås ihop tillbaka med en Pull Request eller merge.
- `hotfix/<beskrivning>`
  - Snabba fixar som behövs direkt på `main`.

## Rekommenderad arbetsflöde

1. Hämta senaste ändringar:
   ```powershell
   git checkout develop
   git pull origin develop
   ```
2. Skapa en feature branch:
   ```powershell
   git checkout -b feature/<beskrivning>
   ```
3. Arbeta och committa ofta.
4. Slå ihop till `develop` när klar:
   ```powershell
   git checkout develop
   git merge feature/<beskrivning>
   ```
5. När `develop` är stabil, slå ihop till `main`.

## Lokala brancher i detta repo

- `main` (existerar)
- `develop` (rekommenderas att skapa som arbetsgren)

## Synkronisering med fjärrrepo

- `origin` pekar mot `https://github.com/SummerADDE/TS-SwedenV2.git`
- Du kan pusha lokala brancher till `origin` med:
  ```powershell
  git push origin develop
  ```

## Notera

Eftersom `TS-SwedenV2` är ett GitHub-klonat repo är det bra att arbeta i feature-brancher och undvika att göra större ändringar direkt på `main`.
