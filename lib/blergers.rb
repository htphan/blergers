require 'pry'

$LOAD_PATH.unshift(File.dirname(__FILE__))
require "blergers/version"
require 'blergers/init_db'
require 'blergers/importer'

module Blergers
  class Post < ActiveRecord::Base
    has_many :post_tags
    has_many :tags, through: :post_tags

    def self.post(n)
      self.order(date: :desc).limit(10).offset((n-1)*10)
    end

    ## count_tagged_by(tags) where the tag parameter is an array of tag strings
    def self.count_tagged_by(tags)
      tag_counts = Blergers::Tag.joins(:post_tags).where(name: tags).group(:name).count
      tag_counts = tag_counts.sort_by { |key, value| value }.reverse.to_a
      puts "** Post Tagged Count Search Query **"
      tag_counts.each do |tag_name, tag_count|
        puts "#{tag_name} -> #{tag_count}"
      end
    end
  end

  class Tag < ActiveRecord::Base
    has_many :post_tags
    has_many :posts, through: :post_tags

    def self.top_tags
      tag_counts = Tag.joins(:post_tags).group(:name).count
      tag_counts = tag_counts.sort_by { |key, value| value }.reverse.each_slice(10).to_a
      puts "** Top 10 Most Used Tags **"
      tag_counts[0].each do |tag_name, tag_count|
        puts "#{tag_name} -> #{tag_count}"
      end
    end
  end

  class PostTag < ActiveRecord::Base
    belongs_to :post
    belongs_to :tag
  end
end

def add_post!(post)
  puts "Importing post: #{post[:title]}"

  tag_models = post[:tags].map do |t|
    Blergers::Tag.find_or_create_by(name: t)
  end
  post[:tags] = tag_models

  post_model = Blergers::Post.create(post)
  puts "New post! #{post_model}"
end

def run!
  blog_path = '/Users/brit/projects/improvedmeans'
  toy = Blergers::Importer.new(blog_path)
  toy.import
  toy.posts.each do |post|
    add_post!(post)
  end
end

binding.pry
