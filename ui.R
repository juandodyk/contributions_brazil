UI = list()

UI$data_main_panel = tabsetPanel(
  tabPanel("Firms", dataTableOutput('table_firms')),
  tabPanel("Leadership",
           titlePanel(textOutput('selected_firm')),
           selectInput('leadership_year', "Select a year", c()),
           tableOutput('table_leadership')),
  tabPanel("Ownership",
           titlePanel(textOutput('ownership_selected_firm')),
           selectInput('ownership_year', "Select a year", c()),
           tableOutput('table_ownership')),
  tabPanel("Contributions",
           titlePanel(textOutput('contrib_selected_firm')),
           selectInput('contrib_year', "Select a year", c()),
           tableOutput('table_contrib')),
  tabPanel("Contributions (plots)",
           titlePanel("Corporate contributions"),
           sidebarLayout(
             sidebarPanel(
               selectInput('plot_var_selection', "Select an independent variable",
                           names(firms_variables)),
               selectInput('plot_year_selection', "Select the year",
                           c(2010, 2012, 2014))
             ),
             mainPanel(plotOutput('contrib_plot'))
           ))
)

UI$data = tabPanel(
  "Data",
  UI$data_main_panel
)

UI$did = tabPanel(
  "Diff-in-diff",
  titlePanel("Event-study plots"),
  p("Linear probability models. The units are (individual, year). The DV is an indicator of whether
    the individual made a campaign contribution. I include time-varying individual-level controls,
    and individual-level and firm-year-level fixed effects. Then I interact indicators of the year with
    an indicator of membership to the controlling family (and other individual-level covariates).
    Standard errors are clustered at the individual level.
    The coefficients can be interpreted as departures by members of the family
    from parallel trends within the firm. The lines are 95% confidence intervals."),
  sidebarLayout(
    sidebarPanel(radioButtons("did_selection", label = h3("Select subset"),
                              choices = list("All firms" = 1,
                                             "Firms that made donations before 2015" = 2,
                                             "Firms that did not" = 3),
                              selected = 1)),
    mainPanel(plotOutput('event_study_plot'))
  )
)

UI$about = tabPanel(
  "About",
  titlePanel("About"),
  h3("Project Background"),
  p("This shiny app stems from the research for my paper 'The political behavior of family firms',
             co-authored with Pablo Balan (Harvard) and Ignacio Puente (MIT).
             In that paper we study the campaign contributions by publicly listed firms in Brazil.
             In particular, we focus on family firms, i.e., companies where top executives have
             kinship ties to owners. We argue that family firms have a comparative advantage at
             building and maintaining political connections. Consistent with the hypothesis,
             we find that family firms are more likely to make campaign contributions, controlling
             for sector, firm size, return on assets, age, and corporate governance variables.
             We also study a 2015 reform of the electoral law that banned contributions made by companies.
             We find that family firms were more capable of substituting the firm's contributions
             with donations by individuals in leadership positions.
             In particular, using a differences-in-differences design, we find that the ban increased
             the probability that members of the family make campaign donations."),
  h3("Data source"),
  p("I used web-scraping to get the data on firms from the CVM, Brazil's SEC.
    Firms that sell stock or bonds in public markets have to present an annual report to the CVM.
    From those reports I extracted several data about the firms.
    First, basic accounting data: main sector of activity, assets, profits, debt.
    Second, data on the ownership structure: the proportion of shares traded in public markets,
    the individuals and legal entities who own a block of voting shares, and, for legal entities,
    their ownership structure (recursively). I can automatically reconstruct who the ultimate owners are
    using an algorithm. Third, I have data on members of the board of directors and the top management:
    who they are, their position, their professional experience (I can detect if they served in
    elected office in government or they worked in the bureaucracy).
    Crucially for my research, firms have to disclose family ties among individuals in leadership
    positions (directors, top executives, blockholders).
    Finally, I match these data with the data on campaign contributions (using unique identifiers for
    both firms and individuals) provided by the electoral authorities.
    Thus, I know how much each firm and each individual contributed in each electoral cycle,
    and to which candidates/parties."),
  h3("About Me"),
  p("My name is Juan Dodyk and I study political economy with a focus on Latin America.
             You can reach me at juandodyk@g.harvard.edu."))

ui <- navbarPage(
  "Corporate campaign contributions in Brazil",
  UI$about,
  UI$data,
  UI$did)

shinyUI(fluidPage(theme = shinytheme("yeti"), ui))
