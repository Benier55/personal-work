# R script to scrape World Series ratings off Wikipedia, process the data, and graph it for a historical perspective.
# Created by David H. Montgomery, dhmontgomery.com

library(rvest)
library(dplyr)
library(tidyr)
devtools::install_github("hadley/ggplot2") # Install beta version of ggplot with subtitle support
library(ggplot2)

setwd("~/Dropbox/Sharing Folder/Code/World Series ratings")

# Scrape the data
url <- "https://en.wikipedia.org/wiki/World_Series_television_ratings" # Set the URL
ratings <- url %>%
  read_html() %>%
  html_nodes(xpath='//*[@id="mw-content-text"]/table[2]') %>% # Point to the right table on the page via its xpath ID
  html_table(fill = TRUE) # Fill out any missing cells
ratings <- ratings[[1]] # Extract the data frame from the list created above
ratings <- ratings[-24,] # Remove the cancelled 1994 World Series

# Clean the data
ratings[,3] <- gsub("\\[[^\\]]*\\]", "",ratings[,3], perl=TRUE) # Remove footnoted brackets
ratings[,6] <- gsub("\\[[^\\]]*\\]", "",ratings[,6], perl=TRUE)
# Convert the data from a wide format (one column each per game of a series) to a tall format (all data in a single column, with another column identifying which game)
ratings <- ratings %>% gather(Game, Ratings, 5:11) %>% arrange(Year,Game) %>% select(-4) # Also drop the averages column
ratings[,5] <- gsub("\\[[^\\]]*\\]", "",ratings[,5], perl=TRUE) # Remove more brackets
# Ratings and total viewers are in the same column. Let's separate them, awkwardly.
ratings[,5] <- gsub("\\(","π",ratings[,5]) # Convert left-parentheses in the Ratings column into a distinctive symbol, in this case π
ratings[,5] <- gsub("\\)","",ratings[,5]) # Delete all right-parentheses
ratings <- subset(ratings, Ratings != "No Game") # Remove all games that weren't played
ratings <- ratings %>% separate(Ratings, c("Share","Raw"), sep = "π") %>% separate(Share, c("Ratings","Share"), sep = "/", convert = TRUE) # Separate the Ratings column at our pi symbols into new Ratings, Share and Raw figures.
ratings$Raw <- gsub("\n"," ",ratings$Raw) # Clean up some newline characters in the Raw column
ratings$Raw <- as.numeric(gsub(" M viewers","",ratings$Raw)) # Delete the units label and convert to numeric

# Graph the ratings
a <- ggplot(ratings, aes(Year,Raw)) + # Plotting year vs. raw numbers
	geom_smooth() + # Add a smoothing line
	geom_point(size = 2, aes(color = Game)) + # Increase the point size and color points by which game of the Series they were
	labs( # Add a title, subtitle and caption
		title = "World Series ratings (1984-present)",
		subtitle = "By David H. Montgomery, dhmontgomery.com",
		caption = "Data from wikipedia.org/wiki/World_Series_television_ratings"
	) +
	ylab("Millions of viewers") + # Label the y-axis
	theme_bw() # Set a clean theme
ggsave("ratings.png") # Save the file

# Graph it, but faceted by game of the series
b <- ggplot(ratings, aes(Year,Raw)) +
	geom_point(size = 2) + # No smoothing surve. No colors
	labs(
		title = "World Series ratings (1984-present)",
		subtitle = "By David H. Montgomery, dhmontgomery.com",
		caption = "Data from wikipedia.org/wiki/World_Series_television_ratings"
	) +
	ylab("Millions of viewers") +
	theme_bw() +
	facet_grid(. ~ Game) # Facet the chart by game
ggsave("ratings-facet.png") # Save the faceted image file