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

## Exemplo completo

```r
library(vigiar)
library(dplyr)
library(ggplot2)

# 1. Conectar ao dashboard
vigiar_conectar()

# 2. Explorar o catalogo
vigiar_info()
vigiar_esquema("df_anual")

# 3. Baixar e processar dados
pm25 <- vigiar_baixar("df_anual") |>
  process_pm25()

saude <- vigiar_baixar("tb_brasil") |>
  process_indicadores_saude(agregacao = "brasil")

indoor <- vigiar_baixar("df_indoor") |>
  process_exposicao_indoor()

# 4. Validar dados
vigiar_checar_dados(pm25, "df_anual")

# 5. Resumos descritivos
vigiar_resumo_pm25(pm25)

# 6. Serie temporal (nacional)
serie <- vigiar_serie_temporal(pm25, nivel = "nacional")

# 7. Tendencia descritiva
tendencia <- vigiar_tendencia_descritiva(pm25)

# 8. Grafico simples
pm25 |>
  group_by(ano) |>
  summarise(pm25_medio = mean(pm25_media_anual, na.rm = TRUE)) |>
  ggplot(aes(ano, pm25_medio)) +
  geom_line() + geom_point() +
  labs(title = "PM2.5 medio no Brasil", y = expression(PM[2.5] ~ (mu*g/m^3))) +
  theme_minimal()

# 9. Exportar
vigiar_exportar_csv(pm25, "pm25_anual.csv")

# 10. Consultar dicionario
vigiar_variaveis("pm25")
vigiar_descrever_variavel("pm25", "pm25_media_anual")

# 11. Validar schema
vigiar_validar_dicionario()

# 12. Encerrar
vigiar_desconectar()
```

## Funções

### Conexão
| Função | Descrição |
|--------|-----------|
| `vigiar_conectar(refresh, timeout)` | Estabelece sessão com o Power BI |
| `vigiar_desconectar()` | Encerra a sessão e limpa cache |
| `vigiar_sessao_ativa()` | TRUE se há sessão ativa |
| `vigiar_status()` | Dashboard online? Schema consistente? |

### Download
| Função | Descrição |
|--------|-----------|
| `vigiar_tabelas()` | Lista as 32 tabelas |
| `vigiar_info()` | Catálogo com descrições e categorias |
| `vigiar_esquema(tabela)` | Colunas e tipos de uma tabela |
| `vigiar_baixar(tabela, colunas, limite)` | Baixa uma tabela |
| `vigiar_baixar_tudo(tabelas, delay)` | Baixa múltiplas tabelas |
| `vigiar_baixar_principais()` | Atalho: 14 tabelas principais |

### Processamento
| Função | Descrição |
|--------|-----------|
| `process_vigiar(dados, tabela)` | Dispatcher automático |
| `process_pm25(dados, tipo)` | PM2.5 (anual/mensal/dias) |
| `process_populacao_exposta(dados)` | População por categoria |
| `process_indicadores_saude(dados, agregacao)` | Indicadores (brasil/uf/municipio) |
| `process_fracao_atribuivel(dados)` | Fração atribuível |
| `process_exposicao_indoor(dados, tipo)` | Exposição indoor |
| `process_municipios(dados)` | Cadastro de municípios |
| `process_ufs(dados)` | Dados agregados por UF |

### Validação
| Função | Descrição |
|--------|-----------|
| `vigiar_padronizar_colunas(dados, tabela)` | Padroniza nomes |
| `vigiar_validar_ibge(dados)` | Códigos IBGE (110001–530010) |
| `vigiar_validar_datas(dados)` | Anos (2000+) e meses (1–12) |
| `vigiar_validar_unidades(dados)` | PM2.5 (0–1000 µg/m³) |
| `vigiar_checar_dados(dados, tabela)` | NAs, duplicatas, tipos |
| `vigiar_diagnostico(amostra)` | Amostra + diagnostica tudo |

### Resumos e Séries
| Função | Descrição |
|--------|-----------|
| `vigiar_resumo(x)` | S3 genérico |
| `vigiar_resumo_pm25(x)` | Média, DP, percentis PM2.5 |
| `vigiar_resumo_saude(x)` | Nº indicadores, desfechos |
| `vigiar_resumo_populacao(x)` | Pop total, cobertura |
| `vigiar_resumo_fracao_atribuivel(x)` | Média, min, max fração |
| `vigiar_resumo_indoor(x)` | Média, min, max indoor |
| `vigiar_serie_temporal(dados, nivel)` | Agrega por ano |
| `vigiar_tendencia_descritiva(dados)` | Variação anual + média móvel |
| `vigiar_agregar_tempo(dados, agregar_por)` | Agregação flexível |

### Dicionário
| Função | Descrição |
|--------|-----------|
| `vigiar_dicionario()` | 67 variáveis documentadas |
| `vigiar_variaveis(dominio)` | Filtra por domínio |
| `vigiar_descrever_variavel(dominio, var)` | Detalhes de uma variável |
| `vigiar_schema(dominio)` | Schema resumido |
| `vigiar_convencoes()` | Abre página de convenções |
| `vigiar_tabelas_documentadas()` | Tabelas no dicionário |
| `vigiar_variaveis_nao_documentadas()` | Variáveis órfãs |
| `vigiar_variaveis_orfas()` | Documentadas mas ausentes |
| `vigiar_validar_dicionario()` | Relatório de cobertura |
| `vigiar_comparar_schema()` | Live vs documentado |

### Exportação
| Função | Descrição |
|--------|-----------|
| `vigiar_exportar_csv(dados, caminho)` | CSV (UTF-8) |
| `vigiar_exportar_rds(dados, caminho)` | RDS (preserva metadados) |
| `vigiar_exportar_parquet(dados, caminho)` | Parquet (requer arrow) |

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
