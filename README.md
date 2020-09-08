# Shiny app to explore campaign contributions of Brazilian firms

## Project Background

This shiny app stems from the research for my paper 'The political behavior of family firms',
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
             the probability that members of the family make campaign donations.
             
## Data sources

I used web-scraping to get the data on firms from the CVM, Brazil's SEC.
    Firms that sell stock or bonds in public markets have to present an annual report to the CVM.
    From those reports I extracted several data about the firms.
* First, basic accounting data: main sector of activity, assets, profits, debt.
* Second, data on the ownership structure: the proportion of shares traded in public markets,
    the individuals and legal entities who own a block of voting shares, and, for legal entities,
    their ownership structure (recursively). I can automatically reconstruct who the ultimate owners are
    using an algorithm.
* Third, I have data on members of the board of directors and the top management:
    who they are, their position, their professional experience (I can detect if they served in
    elected office in government or they worked in the bureaucracy).
* Crucially for my research, firms have to disclose family ties among individuals in leadership
    positions (directors, top executives, blockholders).
* Finally, I match these data with the data on campaign contributions (using unique identifiers for
    both firms and individuals) provided by the electoral authorities.
    Thus, I know how much each firm and each individual contributed in each electoral cycle,
    and to which candidates/parties.
    
## About Me

My name is Juan Dodyk and I study political economy with a focus on Latin America.
             You can reach me at juandodyk@g.harvard.edu.
