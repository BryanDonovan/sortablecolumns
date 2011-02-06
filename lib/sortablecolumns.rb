Dir[File.join(File.dirname(__FILE__), "sortablecolumns/**/*.rb")].sort.each { |lib| require lib }
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Sortablecolumns)
ActionView::Base.send(:include, Sortablecolumns::Helpers)
