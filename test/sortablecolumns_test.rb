require 'rubygems'
require 'test/unit'
require 'mocha'
require 'hpricot'
$:.unshift File.dirname(__FILE__) + '/../lib'
require 'sortablecolumns'
require 'rails'
require 'action_dispatch/testing/integration'
require 'active_record/railtie'

module MySorterApp
  class Application < Rails::Application
  end
end

RAILS_ROOT = File.dirname(__FILE__) + '/../' 

#If you have SQLite3 installed along with the sqlite3-ruby gem, you can run this 
#test file without any prior setup.
#Based on test code for Rails' acts_as_tree
#http://dev.rubyonrails.org/svn/rails/plugins/acts_as_tree/test/acts_as_tree_test.rb

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

# AR keeps printing annoying schema statements
$stdout = StringIO.new

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
    create_table :people do |t|
      t.column :firstname, :string
      t.column :lastname, :string
      t.column :age, :integer
      t.column :description, :string
      t.column :balance, :decimal
      t.column :created_at, :datetime
      t.column :registered_at, :datetime
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

#---------------------------------------------------
# Models
#---------------------------------------------------
class Person < ActiveRecord::Base
  sortable_columns :mysorter, 
    :path_prefix => "/test/col_def_test_yaml_files"
  sortable_columns :tacosorter,
    :path_prefix => "/test/col_def_test_yaml_files"
  sortable_columns :default_sorter,
    :path_prefix => "/test/col_def_test_yaml_files"

  #Some mock methods. Normally we would have an AR object which could have been
  #created by a find_by_sql query, which could include methods such as these.
  def meat
    'Beef'
  end

  def type
    'Soft Shell'
  end

  def calories
    1200
  end

  def packaged_on
    Date.new(2008,01,03)
  end
end

class Dude < Person
  sortable_columns :dude_report, :subclass_name => 'Dude',
    :path_prefix => "/test/col_def_test_yaml_files"

  def dudename
    firstname
  end
end

class SubPerson < Person
  sortable_columns :cool_sorter_thing, :subclass_name => 'SubPerson',
  :path_prefix => "/test/col_def_test_yaml_files"
end

#---------------------------------------------------
# Routes 
#---------------------------------------------------
MySorterApp::Application.routes.draw do
  #   match 'products/:id' => 'catalog#view'
  match 'people/show/:id' => 'people#show', :as => :person
  match 'people/:person_id/foods' => 'foods#show', :as => :people_foods
  #match 'foods/meats/:id' => 'foods#show', :as => :meat

  #map.people_foods '/people/:person_id/foods',
    #:controller => 'foods',
    #:action => 'show'
  #simulate the RESTful urls:
  resources :dudes
  #map.dude '/dudes/:id',
    #:controller => 'dudes',
    #:action => 'show'

  match ':controller(/:action(/:id(.:format)))'
end


