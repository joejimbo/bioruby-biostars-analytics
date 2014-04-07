
require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'chronic'
require 'date'
require 'json'

module BioBiostarsAnalytics

  # Categories in Biostar:
  # Type ID     Type
  #    1        Question
  #    2        Answer
  #    3        Comment
  #    4        Tutorial
  #    5        Blog
  #    6        Forum
  #    7        News
  #    8
  #    9        Tool
  #   10        FixMe
  #   11        Video
  #   12        Job
  #   13        Research Paper
  #   14        Tip
  #   15        Poll
  #   16        Ad
  @@CATEGORIES = 16

  # Extract the date (day, month, year) from a Biostar forum post formatted date string.
  def self.extract_date(datestring)
      # Major headache: weird years like "3.4 years ago"
      if datestring.match(/\d+\.\d+ years ago/) then
          return Chronic.parse("#{(datestring.sub(/\d+\./, '').sub(/\s.*$/, '').to_i * 5.2).to_i} weeks ago",
                                   :now => Chronic.parse(datestring.sub(/\.\d+/, '')))
      else
          return Chronic.parse(datestring)
      end
  end

  # Extracts data from the rendered forum post as well as the Biostar's "post" API.
  #
  # Algorithm:
  # 1.  mine data from the rendered forum post
  # 2.  retrieve limited information from Biostar's API
  # 3.  check that gathered data matches up
  # 4.  log it
  def self.minecontent(log, id)
      # This hash aggregates information about a particular Biostar question and its answers/comments:
      post = { 'id' => id }

      #
      # First: mine data from the rendered forum post
      #

      url = "http://www.biostars.org/p/#{id}/"
      page = nil

      begin
          page = open(url)
      rescue
          return
      end

      if page.base_uri.to_s != url then
          # Answer URL.
          return
      end

      # Question URL that contains the question, its answers and edits.
      doc = Hpricot(page.read)

      # Bail out if this page does not explicitly mentions a question.
      return unless doc.search('doc.title') or doc.search('doc.title')[0].inner_html.match(/^Question:/)

      users = []

      # Extract user interactions: questions asked, answered and edits being made
      times = doc.search('span.relativetime|div.lastedit').map { |element|
          element.inner_html.sub(/^[^0-9]+/, '').sub(/by\s+$/, '').split("\n").first.strip
      }
      links = (doc/'a').delete_if { |link|
          if link.get_attribute('href') then
              not link.get_attribute('href').match(/^\/u\/\d+\//) # Has to be a relative link, or we catch Dropbox link-outs too...
          else
              true
          end
      }.map { |userlink| "#{userlink.get_attribute('href').gsub(/[\/u]+/, '')}\t#{userlink.inner_html}" }
      votes = doc.search('div.vote-count').map { |vote|
          if vote.inner_html.match(/^\d+$/) then
              vote.inner_html.to_i
          else
              nil
          end
      }
      tags = doc.search('a.tag').map { |link|
          link.inner_html
      }
      # Sanity check: times and users need to match up (i.e., both arrays need to be of the same length)
      unless times.length == links.length then
          $stderr.puts "Post ##{id}: recorded times and author links do not match up (#{times.length} vs. #{links.length})."
          return
      end
      # Sanity check: there cannot be more votes than times/links
      if votes.length > times.length then
          $stderr.puts "Post ##{id}: there are more votes than recorded user actions? (#{votes.length} vs. #{links.length})"
          return
      end
      # Question/answer specific stats regarding votes:
      question_vote = votes[0]
      answer_number = votes[1..-1].compact.length
      answer_min_vote = votes[1..-1].compact.sort[0]
      answer_max_vote = votes[1..-1].compact.sort[-1]
      answer_avg_vote = nil
      answer_avg_vote = (answer_min_vote + answer_max_vote).to_f / 2.0 if answer_min_vote and answer_max_vote
      # Helper variables to deal with the "votes" array, which is shorter than the times/links arrays.
      # These variables determine when the index counter for the "votes" array is incremented and when
      # said index is valid.
      vote_used = false
      vote_index = 0
      # Go through each time occurrence/author link pair (and also consider votes):
      post['records'] = times.length
      times.each_index { |index|
          # Sanity check: first time is not an update...
          if index == 0 and times[index].match(/updated/) then
              $stderr.puts "Post ##{id}: First recorded time is also an update?"
              return
          end
          # Sanity check: first time is also not a comment...
          if index == 0 and votes[index] == nil then
              $stderr.puts "Post ##{id}: First recorded time is a comment?"
              return
          end
          action = 'answered'
          action = 'asked' if index == 0
          if votes[vote_index] == nil and not vote_used then
              action = 'commented'
              vote_used = true
          end
          if times[index].match(/updated/) then
              action = 'edited'
          else
              vote_index += 1
              vote_used = false
          end
          times[index] = times[index].sub(/^[^0-9]+/, '')
          datetime = extract_date(times[index])
          post["#{index}"] = {
              'datestring' => times[index],
              'year' => datetime.year,
              'month' => datetime.month,
              'day' => datetime.day,
              'action' => action,
              'uid' => links[index],
              'question_vote' => question_vote,
              'answer_number' => answer_number,
              'answer_min_vote' => answer_min_vote,
              'answer_max_vote' => answer_max_vote,
              'answer_avg_vote' => answer_avg_vote,
              'tags' => tags
          }
      }

      page.close

      #
      # Second: retrieve limited information from Biostar's API
      #

      url = "http://www.biostars.org/api/post/#{id}/"

      begin
          doc = JSON.parse(open(url).read)
      rescue
          return
      end
      
      # Extract the limited information the API offers:
      post['api_creation_date'] = Chronic.parse(doc['creation_date'])
      post['api_answer_number'] = doc['answer_count']
      post['api_question_vote'] = doc['score']
      post['api_type'] = doc['type']
      post['api_type_id'] = doc['type_id']

      #
      # Third: check that gathered data matches up (API and data mined results are matching)
      #

      # Warning: number of answers matches
      #
      # Cannot be used as sanity check, because the Biostar implementation actually returns
      # a wrong number of answers. For example, http://www.biostars.org/p/7542/ (20 March 2014)
      # says "4 answers" even though there are clearly just three answers being displayed.
      # The same applies to underreporting of answers, such as in http://www.biostars.org/p/10927/
      # (20 March 2014), where 12 answers are shown on the web-page, but the summary on top
      # reports only 11 answers.
      unless post['api_answer_number'] == post['0']['answer_number'] then
          $stderr.puts "Post ##{id}: number of answers differ (#{post['api_answer_number']} vs. #{post['0']['answer_number']}). Resetting number returned by API; using actual count of answers visible to the user."
          post['api_answer_number'] = post['0']['answer_number']
      end

      # Sanity check: voting score for the question matches
      unless post['api_question_vote'] == post['0']['question_vote'] then
          $stderr.puts "Post ##{id}: mismatch between API's reported question vote and data mined voting score (#{post['api_question_vote']} vs. #{post['0']['question_vote']})."
          return
      end

      #
      # Fourth: log it
      #

      (0..post['records']-1).each { |index|
          record = post["#{index}"]
          log.puts "#{post['id']}\t#{record['datestring']}\t#{record['year']}\t#{record['month']}\t#{record['day']}\t#{record['action']}\t#{record['uid']}\t#{record['question_vote']}\t#{record['answer_number']}\t#{record['answer_min_vote']}\t#{record['answer_max_vote']}\t#{record['answer_avg_vote']}\t#{record['tags'].join(',')}\t#{post['api_type']}\t#{post['api_type_id']}"
     }
  end

  # Extracts data from Biostar's "stats" API.
  def self.minehistory(log, age)
      url = "http://www.biostars.org/api/stats/#{age}/"

      begin
          stats = JSON.parse(open(url).read)
      rescue
          return
      end
      
      # Extract the limited information the API offers:
      parseddate = Chronic.parse(stats['date'])
      stats['year'] = parseddate.year
      stats['month'] = parseddate.month
      stats['day'] = parseddate.day
      
      (1..@@CATEGORIES).each { |category|
          stats["new_posts_in_category_#{category}"] = 0
      }

      # Types of votes in Biostar:
      #   Accept
      #   Bookmark
      #   Downvote
      #   Upvote
      stats['new_votes_of_type_Accept'] = 0
      stats['new_votes_of_type_Bookmark'] = 0
      stats['new_votes_of_type_Downvote'] = 0
      stats['new_votes_of_type_Upvote'] = 0

      stats['posters'] = []
      stats['poster_ages'] = []
      stats['root_post_ages'] = []
      stats['vote_post_ages'] = []
      stats['biostarbabies'] = []

      if stats.has_key?('x_new_users') then
          stats['x_new_users'].each { |post|
              @user_age[post['id']] = age
              stats['biostarbabies'] = stats['biostarbabies'] + [ post['id'] ]
          }
          stats['new_users'] = stats['x_new_users'].length
      else
          stats['new_users'] = 0
      end

      if stats.has_key?('x_new_posts') then
          stats['x_new_posts'].each { |post|
              @post_age[post['id']] = age
              stats['posters'] = stats['posters'] + [ post['author_id'] ]
              stats['poster_ages'] = stats['poster_ages'] + [ @user_age[post['author_id']] ]
              stats['root_post_ages'] = stats['root_post_ages'] + [ @post_age[post['root_id']] ] if post['root_id'] != post['id']
              stats["new_posts_in_category_#{post['type_id']}"] = stats["new_posts_in_category_#{post['type_id']}"] + 1
          }
          stats['new_posts'] = stats['x_new_posts'].length
      else
          stats['new_posts'] = 0
      end

      # Poster age might not be applicable when having gone too far back in time...
      stats['poster_ages'].reject! { |i| i == nil }

      if stats.has_key?('x_new_votes') then
          stats['x_new_votes'].each { |vote|
              stats['vote_post_ages'] = stats['vote_post_ages'] + [ @post_age[vote['post_id']] ] if vote['type'] == 'Upvote' or vote['type'] == 'Downvote'
              stats["new_votes_of_type_#{vote['type']}"] = stats["new_votes_of_type_#{vote['type']}"] + 1
          }
          stats['new_votes'] = stats['x_new_votes'].length
      else
          stats['new_votes'] = 0
      end

      line = "#{age}\t#{stats['date']}\t#{stats['year']}\t#{stats['month']}\t#{stats['day']}\t"
      (1..@@CATEGORIES).each { |category|
          line << "#{stats["new_posts_in_category_#{category}"]}\t"
      }
      line << "#{stats['new_votes_of_type_Accept']}\t"
      line << "#{stats['new_votes_of_type_Bookmark']}\t"
      line << "#{stats['new_votes_of_type_Downvote']}\t"
      line << "#{stats['new_votes_of_type_Upvote']}\t"
      line << "#{stats['new_posts']}\t#{stats['new_votes']}\t#{stats['new_users']}\t"
      line << "#{stats['posters'].join(',')}\t#{stats['poster_ages'].join(',')}\t#{stats['root_post_ages'].join(',')}\t#{stats['vote_post_ages'].join(',')}\t#{stats['biostarbabies'].join(',')}\t"

      log.puts line
  end

  def self.cli
    if not ARGV.length.between?(2, 3) or
       not ARGV[0].match(/\d+/) or
       not ARGV[1].match(/\d+/) or
       (ARGV.length == 3 and not ARGV[2].match(/\d+/))then
      puts 'Usage: biostars-analytics max_post_number months_look_back [min_post_number]'
      puts ''
      puts 'Required parameters:'
      puts '  max_post_number    : highest number (ID) of the post that should'
      puts '                       be mined for data; the crawler will go over'
      puts '                       posts min_post_number to max_post_number'
      puts '  months_look_back   : how many months back should queries to the'
      puts '                       Biostar API go (1 month = 30 days); default'
      puts '                       value is 1'
      puts ''
      puts 'Optional parameters:'
      puts '  min_post_number    : lowest number (ID) of the post that should'
      puts '                       be mined for data'
      puts ''
      puts 'Output (date matches the script\'s invokation):'
      puts '  <date>_crawled.tsv : data mined from crawling over posts'
      puts '  <date>_api.tsv     : data extracted from the Biostar API'
      puts ''
      puts 'Example: mining Biostars in March 2014:'
      puts '  biostars-analytics 96000 54'
      exit 1
    end

    max_post_number = ARGV[0].to_i
    months_look_back = ARGV[1].to_i
    min_post_number = 1
    min_post_number = ARGV[2].to_i if ARGV.length == 3

    # Make sure not to buffer stdout, so that it is possible to
    # snoop around whilst the script is running.
    STDOUT.sync = true

    today = Time.now.strftime('%Y%m%d')
    crawler_log = File.open("#{today}_crawled.tsv", 'w')
    api_log = File.open("#{today}_api.tsv", 'w')

    (min_post_number..max_post_number).each { |i|
        minecontent(crawler_log, i)
    }

    @post_age = {}
    @user_age = {}

    (1..months_look_back*30).to_a.reverse.each { |i|
        minehistory(api_log, i)
    }

    crawler_log.close
    api_log.close
  end

end

