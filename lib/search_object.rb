class SearchObject < ActiveRecord::Base
  belongs_to    :searchable, :polymorphic => true
  after_destroy :remove_search_words
  after_create  :add_search_words
  
  private
  
  def count_search_words
    return {} unless searchable.is_a? Work
    [title, content].join(" ").strip.split(/[\s.,;:'"+=()\[\]]+/)\
      .map { |s| s.downcase }.reject { |s| s.length < 2 }.inject(Hash.new(0)) { |h, w| h[w] += 1; h }
  end
  
  def remove_search_words
    count_search_words.each do |w, c|
      sw = SearchWord.find_by_word(w)
      next unless sw
      sw.weight -= c
      next sw.destroy if sw.weight <= 0
      sw.save!
    end
  end
  
  def add_search_words
    count_search_words.each do |w, c|
      sw = SearchWord.find_or_initialize_by_word(w)
      sw.weight += c
      sw.save!
    end
  end
end