#---------------------------------------------------
# Tests
#---------------------------------------------------
class SortableColumnsTest < Test::Unit::TestCase
  def setup
    setup_db
    @person = Person.create(:firstname => "Billy", :lastname => "Jones", :age => 24, 
    :description => "Billy is an awesome guy.\nHowever, he is also a punk. He loves www.google.com. ")
    @person.save 
		@this_dir = File.expand_path(File.dirname(__FILE__))
  end

  def teardown
    teardown_db
  end

  def test_basic
    assert @person.valid?
  end

  def test_person_yaml_path
		expected = File.expand_path(File.join(@this_dir,"col_def_test_yaml_files/person/mysorter.yml")) 
    assert_equal expected, File.expand_path(Person.mysorter_yaml_path)
  end

  def test_sub_person_yaml_path
    #test sub-models & models with multi-word names, such as SubPerson
		expected = File.expand_path(File.join(@this_dir,"col_def_test_yaml_files/person/sub_person/cool_sorter_thing.yml")) 
    assert_equal expected, File.expand_path(SubPerson.cool_sorter_thing_yaml_path)
  end

  def test_person_mysorter_yaml_load
    col_defs = Person.mysorter_col_defs
    assert_equal Array, col_defs.class
    expected = {"firstname"=>
    {"link_options"=>{:action=>"show", :id=>'obj_id', :controller=>"people"},
    "td_class"=>"left",
    "heading"=>"First",
    "datatype"=>"string"}}
    assert_equal expected, col_defs[0]
  end

  def test_person_tacosorter_yaml_load
    col_defs = Person.tacosorter_col_defs
    assert_equal Array, col_defs.class
    expected = {"type"=>
      {"link_options"=>{'url'=>"http://www.tacotypes.com"},
      "heading"=>"Taco Type",
      "datatype"=>"string"}}
    assert_equal expected, col_defs[0]
  end

  def test_dude_yaml_path
		expected = File.expand_path(File.join(@this_dir,"col_def_test_yaml_files/person/dude/dude_report.yml")) 
    assert_equal expected, File.expand_path(Dude.dude_report_yaml_path)
  end

  def test_dude_yaml_load
    col_defs = Dude.dude_report_col_defs
    assert_equal Array, col_defs.class
    expected = {"dudename"=> {"link_options"=>{'object_url'=>true}, "heading"=>"Dudename", "datatype"=>"string"}}
    assert_equal expected, col_defs[0]
  end

  def test_dude_col_def_hash
    expected = {"registered_at"=>{"heading"=>"Registration Date", "datatype"=>"datetime"},
    "print_view"=>
    {"link_options"=>
    {"action"=>"print_view", "controller"=>"dudes", "person_id"=>"person_id"},
    "in_resultset"=>false,
    "heading"=>false,
    "print_text"=>"Print"},
    "lastname"=>{"heading"=>"Last", "datatype"=>"string"},
    "description"=>
    {"print_options"=>{"wrappers"=>[{"truncate"=>{:length => 5}}, "simple_format"]},
    "sortable"=>false,
    "heading"=>"Description",
    "datatype"=>"string"},
    "dudename"=>
    {"link_options"=>{"object_url"=>true},
    "heading"=>"Dudename",
    "datatype"=>"string"},
    "age"=>{"heading"=>"Age", "datatype"=>"number"},
    "created_at"=>
    {"date_format"=>"%m/%d/%Y at %I:%M%p",
    "heading"=>"Create Date",
    "datatype"=>"datetime"}}
    assert_equal expected, Dude.dude_report_col_def_hash
  end

  def test_col_keys_in_order
    assert_equal ['firstname','lastname','age','description','balance','edit','delete'], Person.mysorter_col_keys_in_order
    assert_equal ['type','meat','calories','packaged_on'], Person.tacosorter_col_keys_in_order
  end

  def test_heading
    assert_equal 'Last',        Dude.dude_report_heading('lastname')
    assert_equal 'Description', Dude.dude_report_heading('description')
    assert_equal 'Meat',        Person.tacosorter_heading('meat')
    assert_equal 'First',       Person.mysorter_heading('firstname')
    assert_equal false,         Person.mysorter_heading('edit')
  end

  def test_headings_in_order
    assert_equal  ['Taco Type','Meat','Calories','Packaged On'], Person.tacosorter_headings_in_order
    #should not include the print field in headings:
    assert_equal ['Dudename','Last','Age','Description', 'Create Date', 'Registration Date'], Dude.dude_report_headings_in_order  
    #should not include the edit field in headings:
    assert_equal ['First','Last','Age','Description','Balance'], Person.mysorter_headings_in_order
  end
  
  def test_datatype
    assert_equal 'string',  Dude.dude_report_datatype('lastname')
    assert_equal 'number', Dude.dude_report_datatype('age')
    assert_equal 'currency', Person.mysorter_datatype('balance')
  end

  def test_sortable
    assert_equal true,  Dude.dude_report_sortable?('lastname')
    assert_equal false, Dude.dude_report_sortable?('description')
    assert_equal false, Person.mysorter_sortable?('edit')
  end

  def test_link
    assert_equal true,  Person.mysorter_link?('firstname')
    assert_equal false, Person.mysorter_link?('description')
  end

  def test_sort_options
    assert_equal({"default_dir"=> 'desc'}, Person.mysorter_sort_options('age'))
    assert_equal nil, Person.mysorter_sort_options('description')
  end

  def test_print_options
    assert_equal({"wrappers"=> ['auto_link','sanitize', 'simple_format']}, Person.mysorter_print_options('description'))
    assert_equal({"wrappers"=> 'sanitize'}, Person.mysorter_print_options('lastname'))
    assert_equal nil, Person.mysorter_print_options('age')
    assert_equal({"wrappers"=> [{'truncate' => {:length => 5}},'simple_format']}, Dude.dude_report_print_options('description'))
  end

  def test_td_class
    assert_equal 'center', Person.mysorter_td_class('age')
    assert_equal nil,      Person.mysorter_td_class('lastname')
  end

  def test_precision
    assert_equal 2, Person.mysorter_precision('balance')
    assert_equal nil, Person.mysorter_precision('firstname')
  end

  def test_delimiter
    assert_equal " ", Person.mysorter_delimiter('balance')
    assert_equal ",", Person.mysorter_delimiter('age')
  end

  def test_separator
    assert_equal ",", Person.mysorter_separator('balance')
    assert_equal ".", Person.mysorter_separator('age')
  end

  def test_date_format
    assert_equal "%m/%d/%Y at %I:%M%p" , Dude.dude_report_date_format('created_at')
    #default:
    assert_equal "%Y-%m-%d %I:%M:%S", Dude.dude_report_date_format('registered_at')
    assert_equal "%m/%d/%Y", Person.tacosorter_date_format('packaged_on')
  end

  def test_default_sort_dir
    assert_equal "desc", Person.mysorter_default_sort_dir('age')
    assert_equal 'asc', Person.mysorter_default_sort_dir('firstname')
  end

  def test_col_def_for_yui
    expected = {:sortOptions=>{:defaultDir=>"YAHOO.widget.DataTable.CLASS_DESC"}, :key=>"age", :sortable=>true, 
    :label=>"Age", :formatter=>"number"}
    assert_equal expected, Person.mysorter_col_def_for_yui('age')
  end

  def test_col_defs_for_yui
    expected = [{:key=>"firstname", :sortable=>true, :label=>"First"},
    {:key=>"lastname", :sortable=>true, :label=>"Last"},
    {:key=>"age",
      :sortable=>true,
      :label=>"Age",
      :formatter=>"number",
      :sortOptions=>{:defaultDir=>"YAHOO.widget.DataTable.CLASS_DESC"}},
    {:key=>"description", :sortable=>false, :label=>"Description"},
    {:key=>"balance", :sortable=>true, :label=>"Balance", :formatter=>"currency"},
    {:key=>"edit", :sortable=>false, :label=>""},
    {:key=>"delete", :sortable=>false, :label=>""}]
    assert_equal expected, Person.mysorter_col_defs_for_yui
  end

  def test_fields_for_yui
    expected = [{:key=>"firstname"},
    {:key=>"lastname"},
    {:key=>"age", :parser=>"YAHOO.util.DataSource.parseNumber"},
    {:key=>"description"},
    {:key=>"balance", :parser=>"this.parseNumberFromCurrency"},
    {:key=>"edit"},
    {:key=>"delete"}]
    assert_equal expected, Person.mysorter_fields_for_yui
  end

  def test_default_yaml_col_defs_for_person
    expected='---
