class CallData
  require 'rest-client'
  attr_reader :raw_data, :data, :type

  def initialize params

    str_params = params.permit(:min_date, :max_date, :sort, :callback).to_h
      .inject("&") { |string, (k,v)| string += "#{k}=#{v}&" }.gsub(/\&$/, '')
    url = "#{ENV['API_PATH']}/call_data?sort=asc"
    url.tap { |x| x << str_params if str_params.length > 1 }

    RestClient::Request.execute method: :get, 
    url: url, 
    user: ENV['API_NAME'], 
    password: ENV['API_PW'] do |response, request, result, &block|
      case response.code
      when 200
        @raw_data = JSON.load(response.body).each_with_object({calls_offered: [], calls_handled: []}) do |hash, memo|
          hash.deep_symbolize_keys!
          hash[:timestamp] *= 1000
          hash.reject { |k,v| k == :id }
          %i(calls_handled calls_offered).each { |sym| memo[sym] << [hash[:timestamp], hash[sym]] }        
        end
        @data = case (@type = params[:callback])
        when 'all'
          [@raw_data, alt_interval(:both, false)].flatten
        when 'day', 'week', 'both'
          alt_interval(params[:callback].to_sym)
        else
          @raw_data
        end

      else
        response.return!(request, result, &block)
      end
    end
  end

  def alt_interval type, update = true

    raise(ArgumentError, "type must be a symbol matching :day, :week or :both") if %i(day week both).exclude? type
    args = case type
    when :day
      raw_alt_data(:beginning_of_day)
    else
      data = raw_alt_data([:beginning_of_week, :sunday])
      if type == :both
        day_data = raw_alt_data(:beginning_of_day, update)
        day_data.each { |k,v| day_data[k] = v.last(2) } if update
        [ day_data, data]
      else
        data
      end
    end
  end

  private
    def raw_alt_data args, last = false
      @raw_data.each_with_object(Hash.new) do |(type, data), memo|
        grouped = data.group_by { |hash| Time.at(hash[0]/1000).send(*args) }
        grouped = grouped.to_a.last(2).to_h if last 
        memo[type] = grouped.map do |k,v|
          [k.to_i*1000,v.inject(0) { |sum, ary| sum += ary.last }]
        end
      end
    end
end
