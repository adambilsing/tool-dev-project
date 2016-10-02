stringifyKey = (val, reverse = false) ->
  locator = {true: ' ',false: '_'}
  (val.split(locator[reverse]).map (word) -> 
    word[0][if reverse then 'toLowerCase' else 'toUpperCase']() + word[1..-1].toLowerCase()).join locator[!reverse]

getSunday = (d) ->
  day = d.getDay()
  diff = d.getDate() - day
  date = new Date new Date(d.setDate(diff)).setHours(0,0,0,0)
  new Date date.setDate(date.getDate() - 7)

getHour = (d) ->
  new Date d.setHours(d.getHours()-1)

buildChart = (id, title, buttons) ->
  $("##{id}").highcharts 'StockChart',
    rangeSelector:
      buttons: buttons.concat [{type: 'all', text: 'All'}]
      inputEnabled: false
      selected: 0
    title: text: "Calls Offered & Handled (#{title})"
    exporting: enabled: false
    credits: enabled: false
    legend: enabled: true
    tooltip:
      formatter: ->
        date = Highcharts.dateFormat("%A, %b %e, %Y#{if id == 'min' then ', %H:%M' else ''}", @x)
        s = "<b>#{date}</b>"
        if @points?
          for point in @points
            s += "<br/><span style=color:#{point.series.color}>\u25CF</span>#{point.series.name }: #{point.y}"
        s
        
updateChart = (index, data) ->
  chart = Highcharts.charts[index]
  for series in chart.series
    reverse_key = stringifyKey series.name, true
    reverse_key = 'calls_offered' if reverse_key == 'navigator'
    length = series.data.length
    if length > 0
      num = length - 6
      ary = data[reverse_key].reverse()
      for point, i in ary
        series.addPoint(point, false) if point[0] > series.data[length-1].x
      while num != length
        for point, i in ary
          series.data[num].update(point[1]) if point[0] == series.data[num].x
        num += 1
  chart.redraw() 

requestAltData = ->
  date = new Date()
  url = window.location.origin
  $.getJSON url + "?min_date=#{alt_req}&callback=both", (data) ->
    for object, i in data
      updateChart i+1, object
    window.alt_req = window.alt_req = getSunday date
    setTimeout requestAltData, 1800000

$ ->
  buildChart 'min', '15 minute interval', [
      {
        count: 1
        type: 'day'
        text: '1D'
      }
      {
        count: 1
        type: 'week'
        text: '1W'
      }
    ]
  buildChart 'day', 'daily interval', [
      {
        count: 1
        type: 'week'
        text: '1W'
      }
      {
        count: 1
        type: 'month'
        text: '1M'
      }
    ]
  buildChart 'week', 'weekly interval', [
      {
        count: 12
        type: 'week'
        text: '3M'
      }
      {
        count: 24
        type: 'week'
        text: '6M'
      }
    ]

  do requestData = ->
    date = new Date()
    url = window.location.origin
    if min_req?
      $.getJSON url + "?min_date=#{min_req}", (data) -> updateChart 0, data
    else
      # one api call to rule them all
      $.getJSON url + "?callback=all", (data) ->
        for chart, i in Highcharts.charts
          for k,v of data[i]
  	        chart.addSeries {
  	          name: stringifyKey k
  	          data: v
  	        }, false
          chart.redraw()
  	    
  	    window.alt_req = getSunday date
  	    setTimeout requestAltData, 1800000
    window.min_req = getHour date
    setTimeout requestData, 600000