- id:
    sort_options:
      default_dir: asc
    datatype: number
    heading: Id
- firstname:
    heading: Firstname
    sortable: "false"
- lastname:
    heading: Lastname
    sortable: "false"
- age:
    sort_options:
      default_dir: asc
    datatype: number
    heading: Age
- description:
    heading: Description
    sortable: "false"
- balance:
    sort_options:
      default_dir: desc
    datatype: currency
    heading: Balance
- created_at:
    datatype: datetime
    heading: Created At
- registered_at:
    datatype: datetime
    heading: Registered At'
    
    default_col_defs = Person.default_col_defs(:yaml)
    assert_equal YAML.load(expected), YAML.load(default_col_defs)
  end

  def test_default_sorter_for_person
    assert_equal 'number', Person.default_sorter_datatype('age')
    assert_equal 'Balance', Person.default_sorter_heading('balance')
  end
end


#------------------------------------------------
# Helpers
#------------------------------------------------

class SortablecolumnsHelperTest < Test::Unit::TestCase

  class View
    include ActionView::Helpers
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::SanitizeHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
		include Rails.application.routes.url_helpers
    include Sortablecolumns::Helpers

    default_url_options[:host] = 'test.host'
    attr_accessor :params
    attr_accessor :request

    def initialize
      @request = ActionController::TestRequest.new
      @request.request_uri = 'http://' + default_url_options[:host] + "/people"
      @params = {}
      @params[:controller] = 'people'
      @params[:action] = 'index'
    end

    def protect_against_forgery?
      false
    end
  end

  def setup
    @view = View.new
    @view.stubs(:controller).returns('people')
    setup_db
    @person = Person.create(:firstname => "Billy", :lastname => "Jones", 
      :age => 24, :balance => '1234.5678',
      :description => "Billy is an awesome guy.\nHowever, he is also a punk. " +
        "<script src='http://www.badguy.com/death.js'/>He loves www.google.com")

    @person2 = Person.create(:firstname => "Joe", :lastname => "Shmoe", :age => 54, 
      :balance => '12.00', :description => "Joe rocks")

    created_at = DateTime.new(2008,4,28,9,26)
    registered_at = DateTime.new(2008,5,1,7,30)
    @dude = Dude.create(:firstname => "The Dude", :lastname => "Lebowski", :age => 45, 
    :description => "The Dude Speaks", :created_at => created_at, :registered_at => registered_at)

    #make sure a find_by_sql query works with an arbitrary attribute (person_id in this case)
    query = "select p.*, '23445' as person_id from people p where id = #{@dude.id}"
    @dude = Dude.find_by_sql(query).first
    
    @expected_person_row = "<tr><td class=\"left\"><a href=\"http://test.host/people/show/1\">Billy</a></td><td>Jones</td><td class=\"center\">24</td><td class=\"left\"><p>Billy is an awesome guy.\n<br />However, he is also a punk. <a href=\"http://www.google.com\">www.google.com</a></p></td><td class=\"right\">£1 234,57</td><td><a href=\"http://test.host/people/edit/1\">Edit</a></td><td><a href=\"http://test.host/people/destroy/1\" onclick=\"if (confirm('Are you sure?')) { var f = document.createElement('form'); f.style.display = 'none'; this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;var m = document.createElement('input'); m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method'); m.setAttribute('value', 'delete'); f.appendChild(m);f.submit(); };return false;\">Delete</a></td></tr>"
    @expected_person_row_alternate = @expected_person_row.gsub(/<tr>/, "<tr class=\"even\">")
    @expected_person2_row = "<tr><td class=\"left\"><a href=\"http://test.host/people/show/2\">Joe</a></td><td>Shmoe</td><td class=\"center\">54</td><td class=\"left\"><p>Joe rocks</p></td><td class=\"right\">£12,00</td><td><a href=\"http://test.host/people/edit/2\">Edit</a></td><td><a href=\"http://test.host/people/destroy/2\" onclick=\"if (confirm('Are you sure?')) { var f = document.createElement('form'); f.style.display = 'none'; this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;var m = document.createElement('input'); m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method'); m.setAttribute('value', 'delete'); f.appendChild(m);f.submit(); };return false;\">Delete</a></td></tr>"
    @expected_person2_row_alternate = @expected_person2_row.gsub(/<tr>/, "<tr class=\"odd\">")
    @expected_person_heading_row = "<tr><th><a href=\"http://test.host/people?dir=asc&order_by=firstname\">First</a></th><th><a href=\"http://test.host/people?dir=asc&order_by=lastname\">Last</a></th><th><a href=\"http://test.host/people?dir=desc&order_by=age\">Age</a></th><th>Description</th><th><a href=\"http://test.host/people?dir=asc&order_by=balance\">Balance</a></th><th class=\"invisible\"></th><th class=\"invisible\"></th></tr>"
  end

  def teardown
    teardown_db
  end

  def test_print_col_person_lastname
    assert_equal '<td>Jones</td>', @view.print_col(@person, 'mysorter', 'lastname')
    #while we're here, make sure we can use symbols or strings
    assert_equal '<td>Jones</td>', @view.print_col(@person, :mysorter, :lastname)
  end

  def test_print_col_person_description
    #should be same as: simple_format(sanitize(auto_link(@person.description)))
    expected = "<p>Billy is an awesome guy.\n<br />However, he is also a punk. <a href=\"http://www.google.com\">www.google.com</a></p>"
    html = @view.print_col(@person, :mysorter, :description)
    doc = Hpricot(html)
    td = doc.at("/td")
    assert_equal 'left', td['class']
    _p = doc.at("/td/p").inner_text
    assert _p.match(/Billy.*\n.*punk/)
    assert_equal 1, doc.search("/td/p/br").size
    link = doc.search("/td/p/a").last
    assert_equal 'http://www.google.com', link['href']
    assert_equal 'www.google.com', link.inner_text
    assert_equal 0, doc.search("/script").size
  end

  def test_print_col_dude_description
    #should be same as: simple_format(truncate(@dude.description, :length => 5))
    expected = "<p>Th...</p>"
    assert_equal "<td>#{expected}</td>", @view.print_col(@dude, :dude_report, :description)
  end

  def test_print_col_person_balance
    assert_equal "<td class=\"right\">£1 234,57</td>", @view.print_col(@person, :mysorter, :balance)
  end

  def test_print_col_person_age
    assert_equal "<td class=\"center\">24</td>", @view.print_col(@person, :mysorter, :age)
  end

  def test_print_col_person_firstname
    assert_equal "<td class=\"left\"><a href=\"/people/show/#{@person.id}\">Billy</a></td>", @view.print_col(@person, :mysorter, :firstname)
  end

  def test_print_col_dude_dudename
    assert_equal "<td><a href=\"http://test.host/dudes/#{@dude.id}\">The Dude</a></td>", @view.print_col(@dude, :dude_report, :dudename)
  end

  def test_print_col_taco_meat
    assert_equal "<td><a href=\"/foods/meats/#{@person.id}\">Beef</a></td>", @view.print_col(@person, :tacosorter, :meat)
  end

  def test_print_col_taco_type
    assert_equal "<td><a href=\"http://www.tacotypes.com\">Soft Shell</a></td>", @view.print_col(@person, :tacosorter, :type)
  end

  def test_print_col_taco_calories
    #testing if we can have extra parameters in the url
    assert_equal "<td><a href=\"/foods/calories?foo=bar\">1200.00</a></td>", @view.print_col(@person, :tacosorter, :calories)
  end

  def test_print_col_dude_print_view
    #testing if we can have extra parameters in the url, and those params are attributes in the resultset
    # e.g.
    #-
    #print_view:
    #  heading: Print
    #  link_options: 
    #    controller: dudes
    #    action: print_view
    #    person_id: person_id
    #
    # Where person_id is a field in the result set (in this test, there's a mock method instead)

    expected = "<td><a href=\"/dudes/print_view?person_id=23445\">Print</a></td>"
    assert_equal expected, @view.print_col(@dude, :dude_report, :print_view)
  end

  def test_print_col_dude_created_at
    expected = "<td>04/28/2008 at 09:26AM</td>"
    assert_equal expected, @view.print_col(@dude, :dude_report, :created_at)
  end

  def test_print_col_dude_registered_at
    expected = "<td>2008-05-01 07:30:00</td>"
    assert_equal expected, @view.print_col(@dude, :dude_report, :registered_at)
  end

  def test_print_col_person_packaged_on
    expected = "<td>01/03/2008</td>"
    assert_equal expected, @view.print_col(@person, :tacosorter, :packaged_on)
  end

  def test_print_col_edit
    expected = "<td><a href=\"/people/edit/#{@person.id}\">Edit</a></td>" 
    assert_equal expected, @view.print_col(@person, :mysorter, :edit)
  end

  def test_print_col_delete
    # Should be something like:
    # <td><a href=\"/people/destroy/1\" data-confirm=\"Are you sure?\" data-method=\"delete\" rel=\"nofollow\">Delete</a></td>
    html = @view.print_col(@person, :mysorter, :delete)
    doc = Hpricot(html)
    assert_equal 1, doc.search("/td").size
    link = doc.at("/td/a")
    assert_equal "/people/destroy/1", link['href']
    assert_equal "Delete", link.inner_text
    ['data-confirm', 'data-method', 'rel'].each do |attr|
      assert_not_nil link[attr]
    end
  end

  #---[ Column Headings ]-------------------------------------------------

  def test_get_url
    @view.params[:controller] = 'cars'
    @view.params[:action] = 'wheels'
    @view.params[:foo] = 'blah'
    @view.params[:bar] = '123'
    @view.params[:order_by] = 'wheel_type'
    @view.params[:dir] = 'desc'
    new_order = 'windshield_strength'
    new_dir = 'asc'
    expected = "/cars/wheels?bar=123&dir=asc&foo=blah&order_by=windshield_strength"
    assert_equal expected, @view.get_url(new_order, new_dir)
  end

  def test_get_url_with_page
    # If pagination is being used and a page param is in the url, it should be removed.  
    # That is, we don't want to sort the current page of results, we want to start 
    # back at the beginning (page 1) and sort that.  Maybe make this customizable in 
    # the future.

    @view.params[:controller] = 'cars'
    @view.params[:action] = 'wheels'
    @view.params[:foo] = 'blah'
    @view.params[:bar] = '123'
    @view.params[:order_by] = 'wheel_type'
    @view.params[:dir] = 'desc'
    @view.params[:page] = '2' 
    new_order = 'windshield_strength'
    new_dir = 'asc'
    expected = "/cars/wheels?bar=123&dir=asc&foo=blah&order_by=windshield_strength"
    assert_equal expected, @view.get_url(new_order, new_dir)
  end

  def test_person_heading_firstname
    expected = "<th><a href=\"/people?dir=asc&amp;order_by=firstname\">First</a></th>"
    assert_equal expected, @view.print_col_heading(Person, :mysorter, :firstname)

    #test if controller changes
    #@view.stubs(:controller).returns('blah')
    @view.params[:controller] = 'blah'
    expected = "<th><a href=\"/blah?dir=asc&amp;order_by=firstname\">First</a></th>"
    assert_equal expected, @view.print_col_heading(Person, :mysorter, :firstname)

    #test if action changes
    @view.params[:action] = 'foo'
    expected = "<th><a href=\"/blah/foo?dir=asc&amp;order_by=firstname\">First</a></th>"
    assert_equal expected, @view.print_col_heading(Person, :mysorter, :firstname)

    #test if sort direction changes
    @view = View.new
    @view.stubs(:controller).returns('people')
    @view.params[:order_by] = 'firstname'
    @view.params[:dir] = 'asc'
    #should switch the direction to descending:
    expected = "<th><a href=\"/people?dir=desc&amp;order_by=firstname\">First</a></th>"
    assert_equal expected, @view.print_col_heading(Person, :mysorter, :firstname)

    #test a url route that has more than just controller and action 
    @view = View.new
    @view.stubs(:controller).returns('people')
    @view.params[:controller] = 'foods'
    @view.params[:action] = 'show'
    @view.params[:person_id] = 1 
    expected = "<th><a href=\"/people/1/foods?dir=asc&amp;order_by=firstname\">First</a></th>"
    assert_equal expected, @view.print_col_heading(Person, :mysorter, :firstname)
  end

  def test_person_heading_age
    #default direction should be desc
    expected = "<th><a href=\"/people?dir=desc&amp;order_by=age\">Age</a></th>"
    assert_equal expected, @view.print_col_heading(Person, :mysorter, :age)
    @view.params[:order_by] = 'age'
    @view.params[:dir] = 'desc'
    #back to asc
    expected = "<th><a href=\"/people?dir=asc&amp;order_by=age\">Age</a></th>"
    assert_equal expected, @view.print_col_heading(Person, :mysorter, :age)
  end

  def test_person_heading_description
    #not sortable, so no link in heading
    expected = "<th>Description</th>"
    assert_equal expected, @view.print_col_heading(Person, :mysorter, :description)
  end

  def test_taco_heading_meat
    #test order_by sort_option from col_defs
    expected = "<th><a href=\"/people?dir=asc&amp;order_by=meats.id\">Meat</a></th>"
    assert_equal expected, @view.print_col_heading(Person, :tacosorter, :meat)
  end

  def test_person_heading_edit
    expected = "<th class=\"invisible\"></th>"
    assert_equal expected, @view.print_col_heading(Person, :mysorter, :edit)
  end

  def test_person_print_table_row
    html = @view.print_table_row(@person, :mysorter)
    doc = Hpricot(html)
    assert_equal 1, doc.search("/tr").size
    assert_equal 7, doc.search("/tr/td").size
    first_td = doc.at("/tr/td")
    assert_equal 'left', first_td['class']
    assert_equal "/people/show/1", first_td.at("/a")['href']
  end

  def test_person_print_table_heading_row
    html = @view.print_table_heading_row(Person, :mysorter)
    doc = Hpricot(html)
    assert_equal 1, doc.search("/tr").size
    assert_equal 7, doc.search("/tr/th").size
    first_th = doc.at("/tr/th")
    assert_equal "/people?dir=asc&order_by=firstname", first_th.at("/a")['href']
  end

  def test_person_print_table_thead
    expected = "<thead>#{@expected_person_heading_row}</thead>"
    html = @view.print_table_thead(Person, :mysorter)
    doc = Hpricot(html)
    assert_equal 1, doc.search("/thead").size
    assert_equal 7, doc.search("/thead/tr/th").size
  end


  def test_person_print_table_body
    people = [@person, @person2]
    expected = "<tbody>" + @expected_person_row + @expected_person2_row + "</tbody>"
    html = @view.print_table_body(people, :mysorter)
    doc = Hpricot(html)
    assert_equal 2, doc.search("/tbody/tr").size
    assert_equal 14, doc.search("/tbody/tr/td").size
  end

  def test_person_print_table
    people = [@person, @person2]
    html = @view.print_table(people, :mysorter)
    doc = Hpricot(html)
    assert_equal 1, doc.search("/table").size
    assert_equal 2, doc.search("/table/tbody/tr").size
    assert_equal 14, doc.search("/table/tbody/tr/td").size

    html = @view.print_table(people, :mysorter, 
      {:table => {:class => 'yui-skin-sam', :id => 'yui_table'}})
    doc = Hpricot(html)
    table = doc.at("/table")
    assert_equal 'yui-skin-sam', table['class']
    assert_equal 'yui_table', table['id']

    html = @view.print_table(people, :mysorter, 
      :table => {:class => 'yui-skin-sam', :id => 'yui_table'},
       :tr => {:classes => ['even','odd']})
    doc = Hpricot(html)
    assert_equal 'yui-skin-sam', table['class']
    assert_equal 'yui_table', table['id']
    rows = doc.search("/table/tbody/tr")
    first_td_row = rows[0]
    assert_equal 'even', first_td_row['class']
    second_td_row = rows[1]
    assert_equal 'odd', second_td_row['class']
  end
end
