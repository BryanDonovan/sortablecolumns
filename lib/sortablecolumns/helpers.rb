module Sortablecolumns
  module Helpers

    #Prints entire HTML table with content
    def print_table(collection, sorter, options={})
      klass = collection.first.class
      txt = print_table_thead(klass, sorter)
      txt << print_table_body(collection, sorter, options)
      return content_tag('table', txt, options[:table])
    end

    #Prints a single table column (TD element) with content
    def print_col(obj, sorter, col)
      col = col.to_s
      klass = obj.class
      txt = klass.send("#{sorter}_col_text",obj,col) 
      wrappers = []

      datatype = klass.send("#{sorter}_datatype",col) || 'string'

      if datatype == 'number'
        precision = klass.send("#{sorter}_precision",col) 
        txt = number_with_precision(txt, :precision => precision) if precision
      end

      if datatype == 'currency'
        precision = klass.send("#{sorter}_precision",col) 
        unit      = klass.send("#{sorter}_unit",col) 
        separator = klass.send("#{sorter}_separator",col) 
        delimiter = klass.send("#{sorter}_delimiter",col) 
        txt = number_to_currency(txt, :precision => precision, 
        :unit => unit, :separator => separator, :delimiter => delimiter)
      end

      if datatype == 'datetime' or datatype == 'date'
        if txt.respond_to?(:strftime)
          format = klass.send("#{sorter}_date_format",col)
          txt = txt.strftime(format)
        end
      end

      do_link = klass.send("#{sorter}_link?",col)

      if do_link
        link_ops = klass.send("#{sorter}_link_options",col).dup
        raise "link_options must be defined for #{klass}:#{col}" unless link_ops
        if link_ops[:object_url]
          #link_to failed in the tests in Rails 2.2.2
          url = send("#{klass.to_s.downcase}_url", obj)
          txt = link_to(txt, url)
        elsif link_ops[:controller] && link_ops[:action]
          if link_ops[:id] && link_ops[:id] == 'obj_id'
            link_ops[:id] = obj.id
          end
          if link_ops[:extras]
            extras = link_ops.delete(:extras)
            txt = link_to(txt, link_ops, extras)
          else
            if link_ops.size > 2
              # cycle through link_ops, other than controller, action, and id, 
              # and check if the option value is a method for this object.  If not, 
              # assign the value directly in the url.
              ops = link_ops.reject{|key,val| key == :controller || key == :action }# || key == :id}
              ops.each do |key, val|
                unless key == :id && val == 'obj_id'
                  if val.is_a?(String) || val.is_a?(Symbol)
                    link_ops[key] = obj.send(val) if val && obj.respond_to?(val.to_sym)
                  end
                end
              end
            end
            txt = link_to(txt, link_ops)
          end
        elsif link_ops[:url]
          url = link_ops[:url].gsub(/:id/, obj.id.to_s)
          txt = link_to(txt, url)
        end
      end

      print_options = klass.send("#{sorter}_print_options",col)
      wrappers << print_options['wrappers'] if print_options && print_options['wrappers']

      wrappers.flatten.each do |wrapper|
        if wrapper.is_a? Hash
          key = wrapper.keys.first
          extra_args = wrapper[key]
          txt = send(key, txt, extra_args)
        else
          txt = send(wrapper, txt)
        end
      end

      td_class = klass.send("#{sorter}_td_class",col)

      return content_tag("td", txt, :class => td_class)
    end

    #Prints single table row with content
    def print_table_row(obj, sorter, options={})
      txt = ''
      klass = obj.class
      cols = klass.send("#{sorter}_col_keys_in_order")
      cols.each do |col|
        txt << print_col(obj, sorter, col)
      end
      content_tag("tr", txt.html_safe, options)
    end

    #Prints table body with content
    def print_table_body(collection, sorter, options={})
      txt = ""
      if options[:tr] && options[:tr][:classes]
        alternate = true
        tr_classes = options[:tr][:classes]
      end
      tr_class = nil
      i = 0
      collection.each do |obj|
        if alternate 
          tr_class = tr_classes[i % 2]
        end
        txt << print_table_row(obj, sorter, :class => tr_class) 
        i += 1
      end
      content_tag("tbody", txt.html_safe)
    end

    #Prints single TH tag with content
    def print_col_heading(klass, sorter, col, options={})
      col      = col.to_s
      th_txt   = klass.send("#{sorter}_heading", col)
      th_class = klass.send("#{sorter}_th_class", col)
      return content_tag("th", '', :class => th_class) unless th_txt
      sortable = klass.send("#{sorter}_sortable?", col)
      return content_tag("th", th_txt, :class => th_class) unless sortable
      url = get_col_heading_url(klass, sorter, col)
      link = link_to(th_txt, url)
      #link = "<a href=\"#{url}\">#{th_txt}</a>"
      return content_tag("th", link, :class => th_class)
    end

    #Get URL for sortable table column header (TH element)
    def get_col_heading_url(klass, sorter, col)
      order_by    = col
      default_dir = 'asc'
      sort_ops = klass.send("#{sorter}_sort_options", col)
      if sort_ops
        order_by    = sort_ops['order_by']    if sort_ops['order_by']
        default_dir = sort_ops['default_dir'] if sort_ops['default_dir']
      end

      reg = Regexp.new(order_by.to_s)
      if params[:order_by] =~ reg
        dir = (params[:dir] == "asc") ? "desc" : "asc"
      else
        dir = default_dir
      end

      get_url(order_by, dir)
    end

    #get url for given set of params, order_by, and dir
    def get_url(order_by, dir)
      _params = params.dup
      _params[:order_by] = order_by
      _params[:dir] = dir 
      _params.delete(:page)
      url_for(_params)
    end

    #Prints a row of TH tags with content
    def print_table_heading_row(klass, sorter, options={})
      cols = klass.send("#{sorter}_col_keys_in_order")
      txt = ''
      cols.each do |col|
        txt << print_col_heading(klass, sorter, col)
      end
      content_tag("tr", txt.html_safe, options)
    end

    #Prints THEAD tags with content
    def print_table_thead(klass, sorter)
      content_tag('thead', print_table_heading_row(klass, sorter))
    end
  end 
end
