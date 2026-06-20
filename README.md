# vigiar

<!-- badges: start -->
[![R-CMD-check](https://github.com/santosry/vigiar-download/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/santosry/vigiar-download/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/santosry/vigiar-download/branch/main/graph/badge.svg)](https://app.codecov.io/gh/santosry/vigiar-download)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R >= 4.0.0](https://img.shields.io/badge/R-%3E%3D%204.0.0-blue.svg)](https://cran.r-project.org/)
<!-- badges: end -->

Download automatizado de **todos os dados** do dashboard
[VIGIAR](https://app.powerbi.com/view?r=eyJrIjoiNmRhODQwNzItNThlOS00ZmQ4LWJjZmItZDYxOTNhOTRmYmFhIiwidCI6IjlhNTU0YWQzLWI1MmItNDg2Mi1hMzZmLTg0ZDg5MWU1YzcwNSJ9)
(Vigilância em Saúde Ambiental — Ministério da Saúde) para o R.

---

## Sobre o VIGIAR

O VIGIAR é o sistema de vigilância em saúde ambiental do Ministério da
Saúde. O dashboard público fornece **32 tabelas** abrangendo:

- **Qualidade do Ar**: PM2.5 anual/mensal por município, dias acima dos
  limites OMS e CONAMA
- **População Exposta**: população por faixa de concentração de PM2.5
- **Indicadores de Saúde**: fração atribuível, óbitos, internações por
  doenças respiratórias, cardiovasculares, AVC e câncer de pulmão
- **Exposição Indoor**: combustíveis sólidos em domicílios e desfechos
  de saúde associados

## Instalação

```r
# install.packages("remotes")
remotes::install_github("santosry/vigiar-download")
```

**Dependências**: `httr2`, `jsonlite`, `tibble` · **R ≥ 4.0.0**

## Uso rápido

```r
library(vigiar)

# Conectar e explorar
vigiar_conectar()
vigiar_info()         # catálogo com descrições e categorias

# Baixar dados
pm25 <- vigiar_baixar("df_anual")         # qualidade do ar
saude <- vigiar_baixar("tb_brasil")        # indicadores de saúde
indoor <- vigiar_baixar("df_indoor")       # exposição indoor

# Baixar tudo de uma vez
tudo <- vigiar_baixar_principais()
```

## Funções

| Função | Descrição |
|--------|-----------|
| `vigiar_conectar()` | Estabelece sessão anônima com o Power BI |
| `vigiar_desconectar()` | Encerra a sessão |
| `vigiar_sessao_ativa()` | Verifica se há sessão ativa |
| `vigiar_status()` | Verifica se o dashboard está online |
| `vigiar_tabelas()` | Lista todas as 32 tabelas |
| `vigiar_info()` | Catálogo com descrições e categorias |
| `vigiar_esquema(tabela)` | Mostra colunas e tipos |
| `vigiar_baixar(tabela, ...)` | Baixa uma tabela |
| `vigiar_baixar_tudo(tabelas)` | Baixa múltiplas tabelas |
| `vigiar_baixar_principais()` | Baixa 14 tabelas principais |
| `vigiar_checar_dados(dados)` | Diagnóstico de qualidade |
| `vigiar_diagnostico()` | Amostra e diagnostica todas as tabelas |

## Catálogo de dados

```r
> vigiar_info()
# A tibble: 32 × 4
   tabela       colunas descricao                              categoria
   <chr>          <int> <chr>                                  <chr>
 1 df_anual           6 Médias anuais PM2.5                    Qualidade do Ar
 2 df_mensal         20 Médias mensais PM2.5 (LAT/LON)         Qualidade do Ar
 3 df_dias            7 Dias acima do limite OMS               Qualidade do Ar
 4 df_dias_conama     5 Dias acima do limite CONAMA            Qualidade do Ar
 5 tb_brasil          8 Indicadores de saúde — Brasil          Indicadores de Saúde
 6 tb_uf              8 Indicadores de saúde — UF              Indicadores de Saúde
 7 tb_muni           12 Indicadores de saúde — Município       Indicadores de Saúde
 8 tb_fracao          9 Fração atribuível                      Indicadores de Saúde
 9 tb_quartis         5 Quartis dos indicadores                Indicadores de Saúde
10 df_indoor         10 Exposição indoor (combustíveis)        Exposição Indoor
...
```

## Como funciona

O pacote implementa o protocolo da API Power BI "Publish to Web":

1. **Sessão**: `GET` na página do dashboard → cookies + `telemetrySessionId`
2. **Schema**: `GET /conceptualschema` → 32 tabelas e colunas
3. **Query**: `POST /querydata` com JSON SemanticQuery → resposta DSR
4. **Parser**: decodifica ValueDicts + DM0 array + referências R → tibble

Inclui retry com backoff exponencial para falhas transitórias e
validação de schema.

## Uso responsável

- Os dados são públicos e anonimizados. Não há dados pessoais.
- O pacote não armazena credenciais nem tokens persistentes.
- Respeite a disponibilidade do serviço: evite downloads repetidos
  desnecessários. Prefira cache local.

## Fonte dos dados

Ministério da Saúde do Brasil — VIGIAR (Vigilância em Saúde Ambiental).
Dashboard público via Power BI "Publish to Web".

## Citação

```r
citation("vigiar")
```

## IA Disclosure

Este pacote utilizou DeepSeek v4 Pro e ChatGPT GPT-5.5 para revisão
de código, refatoração, documentação e testes. Todas as decisões foram
revisadas pelo autor humano. Veja [AI_USE_DECLARATION.md](AI_USE_DECLARATION.md).

## Licença

MIT © Ryan Santos · Dados: Ministério da Saúde / VIGIAR
