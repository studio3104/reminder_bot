require 'logger'
require 'twitter'

module ReminderBot
  def self.twitter
    @twitter_client ||= Twitter::REST::Client.new do |c|
      c.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      c.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
      c.access_token = ENV['TWITTER_ACCESS_TOKEN']
      c.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end
  end

  def self.stream
    @stream_client ||= Twitter::Streaming::Client.new do |c|
      c.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      c.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
      c.access_token = ENV['TWITTER_ACCESS_TOKEN']
      c.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end
  end

  def self.run
    require 'awesome_print'
    streaming_thread = Thread.start {
      stream.user do |tweet|
        next unless tweet.is_a?(Twitter::Tweet)
        next if tweet.retweet?
        next unless tweet.text.match(/^(\@__reminder__|＠リマインダー)/)
        process_tweet(tweet)
      end
    }

    tweet_remind_thread = Thread.start {
    }

    follow_or_unfollow_thread = Thread.start {
      loop do
        follow_or_unfollow()
        sleep 1000
      end
    }

    streaming_thread.join
    tweet_remind_thread.join
    follow_or_unfollow_thread.join
  end

  def self.process_tweet(tweet)
    time, remind_text = parse_tweet(tweet)
    unknown_messasge = ''
    unknown_messasge += 'いつ' unless time
    unknown_messasge += 'なにを' unless remind_text
    if !unknown_messasge.empty?
      unknown_messasge += 'sadgadおもいださせてあげればいいの？'
      res = twitter.update('@' + tweet.user.username + ' ' + unknown_messasge, in_reply_to_status_id: tweet.id)
    end
  end

  def self.parse_tweet(tweet)
    [nil, nil]
  end

  def self.follow_or_unfollow
    friends = twitter.friends.to_a
    followers = twitter.followers.to_a

    to_follow = followers - friends
    to_unfollow = friends - followers

    to_follow.each do |user|
      twitter.follow(user.id)
    end
    to_unfollow.each do |user|
      twitter.unfollow(user.id)
    end
  end
end

ReminderBot.run
