
shinyServer(function(input, output, session) {

  # Firms

  output$table_firms = renderDataTable({
    firms_condensed %>%
      datatable(selection = 'single')
  })

  firm_table_selection <- reactive({
    input$table_firms_rows_selected
  })

  # Leadership

  output$selected_firm = renderText({
    row = firm_table_selection()
    if(is.null(row)) return("Please select a firm")
    firms_condensed$`Name`[row]
  })

  leadership_year_selection = reactive({
    input$leadership_year
  })

  observe({
    row = firm_table_selection()
    if(is.null(row)) years = c()
    else {
      cnpj_selected = firms_condensed$`ID (CNPJ)`[row]
      years = firms %>% filter(cnpj == cnpj_selected) %$% year
    }
    updateSelectInput(session, 'leadership_year', choices = years)
    updateSelectInput(session, 'ownership_year', choices = years)
    updateSelectInput(session, 'contrib_year', choices = years)
  })

  output$table_leadership = renderTable({
    row = firm_table_selection()
    year_selected = leadership_year_selection()
    if(is.null(row) || is.null(year_selected)) return(NULL)
    cnpj_selected = firms_condensed$`ID (CNPJ)`[row]
    individuals %>%
      filter(cnpj == cnpj_selected, year == year_selected) %>%
      mutate(is_in_family = has_tie * family_firm,
             contributions = convert_reals(contrib_total, year)) %>%
      arrange(desc(has_tie), desc(is_manager), desc(is_in_bod),
              desc(contributions), desc(age)) %>%
      mutate_at(vars(is_in_family, is_manager, is_in_bod,
                     public_sector, politician), bool_to_yes) %>%
      select(`ID (CPF)` = cpf,
             `Name` = name,
             `Is member of the family` = is_in_family,
             `Is Manager` = is_manager,
             `Is in board of directors` = is_in_bod,
             `Age` = age,
             `Worked in public sector` = public_sector,
             `Held elected office` = politician,
             `Contributions ($)` = contributions,
             `Contributions (parties)` = contribs_parties)
  })

  # Ownership

  output$ownership_selected_firm = renderText({
    row = firm_table_selection()
    if(is.null(row)) return("Please select a firm")
    firms_condensed$`Name`[row]
  })

  ownership_year_selection = reactive({
    input$ownership_year
  })

  output$table_ownership = renderTable({
    row = firm_table_selection()
    year_selected = ownership_year_selection()
    if(is.null(row) || is.null(year_selected)) return(NULL)
    cnpj_selected = firms_condensed$`ID (CNPJ)`[row]
    ownership %>%
      filter(cnpj == cnpj_selected, year == year_selected) %>%
      mutate(p = 100 * p,
             pt = 100 * pt,
             entity_id = recode(entity_id,
                                "__OUTROS__" = "(Free float)",
                                "__ACOES_TESOURARIA__" = "(In treasury)")) %>%
      arrange(desc(p)) %>%
      select(`Entity ID` = entity_id,
             `Name` = name,
             `Voting shares (%)` = p,
             `Total shares (%)` = pt)
  })

  # Contributions

  output$contrib_selected_firm = renderText({
    row = firm_table_selection()
    if(is.null(row)) return("Please select a firm")
    firms_condensed$`Name`[row]
  })

  contrib_year_selection = reactive({
    input$contrib_year
  })

  output$table_contrib = renderTable({
    row = firm_table_selection()
    year_selected = contrib_year_selection()
    if(is.null(row) || is.null(year_selected)) return(NULL)
    cnpj_selected = firms_condensed$`ID (CNPJ)`[row]
    contributions %>%
      filter(cnpj == cnpj_selected, year == year_selected) %>%
      mutate(amount = convert_reals(amount, year),
             contrib_type =
               recode(contrib_type,
                      "cand" = "Candidate",
                      "com" = "Committee",
                      "par" = "Party")) %>%
      arrange(date) %>%
      select(`Donor name` = name,
             `State` = UF,
             `Party` = party_id,
             `Amount ($)` = amount,
             `Date` = date,
             `Recipient type` = contrib_type,
             `Candidate ID` = CPF_candidate,
             `Office` = Cargo,
             `Candidate occupation` = occupation)
  })

  # Plots

  plot_var_selection = reactive({ input$plot_var_selection })
  plot_year_selection = reactive({ input$plot_year_selection })

  output$contrib_plot = renderPlot({
    variable = firms_variables[plot_var_selection()] %>% unname()
    p = firms %>%
      filter(!foreign, !state_owned, !is.na(family_firm),
             year == plot_year_selection()) %>%
      mutate(contributions = convert_reals(contributions, year),
             `Firm type` =
               ifelse(family_firm>0, "Family firm", "Non-family firm"),
             roa = income/assets,
             roa = ifelse(roa >= 0 & roa <= 1, roa, NA)) %>%
      rename(x = !!variable) %>%
      ggplot(aes(x = x,
                 y = contributions,
                 color = `Firm type`,
                 group = `Firm type`,
                 shape = `Firm type`)) +
      theme_classic() +
      geom_point(size = 2) +
      scale_shape_manual(values = c(17, 16)) +
      geom_smooth(method = lm, se = FALSE) +
      scale_color_manual(values = c("#FC4E07", "#00AFBB")) +
      scale_y_log10() +
      theme(legend.position = "top") +
      ylab("Contributions by the firm ($)") +
      xlab(plot_var_selection())
    if(variable == 'assets') p = p + scale_x_log10()
    p
  })

  # Diff-in-diff

  did_selection = reactive({ input$did_selection })

  output$event_study_plot = renderPlot({
    model = if(did_selection() == 1) event_studies$model1 else event_studies$model2

    model %>% summary() %$%
      coefficients %>%
      as.data.frame() %>%
      rownames_to_column("variable") %>%
      as_tibble() %>%
      filter(str_starts(variable,
                        switch (did_selection(),
                                `1` = "family_firm:has_tie",
                                `2` = "family_firm:has_tie:firm",
                                `3` = "family_firm:has_tie:I"
                        ))) %>%
      mutate(year = str_extract(variable, "[0-9]+")) %>%
      bind_rows(tibble(year = "2014", Estimate = 0, `Cluster s.e.` = 0)) %>%
      mutate(Year = as.integer(year)) %>%
      ggplot(aes(x = Year, y = Estimate,
                 ymin = Estimate - qnorm(0.975) * `Cluster s.e.`,
                 ymax = Estimate + qnorm(0.975) * `Cluster s.e.`)) +
      geom_pointrange() +
      geom_hline(yintercept = 0, linetype = 2, colour = "grey60") +
      geom_vline(xintercept = 2015, linetype = 2, colour = "grey60") +
      theme_classic()
  })
})
