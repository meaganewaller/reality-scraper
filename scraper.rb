require 'open-uri'
require 'nokogiri'
require 'pry'
require 'json'

class Scraper
  file = File.open('contestants.json', "w")

  ### JSON DATA STRUCTURE
  # {
  #   season_name: {
  #     url: url
  #     contestants: [
  #         [ name, birthday ],
  #         [ name, birthday ]
  #     ]
  #   }

  # }

  survivor_json = {}
  survivor_seasons_url = 'https://survivor.fandom.com/wiki/Category:Seasons'
  base_url = 'https://survivor.fandom.com'
  html = open(survivor_seasons_url)

  doc = Nokogiri::HTML(html)

  season_categories = doc.css('#mw-content-text').css('.category-page__first-char')

  valid_seasons = season_categories.select do |category|
    if category.children.text.strip.to_i.to_s == category.children.text.strip
      category
    end
  end

  season_urls = []

  valid_seasons.each do |season|
    season.next_element.css('a.category-page__member-link').map do |s|
      title = s.attributes['title'].value
      link = s.attributes['href'].value
      survivor_json[title] = { url: link }
      survivor_json[title][:contestants] = []
    end.flatten
  end


  survivor_json.keys.each do |season_name|
    url = survivor_json[season_name][:url]
    season_html = URI.open("#{base_url}/#{url}")
    season_doc = Nokogiri::HTML(season_html)
    contestants = season_doc.css('.wikitable')[0].css('b a')
    contestants.each do |contestant|
      contestant_url = contestant.attributes['href'].value
      contestant_html = URI.open("#{base_url}/#{contestant_url}")
      contestant_doc = Nokogiri::HTML(contestant_html)
      birthday = contestant_doc.css("div[data-source='birthdate']").css('.pi-data-value').children.text
      name = contestant_doc.css("h2[data-source='title']").children.text
      survivor_json[season_name][:contestants] << [name, birthday]
    end
  end

  file.puts(survivor_json.to_json)
end
