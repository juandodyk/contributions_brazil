library(tidyverse)
library(magrittr)
library(shiny)
library(shinythemes)
library(DT)
library(rio)
import_csv = function(..., keepLeadingZeros = TRUE)
  rio::import(..., keepLeadingZeros = keepLeadingZeros, setclass = "tibble")

firms = import_csv("data/firms.csv", encoding = "UTF-8")
firms = firms %>%
  left_join(firms %>%
              group_by(cnpj) %>%
              summarise(contributed_pre_ban = sum(contributions, na.rm = TRUE) > 0),
            by = "cnpj")
individuals = import_csv("data/individuals.csv", encoding = "UTF-8") %>%
  mutate(cnpj_year = paste0(cnpj, "_", year),
         shares_owns = shares_ordinary > 0,
         is_2010 = year == 2010,
         is_2012 = year == 2012,
         is_2016 = year == 2016,
         is_2018 = year == 2018) %>%
  mutate_if(is.logical, as.numeric)
ownership = import_csv("data/ownership.csv", encoding = "UTF-8")
contributions = import_csv("data/contributions.csv", encoding = "UTF-8")

# individuals %>%
#   select(cnpj, year, name, id = cpf) %>%
#   bind_rows(firms %>% select(cnpj, year, name) %>% mutate(id = cnpj)) %>%
#   mutate(id = map_chr(id, ~ ifelse(str_length(.) == 14, substr(., 1, 8), .))) %>%
#   inner_join(import_csv("data/contributions_relevant_not_grouped.csv", encoding = "UTF-8"),
#              by = c("id" = "CPFCNPJ_donor", "year")) %>%
#   export("data/contributions.csv")

event_studies = readRDS("data/event_study.rds")

convert_reals = function(money, year) {
  conversion =
    1/c(1.7292, 2.0484, 2.6572, 3.2551, 3.87) *
    c(1.19, 1.13, 1.09, 1.08, 1.03)
  names(conversion) = c(2010, 2012, 2014, 2016, 2018)
  money * conversion[as.character(year)]
}

bool_to_yes = function(x)
  ifelse(x > 0, "Yes", "")

firms_condensed = firms %>%
  mutate(contributions = convert_reals(contributions, year)) %>%
  group_by(cnpj) %>%
  summarise(name = first(name),
            family_firm = any(family_firm, na.rm = TRUE),
            contributions = sum(contributions, na.rm = TRUE),
            sector = first(sector),
            age = max(age)) %>%
  arrange(desc(contributions)) %>%
  mutate(family_firm = bool_to_yes(family_firm),
         contributions = prettyNum(round(contributions), big.mark = ",")) %>%
  select(`ID (CNPJ)` = cnpj,
         `Name` = name,
         `Family firm` = family_firm,
         `Contributions ($)` = contributions,
         `Sector` = sector,
         `Age` = age)

firms_variables = c('Assets' = 'assets',
                    'Return on assets' = 'roa',
                    'Age' = 'age',
                    'Ownership concentration' = 'ordinary_concentration_max',
                    'Shares in free float' = 'ordinary_shares_free_float')
