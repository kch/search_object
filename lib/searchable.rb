require 'set'

module Searchable
  RX_WORD_SPLITTER = /[\s.,;:"+=()\[\]]+/
  
  def self.searchable_models
    @searchable_models ||= []
  end
  
  def self.included base
    base.extend ClassMethods
  end
  
  def self.reset_all_search_objects!
    SearchObject.delete_all
    searchable_models.map(&:constantize).each { |m| m.find(:all).each(&:update_search_object!) }
  end
  
  module ClassMethods
    def searchable_by(*attrs, &block)
      make_searchable!
      attrs.each do |att|
        next write_inheritable_hash :searchable_by, att => block if block
        case
        when att == :*                   then searchable_by *content_columns.map(&:name)
        when att == :**                  then searchable_by *reflect_on_all_associations.map(&:name)
        when reflect_on_association(att) then searchable_by(att) { |r, a| searchable_content_for_association r, a }
        when column_names.include?(att.to_s),
             method_defined?(att)        then searchable_by(att) { |r, a| r.send a }
        else raise "wtf?: #{att}"
        end
      end
      
      def manage_search_words
        write_inheritable_attribute :manage_search_words, true
      end
    end
    
    def searchable_content_for_association(record, assoc_name)
      [record.send(assoc_name)].flatten.compact.map(&:searchable_content).join("\n\n")
    end
    
    def make_searchable!
      return if reflect_on_association :search_object
      Searchable.searchable_models << name
      named_scope :search, lambda { |str| search_params(str) }
      has_one     :search_object, :as => :searchable, :dependent => :delete
      after_save  :update_search_object!
    end
    
    def search_params(str)
      q = str.to_s.strip.split(RX_WORD_SPLITTER).uniq.join(" ")
      return {} if q.blank?
      quoted_q      = quote_value(q)
      title_score   = "MATCH (so.title)   AGAINST (#{quoted_q})"
      content_score = "MATCH (so.content) AGAINST (#{quoted_q})"
      klass         = base_class.name
      { :select     => "#{table_name}.*, #{title_score} AS title_score, #{content_score} AS content_score",
        :joins      => "INNER JOIN search_objects so ON 
                        so.searchable_id = `#{table_name}`.`#{primary_key}` AND
                        so.searchable_type = '#{klass}'",
        :conditions => content_score,
        :order      => "title_score DESC, content_score DESC, #{human_column}"
      }
    end
  end
  
  def manage_search_words?
    !!self.class.read_inheritable_attribute(:manage_search_words)
  end
  
  def searchable?
    true
  end
  
  def searchable_title
    human_id
  end
  
  def searchable_content
    return unless r = self.class.read_inheritable_attribute(:searchable_by)
    r.map { |k, v| v[self, k] }.join("\n\n")
  end  
  
  private
  
  def update_search_object!
    search_object.destroy if search_object
    raise "uh?" unless search_object(true).nil?
    build_search_object(:title => searchable_title, :content => searchable_content).save! if searchable?
  end
  
end
