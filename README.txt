= SortableColumns

* https://github.com/bdondo/sortablecolumns

== DESCRIPTION:

SortableColumns is a Rails plugin that allows easy creation of sortable HTML tables as plain HTML or as a YUI DataTable (requires YUI4Rails plugin - http://rubyforge.org/projects/yui4rails/).  Table column characteristics (e.g., default sort direction, data type, CSS attributes, and methods to wrap the output in) are defined in YAML files (more options to be added later, such auto-detecting the column types, using a hash, etc.). Multiple table column definitions can be created for a single model.


Also see: ActiveRecord::Acts::SortableColumns::ClassMethods#sortable_columns

== INSTALL:

* sudo gem install sortablecolumns
* IMPORTANT: create a directory named col_defs in your app/models directory if you want to use the default YAML directory (otherwise you can specify a path using :path_prefix).

== FEATURES/PROBLEMS:

=== Features
* Simple to define column characteristics in YAML
* Can be used with regular HTML or with YUI DataTable (http://developer.yahoo.com/yui/datatable/)
* Allows definitions of arbitrary columns, so you aren't limited to the columns in your model.  E.g., 
  you can use custom SQL queries that return a mix of columns from different models or "virtual" columns
  created in the SQL query.
* Test coverage for all current features.

== SYNOPSIS:
* First, create a directory to store your column definitions YAML files.  The default location SortableColumns will look is app/models/col_defs. 
* Create a YAML file for the configuration of your table columns.
* NEW: You can now set a :sorter_name of :default_sorter which will guess the configuration of the model's table. You can also use ModelName.default_col_defs(:yaml) to generate YAML output with these same defaults.
* Call sortable_tables in your model
* Run query (get an ActiveRecord result set)
* Render table in your view

=== Example Usage
Say we have a Person model (or a custom SQL query result) with the following columns/attributes:
* firstname - string, should be a link to the people/show action, TD CSS class of "left".
* lastname - string, should be wrapped in sanitize.
* age - integer, default sort direction: descending. TD CSS class: "center".
* description - string/text - should have a TD CSS class of "left", should be wrapped in auto_link, sanitize, and simple_format.
* balance - decimal/currency - precision of 2, comma for a separator, space for delimiter, British pound for unit. Default sort: descending.
* edit and detroy links, called "Edit" and "Delete" (which, of course, are not fields in the query result, but will be in the displayed table).

We're going to call this sorter "mysorter".  This will be the name of the YAML file and the name passed into the sortable_columns method in the model.

==== Model:

  class Person < ActiveRecord::Base
    sortable_columns :mysorter
    # or if you want to use the defaults:
    # sortable_columns :default_sorter

    # method to run query with sort options
    def self.find_for_mysorter(options = {})
      order_by = options[:order_by]
      dir = options[:dir]
      query = "select * from people"
      query << " order by #{order_by}" if order_by
      query << " #{dir}" if dir
      Person.find_by_sql(query)
    end
  end

==== YAML file:

  The YAML file needs to be in an ordered format (i.e., it gets loaded into Ruby 
  as an Array).  The order of the columns in the YAML file determines their 
  display order when rendered as HTML.

-
  firstname:
    heading: First
    datatype: string
    link_options:
      controller: people
      action: show
      id: obj_id
    td_class: left

-
  lastname:
    heading: Last
    datatype: string
    print_options:
      wrappers: sanitize
-
  age:
    datatype: number
    sort_options:
      default_dir: desc
    td_class: center
-
  description:
    datatype: string
    sortable: false
    print_options:
      wrappers:
        - auto_link
        - sanitize
        - simple_format
    td_class: left
-
  balance:
    datatype: currency
    precision: 2
    separator: ","
    delimiter: " "
    unit: £
    td_class: right
-
  created_at:
    heading: Create Date
    datatype: datetime
    date_format: "%m/%d/%Y at %I:%M%p"
-
  edit:
    in_resultset: false
    heading: false
    th_class: invisible
    print_text: Edit
    link_options:
      controller: people
      action: edit
      id: obj_id
-
  delete:
    in_resultset: false
    heading: false
    th_class: invisible
    print_text: Delete
    link_options:
      controller: people
      action: destroy
      id: obj_id
      extras:
        method: delete
        confirm: Are you sure?

In the link_options, use obj_id to specify that the current object's id field should be used.
You can also have extra parameters in the url that are attributes in the resultset.
 e.g.
  -
    print_view:
      heading: Print   
      link_options:     
      controller: dudes    
      action: print_view   
      person_id: person_id   

...where person_id is a field (method) in the result set that will be invoked.

==== Controller:

  def index #plain HTML table
    @people = Person.find_for_mysorter(options=params.dup)
    respond_to do |format|
      format.html
    end
  end

  def yui #YUI DataTable
    @people = Person.find_for_mysorter(options=params.dup)
    @col_defs = Person.mysorter_col_defs_for_yui
    @data_keys = Person.mysorter_fields_for_yui

    @data_table = Yui4Rails::Widgets::DataTable.new(:table_div_id => "markup",
      :col_defs => @col_defs,
      :data_keys => @data_keys,
      :table_id => 'yui_table')

    @data_table.paginate(5)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

==== View:

 <%= print_table(@people, :mysorter %>

Or if you want alternating styles for table rows:
 <%= print_table(@people, :mysorter, :tr => {:classes => ['even','odd']}) %>

And you can specify a table CSS class & id:
 <%= print_table(@people, :mysorter, :table => {:class => 'yui-skin-sam', :id => 'yui_table'}) %>

For YUI DataTable, add the followoing after the print_table call:
 <%= @data_table.render(:source => :html)%>
Also make sure the table is inside a div with the same id as specified in the controller when using the YUI DataTable.

== REQUIREMENTS:

* YUI4Rails gem if you want to use YUI datatables

== DISCLAIMER 

This is beta-quality software. It works well according to my tests, but the API may change and other features may be added.

== LICENSE:

(The MIT License)

Copyright (c) 2008-2011 Bryan Donovan

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
