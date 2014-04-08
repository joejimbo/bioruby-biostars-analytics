# bio-biostars-analytics

[![Build Status](https://secure.travis-ci.org/joejimbo/bioruby-biostars-analytics.png)](http://travis-ci.org/joejimbo/bioruby-biostars-analytics)

Data-mining analysis that make use of this gem (newest to oldest):

-  [Analyzing the Biostar: Fourth Anniversary](http://joachimbaran.wordpress.com/2014/04/07/biostar_analysis_4th_year/)
-  [Uh-oh, Biostar: Three Years of User Metrics Analysis](http://joachimbaran.wordpress.com/2013/03/15/uh-oh-biostar/)
-  [BioStar: Activity of its BioStars](http://joachimbaran.wordpress.com/2012/03/20/biostar-activity-of-its-biostars/)
-  [BioStar: Is the BioStar fading? An Annual Follow-Up](http://joachimbaran.wordpress.com/2012/03/11/biostar-second-analysis/)
-  [BioStar: Is the BioStar fading?](http://joachimbaran.wordpress.com/2011/03/07/biostar-fading/)

## Installation

Biostars analytics can be installed as a Ruby gem:

    gem install bio-biostars-analytics

Statistical analytics requires the installation of [R](http://www.r-project.org) 2.15.0 or later; requires the installation
of the plyr package 2.15.1 or later.

## Usage

Data-mining: crawl the Biostars forum and retrieve data from the Biostar RESTful API; parameters
as of March 2014:

    biostars-analytics 96000 54

This will create two files: `<date>_api.tsv` and `<date>_crawled.tsv`

Various plots in PNG file format can be generated via:

    biostar_api_stats <date>_api.tsv
    biostar_crawled_stats <date>_crawled.tsv

### Command Line Usage Instructions

#### Data-Mining

    Usage: biostars-analytics max_post_number months_look_back [min_post_number]
    
    Required parameters:
      max_post_number    : highest number (ID) of the post that should
                           be mined for data; the crawler will go over
                           posts min_post_number to max_post_number
      months_look_back   : how many months back should queries to the
                           Biostar API go (1 month = 30 days); default
                           value is 1
    
    Optional parameters:
      min_post_number    : lowest number (ID) of the post that should
                           be mined for data
    
    Output (date matches the script\'s invokation):
      <date>_crawled.tsv : data mined from crawling over posts
      <date>_api.tsv     : data extracted from the Biostar API
    
    Example: mining Biostars in March 2014:
      biostars-analytics 96000 54

#### Statistics (based on RESTful API data)

Generates plots as PNG files in the current working directory.

    Usage: biostar_api_stats apitsvfile
    
    Example (data provided at http://github.com/joejimbo/bioruby-biostars-analytics):
      biostar_api_stats data/20140328_api.tsv

#### Statistics (based on forum mining/crawling)

Generates plots as PNG files in the current working directory.

    Usage: biostar_crawled_stats crawledtsvfile
    
    Example (data provided at http://github.com/joejimbo/bioruby-biostars-analytics):
      biostar_api_stats data/20140328_crawled.tsv

## Project Repository

Contributions can be made to the open repository on GitHub:

  [http://github.com/joejimbo/bioruby-biostars-analytics](http://github.com/joejimbo/bioruby-biostars-analytics)

The BioRuby community is on IRC server: irc.freenode.org, channel: #bioruby.

## Cite

If you use this software, please cite one of
  
* [BioRuby: bioinformatics software for the Ruby programming language](http://dx.doi.org/10.1093/bioinformatics/btq475)
* [Biogem: an effective tool-based approach for scaling up open source software development in bioinformatics](http://dx.doi.org/10.1093/bioinformatics/bts080)

## Biogems.info

This Biogem is published at (http://biogems.info/index.html#bio-biostars-analytics)

## Copyright

Copyright (c) 2014 Joachim Baran. See LICENSE.txt for further details.

