# vigiar

<!-- badges: start -->
[![R-CMD-check](https://github.com/santosry/vigiar/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/santosry/vigiar/actions/workflows/R-CMD-check.yaml)
[![lint](https://github.com/santosry/vigiar/actions/workflows/lint.yaml/badge.svg)](https://github.com/santosry/vigiar/actions/workflows/lint.yaml)
[![pkgdown](https://github.com/santosry/vigiar/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/santosry/vigiar/actions/workflows/pkgdown.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R >= 4.1.0](https://img.shields.io/badge/R-%3E%3D%204.1.0-blue.svg)](https://www.r-project.org/)
<!-- badges: end -->

Pacote R para download, processamento, validação e diagnóstico dos dados do
[VIGIAR](https://app.powerbi.com/view?r=eyJrIjoiNmRhODQwNzItNThlOS00ZmQ4LWJjZmItZDYxOTNhOTRmYmFhIiwidCI6IjlhNTU0YWQzLWI1MmItNDg2Mi1hMzZmLTg0ZDg5MWU1YzcwNSJ9)
(Vigilância em Saúde Ambiental) do Ministério da Saúde. Foco no estado do
Rio de Janeiro, com 92 municípios e 9 macrorregiões de saúde (SES-RJ).

**vigiar desconfia dos dados antes de seduzir o pesquisador com gráficos.**

## Instalação

```r
# Instalar do GitHub
devtools::install_github("santosry/vigiar")
```

Dependências: `httr2`, `jsonlite`, `tibble`, `dplyr`, `cli`, `openssl`.

## Exemplo rápido (20 linhas)

```r
library(vigiar)
library(dplyr)

# 1. Conectar
vigiar_conectar()

# 2. Baixar dados do RJ
pm25 <- vigiar_baixar_rj("df_anual")

# 3. Processar e validar
pm25 <- process_pm25(pm25, tipo = "anual")

# 4. Diagnosticar qualidade
diag <- vigiar_diagnosticar_serie(pm25)
vigiar_relatorio_diagnostico(diag)

# 5. Agregar por ano
tendencia <- vigiar_serie_temporal(pm25, nivel = "nacional")
print(tendencia)

# 6. Auditoria completa
audit <- vigiar_auditar(pm25, tabela = "df_anual")
print(audit)

# 7. Snapshot para reprodutibilidade
snap <- vigiar_snapshot(dados = pm25, tabela = "df_anual")
vigiar_salvar_snapshot(snap, "pm25_rj_2026.rds")

vigiar_desconectar()
```

## Funcionalidades principais

### Download

```r
# Listar tabelas disponíveis
vigiar_tabelas()

# Ver schema de uma tabela
vigiar_esquema("df_anual")

# Baixar tabela com filtro RJ
pm25 <- vigiar_baixar_rj("df_anual")
# Usa estratégia particionada (ASC + DESC) para cobrir todo o range

# Baixar várias tabelas
tudo <- vigiar_baixar_principais()

# Download com cache local (reusa por 24h)
vigiar_cache_dir("~/vigiar_cache")
dados <- vigiar_baixar_com_cache("df_anual")
```

### Processamento e validação

```r
# Padronizar nomes de colunas
pm25 <- process_pm25(dados, tipo = "anual")
# Converte muni→cod_municipio, UF→sigla_uf, Media_pm25→pm25_media_anual

# Validar códigos IBGE
vigiar_validar_ibge(pm25, col_codigo = "cod_municipio")

# Validar datas
vigiar_validar_datas(pm25)

# Checar dados completos
vigiar_checar_dados(pm25, tabela = "df_anual")
```

### Diagnóstico (v0.7.0)

```r
# Diagnóstico completo de série temporal
diag <- vigiar_diagnosticar_serie(pm25)

# Severidade: ok | aviso | problema | crítico
diag$severidade

# Relatório detalhado
vigiar_relatorio_diagnostico(diag)

# Checks individuais
vigiar_checar_ibge(diag, pm25, "cod_municipio")
vigiar_checar_pm25(diag, pm25, "pm25_media_anual")
vigiar_checar_duplicatas(diag, pm25, "cod_municipio", "ano")
vigiar_checar_quebra_serie(diag, pm25, "cod_municipio", "ano", "pm25_media_anual")
vigiar_checar_cobertura_temporal(diag, pm25, "ano")
vigiar_checar_cobertura_espacial(diag, pm25, "cod_municipio", uf = "RJ")
```

### Séries temporais e agregação

```r
# Agregar por ano
anual <- vigiar_agregar_tempo(pm25, agregar_por = "ano",
  variavel = "pm25_media_anual",
  funcoes = list(media = mean, dp = sd, n = length))

# Tendência descritiva
tend <- vigiar_tendencia_descritiva(pm25, variavel = "pm25_media_anual")
# Retorna: ano, media, variacao_anual (%), media_movel

# Série temporal por UF
uf_series <- vigiar_serie_temporal(pm25, nivel = "uf")
```

### Rio de Janeiro

```r
# 92 municípios com macrorregiões de saúde
rj <- vigiar_rj_municipios()

# 9 macrorregiões
vigiar_rj_macrorregioes()

# Agregar por macrorregião
resumo <- vigiar_rj_resumo(pm25, agregacao = "macrorregiao")

# Validar se dados contêm apenas RJ
vigiar_validar_rj(pm25)
```

### Auditoria e compliance

```r
# Auditoria completa
audit <- vigiar_auditar(pm25, tabela = "df_anual")
print(audit)
# Schema, IBGE, temporal, unidades, cobertura, checksums

# Múltiplos perfis de compliance
comp <- vigiar_compliance_check(pm25, tabela = "df_anual",
  profiles = c("basico", "rigoroso", "rj", "corrupcao"))

# Checksum determinístico (SHA256)
vigiar_checksum(pm25)

# Exportar auditoria em JSON
vigiar_exportar_auditoria(audit, "auditoria_pm25.json")
```

### Benchmark

```r
# Comparar estratégias de download
bench <- vigiar_benchmark("df_anual",
  strategies = c("direct", "year_asc_desc", "minimal_columns"),
  repeticoes = 3)

# Benchmark multi-tabela
vigiar_benchmark_tabelas(c("df_anual", "df_mensal", "pop"))

# Health check completo
vigiar_health_check()
```

### Logging

```r
# Visualizar log de operações
vigiar_log()

# Resumo do log
vigiar_resumo_log()

# Histórico de downloads
vigiar_historico_downloads()

# Exportar log
vigiar_exportar_log("log_operacoes.json")
```

### Snapshots e reprodutibilidade

```r
# Criar snapshot com checksum
snap <- vigiar_snapshot(dados = pm25, tabela = "df_anual")

# Verificar integridade
vigiar_verificar_snapshot(snap)  # TRUE/FALSE

# Salvar e carregar
vigiar_salvar_snapshot(snap, "snapshot.rds")
snap2 <- vigiar_carregar_snapshot("snapshot.rds")

# Comparar duas versões
diffs <- vigiar_comparar_snapshots(snap, snap2)

# Congelar schema para detectar mudanças
vigiar_esquema_lock("schema_lock.json")
vigiar_esquema_verificar("schema_lock.json")
```

### Exportação

```r
vigiar_exportar_csv(pm25, "pm25_rj.csv")
vigiar_exportar_rds(pm25, "pm25_rj.rds")  # Preserva metadata
vigiar_exportar_parquet(pm25, "pm25_rj.parquet")  # Requer arrow
```

### Dicionário

```r
# Dicionário completo
dict <- vigiar_dicionario()

# Variáveis de um domínio
vigiar_variaveis("pm25")
vigiar_variaveis("indicadores_saude")

# Descrever uma variável
vigiar_descrever_variavel("pm25", "pm25_media_anual")

# Abrir página de convenções
vigiar_convencoes()
```

## Tabelas disponíveis

| Tabela | Descrição | Categoria |
|--------|-----------|-----------|
| `df_anual` | Médias anuais PM2.5 | Qualidade do Ar |
| `df_mensal` | Médias mensais PM2.5 | Qualidade do Ar |
| `df_dias` | Dias críticos (OMS) | Qualidade do Ar |
| `df_dias_conama` | Dias críticos (CONAMA) | Qualidade do Ar |
| `pop` | População exposta | População |
| `df_muni` | Cadastro de municípios | Cadastro |
| `tb_brasil` | Indicadores Brasil | Saúde |
| `tb_uf` | Indicadores por UF | Saúde |
| `tb_muni` | Indicadores por município | Saúde |
| `tb_fracao` | Fração atribuível | Saúde |
| `tb_quartis` | Quartis | Saúde |
| `df_indoor` | Exposição indoor | Indoor |
| `df_indoor_desfecho` | Desfechos indoor | Indoor |
| `medidas` | Medidas calculadas | Medidas |

Use `vigiar_info()` para catálogo completo com descrições e categorias.

## Limitações

- **API Power BI**: limita respostas a ~30K linhas. Use `vigiar_baixar_rj()` para
  tabelas grandes (download ASC + DESC particionado).
- **Schema instável**: o dashboard pode mudar sem aviso. Use `vigiar_esquema_lock()`
  para congelar e `vigiar_status()` para verificar.
- **Cobertura**: nem todos os 92 municípios do RJ têm dados em todos os anos.
- **Dados secundários**: o pacote baixa dados públicos, não os gera. Validação é
  obrigatória antes de qualquer análise.
- **Inferência causal**: baixar dados não é modelar. O pacote prepara dados;
  modelos (GAM, DLNM) devem ser feitos externamente.
- **Dependência externa**: o pacote depende do portal Power BI do Ministério da Saúde.
  Se o portal sair do ar, o download falha.

## Citação

Para citar o pacote em trabalhos acadêmicos:

> Santos, R. (2026). vigiar: Download Data from the VIGIAR Environmental Health
> Surveillance Dashboard. R package version 0.7.1.9000.
> https://github.com/santosry/vigiar

## Licença

MIT. Os dados baixados pertencem ao Ministério da Saúde / VIGIAR.
