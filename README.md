# vigiar — Dados do Rio de Janeiro

[![R-CMD-check](https://github.com/santosry/vigiar-download/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/santosry/vigiar-download/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R >= 4.0.0](https://img.shields.io/badge/R-%3E%3D%204.0.0-blue.svg)](https://cran.r-project.org/)

Download e processamento dos dados do [VIGIAR](https://app.powerbi.com/view?r=eyJrIjoiNmRhODQwNzItNThlOS00ZmQ4LWJjZmItZDYxOTNhOTRmYmFhIiwidCI6IjlhNTU0YWQzLWI1MmItNDg2Mi1hMzZmLTg0ZDg5MWU1YzcwNSJ9)
(Vigilancia em Saude Ambiental — Ministerio da Saude) com **foco no estado do Rio de Janeiro**.

---

## Instalacao

```r
remotes::install_github("santosry/vigiar-download")
```

**Dependencias**: `httr2`, `jsonlite`, `dplyr`, `tibble` · **R >= 4.0.0**

## Exemplo: Rio de Janeiro

```r
library(vigiar)
library(dplyr)
library(ggplot2)

vigiar_conectar()

# Opcao 1: Baixar tudo filtrado para RJ
rj <- vigiar_baixar_rj()
rj$df_muni  # 92 municipios do RJ

# Opcao 2: Baixar uma tabela especifica com filtro
pm25 <- vigiar_baixar("df_anual", uf = "RJ") |>
  process_vigiar(tabela = "df_anual")

# PM2.5 medio por ano no RJ
pm25 |>
  group_by(ano) |>
  summarise(pm25_medio = mean(pm25_media_anual, na.rm = TRUE)) |>
  ggplot(aes(ano, pm25_medio)) +
  geom_line(color = "darkred", linewidth = 1) + geom_point() +
  labs(title = "PM2.5 medio — Rio de Janeiro",
       y = expression(PM[2.5] ~ (mu*g/m^3))) +
  theme_minimal()

vigiar_exportar_csv(pm25, "pm25_rj.csv")
vigiar_desconectar()
```

## Funcoes

| Funcao | Descricao |
|--------|-----------|
| `vigiar_conectar()` | Conecta ao dashboard Power BI |
| `vigiar_desconectar()` | Encerra a sessao |
| `vigiar_baixar(tabela, uf, limite)` | Baixa uma tabela (filtro por UF opcional) |
| `vigiar_baixar_rj()` | Atalho: baixa todas as tabelas filtradas para RJ |
| `vigiar_baixar_tudo(tabelas, delay)` | Baixa multiplas tabelas |
| `vigiar_tabelas()` | Lista tabelas disponiveis |
| `vigiar_esquema(tabela)` | Mostra colunas e tipos |
| `vigiar_info()` | Catalogo com descricoes |
| `process_vigiar(dados, tabela)` | Dispatcher: processa e padroniza |
| `process_pm25(dados)` | Padroniza dados de PM2.5 |
| `process_indicadores_saude(dados)` | Padroniza indicadores de saude |
| `vigiar_checar_dados(dados)` | Diagnostico de qualidade |
| `vigiar_resumo(x)` | Resumo descritivo |
| `vigiar_serie_temporal(dados)` | Serie temporal por ano |
| `vigiar_dicionario()` | Dicionario de variaveis |
| `vigiar_variaveis(dominio)` | Variaveis por dominio |
| `vigiar_exportar_csv(dados, path)` | Exporta para CSV |
| `vigiar_exportar_rds(dados, path)` | Exporta para RDS |

## Municipios disponiveis

```r
vigiar_conectar()
muni <- vigiar_baixar("df_muni", uf = "RJ")
# 92 municipios do Rio de Janeiro
```

## Fonte

Ministerio da Saude — VIGIAR (Vigilancia em Saude Ambiental).
Dashboard publico via Power BI "Publish to Web".

## IA Disclosure

DeepSeek v4 Pro e ChatGPT GPT-5.5 para revisao de codigo e documentacao.
Veja `AI_USE_DECLARATION.md`.

## Licenca

MIT © Ryan Santos
