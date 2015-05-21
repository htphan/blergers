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
      tag_counts = []
      # select("id")
      tag_ids = []
      tags.each do |x|
        t_id = Blergers::Tag.where(name: x).pluck(:id)
        tag_ids << t_id[0]
      end
      tag_ids.each do |x|
        tag_count = Blergers::PostTag.where("tag_id == #{x}").count
        tag_name = Blergers::Tag.where(id: x).pluck(:name)
        tag_name = tag_name[0]
        tag_counts << [tag_count, tag_name]
      end
      puts "** Post Tagged Count Search Query **"
      tag_counts.each do |tag_count, tag_name|
        puts "#{tag_name} -> #{tag_count}"
      end
    end
  end

  class Tag < ActiveRecord::Base
    has_many :post_tags
    has_many :posts, through: :post_tags

    attr_reader :tag_counts

    def self.tag_total
      @tag_counts = []
      self.all.each do |x|
        t_id = x.id
        tag_count = Blergers::PostTag.where("tag_id == #{x.id}").count
        tag_name = self.where(id: x.id).pluck(:name)
        tag_name = tag_name[0]
        @tag_counts << [tag_count, tag_name]
      end
      @tag_counts
    end

    def self.top_tags
      self.tag_total
      tag_counts = @tag_counts.sort.reverse.each_slice(10).to_a
      puts "** Top 10 Most Used Tags **"
      tag_counts[0].each do |tag_count, tag_name|
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
